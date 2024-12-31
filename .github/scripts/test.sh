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

S3_CACHE_BUCKET=flicspy-$ENV-$REPO_NAME-docker-cache
S3_CACHE_PREFIX=$TARGET_TYPE-$TARGET_NAME-$OS-$ARCH-gotest
GO_TEST_IMAGE=go-test-image

docker buildx build \
--progress plain \
-t $GO_TEST_IMAGE \
--platform=local \
--provenance=false \
-f ./go/cmd/$TARGET_TYPE/$TARGET_NAME/Dockerfile \
--build-arg MY_GITHUB_LOGIN=${MY_GITHUB_LOGIN} \
--build-arg TARGET_TYPE=$TARGET_TYPE \
--build-arg TARGET_NAME=$TARGET_NAME \
--target base \
--cache-from type=s3,region=us-east-2,bucket=$S3_CACHE_BUCKET,prefix=$S3_CACHE_PREFIX/ \
--cache-to type=s3,region=us-east-2,bucket=$S3_CACHE_BUCKET,prefix=$S3_CACHE_PREFIX/ \
--load \
./go

docker run $GO_TEST_IMAGE go test ./...

