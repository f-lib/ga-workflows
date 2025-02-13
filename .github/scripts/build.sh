#!/bin/bash
set -eux -o pipefail

ENV=$1
TARGET_TYPE=$2
TARGET_NAME=$3
REGIONS=$4
OS=$5
ARCH=$6
MY_GITHUB_LOGIN=$7
AWS_ACCOUNT_ID=$8
DRY_RUN=$9
REPO_NAME=${10}
ALL_REGIONS=${11}

if [[ $DRY_RUN == "true" ]]; then
  exit 0
fi

LAMBDA_NAME=flicspy-$ENV-$REPO_NAME-$TARGET_NAME
CLUSTER_NAME=flicspy-$ENV-$REPO_NAME
SERVICE_NAME=flicspy-$ENV-$REPO_NAME-$TARGET_NAME
IMAGE=flicspy-$ENV-$REPO_NAME-$TARGET_TYPE-$TARGET_NAME:$OS-$ARCH
S3_CACHE_BUCKET=flicspy-$ENV-$REPO_NAME-docker-cache
S3_CACHE_PREFIX=$TARGET_TYPE-$TARGET_NAME-$OS-$ARCH

  docker buildx build \
  --progress plain \
  -t $IMAGE \
  --platform=local \
  --provenance=false \
  -f ./go/cmd/$TARGET_TYPE/$TARGET_NAME/Dockerfile \
  --build-arg MY_GITHUB_LOGIN=${MY_GITHUB_LOGIN} \
  --build-arg TARGET_TYPE=$TARGET_TYPE \
  --build-arg TARGET_NAME=$TARGET_NAME \
  --target final \
  --cache-from type=s3,region=us-east-2,bucket=$S3_CACHE_BUCKET,prefix=$S3_CACHE_PREFIX/ \
  --cache-to type=s3,region=us-east-2,bucket=$S3_CACHE_BUCKET,prefix=$S3_CACHE_PREFIX/ \
  --load \
  ./go

docker run $IMAGE go test ./...

# Push to all regions, including black.
for REGION in $(set -e; echo $ALL_REGIONS | jq -r '.[]')
do
  ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
  REMOTE_IMAGE=$ECR_URI/$IMAGE
  docker image tag $IMAGE $REMOTE_IMAGE
  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI
  docker image push $REMOTE_IMAGE
done

# Deploy to blue and green regions
for REGION in $(set -e; echo $REGIONS | jq -r '.[]')
do
  ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
  REMOTE_IMAGE=$ECR_URI/$IMAGE
  if [[ $TARGET_TYPE == "lambda" ]]; then
    aws lambda update-function-code --function-name $LAMBDA_NAME --image-uri $REMOTE_IMAGE --region $REGION
  elif [[ $TARGET_TYPE == "ecs" ]]; then
    aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $REGION 1>/dev/null
  fi
done