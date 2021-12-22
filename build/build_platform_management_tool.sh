#!/usr/bin/env bash
##
## Container build for Platform Manager
##

# Exit script on first error
set -o errexit

# only for local build
# source build_config

# Set envs
VCMTS_ROOT="/usr/src/vcmts"
IMAGE_NAME=${REGISTRY_URL}/vcmts-platform-management-tool
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}

# Check if image already exist
buildah pull $IMAGE_TAG
EXISTS=`buildah inspect $IMAGE_TAG >/dev/null 2>&1 && echo yes || echo no`
if [[ $EXISTS == yes ]]; then
    exit 0
fi

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz -C ${VCMTS_ROOT}

cp containerfiles/platform-management-tool-Containerfile.ubi8 ${VCMTS_ROOT}/vcmts/tools/vcmts-pm/Containerfile.ubi8
cd ${VCMTS_ROOT}/vcmts/tools/vcmts-pm

buildah --storage-driver vfs bud --build-arg VCMTS_VERSION=$VCMTS_VERSION -t ${IMAGE_TAG} Containerfile.ubi8
buildah --storage-driver vfs push ${IMAGE_TAG}