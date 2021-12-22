# `env.sh` 
- line 47: Add a `IS_RHEL` knob to use the modification required for Red Hat UBI build
- line 338: Build using Red Hat UBI container using the `vfs` storage driver
- line 501: Comment `VIRTIO_F_IOMMU_PLATFORM` from `ifcvf.sh` to avoid build error
- line 758: Use build_baremetal_power_mgr instead

# vcmts chart

#### `run_vcmstd.sh`
- line 116: `us_sched_ip_addr` do you need the IP address or DNS name is fine?


#### `vcmtsd-pod.yaml`
- many edits