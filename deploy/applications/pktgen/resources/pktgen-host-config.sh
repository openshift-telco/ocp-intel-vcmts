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
# PKTGEN HOST CONFIGURATION
################################################################################

export LD_LIBRARY_PATH="/usr/local/lib/x86_64-linux-gnu"

# Number of VF to create and use per PF
# Depends on number of SG's being configured
export num_vf_per_pf=4
export gen_num_vf_per_pf=8
export max_sg_per_cpu_socket=8
export nic_type='25G'

# PFs and VFs to instantiate
declare -a ports_pf=("4b:00.0" "4b:00.1")
declare -A ports_vf=(
["4b:00.1"]="4b:11.0 4b:11.1 4b:11.2 4b:11.3 4b:11.4 4b:11.5 4b:11.6 4b:11.7"
["31:00.1"]="31:11.0 31:11.1 31:11.2 31:11.3 31:11.4 31:11.5 31:11.6 31:11.7"
["b1:00.1"]="b1:11.0 b1:11.1 b1:11.2 b1:11.3 b1:11.4 b1:11.5 b1:11.6 b1:11.7"
["ca:00.1"]="ca:11.0 ca:11.1 ca:11.2 ca:11.3 ca:11.4 ca:11.5 ca:11.6 ca:11.7"
)

# Mapping of pktgen ports to cores
declare -A pktgen_port_to_core_map=(
["0 ct"]="1" # HT0 of core 1 used for Pktgen command shell and timers for CPU socket 0 
["0 crx"]="65" # HT1 of core 1 used for traffic Rx for CPU socket 0 
["1 ct"]="33" # HT0 of core 1 used for Pktgen command shell and timers for CPU socket 1
["1 crx"]="97" # HT1 of core 1 used for traffic Rx for CPU socket 1
# Socket 0
["0 us"]="4" # Pktgen port for SG 0 US uses core 3 (CPU socket 0) 
["0 ds"]="5" # Pktgen port for SG 0 US uses core 4 (CPU socket 0) 
["1 us"]="6"
["1 ds"]="7"
["2 us"]="8"
["2 ds"]="9"
["3 us"]="10"
["3 ds"]="11"
["4 us"]="12"
["4 ds"]="13"
["5 us"]="14"
["5 ds"]="15"
["6 us"]="16"
["6 ds"]="17"
["7 us"]="18"
["7 ds"]="19"
["8 us"]="20" 
["8 ds"]="21"
["9 us"]="22"
["9 ds"]="23"
["10 us"]="24"
["10 ds"]="25"
["11 us"]="26"
["11 ds"]="27"
["12 us"]="28"
["12 ds"]="29"
["13 us"]="30"
["13 ds"]="31"
# Socket 1
["14 us"]="36"
["14 ds"]="37"
["15 us"]="38"
["15 ds"]="39"
["16 us"]="40"
["16 ds"]="41"
["17 us"]="42"
["17 ds"]="43"
["18 us"]="44"
["18 ds"]="45"
["19 us"]="46"
["19 ds"]="47"
["20 us"]="48"
["20 ds"]="49"
["21 us"]="50"
["21 ds"]="51"
["22 us"]="52"
["22 ds"]="53"
["23 us"]="54"
["23 ds"]="55"
["24 us"]="56"
["24 ds"]="57"
["25 us"]="58"
["25 ds"]="59"
["26 us"]="60"
["26 ds"]="61"
["27 us"]="62"
["27 ds"]="63"
)
