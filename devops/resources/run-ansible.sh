#!/usr/bin/env bash

set -ex

cd $WORKSPACE/configuration
pip install -r requirements.txt
pip install awscli
export AWS_PROFILE=$deployment_tag

env


set +x
# Need to get util.sh in the workspace
# . util.sh
assume-role(){
    ROLE_ARN="${1}"
    SESSIONID=$(date +"%s")

    RESULT=(`aws sts assume-role --role-arn $ROLE_ARN \
            --role-session-name $SESSIONID \
            --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
            --output text`)

    export AWS_ACCESS_KEY_ID=${RESULT[0]}
    export AWS_SECRET_ACCESS_KEY=${RESULT[1]}
    export AWS_SECURITY_TOKEN=${RESULT[2]}
    export AWS_SESSION_TOKEN=${AWS_SECURITY_TOKEN}
}

# Assume the role that will allow running ec2.py for getting a dynamic inventory
assume-role ${ROLE_ARN}

set -x

cd $WORKSPACE/configuration/playbooks

# Pattern must be supplied explicitly as we take a conservative
# approach given that ec2.py will provide a dynamic inventory
if [[ -z "${PATTERN}" ]]; then
  ANSIBLE_PATTERN="-i ${PATTERN}"
else
  ANSIBLE_PATTERN="__NONE__"
fi

if [[ -z "${INVENTORY}" ]]; then
  ANSIBLE_INVENTORY="-i ${INVENTORY} "
else
  ANSIBLE_INVENTORY="-i ./ec2.py"
fi

if [[ -z "${BECOME_USER}" ]]; then
  ANSIBLE_BECOME=" --become --become-user=${BECOME_USER} "
fi

ansible ${ANSIBLE_PATTERN} ${ANSIBLE_INVENTORY} -u ${ANSIBLE_SSH_USER} ${ANSIBLE_BECOME} -m ${ANSIBLE_MODULE_NAME} \
-a ${ANSIBLE_MODULE_ARGS}
