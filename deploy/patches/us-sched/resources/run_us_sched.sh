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

TEMPLATE_CONFIG="us_sched.cfg"

source /home/vcmts/us-sched-config/k8s_cpus.sh
IFS=' ' read -ra cpus <<< $(k8s_cpus_get)

# Print allocated cpus for debug
echo CPUs allocated to container cgroup are: ${cpus[*]}

# Confirm 1 lcores was allocated
if [ ${#cpus[@]} -ne 1 ]; then
    echo 'Exactly 1 lcore was not allocated by Native CPU Manager'
    exit
fi

# Write lcore to config file
sed -i "s/us_sched_lcore/${cpus[0]}/" $TEMPLATE_CONFIG

sed -i "s/FILE_PREFIX/us_sched_$US_SCHED_ID/" $TEMPLATE_CONFIG

# Set numa settings in config file
sed -i "s/cpu =.*/cpu = $CPU_SOCKET_ID/" $TEMPLATE_CONFIG
sed -i "s/socket_mem.*/socket_mem = $SOCKET_MEM/" $TEMPLATE_CONFIG
sed -i "s/socket_limit.*/socket_limit = $SOCKET_LIM/" $TEMPLATE_CONFIG

sed -i "s/VCMTSD_PORT_ID/$US_SCHED_PORT_ID/" $TEMPLATE_CONFIG
sed -i "s/TCP_SERVER_IP/0\.0\.0\.0/" $TEMPLATE_CONFIG

/home/vcmts/us-sched -f $TEMPLATE_CONFIG -j /home/vcmts/us_sched.json
