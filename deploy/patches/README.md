# Charts
Labels are define as follow in repsective pod:
    vcmtspktgen=true
    vcmts=true

#### `*-configmap.yaml`
- remove hardcoded namespace

#### `*-pod.yaml`
- use respective us/ds sriov networks
- change intel.com to openshift.io
- change entrypoint to use `sleep infinity` to debug and not fail the container
- use subPath for entrypoint script as directory exist in container
- remove ipsec mount as provided directly in the container
- do not rely on pci override

#### pktgen
- Where /home/vcmts/Pktgen.lua comes from?
    - https://raw.githubusercontent.com/pktgen/Pktgen-DPDK/pktgen-19.10.0/Pktgen.lua
- fork `pktgen-host-config.sh` to add PCI PF/VF mapping
-`run_pktgen.sh`
    - line 39 & 41: change intel.com to openshift.io

#### vcmtsd
- fork `vcmts-host-config.sh` to add PCI PF/VF mapping
- `run_vcmstd.sh`
    - line 116: `us_sched_ip_addr` do you need the IP address or DNS name is fine?