#!/usr/bin/env bash
##
## Container build for Platform Manager
##

# Exit script on first error
set -o errexit

# only for local build
source build_config

# Set envs
VCMTS_ROOT="/usr/src/vcmts"
IMAGE_NAME=${REGISTRY_URL}/vcmts-platform-management-tool
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz -C ${VCMTS_ROOT}

cp patches/manager-Containerfile.ubi8 ${VCMTS_ROOT}/vcmts/tools/vcmts-pm/Containerfile.ubi8
cd ${VCMTS_ROOT}/vcmts/tools/vcmts-pm

buildah --storage-driver vfs bud --build-arg VCMTS_VERSION=$VCMTS_VERSION -t ${IMAGE_TAG} Containerfile.ubi8
buildah --storage-driver vfs push ${IMAGE_TAG}