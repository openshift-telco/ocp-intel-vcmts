# `env.sh` 
- line 47: Add a `IS_RHEL` knob to use the modification required for Red Hat UBI build
- line 338: Build using Red Hat UBI container using the `vfs` storage driver
- line 501: Comment `VIRTIO_F_IOMMU_PLATFORM` from `ifcvf.sh` to avoid build error
- line 568: Change RTE_SDK path to match build path
- line 758: Use build_baremetal_power_mgr instead