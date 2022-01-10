# `env.sh` 
- line 47: Add a `IS_RHEL` knob to use the modification required for Red Hat UBI build
- line 338: Build using Red Hat UBI container using the `vfs` storage driver
- line 501: Comment `VIRTIO_F_IOMMU_PLATFORM` from `ifcvf.sh` to avoid build error
- line 758: Use build_baremetal_power_mgr instead

# vcmts chart

- Does it need power-manager? How does that translate in a K8S environment: https://doc.dpdk.org/guides/sample_app_ug/vm_power_management.html

#### `run_vcmstd.sh`
- line 116: `us_sched_ip_addr` do you need the IP address or DNS name is fine?


#### `vcmtsd-pod.yaml`
- many edits

# Questions

2.9.1 Configure vCMTS dataplane service-group options
        --> this generate helm chart?

How overall does power management works?
    CommsPowerManagement
    dpdk vm_power_manager

#### Server
vCMTS server preparation
  install_pcm_tool
  install_power_mgmt_utilities
  install_qat_drivers --> do we support QAT offload in OpenShift
--> These are tools built on the host... they can't/shouldn't be there in OpenShift - what is expected from them in the containers

#### Containers

vcmtsd
  /opt/power_mgmt --> 
  /var/run/collectd

vcmts-power-mgr
  /opt/power_mgmt --> why is this mounted given it is already provided under /home/vcmts/

pktgen
  /usr/local/lib/x86_64-linux-gnu (dpdk)