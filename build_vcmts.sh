#!/usr/bin/env bash
##
## Container build for Intel VCMTS Data Plane Application
##

# Exit script on first error
set -o errexit

# only for local build
# source build_config

# Set envs
ISREDHATOS=y
VCMTSD_HOST=y
IMAGE_NAME=${REGISTRY_URL}/vcmts-pktgen
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}
VCMTS_ROOT="/usr/src/vcmts"
MYHOME=${VCMTS_ROOT}
PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib64/pkgconfig

echo -e "Copy and uncompress Intel VCMTS package"
mkdir -p ${VCMTS_ROOT}
cp intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz -C ${VCMTS_ROOT}

# add Red Hat Containerfile
cp patches/vcmts-Dockerfile.RedHat ${VCMTS_ROOT}/vcmts/src/app/vcmtsd/container/Dockerfile.RedHat

# apply fork and exports build functions
rm ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
cp patches/fork/env.sh ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh
source ${VCMTS_ROOT}/vcmts/tools/vcmts-env/env.sh

echo -e "Install packages and dependencies"
dnf install -y --nogpgcheck --disableplugin=subscription-manager git golang gcc-c++ gcc cmake make automake autoconf patch libtool openssl-devel python3-pip wget xz bzip2 systemd-devel
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/nasm-2.15.03-3.el8.x86_64.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-5.12.0-2.fc34.x86_64.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-devel-5.12.0-2.fc34.x86_64.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/ninja-build-1.8.2-1.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/meson-0.55.3-3.el8.noarch.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/jansson-2.11-3.el8.x86_64.rpm http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/jansson-devel-2.11-3.el8.x86_64.rpm
dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/yasm-1.3.0-7.el8.x86_64.rpm
pip3 install pyelftools
dnf clean all
rm -fr /var/cache/dnf

# install_power_mgmt_utilities
# install_qat_drivers

echo -e "Install Intel IPSec MB Library"
build_baremetal_ipsec_mb
mkdir ${VCMTS_ROOT}/src/app/vcmtsd/container/lib
cp /usr/lib/libIPSec_MB* ${VCMTS_ROOT}/src/app/vcmtsd/container/lib

echo -e "Build patched dpdk ${DPDK_VERSION}"
build_baremetal_dpdk

echo -e "Generate certificates for vCMTS"
generate_openssl_certs

echo -e "Build vCMTS-D"
sed -e "s#/usr/lib/pkgconfig/libcollectdclient.pc#/usr/lib64/pkgconfig/libcollectdclient.pc#g" -i ${VCMTS_ROOT}/src/app/vcmtsd/Makefile
build_container_vcmtsd

# buildah --storage-driver vfs requires a slight modification to the push secret provided by the service
# account to use it for pushing the image
cp /var/run/secrets/openshift.io/push/.dockercfg /tmp
(echo "{ \"auths\": " ; cat /var/run/secrets/openshift.io/push/.dockercfg ; echo "}") > /tmp/.dockercfg
#
# # push the new image to the target for the build
buildah --storage-driver vfs --storage-driver vfs push --tls-verify=false --authfile /tmp/.dockercfg ${IMAGE_TAG}
