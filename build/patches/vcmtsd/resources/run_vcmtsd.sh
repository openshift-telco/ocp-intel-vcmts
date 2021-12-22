#!/bin/bash

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

source /home/vcmts/vcmts-config/vcmtsd-host-config.sh
TEMPLATE_CONFIG="/home/vcmts/$TEMPLATE_CONFIG"

source /home/vcmts/vcmts-config/k8s_cpus.sh
IFS=' ' read -ra cpus <<< $(k8s_cpus_get)

# Print allocated cpus for debug
echo CPUs allocated to container cgroup are: ${cpus[*]}

# Determine hyperthread sibling lcores from allocated cpus
ht_pairs=()
for ((i=0; i<${#cpus[@]}; i++))
do
    ht_pairs+=($(cat /sys/devices/system/cpu/cpu${cpus[$i]}/topology/thread_siblings_list))
done
echo Hyperthread sibling pairs of CPUs are: ${ht_pairs[*]}
for ((i=0; i<${#ht_pairs[@]}; i++))
do
    pair_found=0
    for ((j=0; j<${#ht_pairs[@]}; j++))
    do
        if [ ${ht_pairs[$i]} = ${ht_pairs[$j]} ]; then
            pair_found=1
            break
        fi
    done
    if [ $pair_found -ne 1 ]; then
        echo 'Sibling hyperthreads were not allocated by Native CPU Manager'
        exit
    fi
done
# Above code has confirmed allocated cores were hyperthread siblings.
# Confirm 4 lcores were allocated
if [ ${#cpus[@]} -ne 4 ]; then
    echo 'Exactly 4 lcores were not allocated by Native CPU Manager'
    exit
fi

# Write lcores to config file - using stats lcore as main lcore
if [ $CORE_CONFIG == "1us1t_1ds2t" ]; then
    sed -i "s/MAIN_LCORE/${cpus[2]}/" $TEMPLATE_CONFIG
    sed -i "s/stats_lcore/${cpus[2]}/" $TEMPLATE_CONFIG
    sed -i "s/us_lcore/${cpus[0]}/" $TEMPLATE_CONFIG
    sed -i "s/ds_um_lcore/${cpus[1]}/" $TEMPLATE_CONFIG
    sed -i "s/ds_lm_lcore/${cpus[3]}/" $TEMPLATE_CONFIG
    echo "lcore map is us=${cpus[0]},ds_um=${cpus[1]},ds_lm=${cpus[3]},stats=${cpus[2]}"
else # $CORE_CONFIG == "1us1t_1ds1t"
    sed -i "s/MAIN_LCORE/${cpus[2]}/" $TEMPLATE_CONFIG
    sed -i "s/stats_lcore/${cpus[2]}/" $TEMPLATE_CONFIG
    sed -i "s/us_lcore/${cpus[0]}/" $TEMPLATE_CONFIG
    sed -i "s/ds_lcore/${cpus[1]}/" $TEMPLATE_CONFIG
    echo "lcore map is us=${cpus[0]},ds=${cpus[1]},stats=${cpus[2]}"
fi

# Set numa settings in config file
sed -i "s/socket_mem.*/socket_mem = $SOCKET_MEM/" $TEMPLATE_CONFIG
sed -i "s/socket_limit.*/socket_limit = $SOCKET_LIM/" $TEMPLATE_CONFIG
sed -i "s/cpu =.*/cpu = $CPU_SOCKET_ID/" $TEMPLATE_CONFIG

# Set yield limits
sed -i "s/ds_um_empty_rx_limit.*/ds_um_empty_rx_limit = 0/" $TEMPLATE_CONFIG
sed -i "s/ds_um_type.*/ds_um_type = scheduler/" $TEMPLATE_CONFIG
sed -i "s/ds_lm_empty_rx_limit.*/ds_lm_empty_rx_limit = 0/" $TEMPLATE_CONFIG
sed -i "s/ds_lm_type.*/ds_lm_type = scheduler/" $TEMPLATE_CONFIG
sed -i "s/us_um_empty_rx_limit.*/us_um_empty_rx_limit = 0/" $TEMPLATE_CONFIG
sed -i "s/us_um_type.*/us_um_type = scheduler/" $TEMPLATE_CONFIG
sed -i "s/us_lm_empty_rx_limit.*/us_lm_empty_rx_limit = 0/" $TEMPLATE_CONFIG
sed -i "s/us_lm_type.*/us_lm_type = scheduler/" $TEMPLATE_CONFIG

# Set stat settings
sed -i "s/LATENCY_ENABLED/$LATENCY/" $TEMPLATE_CONFIG
sed -i "s/CYCLES_ENABLED/$CYCLES/" $TEMPLATE_CONFIG
sed -i "s/APP_STATS_ENABLED/$APP_STATS/" $TEMPLATE_CONFIG

# Set the us-scheduler settings
sed -i "s/US_SCHED_ENABLED/$US_SCHED_ENABLED/" $TEMPLATE_CONFIG
us_sched_port_id=`expr 8300 + $US_SCHED_ID`
sed -i "s/US_SCHED_PORT_ID/$us_sched_port_id/" $TEMPLATE_CONFIG
if [ $US_SCHED_ENABLED == "true" ]; then
    us_sched_ip_addr=$(nslookup us-sched-$US_SCHED_ID.default.svc.cluster.local | grep Address | awk 'FNR == 2 {print $2}')
    if [ $us_sched_ip_addr == "" ]; then
        echo "There was an issue resolving the IP address of the Upstream Scheduler for SG $SG_ID vCMTS"
        echo "Upstream Scheduler hostname us-sched-$US_SCHED_ID.default.svc.cluster.local could not be resolved"
        exit
    fi
else
    us_sched_ip_addr="127.0.0.1"
fi
sed -i "s/US_SCHED_IP_ADDR/$us_sched_ip_addr/" $TEMPLATE_CONFIG

# Set crypto settings
sed -i "s/CRC_RECALC_ENABLED/$CRC/" $TEMPLATE_CONFIG
sed -i "s/AES_KEY_SIZE/$AES_KEY_SIZE/" $TEMPLATE_CONFIG

# Disable QAT
sed -i "s/QAT_ENABLED/$QAT/" $TEMPLATE_CONFIG
if [ "$QAT" = "true" ];
then
    if [[ ! -z $QAT_OVERRIDE ]]; then
        qat_dev=$QAT_OVERRIDE
    else
        qat_dev=`env | grep "QAT" | grep -v "QAT_" | grep -v "QAT=" | sed "s/.*=//"`
    fi
    sed -i "s/.*QAT_PCI.*/pci_allow = $qat_dev/" $TEMPLATE_CONFIG
fi

# Set service group ID specific settings
# IP address and tls ports depend on SG_ID
sed -i "s/SG_ID.*/$SG_ID/" $TEMPLATE_CONFIG
ip=`expr 200 + $SG_ID`
IP_ADDR="192.168.1.$ip"
sed -i "s/VCMTSD_IP_ADDR_NETWORK/$IP_ADDR/" $TEMPLATE_CONFIG
ip=`expr 100 + $SG_ID`
IP_ADDR="192.168.1.$ip"
sed -i "s/VCMTSD_IP_ADDR_RPHY/$IP_ADDR/" $TEMPLATE_CONFIG
TLS_CERTS_DIR="\/home\/vcmts\/"
sed -i "s/TLS_CERTS_DIR/$TLS_CERTS_DIR/" $TEMPLATE_CONFIG
TLS_PORT=`expr 8100 + $SG_ID`
sed -i "s/TLS_PORT_ID/$TLS_PORT/" $TEMPLATE_CONFIG
sed -i "s/TLS_SERVER_IP_ADDR/0\.0\.0\.0/" $TEMPLATE_CONFIG

# Set json config file depending on subscriber settings
scqam="32sc"
if [ $NUM_OFDM -gt 3 ];
then
    scqam="0sc"
fi
vcmts_json_config=""$NUM_OFDM"ofdm-"$scqam"-qam_"$NUM_SUBS"cms_"$CM_CRYPTO".json"
echo $vcmts_json_config

# Set NIC PCI addr
PCI_ADDR=$(eval echo \$$NIC_PCIADDR_RPHY)
if [[ ! -z $NIC_OVERRIDE_RPHY ]]; then
    PCI_ADDR=$NIC_OVERRIDE_RPHY
fi
sed -i "s/NIC_PCI_RPHY/$PCI_ADDR/" $TEMPLATE_CONFIG
PCI_ADDR=$(eval echo \$$NIC_PCIADDR_NET)
if [[ ! -z $NIC_OVERRIDE_NET ]]; then
    PCI_ADDR=$NIC_OVERRIDE_NET
fi
sed -i "s/NIC_PCI_NET/$PCI_ADDR/" $TEMPLATE_CONFIG
sed -i "s/FILE_PREFIX/$PCI_ADDR/" $TEMPLATE_CONFIG

# Write power mgmt policy if enabled
if [ "$POWER_MGMT" = "time_of_day" ];
then
    cp /home/vcmts/vcmts-config/power_policy_create.cfg /tmp/power_policy_create.cfg
    cp /home/vcmts/vcmts-config/power_policy_destroy.cfg /tmp/power_policy_destroy.cfg
    echo "cat /tmp/power_policy_destroy.cfg >> /opt/power_mgmt/fifo${cpus[0]}" > /tmp/power_policy_destroy.sh
    echo "cat /tmp/power_policy_destroy.cfg >> /opt/power_mgmt/fifo${cpus[1]}" >> /tmp/power_policy_destroy.sh
    echo "cat /tmp/power_policy_destroy.cfg >> /opt/power_mgmt/fifo${cpus[2]}" >> /tmp/power_policy_destroy.sh
    echo "cat /tmp/power_policy_destroy.cfg >> /opt/power_mgmt/fifo${cpus[3]}" >> /tmp/power_policy_destroy.sh
    cat /home/vcmts/tmp/power_policy_create.cfg >> /opt/power_mgmt/fifo${cpus[0]}
    cat /home/vcmts/tmp/power_policy_create.cfg >> /opt/power_mgmt/fifo${cpus[1]}
    cat /home/vcmts/tmp/power_policy_create.cfg >> /opt/power_mgmt/fifo${cpus[2]}
    cat /home/vcmts/tmp/power_policy_create.cfg >> /opt/power_mgmt/fifo${cpus[3]}
    chmod +x /tmp/power_policy_destroy.sh
fi

cp $TEMPLATE_CONFIG /home/vcmts/vcmts_"$SG_ID".cfg
/home/vcmts/vcmts-d -f $TEMPLATE_CONFIG -j /home/vcmts/$vcmts_json_config
