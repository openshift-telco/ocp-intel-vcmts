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

source /home/vcmts/pktgen-config/pktgen-host-config.sh

var="PCIDEVICE_OPENSHIFT_IO_PKTGEN_NW_VF_US_"$PF_INDEX""
PCIADDR_0=$(eval echo \$$var)
var="PCIDEVICE_OPENSHIFT_IO_PKTGEN_NW_VF_DS_"$PF_INDEX""
PCIADDR_1=$(eval echo \$$var)

if [[ ! -z $OVERRIDE_PCIADDR_0 ]]; then
  PCIADDR_0=$OVERRIDE_PCIADDR_0
  PCIADDR_1=$OVERRIDE_PCIADDR_1
fi

if [ $NUM_SOCKETS -eq 1 ]; then
  ct=${pktgen_port_to_core_map[0 ct]};crx=${pktgen_port_to_core_map[0 crx]}
  socketmem="1024"
elif [ $CPU_SOCKET_ID -eq 0 ]; then
  ct=${pktgen_port_to_core_map[0 ct]};crx=${pktgen_port_to_core_map[0 crx]}
  socketmem="1024,0"
else
  ct=${pktgen_port_to_core_map[1 ct]};crx=${pktgen_port_to_core_map[1 crx]}
  socketmem="0,1024"
fi

ctx0=${pktgen_port_to_core_map[$PKTGEN_ID us]}
ctx1=${pktgen_port_to_core_map[$PKTGEN_ID ds]}
core_list="$ct,$crx,$ctx0,$ctx1"
fp="pktgen_us_"$PKTGEN_ID"_0_ds_"$PKTGEN_ID"_1"
port=`expr 23000 + $PKTGEN_ID`

ip=`expr 100 + $PKTGEN_ID`
pktgen_ip_addr_us="192.168.2.$ip"
ip=`expr 100 + $PKTGEN_ID`
vcmtsd_ip_addr_us="192.168.1.$ip"
ip=`expr 200 + $PKTGEN_ID`
pktgen_ip_addr_ds="192.168.2.$ip"
ip=`expr 200 + $PKTGEN_ID`
vcmtsd_ip_addr_ds="192.168.1.$ip"
sed -i "s/pktgen_ip_addr_us/$pktgen_ip_addr_us/" /home/vcmts/pcaps/setup.pkt
sed -i "s/vcmtsd_ip_addr_us/$vcmtsd_ip_addr_us/" /home/vcmts/pcaps/setup.pkt
sed -i "s/pktgen_ip_addr_ds/$pktgen_ip_addr_ds/" /home/vcmts/pcaps/setup.pkt
sed -i "s/vcmtsd_ip_addr_ds/$vcmtsd_ip_addr_ds/" /home/vcmts/pcaps/setup.pkt

  echo "/home/vcmts/pktgen -l $core_list -n 2 --socket-mem $socketmem -w $PCIADDR_0 -w $PCIADDR_1 --file-prefix $fp -- -T -P -m [$crx:$ctx0].0 -m [$crx:$ctx1].1 -f /home/vcmts/pcaps/setup.pkt -s 0:/home/vcmts/pcaps/$PCAP_0 -s 1:/home/vcmts/pcaps/$PCAP_1 -g localhost:$port"
  /home/vcmts/pktgen -l $core_list -n 2 --socket-mem $socketmem -w $PCIADDR_0 -w $PCIADDR_1 --file-prefix $fp -- -T -P -m [$crx:$ctx0].0 -m [$crx:$ctx1].1 -f /home/vcmts/pcaps/setup.pkt -s 0:/home/vcmts/pcaps/$PCAP_0 -s 1:/home/vcmts/pcaps/$PCAP_1 -g localhost:$port
