The `env.sh` script is distributed through the vCMTS package. 
To build application container images using Red Hat Universal Base Image, couple adjustement have been made.

Here is the list of adjustement:
- line 47: Add a `IS_RHEL` knob to use the modification required for Red Hat UBI build
- line 338: Build using Red Hat UBI container using the `vfs` storage driver
- line 501: Comment `VIRTIO_F_IOMMU_PLATFORM` from `ifcvf.sh` to avoid build error
- line 758: Use build_baremetal_power_mgr instead
