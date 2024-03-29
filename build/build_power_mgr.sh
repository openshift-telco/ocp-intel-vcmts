#!/usr/bin/env bash
##
## Container build for Intel VCMTS Data Plane Application
##

# Exit script on first error
set -o errexit

# only for local build
# source build_config

# Set envs
IS_RHEL_BUILD=y
VCMTSD_HOST=y
IMAGE_NAME=${REGISTRY_URL}/vcmts-power-mgr
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}
VCMTS_ROOT="/usr/src/vcmts"
MYHOME=${VCMTS_ROOT}
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib64/pkgconfig

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz -C ${VCMTS_ROOT}

# add Red Hat Containerfile
cp containerfiles/vcmts-Containerfile.ubi8 ${VCMTS_ROOT}/vcmts/src/app/vcmtsd/container/Containerfile.ubi8

# apply fork and export build functions
rm ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
cp patches/env.sh ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
source ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh

echo -e "Install packages and dependencies"
dnf install -y --nogpgcheck --disableplugin=subscription-manager \
  git golang gcc-c++ gcc cmake make automake autoconf patch libtool openssl-devel python3-pip wget xz bzip2 systemd-devel libvirt \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/nasm-2.15.03-3.el8.x86_64.rpm \
  https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-5.12.0-2.fc34.x86_64.rpm \
  https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-devel-5.12.0-2.fc34.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/ninja-build-1.8.2-1.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/meson-0.55.3-3.el8.noarch.rpm \
  http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/jansson-2.14-1.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/jansson-devel-2.14-1.el8.x86_64.rpm \
  http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/yasm-1.3.0-7.el8.x86_64.rpm
pip3 install pyelftools
dnf clean all
rm -fr /var/cache/dnf

echo -e "Install Intel IPSec MB Library"
build_baremetal_ipsec_mb
mkdir ${VCMTS_ROOT}/src/app/vcmtsd/container/lib
cp /usr/lib/libIPSec_MB* ${VCMTS_ROOT}/src/app/vcmtsd/container/lib

echo -e "Build patched dpdk ${DPDK_VERSION}"
build_baremetal_dpdk

echo -e "Build Power Manager"
build_container_power_mgr

buildah --storage-driver vfs push ${IMAGE_TAG}
