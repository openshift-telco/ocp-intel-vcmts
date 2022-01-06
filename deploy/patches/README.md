# Charts

Labels are define as follow in repsective pod:
    vcmtspktgen=true
    vcmts=true

#### `run_vcmstd.sh`
- line 116: `us_sched_ip_addr` do you need the IP address or DNS name is fine?

#### `run_pktgen.sh`
- line 39 & 41: change intel.com to openshift.io

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
- what is /home/vcmts/Pktgen.lua and where it comes from?
- fork `pktgen-host-config.sh` to add PCI PF/VF mapping

### vcmtsd
- fork `vcmts-host-config.sh` to add PCI PF/VF mapping

### vcmts-pm
- `vcmts-pm config-platform vcmtsd` | `vcmts-pm config-platform pktgen`
    - automatically generate pf to vf mapping?! 
        - *-host-config.sh 