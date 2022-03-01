#!/usr/bin/env bash
##
## Container build for Pktgen Manager
##

# Exit script on first error
set -o errexit

# only for local build
# source build_config

# Set envs
VCMTS_ROOT="/usr/src/vcmts"
IMAGE_NAME=${REGISTRY_URL}/vcmts-pktgen-manager
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}

cd containerfiles/
buildah --storage-driver vfs bud --build-arg VCMTS_VERSION=$VCMTS_VERSION -t ${IMAGE_TAG} socat-Containerfile
buildah --storage-driver vfs push ${IMAGE_TAG}