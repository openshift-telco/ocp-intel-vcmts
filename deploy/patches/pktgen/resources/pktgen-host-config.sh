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
["4b:00.0"]="4b:01.0 4b:01.1 4b:01.2 4b:01.3 4b:01.4 4b:01.5 4b:01.6 4b:01.7"
["4b:00.1"]="4b:11.0 4b:11.1 4b:11.2 4b:11.3 4b:11.4 4b:11.5 4b:11.6 4b:11.7"
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
["14 us"]="68" # Pktgen port for SG 14 US uses core 68 (CPU socket 0) 
["14 ds"]="69" # Pktgen port for SG 14 US uses core 69 (CPU socket 0) 
["15 us"]="70"
["15 ds"]="71"
["16 us"]="72"
["16 ds"]="73"
["17 us"]="74"
["17 ds"]="75"
["18 us"]="76"
["18 ds"]="77"
["19 us"]="78"
["19 ds"]="79"
["20 us"]="80"
["20 ds"]="81"
["21 us"]="82"
["21 ds"]="83"
["22 us"]="84"
["22 ds"]="85"
["23 us"]="86"
["23 ds"]="87"
["24 us"]="88"
["24 ds"]="89"
["25 us"]="90"
["25 ds"]="91"
["26 us"]="92"
["26 ds"]="93"
["27 us"]="94"
["27 ds"]="95"
# Socket 1
["28 us"]="36" # Pktgen port for SG 28 US uses core 36 (CPU socket 1)
["28 ds"]="37" # Pktgen port for SG 28 US uses core 37 (CPU socket 1)
["29 us"]="38"
["29 ds"]="39"
["30 us"]="40"
["30 ds"]="41"
["31 us"]="42"
["31 ds"]="43"
["32 us"]="44"
["32 ds"]="45"
["33 us"]="46"
["33 ds"]="47"
["34 us"]="48"
["34 ds"]="49"
["35 us"]="50"
["35 ds"]="51"
["36 us"]="52"
["36 ds"]="53"
["37 us"]="54"
["37 ds"]="55"
["38 us"]="56"
["38 ds"]="57"
["39 us"]="58"
["39 ds"]="59"
["40 us"]="60"
["40 ds"]="61"
["41 us"]="62"
["41 ds"]="63"
["42 us"]="100"
["42 ds"]="101"
["43 us"]="102"
["43 ds"]="103"
["44 us"]="104"
["44 ds"]="105"
["45 us"]="106"
["45 ds"]="107"
["46 us"]="108"
["46 ds"]="109"
["47 us"]="110"
["47 ds"]="111"
["48 us"]="112"
["48 ds"]="113"
["49 us"]="114"
["48 ds"]="115"
["50 us"]="116"
["50 ds"]="117"
["51 us"]="118"
["51 ds"]="119"
["52 us"]="120"
["52 ds"]="121"
["53 us"]="122"
["53 ds"]="123"
["54 us"]="124"
["54 ds"]="125"
["55 us"]="126"
["55 ds"]="127"
)
