#!/usr/bin/env bash

# Exit script on first error
set -o errexit

# only for local build
# source build_config

# Set envs
VCMTSD_HOST=y
IMAGE_NAME=${REGISTRY_URL}/vcmts-pcm
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}
VCMTS_ROOT="/usr/src/vcmts"
MYHOME=${VCMTS_ROOT}

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz -C ${VCMTS_ROOT}

cp containerfiles/pcm-Containerfile.ubi8  $VCMTS_ROOT/vcmts/telemetry/collectd/Containerfile.ubi8
cp patches/collectd.conf  $VCMTS_ROOT/vcmts/telemetry/collectd/collectd.conf
cd $VCMTS_ROOT/vcmts/telemetry/collectd

buildah --storage-driver vfs bud --build-arg VCMTS_VERSION=$VCMTS_VERSION -t ${IMAGE_TAG} Containerfile.ubi8
buildah --storage-driver vfs push ${IMAGE_TAG}