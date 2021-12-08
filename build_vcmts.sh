#!/usr/bin/env bash
##
## Container build for Intel VCMTS Data Plane Application
##

# Exit script on first error
set -o errexit

# See image variables
IMAGE_NAME=${REGISTRY_URL}/vcmts
IMAGE_TAG=${IMAGE_NAME}:${VCMTS_VERSION}

# Use UBI as base vcmts_dev image
vcmts_dev=$(buildah --storage-driver vfs --name vcmts-dev from registry.access.redhat.com/ubi8/ubi)

# Set envs
buildah --storage-driver vfs config --env PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib64/pkgconfig $vcmts_dev
buildah --storage-driver vfs config --env VCMTS_ROOT=${VCMTS_ROOT}/vcmts $vcmts_dev

echo -e "Copy and uncompress Intel VCMTS package"
buildah --storage-driver vfs run $vcmts_dev mkdir ${VCMTS_ROOT}
buildah --storage-driver vfs run $vcmts_dev mkdir /vcmts
buildah --storage-driver vfs run $vcmts_dev mkdir /vcmts-config

buildah --storage-driver vfs copy $vcmts_dev intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz ${VCMTS_ROOT}
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT} $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev tar zxvf intel-vcmtsd-v${VCMTS_VERSION//./-}.tar.gz

echo -e "Install packages and dependencies"
buildah --storage-driver vfs run $vcmts_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager git golang gcc-c++ gcc cmake make automake autoconf patch libtool openssl-devel python3-pip wget xz bzip2
buildah --storage-driver vfs run $vcmts_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/nasm-2.15.03-3.el8.x86_64.rpm 
buildah --storage-driver vfs run $vcmts_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-5.12.0-2.fc34.x86_64.rpm 
buildah --storage-driver vfs run $vcmts_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-devel-5.12.0-2.fc34.x86_64.rpm
buildah --storage-driver vfs run $vcmts_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/ninja-build-1.8.2-1.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/meson-0.55.3-3.el8.noarch.rpm
buildah --storage-driver vfs run $vcmts_dev dnf install -y --nogpgcheck --disableplugin=subscription-manager http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/jansson-2.11-3.el8.x86_64.rpm http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/jansson-devel-2.11-3.el8.x86_64.rpm
buildah --storage-driver vfs run $vcmts_dev pip3 install pyelftools
buildah --storage-driver vfs run $vcmts_dev dnf clean all
buildah --storage-driver vfs run $vcmts_dev rm -fr /var/cache/dnf

echo -e "Install Intel IPSec MB Library"
buildah --storage-driver vfs run $vcmts_dev git clone https://github.com/intel/intel-ipsec-mb.git
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/intel-ipsec-mb $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev git checkout main
buildah --storage-driver vfs run $vcmts_dev git pull
buildah --storage-driver vfs run $vcmts_dev git checkout v${IPSEC_MB_VERSION}
buildah --storage-driver vfs run $vcmts_dev make
buildah --storage-driver vfs run $vcmts_dev make install

echo -e "Build patched dpdk ${DPDK_VERSION}"
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT} $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev git clone http://dpdk.org/git/dpdk
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/dpdk $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev git stash
buildah --storage-driver vfs run $vcmts_dev git clean -df -e build -e install
buildah --storage-driver vfs run $vcmts_dev git checkout main
buildah --storage-driver vfs run $vcmts_dev git pull
buildah --storage-driver vfs run $vcmts_dev git checkout v${DPDK_VERSION}
buildah --storage-driver vfs run $vcmts_dev git apply ${VCMTS_ROOT}/vcmts/src/patches/dpdk-${DPDK_VERSION}/0001-scheduler.patch
buildah --storage-driver vfs run $vcmts_dev git apply ${VCMTS_ROOT}/vcmts/src/patches/dpdk-${DPDK_VERSION}/0002-latency.patch
buildah --storage-driver vfs run $vcmts_dev git apply ${VCMTS_ROOT}/vcmts/src/patches/dpdk-${DPDK_VERSION}/0003-net-drivers.patch
buildah --storage-driver vfs run $vcmts_dev git apply ${VCMTS_ROOT}/vcmts/src/patches/dpdk-${DPDK_VERSION}/0004-config.patch
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/dpdk $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev meson build
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/dpdk/build $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev ninja
buildah --storage-driver vfs run $vcmts_dev ninja install
buildah --storage-driver vfs run $vcmts_dev ldconfig

echo -e "Build vCMTS-D"
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/vcmts/src $vcmts_dev
# libcollectdclient.pc is under lib64
buildah --storage-driver vfs run $vcmts_dev sed -e "s#/usr/lib/pkgconfig/libcollectdclient.pc#/usr/lib64/pkgconfig/libcollectdclient.pc#g" -i app/vcmtsd/Makefile
buildah --storage-driver vfs run $vcmts_dev make
buildah --storage-driver vfs run $vcmts_dev cp ${VCMTS_ROOT}/vcmts/src/build/app/vcmts-d /vcmts/
buildah --storage-driver vfs run $vcmts_dev sh -c "cp -fr ${VCMTS_ROOT}/vcmts/src/app/vcmtsd/config/* /vcmts/"
buildah --storage-driver vfs run $vcmts_dev cp ${VCMTS_ROOT}/vcmts/tools/vcmts-env/vcmtsd-host-config.sh /vcmts-config/

echo -e "Uncompress traffic profiles"
buildah --storage-driver vfs config --workingdir ${VCMTS_ROOT}/vcmts/traffic-profiles $vcmts_dev
buildah --storage-driver vfs run $vcmts_dev tar -jxvf intel-vcmtsd-imix-tp-${VCMTS_VERSION}.tar.bz2
buildah --storage-driver vfs run $vcmts_dev tar -jxvf intel-vcmtsd-fixedsz-tp-${VCMTS_VERSION}.tar.bz2

echo -e "Build VCMTS container"
echo -e "#####################################"
vcmts=$(buildah --storage-driver vfs --name vcmts from registry.access.redhat.com/ubi8/ubi)
vcmts_mount=$(buildah --storage-driver vfs mount $vcmts)
vcmts_dev_mount=$(buildah --storage-driver vfs mount $vcmts_dev)

buildah --storage-driver vfs config --env RTE_SDK=${VCMTS_ROOT}/dpdk $vcmts

mkdir $vcmts_mount/vcmts
mkdir $vcmts_mount/vcmts-config

# Install jansson and libcollectdclient required by vcmts-d binary
buildah --storage-driver vfs run $vcmts dnf install -y --nogpgcheck --disableplugin=subscription-manager openssl http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/jansson-2.11-3.el8.x86_64.rpm https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/Packages/l/libcollectdclient-5.12.0-2.fc34.x86_64.rpm
buildah --storage-driver vfs run $vcmts dnf clean all
buildah --storage-driver vfs run $vcmts rm -fr /var/cache/dnf
# Copy IPsec lib
cp -a $vcmts_dev_mount/usr/lib/libIPSec_MB* $vcmts_mount/usr/lib/
buildah --storage-driver vfs run $vcmts ldconfig

echo -e "Generate vcmts-cli certs"
buildah --storage-driver vfs config --workingdir /vcmts $vcmts
buildah --storage-driver vfs run $vcmts openssl req -newkey rsa:4096 -x509 -sha256 -days 1024 -nodes -out root.crt -keyout root.key -subj "/C=IE/ST=SNN/L=SNN/O=IN/OU=NPG/CN=intel.com"
buildah --storage-driver vfs run $vcmts openssl req -newkey rsa:4096 -x509 -sha256 -days 1024 -nodes -out vcmts_app.crt -keyout vcmts_app.key -subj "/C=IE/ST=SNN/L=SNN/O=IN/OU=NPG/CN=intel.com"
buildah --storage-driver vfs run $vcmts openssl req -newkey rsa:4096 -x509 -sha256 -days 1024 -nodes -out vcmts_cli.crt -keyout vcmts_cli.key -subj "/C=IE/ST=SNN/L=SNN/O=IN/OU=NPG/CN=intel.com"

cp $vcmts_dev_mount/${VCMTS_ROOT}/vcmts/src/build/app/vcmts-d $vcmts_mount/vcmts/
cp -fr $vcmts_dev_mount/${VCMTS_ROOT}/vcmts/src/app/vcmtsd/config/* $vcmts_mount/vcmts/
cp $vcmts_dev_mount/${VCMTS_ROOT}/vcmts/tools/vcmts-env/vcmtsd-host-config.sh $vcmts_mount/vcmts-config/

buildah --storage-driver vfs config --workingdir /vcmts $vcmts
buildah --storage-driver vfs commit $vcmts ${IMAGE_NAME}

# buildah --storage-driver vfs requires a slight modification to the push secret provided by the service
# account to use it for pushing the image
cp /var/run/secrets/openshift.io/push/.dockercfg /tmp
(echo "{ \"auths\": " ; cat /var/run/secrets/openshift.io/push/.dockercfg ; echo "}") > /tmp/.dockercfg

# push the new image to the target for the build
buildah --storage-driver vfs --storage-driver vfs push --tls-verify=false --authfile /tmp/.dockercfg ${IMAGE_TAG}
