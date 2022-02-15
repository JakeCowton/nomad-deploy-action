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
    curl -L "https://releases.hashicorp.com/nomad/$NOMAD_VERSION/nomad_${NOMAD_VERSION}_linux_amd64.zip" -o nomad.zip && unzip nomad.zip
    curl -L "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -o jq && chmod +x jq
fi

IMAGE_FULL_NAME="${INPUT_IMAGE_NAME}:${INPUT_IMAGE_TAG}"

# shellcheck disable=SC2034
GROUP_INDEX="${INPUT_GROUP_INDEX:-0}"

# shellcheck disable=SC2034
TASK_INDEX="${INPUT_TASK_INDEX:-0}"

UPDATES=".Job.TaskGroups[$GROUP_INDEX].Tasks[$TASK_INDEX].Config.image=\"$IMAGE_FULL_NAME\""

if [ -n "${INPUT_NOMAD_TAG_LABEL:-}" ]; then
    UPDATES="${UPDATES} | .Job.TaskGroups[$GROUP_INDEX].Tasks[$TASK_INDEX].Config.labels[0][\"$INPUT_NOMAD_TAG_LABEL\"]=\"$INPUT_IMAGE_TAG\""
fi

# shellcheck disable=SC2090
./nomad job inspect \
    -tls-skip-verify \
    -address=$INPUT_NOMAD_ADDR \
    -namespace=$INPUT_NOMAD_NAMESPACE \
    -region=$INPUT_NOMAD_REGION $INPUT_JOB_NAME \
    | \
    ./jq -r $UPDATES \
    | \
    curl -X POST -H "Content-Type: application/json" --data-binary @- $INPUT_NOMAD_ADDR/v1/jobs

