#!/usr/bin/env bash
##
## Container build for PKTGEN to simulate traffic
##

# only for local build
source build_config

# Exit script on first error
set -o errexit

# Set envs
ISREDHATOS=y
IMAGE_NAME=${REGISTRY_URL}/vcmts-pktgen
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}
PKTGEN_HOST=y
MYHOME=${VCMTS_ROOT}

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
cd ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz

# add Red Hat Containerfile
cp patches/pktgen-Dockerfile.RedHat ${VCMTS_ROOT}/vcmts/pktgen/container/Dockerfile.RedHat

# apply fork and exports build functions
rm ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
cp patches/fork/env.sh ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
source ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh

# install_base_ubuntu_pkgs
echo -e "Install packages and dependencies"
dnf install -y --nogpgcheck --disableplugin=subscription-manager git golang gcc-c++ gcc cmake make automake autoconf bzip2 patch libtool openssl-devel python3-pip wget xz
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/ninja-build-1.8.2-1.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/meson-0.55.3-3.el8.noarch.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/jansson-2.11-3.el8.x86_64.rpm http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/jansson-devel-2.11-3.el8.x86_64.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-libs-2.0.12-11.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-devel-2.0.12-11.el8.x86_64.rpm
# libpcap and lua needed to compile pktgen
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/libpcap-devel-1.9.1-5.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/lua-devel-5.3.4-12.el8.x86_64.rpm
pip3 install pyelftools
dnf clean all
rm -fr /var/cache/dnf

echo -e "Build DPDK"
build_baremetal_dpdk

echo -e "Build Pkgtgen"
build_container_pktgen

# buildah requires a slight modification to the push secret provided by the service account to use it for pushing the image
cp /var/run/secrets/openshift.io/push/.dockercfg /tmp
(echo "{ \"auths\": " ; cat /var/run/secrets/openshift.io/push/.dockercfg ; echo "}") > /tmp/.dockercfg

# push the new image to the target for the build
buildah --storage-driver vfs --storage-driver vfs push --tls-verify=false --authfile /tmp/.dockercfg ${IMAGE_TAG}