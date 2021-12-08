#!/usr/bin/env bash
##
## Container build for PKTGEN to simulate traffic
##

# Exit script on first error
set -o errexit

# See image variables
IMAGE_NAME=${REGISTRY_URL}/vcmts-pktgen
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}

# Use UBI as base pktgen_dev image
pktgen_dev=$(buildah --storage-driver vfs --name vcmts-pktgen-dev from registry.access.redhat.com/ubi8/ubi)

# Set envs
buildah --storage-driver vfs config --env PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib64/pkgconfig $pktgen_dev
buildah --storage-driver vfs config --env VCMTS_ROOT=${VCMTS_ROOT}/vcmts $pktgen_dev
buildah --storage-driver vfs config --env RTE_TARGET=x86_64-native-linuxapp-gcc $pktgen_dev
buildah --storage-driver vfs config --env RTE_SDK=${VCMTS_ROOT}/dpdk $pktgen_dev

echo -e "Copy and uncompress Intel VCMTS package"
buildah --storage-driver vfs run $pktgen_dev mkdir ${VCMTS_ROOT}

buildah --storage-driver vfs copy $pktgen_dev intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT} $pktgen_dev
buildah --storage-driver vfs run $pktgen_dev tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz
 
echo -e "Install packages and dependencies"
buildah --storage-driver vfs run $pktgen_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager git golang gcc-c++ gcc cmake make automake autoconf bzip2 patch libtool openssl-devel python3-pip wget xz
buildah --storage-driver vfs run $pktgen_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/ninja-build-1.8.2-1.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/meson-0.55.3-3.el8.noarch.rpm
buildah --storage-driver vfs run $pktgen_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/jansson-2.11-3.el8.x86_64.rpm http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/jansson-devel-2.11-3.el8.x86_64.rpm
buildah --storage-driver vfs run $pktgen_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-libs-2.0.12-11.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-devel-2.0.12-11.el8.x86_64.rpm
# libpcap and lua needed to compile pktgen
buildah --storage-driver vfs run $pktgen_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/libpcap-devel-1.9.1-5.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/lua-devel-5.3.4-12.el8.x86_64.rpm
buildah --storage-driver vfs run $pktgen_dev pip3 install pyelftools
buildah --storage-driver vfs run $pktgen_dev dnf clean all
buildah --storage-driver vfs run $pktgen_dev rm -fr /var/cache/dnf

echo -e "Build DPDK"
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT} $pktgen_dev
buildah --storage-driver vfs run $pktgen_dev git clone http://dpdk.org/git/dpdk
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/dpdk $pktgen_dev
buildah --storage-driver vfs run $pktgen_dev git stash
buildah --storage-driver vfs run $pktgen_dev git clean -df -e build -e install
buildah --storage-driver vfs run $pktgen_dev git checkout main
buildah --storage-driver vfs run $pktgen_dev git pull
buildah --storage-driver vfs run $pktgen_dev git checkout v${DPDK_VERSION_PKTGEN}
# patch ifcvfi.h, VIRTIO_F_IOMMU_PLATFORM already defined error
buildah --storage-driver vfs run $pktgen_dev sh -c "sed -e 's/\(#define VIRTIO_F_IOMMU_PLATFORM\t\t33\)/\/*\1*\//g' -i ${VCMTS_ROOT}/dpdk/drivers/vdpa/ifc/base/ifcvf.h"

buildah --storage-driver vfs run $pktgen_dev make install T=x86_64-native-linuxapp-gcc -j 11 MAKE_PAUSE=n

echo -e "Uncompress traffic profiles"
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/vcmts/traffic-profiles $pktgen_dev

buildah --storage-driver vfs run $pktgen_dev tar -xjvf intel-vcmtsd-imix-tp-${VCMTS_VERSION}.tar.bz2
buildah --storage-driver vfs run $pktgen_dev tar -xjvf intel-vcmtsd-fixedsz-tp-${VCMTS_VERSION}.tar.bz2
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT} $pktgen_dev
echo -e "Build pktgen-dpdk app"
buildah --storage-driver vfs run $pktgen_dev git clone https://dpdk.org/git/apps/pktgen-dpdk
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/pktgen-dpdk $pktgen_dev
buildah --storage-driver vfs run $pktgen_dev git stash
buildah --storage-driver vfs run $pktgen_dev git checkout master
buildah --storage-driver vfs run $pktgen_dev git pull
buildah --storage-driver vfs run $pktgen_dev git checkout pktgen-${PKTGEN_VERSION}
buildah --storage-driver vfs run $pktgen_dev git apply ${VCMTS_ROOT}/vcmts/src/patches/pktgen-${PKTGEN_VERSION}/0001-pktgen.patch
buildah --storage-driver vfs run $pktgen_dev make

echo -e "Build pktgen container"
echo -e "#########################################"
pktgen=$(buildah --storage-driver vfs --name vcmts-pktgen from registry.access.redhat.com/ubi8/ubi)
pktgen_mount=$(buildah --storage-driver vfs mount $pktgen)
pktgen_dev_mount=$(buildah --storage-driver vfs mount $pktgen_dev)

buildah --storage-driver vfs config --env RTE_SDK=${VCMTS_ROOT}/dpdk $pktgen

buildah --storage-driver vfs run $pktgen dnf install -y --nogpgcheck --disableplugin=subscription-manager libpcap http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-libs-2.0.12-11.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/numactl-devel-2.0.12-11.el8.x86_64.rpm
buildah --storage-driver vfs run $pktgen dnf clean all
buildah --storage-driver vfs run $pktgen rm -fr /var/cache/dnf

mkdir $pktgen_mount/vcmts
mkdir $pktgen_mount/vcmts/pcaps
# Copy files from dev container
cp -fr ${pktgen_dev_mount}/${VCMTS_ROOT}/dpdk $pktgen_mount/vcmts/
cp -fr ${pktgen_dev_mount}/${VCMTS_ROOT}/pktgen-dpdk $pktgen_mount/vcmts/
cp -f  ${pktgen_dev_mount}/${VCMTS_ROOT}/pktgen-dpdk/app/x86_64-native-linuxapp-gcc/app/pktgen $pktgen_mount/vcmts/
cp -f  ${pktgen_dev_mount}/${VCMTS_ROOT}/vcmts/pktgen/config/setup.pkt $pktgen_mount/vcmts/pcaps
cp -fr ${pktgen_dev_mount}/${VCMTS_ROOT}/vcmts/traffic-profiles/intel-vcmtsd-fixedsz-tp-${VCMTS_VERSION}/* $pktgen_mount/vcmts/pcaps/ 
cp -fr ${pktgen_dev_mount}/${VCMTS_ROOT}/vcmts/tools/vcmts-env/pktgen-host-config.sh $pktgen_mount/vcmts/

buildah --storage-driver vfs config --workingdir /vcmts $pktgen
buildah --storage-driver vfs commit $pktgen ${IMAGE_NAME}

# buildah requires a slight modification to the push secret provided by the service
# account to use it for pushing the image
cp /var/run/secrets/openshift.io/push/.dockercfg /tmp
(echo "{ \"auths\": " ; cat /var/run/secrets/openshift.io/push/.dockercfg ; echo "}") > /tmp/.dockercfg

# push the new image to the target for the build
buildah --storage-driver vfs --storage-driver vfs push --tls-verify=false --authfile /tmp/.dockercfg ${IMAGE_TAG}