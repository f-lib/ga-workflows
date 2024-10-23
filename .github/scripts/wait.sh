#!/bin/bash
set -eux -o pipefail

ENV=$1
TARGET_TYPE=$2
TARGET_NAME=$3
REGION=$4
DRY_RUN=$5
REPO_NAME=$6

if [[ $DRY_RUN == "true" ]]; then
  exit 0
fi

LAMBDA_NAME=flicspy-$ENV-$REPO_NAME-$TARGET_NAME
CLUSTER_NAME=flicspy-$ENV-$REPO_NAME
SERVICE_NAME=flicspy-$ENV-$REPO_NAME-$TARGET_NAME

if [[ $TARGET_TYPE == "lambda" ]]; then
  time aws lambda wait function-updated --function-name $LAMBDA_NAME --region $REGION
elif [[ $TARGET_TYPE == "ecs" ]]; then
  time aws ecs wait services-stable --cluster $CLUSTER_NAME --service $SERVICE_NAME --region $REGION
fi
