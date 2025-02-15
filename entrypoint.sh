#!/bin/sh

set -euxo pipefail

readonly PUBLIC_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

_changeSecurityGroupRule() {
    aws \
        --region "${AWS_REGION:-us-east-1}" \
        ec2 "$1-security-group-ingress" \
        --group-id "$AWS_SECURITY_GROUP" \
        --protocol tcp \
        --cidr "$PUBLIC_IP/32" \
        --port "${INPUT_SG_NOMAD_PORT:-4646}"
}

if [ -n "${AWS_SECURITY_GROUP:-}" ]; then
    _changeSecurityGroupRule authorize
    trap "_changeSecurityGroupRule revoke" INT TERM EXIT
fi

if [ ! -f ./nomad ]
then
    NOMAD_VERSION="${INPUT_NOMAD_VERSION:-1.1.4}"
    curl -sL "https://releases.hashicorp.com/nomad/$NOMAD_VERSION/nomad_${NOMAD_VERSION}_linux_amd64.zip" -o nomad.zip && unzip nomad.zip
    curl -sL "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -o jq && chmod +x jq
fi

IMAGE_FULL_NAME="${INPUT_IMAGE_NAME}:${INPUT_IMAGE_TAG}"

# shellcheck disable=SC2034
GROUP_INDEX="${INPUT_GROUP_INDEX:-0}"

# shellcheck disable=SC2034
TASK_INDEX="${INPUT_TASK_INDEX:-0}"

export GROUP_INDEX
export TASK_INDEX
export IMAGE_FULL_NAME

_updateImageAndLabel() {
    if [ -n "${INPUT_NOMAD_TAG_LABEL:-}" ]; then
        # Update image and label
        ./nomad job inspect \
            -tls-skip-verify \
            -address=$INPUT_NOMAD_ADDR \
            -namespace=$INPUT_NOMAD_NAMESPACE \
            -region=$INPUT_NOMAD_REGION \
            $1 \
            | \
            ./jq -r ".Job.TaskGroups[$GROUP_INDEX].Tasks[$TASK_INDEX].Config.image=\"$IMAGE_FULL_NAME\" | .Job.TaskGroups[$GROUP_INDEX].Tasks[$TASK_INDEX].Config.labels[0][\"$INPUT_NOMAD_TAG_LABEL\"]=\"$INPUT_IMAGE_TAG\"" \
            | \
            curl -s -X POST -H "Content-Type: application/json" --data-binary @- $INPUT_NOMAD_ADDR/v1/jobs
    else
        # Update Image
        ./nomad job inspect \
            -tls-skip-verify \
            -address=$INPUT_NOMAD_ADDR \
            -namespace=$INPUT_NOMAD_NAMESPACE \
            -region=$INPUT_NOMAD_REGION \
            $1 \
            | \
            ./jq -r ".Job.TaskGroups[$GROUP_INDEX].Tasks[$TASK_INDEX].Config.image=\"$IMAGE_FULL_NAME\"" \
            | \
            curl -s -X POST -H "Content-Type: application/json" --data-binary @- $INPUT_NOMAD_ADDR/v1/jobs
    fi
}

export -f _updateImageAndLabel

JOB_LIST=$(./nomad job status \
            -tls-skip-verify \
            -address=$INPUT_NOMAD_ADDR \
            -namespace=$INPUT_NOMAD_NAMESPACE \
            -region=$INPUT_NOMAD_REGION)

# Check for no running jobs
NO_JOB_STR="No running jobs"
echo "JOB LIST:\n$JOB_LIST\n"

if [ "$JOB_LIST" = "$NO_JOB_STR" ]; then
    echo "There are no jobs, exiting\n"
    exit 0
else
    echo "There are jobs in namespace\n"
fi

# Check for no jobs with prefix
JOBS_WITH_PREFIXES=$(echo "$JOB_LIST" | grep $INPUT_JOB_NAME_PREFIX)
NO_JOBS_WITH_PREFIXES_STR=""
echo "JOBS WITH PREFIXES:\n$JOBS_WITH_PREFIXES\n"

if [ "$JOBS_WITH_PREFIXES" = "$NO_JOBS_WITH_PREFIXES_STR" ]; then
    echo "There are no jobs with prefix, exiting\n"
    exit 0
else
    echo "There are jobs with prefix\n"
fi

# Check for no running jobs with prefix
RUNNING_JOBS=$(echo "$JOBS_WITH_PREFIXES" | grep -E "running|pending")
NO_RUNNING_JOBS_WITH_PREFIXES_STR=""
echo "RUNNING JOBS:\n$RUNNING_JOBS\n"

if [ "$RUNNING_JOBS" = "$NO_RUNNING_JOBS_WITH_PREFIXES_STR" ]; then
    echo "There are no running jobs with prefix, exiting\n"
    exit 0
else
    echo "There are running jobs with prefix\n"

    JOB_NAMES=$(echo "$RUNNING_JOBS" | cut -f 1 -d ' ')

    echo "Jobs found $JOB_NAMES"
    echo "$JOB_NAMES" | xargs --no-run-if-empty -I {} -n 1 bash -c '_updateImageAndLabel "$@"' _ {}
    exit 0
fi
exit 0
