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
        --port "${NOMAD_PORT:-4646}"
}

if [ -n "${AWS_SECURITY_GROUP:-}" ]; then
    _changeSecurityGroupRule authorize
    trap "_changeSecurityGroupRule revoke" INT TERM EXIT
fi

NOMAD_VERSION="${NOMAD_VERSION:-1.1.4}"
curl -L "https://releases.hashicorp.com/nomad/$NOMAD_VERSION/nomad_${NOMAD_VERSION}_linux_amd64.zip" -o nomad.zip &&  unzip nomad.zip
curl -L "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -o jq && chmod +x jq

JOB_NAME=bot
TASK_INDEX="${TASK_INDEX:-0}"
ECR_URI=257779808675.dkr.ecr.us-east-1.amazonaws.com/api/bot:
DOCKER_TAG=main-081d008
./nomad job inspect $JOB_NAME | ./jq -r ".Job.TaskGroups[0].Tasks[$TASK_INDEX].Config.image=\"$ECR_URI$DOCKER_TAG\"" | curl -X POST -H "Content-Type: application/json" --data-binary @- $NOMAD_ADDR/v1/jobs

