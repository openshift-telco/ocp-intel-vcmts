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
declare -a ports_pf=("8a:00.0" "8a:00.1" "07:00.0" "07:00.1" "05:00.0" "05:00.1" "81:00.0" "81:00.1" "4b:00.0" "4b:00.1")
declare -A ports_vf=(
["8a:00.0"]="8a:02.0 8a:02.1 8a:02.2 8a:02.3 8a:02.4 8a:02.5 8a:02.6 8a:02.7"
["8a:00.1"]="8a:0a.0 8a:0a.1 8a:0a.2 8a:0a.3 8a:0a.4 8a:0a.5 8a:0a.6 8a:0a.7"
["07:00.0"]="07:02.0 07:02.1 07:02.2 07:02.3 07:02.4 07:02.5 07:02.6 07:02.7"
["07:00.1"]="07:0a.0 07:0a.1 07:0a.2 07:0a.3 07:0a.4 07:0a.5 07:0a.6 07:0a.7"
["05:00.0"]="05:02.0 05:02.1 05:02.2 05:02.3 05:02.4 05:02.5 05:02.6 05:02.7"
["05:00.1"]="05:0a.0 05:0a.1 05:0a.2 05:0a.3 05:0a.4 05:0a.5 05:0a.6 05:0a.7"
["81:00.0"]="81:02.0 81:02.1 81:02.2 81:02.3 81:02.4 81:02.5 81:02.6 81:02.7"
["81:00.1"]="81:0a.0 81:0a.1 81:0a.2 81:0a.3 81:0a.4 81:0a.5 81:0a.6 81:0a.7"
["4b:00.0"]="4b:01.0 4b:01.1 4b:01.2 4b:01.3 4b:01.4 4b:01.5 4b:01.6 4b:01.7"
["4b:00.1"]="4b:11.0 4b:11.1 4b:11.2 4b:11.3 4b:11.4 4b:11.5 4b:11.6 4b:11.7"
)

# Mapping of pktgen ports to cores
declare -A pktgen_port_to_core_map=(
["0 ct"]="1"
["0 crx"]="37"
["1 ct"]="19"
["1 crx"]="55"
["0 us"]="2" # SG 0 DS uses core 1
["0 ds"]="3" # SG 0 US uses core 2
["1 us"]="4"
["1 ds"]="5"
["2 us"]="6"
["2 ds"]="7"
["3 us"]="8"
["3 ds"]="9"
["4 us"]="10"
["4 ds"]="11"
["5 us"]="12"
["5 ds"]="13"
["6 us"]="14"
["6 ds"]="15"
["7 us"]="16"
["7 ds"]="17"
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
["14 us"]="32"
["14 ds"]="33"
["15 us"]="34"
["15 ds"]="35"
#["0 us"]="2" # SG 0 DS uses core 1
#["0 ds"]="3" # SG 0 US uses core 2
#["1 us"]="4"
#["1 ds"]="5"
#["2 us"]="38"
#["2 ds"]="39"
#["3 us"]="40"
#["3 ds"]="41"
#["4 us"]="6"
#["4 ds"]="7"
#["5 us"]="8"
#["5 ds"]="9"
#["6 us"]="42"
#["6 ds"]="43"
#["7 us"]="44"
#["7 ds"]="45"
#["8 us"]="10"
#["8 ds"]="11"
#["9 us"]="12"
#["9 ds"]="13"
#["10 us"]="46"
#["10 ds"]="47"
#["11 us"]="48"
#["11 ds"]="49"
#["12 us"]="14"
#["12 ds"]="15"
#["13 us"]="16"
#["13 ds"]="17"
#["14 us"]="50"
#["14 ds"]="51"
#["15 us"]="52"
#["15 ds"]="53"
#["16 us"]="20" # SG 0 DS uses core 1
#["16 ds"]="21" # SG 0 US uses core 2
#["17 us"]="22"
#["17 ds"]="23"
#["18 us"]="56"
#["18 ds"]="57"
#["19 us"]="58"
#["19 ds"]="59"
#["20 us"]="24"
#["20 ds"]="25"
#["21 us"]="26"
#["21 ds"]="27"
#["22 us"]="60"
#["22 ds"]="61"
#["23 us"]="62"
#["23 ds"]="63"
#["24 us"]="28"
#["24 ds"]="29"
#["25 us"]="30"
#["25 ds"]="31"
#["26 us"]="64"
#["26 ds"]="65"
#["27 us"]="66"
#["27 ds"]="67"
#["28 us"]="32"
#["28 ds"]="33"
#["29 us"]="34"
#["29 ds"]="35"
#["30 us"]="68"
#["30 ds"]="69"
#["31 us"]="70"
#["31 ds"]="71"
)
