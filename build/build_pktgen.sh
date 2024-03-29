#!/usr/bin/env bash
##
## Container build for PKTGEN to simulate traffic
##

# Exit script on first error
set -o errexit

# only for local build
# source build_config

# Set envs
IS_RHEL_BUILD=y
PKTGEN_HOST=y
IMAGE_NAME=${REGISTRY_URL}/vcmts-pktgen
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}
VCMTS_ROOT="/usr/src/vcmts"
MYHOME=${VCMTS_ROOT}

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz -C ${VCMTS_ROOT}

echo -e "Copy Intel VCMTS fixedsz traffic policies"
cp intel-vcmtsd-fixedsz-tp-${VCMTS_VERSION}.tar.bz2 ${VCMTS_ROOT}/vcmts/traffic-profiles/

# add Red Hat Containerfile
cp containerfiles/pktgen-Containerfile.ubi8 ${VCMTS_ROOT}/vcmts/pktgen/container/Containerfile.ubi8

# apply fork and export build functions
rm ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
cp patches/env.sh ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
source ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh

echo -e "Install packages and dependencies"
dnf install -y --nogpgcheck --disableplugin=subscription-manager \
  git golang gcc-c++ gcc cmake make automake autoconf bzip2 patch libtool openssl-devel python3-pip wget xz \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/ninja-build-1.8.2-1.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/meson-0.55.3-3.el8.noarch.rpm \
  http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/jansson-2.14-1.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/jansson-devel-2.14-1.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-libs-2.0.12-11.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-devel-2.0.12-11.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/libpcap-devel-1.9.1-5.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/lua-devel-5.3.4-12.el8.x86_64.rpm
pip3 install pyelftools
dnf clean all
rm -fr /var/cache/dnf

echo -e "Copy helper scripts"
mkdir ${VCMTS_ROOT}/pktgen/container/pktgen-config
cp ${VCMTS_ROOT}/tools/vcmts-env/*.sh ${VCMTS_ROOT}/pktgen/container/pktgen-config

wget https://raw.githubusercontent.com/pktgen/Pktgen-DPDK/pktgen-19.10.0/Pktgen.lua -O ${VCMTS_ROOT}/pktgen/container/Pktgen.lua


echo -e "Build DPDK"
build_baremetal_dpdk

echo -e "Build Pkgtgen"
build_container_pktgen

buildah --storage-driver vfs push ${IMAGE_TAG}