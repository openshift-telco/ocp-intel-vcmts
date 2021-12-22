#!/usr/bin/env bash

################################################################################
#   BSD LICENSE
# 
#   Copyright(c) 2007-2021 Intel Corporation. All rights reserved.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions
#   are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * Neither the name of Intel Corporation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
# 
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
################################################################################

################################################################################
# SCRIPT FILE FOR VCMTS HOST
################################################################################

GR='\033[0;32m'
NC='\033[0m'
ISPKTGEN=1; ISVCMTS=1; ISANSIBLE=1; IS_RHEL=1
if [[ -z "${PKTGEN_HOST}" ]]; then ISPKTGEN=0; fi
if [[ -z "${VCMTSD_HOST}" ]]; then ISVCMTS=0; fi
if [[ -z "${ANSIBLE_HOST}" ]]; then ISANSIBLE=0; fi
if [[ -z "${IS_RHEL_BUILD}" ]]; then IS_RHEL=0; fi

# Check if all unset or set
if [ ${ISVCMTS} -eq 0 -a ${ISPKTGEN} -eq 0 -a ${ISANSIBLE} -eq 0 ]; then
	echo \
		"Please export PKTGEN_HOST=y, export VCMTSD_HOST=y or export ANSIBLE_HOST=y env variable"
	return
fi

if [ ${ISVCMTS} -eq 1 -a ${ISPKTGEN} -eq 1 ]; then
	echo \
		"Please export PKTGEN_HOST=y or export VCMTSD_HOST=y"
	return
fi

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-host-config.sh"

if [[ ${ISVCMTS} -eq 1 ]]; then
	DIR="${BASH_SOURCE%/*}"
	if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
	. "$DIR/vcmtsd-host-config.sh"
fi

if [[ ${ISPKTGEN} -eq 1 ]]; then
	DIR="${BASH_SOURCE%/*}"
	if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
	. "$DIR/pktgen-host-config.sh"
fi

BMRA_VERSION="21.09"
DPDK_VERSION="21.08"
DPDK_VERSION_PKTGEN="20.08"
IPSEC_MB_VERSION="1.0"
COLLECTD_VERSION="5.12.0"
PKTGEN_VERSION="19.10.0"
GRAFANA_VERSION="7.2.0"
PROMETHEUS_VERSION="2.0.0"

EDITOR="vim"
VISUAL=$EDITOR

################################################################################

export GIT_SSH_COMMAND='ssh -oHostKeyAlgorithms=+ssh-dss'

################################################################################

################################################################################
# Aliases
################################################################################

alias vcmts-cli='python3 $VCMTS_ROOT/tools/vcmts-cli/cli.py'

################################################################################
# Functions for configuring PFs and VFs
################################################################################

sysfs="/sys/bus/pci/devices"

function _show_pf {
	for PF in "${ports_pf[@]}"
	do
		port_pf=$(dpdk-devbind.py -s | grep $PF | sed 's/.*if=//g' | awk '{print $1}')
		echo $PF
		ip link show $port_pf
	done
}

function _bind_pf_kernel {
	for PF in "${ports_pf[@]}"
	do
		drv=$(dpdk-devbind.py -s | grep $PF | sed "s/.*drv=//" | awk '{print $1}')
		dpdk-devbind.py -b $drv $PF
	done
}

function _create_vf {
	for PF in "${ports_pf[@]}"
	do
		vf_file=$(find /sys/devices -name sriov_numvfs | grep $PF)
		echo 0 > $vf_file
		echo $gen_num_vf_per_pf > $vf_file
	done
	_show_pf
}

function _set_vf_mac {
	for PF in "${ports_pf[@]}"
	do
		pf_iface=$(dpdk-devbind.py -s | grep $PF | sed 's/.*if=//g' | awk '{print $1}')
		i=0
		ihex=$( printf "%x" $i )
		bus=`echo $PF | sed "s/:.*//"`
		slot=`echo $PF | sed "s/.*://" | sed "s/\..*//"`
		func=`echo $PF | sed "s/.*\.//"`
		if [ "${ISPKTGEN}" -eq 1 ]; then
			pktgen_mac_flag="01"
		else
			pktgen_mac_flag="00"
		fi
		while [ $i -lt $gen_num_vf_per_pf ]; do
			ip link set $pf_iface vf $i mac "00:$pktgen_mac_flag:$bus:$slot:$func:$ihex"
			ip link set $pf_iface vf $i spoofchk off
			i=$(expr $i + 1)
			ihex=$( printf "%x" $i )
		done
		ip link set $pf_iface promisc off
	done
}

function _bind_vf_dpdk {
	for PF in "${ports_pf[@]}"
	do
		i=1
		loop_limit=`expr $gen_num_vf_per_pf + 1`
		vf="${ports_vf[$PF]}"
		while [ $i -lt $loop_limit ]; do
			VF=$(echo $vf | cut -d ' ' -f$i)
			dpdk-devbind.py -b vfio-pci $VF
			i=`expr $i + 1`
		done
	done
}

function setup_pf_vf_vcmts {
	_bind_pf_kernel
	_create_vf
	_set_vf_mac
	_bind_vf_dpdk
	_show_pf
}

function _create_qat_vf {
	for PF in "${qat_ports_pf[@]}";
	do
		num_vfs=$(find /sys -name sriov_numvfs | grep $PF)
		echo 16 > $num_vfs
	done
}

function _bind_qat_vf_dpdk {
	for PF in "${qat_ports_pf[@]}";
	do
		for VF in ${qat_ports_vf[$PF]};
		do
			dpdk-devbind.py -b vfio-pci $VF
		done
	done
}

function setup_qat_pf_vf_vcmts {
	_create_qat_vf
	_bind_qat_vf_dpdk
}

function cable_pf_helper {
	echo "This function helps to correctly cable vCMTS and PKTGEN nodes"
	echo "Run this function in parallel on both vCMTS and PKTGEN nodes"
	echo "Wire the flashing ports on each node together"
	echo "Then press enter on both systems and continue"
	link_counter=0
	for PF in "${ports_pf[@]}"
	do
		link_counter=$((link_counter+1))
		port_pf=$(dpdk-devbind.py -s | grep $PF | sed 's/.*if=//g' | awk '{print $1}')
		echo "press enter once link $link_counter  is cabled:"
		read -t 2
		while [ $? != 0  ]; do
			ethtool --identify $port_pf 5
			read -t 2
		done
	done
}

################################################################################
# Functions for installing requirements
################################################################################

function _create_tmp_dir {

	if [ ! -d $MYHOME/tmp ]; then
		mkdir $MYHOME/tmp
	fi
}

# Helper function for base Ubuntu install
function install_base_ubuntu_pkgs {
	DIR=$PWD
	_create_tmp_dir
	echo "base packages install"
	sudo apt update
	for i in golang gcc gcc libnuma-dev linux-headers-generic util-linux msr-tools nasm \
			libssl-dev dtach python-dev build-essential flex autoconf bison \
			libtool libelf-dev libudev-dev libltdl7 linux-tools-common socat \
			linux-tools-generic git unzip libvirt-dev \
			libjansson-dev openipmi libopenipmi-dev liblua5.3-dev libpcap-dev \
			libmicrohttpd-dev protobuf-c-compiler libprotobuf-c-dev libprotobuf-dev \
			python3-pip libcollectdclient-dev python3-selinux dpdk yasm
	do
		apt install -y $i
		if [ $? -ne 0 ]; then
			echo -e "${GR}Error installing package $i. - Check logs to debug${NC}"
			return
		fi
	done

	for i in pyelftools ninja 'meson>=0.49.2,<0.59' jinja2 ansible==2.9.20
	do
		pip3 install $i
		if [ $? -ne 0 ]; then
			echo -e "${GR}Error installing package $i. - Check logs to debug${NC}"
			return
		fi
	done

	echo "end of base package install"
	cd $DIR
}

function install_power_mgmt_utilities {
	DIR=$PWD
	cd $MYHOME
	git clone https://github.com/intel/CommsPowerManagement.git
	cd CommsPowerManagement
	git checkout a3a1869fd88eff5b2b872f447ca69b866e3d318e
	cd $DIR
}

# Generate ssl certs for vcmts-cli
function generate_openssl_certs {

	DIR=$PWD
	mkdir $VCMTS_CERTS_DIR
	cd $VCMTS_CERTS_DIR
	if [ "${ISVCMTS}" -eq 1 ]; then
		# Generate root cert
		openssl req -newkey rsa:4096 -x509 -sha256 -days 1024 -nodes -out root.crt -keyout root.key -subj "/C=IE/ST=SNN/L=SNN/O=IN/OU=NPG/CN=intel.com"

		# Generate vcmts_app cert
		openssl req -newkey rsa:4096 -x509 -sha256 -days 1024 -nodes -out vcmts_app.crt -keyout vcmts_app.key -subj "/C=IE/ST=SNN/L=SNN/O=IN/OU=NPG/CN=intel.com"

		# Generate vcmts_cli cert
		openssl req -newkey rsa:4096 -x509 -sha256 -days 1024 -nodes -out vcmts_cli.crt -keyout vcmts_cli.key -subj "/C=IE/ST=SNN/L=SNN/O=IN/OU=NPG/CN=intel.com"
	else
		echo "Certificates are only required on the vCMTS Application Server"
		return
	fi

	for file in root.crt root.key vcmts_app.crt vcmts_app.key vcmts_cli.crt vcmts_cli.key; do
		if [ ! -f $file ]; then
			echo "Error generating: $file"
		fi
	done

	cd $DIR
}

function install_qat_drivers(){
	DIR=$PWD
	cd $MYHOME
	mkdir qat
	cd qat
	wget https://downloadmirror.intel.com/30178/eng/qat1.7.l.4.14.0-00031.tar.gz
        tar xvf qat1.7.l.4.14.0-00031.tar.gz
	./configure
	make
	make install
	cd $DIR
}

function install_pcm_tool(){
	DIR=$PWD
	cd $MYHOME
	if [ ! -d pcm ]; then
		git clone http://github.com/opcm/pcm.git
	fi
	cd pcm
	make
	cd $DIR
}

################################################################################
# Bare metal component installation
################################################################################

function build
{
	cd "$1"
# CHANGE FROM REDHAT
	if [ "${IS_RHEL}" -eq 1 ]; then
		buildah --storage-driver vfs bud --build-arg VCMTS_VERSION=$VCMTS_VERSION -t ${IMAGE_TAG} Containerfile.ubi8
		return
	else
		buildah bud -t localhost:30500/"$2":"release" .
		buildah push localhost:30500/"$2":release
	fi
# ------------------
	cd -
}

function build_baremetal_collectd {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD
	cd $MYHOME
	git clone https://github.com/01org/intel-cmt-cat.git
	cd intel-cmt-cat
	make
	make install
	cd $MYHOME
	git clone https://github.com/andikleen/pmu-tools.git
	cd pmu-tools/jevents
	make CPPFLAGS+=-fPIC
	make install
	cd $MYHOME/pmu-tools
	./event_download.py -a
	cd $MYHOME
	rm -rf $MYHOME/collectd
	git clone https://github.com/collectd/collectd.git
	cd collectd
	git checkout collectd-${COLLECTD_VERSION}
	./build.sh
	./configure --with-libpython --enable-intel_rdt --enable-intel_pmu --enable-ipmi --enable-write_prometheus
	make
	make install
	mkdir -vp /opt/collectd/share/collectd/python
	cd $VCMTS_ROOT/telemetry/collectd
	cp -f utils.py /opt/collectd/share/collectd/python
	cp -f /root/.cache/pmu-events/* /opt/collectd/etc
	cp -f vcmts.types.db /opt/collectd/share/collectd/vcmts.types.db
	cp -f collectd.service /lib/systemd/system/.
	systemctl daemon-reload
	cd $MYHOME
	mkdir -vp /opt/collectd/var/run/;
	modprobe msr;
	systemctl enable collectd
	cd $DIR
}

function build_baremetal_prometheus {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD
	cd $MYHOME
	mkdir /etc/prometheus
	mkdir /var/lib/prometheus
	wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
	tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
	cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
	cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
	cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles /etc/prometheus
	cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus
	cp -f $VCMTS_ROOT/telemetry/prometheus/prometheus.service /lib/systemd/system/.
	cp -f $VCMTS_ROOT/telemetry/prometheus/prometheus.yml /etc/prometheus/.
	systemctl daemon-reload
	systemctl enable prometheus
	cd $DIR
}

function build_baremetal_grafana {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD
	cd $MYHOME
	rm -rf /opt/grafana
	mkdir /opt/grafana
	mkdir /opt/grafana/plugins
	mkdir /opt/grafana/dashboards
	wget https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz
	tar -zxvf grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz
	mv grafana-${GRAFANA_VERSION}/* /opt/grafana
	cp -fr $VCMTS_ROOT/telemetry/grafana/dashboards/* /opt/grafana/dashboards/.
	cp -fr $VCMTS_ROOT/telemetry/grafana/defaults.ini /opt/grafana/conf/.
	cp -fr $VCMTS_ROOT/telemetry/grafana/dashboard_provisioning.yaml /opt/grafana/conf/provisioning/dashboards/sample.yaml
	cp -fr $VCMTS_ROOT/telemetry/grafana/datasource_provisioning.yaml /opt/grafana/conf/provisioning/datasources/sample.yaml
	cd /opt/grafana/plugins
	wget -nv https://grafana.com/api/plugins/grafana-piechart-panel/versions/latest/download -O grafana-piechart-panel.zip
	unzip grafana-piechart-panel.zip
	rm grafana-piechart-panel.zip
	cp -f $VCMTS_ROOT/telemetry/grafana/grafana-server.service /lib/systemd/system/.
	wget -nv https://grafana.com/api/plugins/pierosavi-imageit-panel/versions/1.0.4/download -O pierosavi-imageit-panel.zip
	unzip pierosavi-imageit-panel.zip
	rm pierosavi-imageit-panel.zip
	wget -nv https://www.intelextrememasters.com/wp-content/uploads/2021/02/logo-energyblue-white-3000px.png -O intel_logo.png
	mv intel_logo.png /opt/grafana/public/img/.
	cp -f $VCMTS_ROOT/telemetry/grafana/grafana-server.service /lib/systemd/system/.
	systemctl daemon-reload
	systemctl enable grafana-server
	cd $DIR
}

function build_baremetal_ipsec_mb {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD
	cd $MYHOME
	if [ ! -d intel-ipsec-mb ]; then
		git clone https://github.com/intel/intel-ipsec-mb.git
	fi
	cd intel-ipsec-mb
	git checkout main
	git pull
	git checkout v${IPSEC_MB_VERSION}
	make uninstall
	make clean
	make
	make install
	cd $DIR
}

function build_baremetal_dpdk {
	DIR=$PWD
	cd $MYHOME
	if [ ! -d dpdk ]; then
		git clone http://dpdk.org/git/dpdk
	fi
	cd dpdk
	git stash
	git clean -df -e build -e install
	git checkout main
	git pull

	if [ "${ISVCMTS}" -eq 1 ]; then
		git checkout v${DPDK_VERSION}
		git apply $VCMTS_ROOT/src/patches/dpdk-${DPDK_VERSION}/0001-scheduler.patch
		git apply $VCMTS_ROOT/src/patches/dpdk-${DPDK_VERSION}/0002-latency.patch
		git apply $VCMTS_ROOT/src/patches/dpdk-${DPDK_VERSION}/0003-config.patch
		meson build
		cd build
		ninja install
		ldconfig
	else
		git checkout v${DPDK_VERSION_PKTGEN}

    # CHANGE FROM REDHAT
		if [ "${IS_RHEL}" -eq 1 ]; then
			sed -e 's/\(#define VIRTIO_F_IOMMU_PLATFORM\t\t33\)/\/*\1*\//g' -i $MYHOME/dpdk/drivers/vdpa/ifc/base/ifcvf.h
		fi
    # ------------------

		make install T=x86_64-native-linuxapp-gcc -j 11 MAKE_PAUSE=n
	fi

	cd $DIR
}

function _build_pktgen {

	export RTE_TARGET=x86_64-native-linuxapp-gcc
	cd $VCMTS_ROOT/traffic-profiles
	if [ ! -d intel-vcmtsd-imix-tp-$VCMTS_VERSION ]; then
		tar -xjvf intel-vcmtsd-imix-tp-$VCMTS_VERSION.tar.bz2
	fi

	if [ -f intel-vcmtsd-fixedsz-tp-$VCMTS_VERSION.tar.bz2 ]; then
		if [ ! -d intel-vcmtsd-fixedsz-tp-$VCMTS_VERSION ]; then
			tar -xjvf intel-vcmtsd-fixedsz-tp-$VCMTS_VERSION.tar.bz2
		fi
	fi

	if [ ! -d intel-docsis-ddp-imix-tp-$VCMTS_VERSION ]; then
		tar -xjvf intel-docsis-ddp-imix-tp-$VCMTS_VERSION.tar.bz2
	fi

	cd $MYHOME
	if [ ! -d pktgen-dpdk ]; then
		git clone https://github.com/pktgen/Pktgen-DPDK.git pktgen-dpdk
	fi
	cd pktgen-dpdk/
	git stash
	git checkout master
	git pull
	git checkout pktgen-${PKTGEN_VERSION}
	git apply $VCMTS_ROOT/src/patches/pktgen-${PKTGEN_VERSION}/0001-pktgen.patch
	make

	_create_tmp_dir
}

function build_baremetal_pktgen {

	if [ "${ISPKTGEN}" -eq 0 ]; then
		echo "Command only usable on PKTGEN_HOST"
		return
	fi

	DIR=$PWD

	export RTE_SDK=$MYHOME/dpdk
	_build_pktgen
	cd $DIR
}

function build_container_pktgen {

	if [ "${ISPKTGEN}" -eq 0 ]; then
		echo "Command only usable on PKTGEN_HOST"
		return
	fi

	DIR=$PWD

  # CHANGE FROM REDHAT
  # export RTE_SDK=/usr/src/dpdk-${DPDK_VERSION_PKTGEN}
	export RTE_SDK=$MYHOME/dpdk
  # ------------------
	_build_pktgen

	cd $VCMTS_ROOT/traffic-profiles
	mkdir -p $VCMTS_ROOT/pktgen/container/pcaps
	cp -r intel-vcmtsd-imix-tp-$VCMTS_VERSION/*.pcap $VCMTS_ROOT/pktgen/container/pcaps
	if [ -d intel-vcmtsd-fixedsz-tp-$VCMTS_VERSION ]; then
		cp -r intel-vcmtsd-fixedsz-tp-$VCMTS_VERSION/*.pcap $VCMTS_ROOT/pktgen/container/pcaps
	fi

	cd $VCMTS_ROOT/pktgen
	cp $MYHOME/pktgen-dpdk/app/x86_64-native-linuxapp-gcc/pktgen container/.
	cp $VCMTS_ROOT/pktgen/config/setup.pkt container/.
	build container vcmts-pktgen
	rm -rf container/pcaps
	rm -rf container/pktgen
	rm -rf container/setup.pkt
	cd $DIR
}

function build_baremetal_docsis_ddp_fwd {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD

	cd $VCMTS_ROOT/src/app
	make docsis-ddp-fwd
	cd $DIR
}

function build_baremetal_us_sched {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD

	cd $VCMTS_ROOT/src/lib
	make

	cd $VCMTS_ROOT/src/app
	make us-sched

	_create_tmp_dir
	cd $DIR
}

function build_container_us_sched {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR_ORIG=$PWD

	build_baremetal_us_sched

	# build us-sched image
	mkdir $VCMTS_ROOT/src/app/us-sched/container/config
	cp $VCMTS_ROOT/src/app/us-sched/config/*.cfg $VCMTS_ROOT/src/app/us-sched/container/config/
	cp $VCMTS_ROOT/src/app/us-sched/config/*.json $VCMTS_ROOT/src/app/us-sched/container/config/
	cd $VCMTS_ROOT/src/app/us-sched
	cp $VCMTS_ROOT/src/build/app/us-sched container/.
	build container "us-sched" $1
	rm -f container/us-sched
	rm -rf container/config

	cd $DIR_ORIG
}

function build_baremetal_vcmtsd {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD

	cd $VCMTS_ROOT/traffic-profiles
	if [ ! -d intel-vcmtsd-imix-tp-$VCMTS_VERSION ]; then
		tar -xjvf intel-vcmtsd-imix-tp-$VCMTS_VERSION.tar.bz2
	fi

	BUILD_OPTIONS=${1:-""}

	cd $VCMTS_ROOT/src/lib
	make $BUILD_OPTIONS

	cd $VCMTS_ROOT/src/app
	make vcmtsd $BUILD_OPTIONS

	_create_tmp_dir
	cd $DIR
}

function build_container_vcmtsd {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR_ORIG=$PWD

	build_baremetal_vcmtsd $1

	# Build vcmts-d image
	mkdir $VCMTS_ROOT/src/app/vcmtsd/container/config
	mkdir $VCMTS_ROOT/src/app/vcmtsd/container/certs
	cp $VCMTS_ROOT/src/app/vcmtsd/config/*.cfg $VCMTS_ROOT/src/app/vcmtsd/container/config/
	cp -r $VCMTS_ROOT/certs/* $VCMTS_ROOT/src/app/vcmtsd/container/certs/
	cd $VCMTS_ROOT/traffic-profiles
	cp -r intel-vcmtsd-imix-tp-$VCMTS_VERSION/*.json $VCMTS_ROOT/src/app/vcmtsd/container/config/
	cd $VCMTS_ROOT/src/app/vcmtsd
	cp $VCMTS_ROOT/src/build/app/vcmts-d container/.
	build container vcmts-d
	rm -f container/vcmts-d
	rm -rf container/config
	rm -rf container/certs

	cd $DIR_ORIG
}

function build_bmra_k8s {

	if [ "${ISANSIBLE}" -eq 0 ]; then
		echo "Command only usable on ANSIBLE_HOST"
		return
	fi

	DIR=$PWD

	cd $MYHOME
	git clone https://github.com/intel/container-experience-kits/
	cd container-experience-kits
	git checkout v${BMRA_VERSION}
	pip3 install -r profiles/requirements.txt
	mkdir group_vars
	mkdir host_vars

	git am $VCMTS_ROOT/bmra/patches/0001-enable-prometheus-write-plugin.patch
	git am $VCMTS_ROOT/bmra/patches/0002-syntax-changes-for-vcmts-deployment.patch
	git am $VCMTS_ROOT/bmra/patches/0003-disable-turbo-boost-auto-update.patch
	git am $VCMTS_ROOT/bmra/patches/0004-disable-iommu-for-high-performance-network-interface.patch
	git submodule update --init

	_create_tmp_dir
	cd $DIR
}

function _build_power_mgr {

	mkdir /opt/power_mgmt
	make static
}

function build_baremetal_power_mgr {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD

	cd $MYHOME/dpdk/examples/vm_power_manager
	_build_power_mgr

	cd $DIR
}

function build_container_power_mgr {

	if [ "${ISVCMTS}" -eq 0 ]; then
		echo "Command only usable on VCMTSD_HOST"
		return
	fi

	DIR=$PWD

	cd /usr/src/dpdk-$DPDK_VERSION/examples/vm_power_manager
	_build_power_mgr

	cd ${VCMTS_ROOT}/power-mgr
	cp /usr/src/dpdk-$DPDK_VERSION/examples/vm_power_manager/build/vm_power_mgr container/.
	build container vcmts-power-mgr
	rm -f container/vm_power_mgr
	cd $DIR
}
