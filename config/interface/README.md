# vcmts chart

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
- use subPath as directory exist in container
- remove ipsec mount