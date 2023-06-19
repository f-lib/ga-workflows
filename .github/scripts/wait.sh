#!/bin/bash
set -eux -o pipefail

ENV=$1
TARGET_TYPE=$2
TARGET_NAME=$3
REGION=$4
ARCH=$5
MY_GITHUB_LOGIN=$6
AWS_ACCOUNT_ID=$7
DRY_RUN=$8

if [[ $DRY_RUN == "true" ]]; then
  exit 0
fi

MS="ms-activity"

LAMBDA_NAME=flicspy-$ENV-$MS-$TARGET_NAME
CLUSTER_NAME=flicspy-$ENV-$MS
SERVICE_NAME=flicspy-$ENV-$MS-$TARGET_NAME

if [[ $TARGET_TYPE == "lambda" ]]; then
  time aws lambda wait function-updated --function-name $LAMBDA_NAME --region $REGION
elif [[ $TARGET_TYPE == "ecs" ]]; then
  time aws ecs wait services-stable --cluster $CLUSTER_NAME --service $SERVICE_NAME --region $REGION
fi
