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

###############################################################################
# VCMTS HOST CONFIGURATION
################################################################################

export LD_LIBRARY_PATH="$COLLECTD_ROOT/lib"

# Number of VF to create and use per PF
# Depends on number of SG's being configured
export num_vf_per_pf=4
export gen_num_vf_per_pf=8
export max_sg_per_cpu_socket=8
export nic_type='25G'

# NIC PFs and VFs
declare -a ports_pf=("4b:00.0" "4b:00.1")
declare -A ports_vf=(
["4b:00.0"]="4b:01.0 4b:01.1 4b:01.2 4b:01.3 4b:01.4 4b:01.5 4b:01.6 4b:01.7"
["4b:00.1"]="4b:11.0 4b:11.1 4b:11.2 4b:11.3 4b:11.4 4b:11.5 4b:11.6 4b:11.7"
)

# QAT PFs and VFs
declare -a qat_ports_pf=("8a:00.0" "8c:00.0" "8e:00.0")
declare -A qat_ports_vf=(
["05:00.0"]="05:01.0 05:01.1 05:01.2 05:01.3 05:01.4 05:01.5 05:01.6 05:01.7"
)
