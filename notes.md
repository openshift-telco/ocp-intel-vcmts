#### TBD
We don't need to run cable_pf_helper?

#### tools that aren't installed
vCMTS server
  install_pcm_tool
  install_power_mgmt_utilities
  install_qat_drivers --> do we support QAT offload in OpenShift?
--> These are tools built on the host... they can't/shouldn't be there in OpenShift - what is expected from them in the containers

#### Remove mounts from host
vcmtsd
  /opt/power_mgmt
  /var/run/collectd

vcmts-power-mgr
  /opt/power_mgmt

#### Monitoring
How do make https://github.com/opcm/pcm work?

#### Power Mgnt
- Does it need power-manager? How does that translate in a K8S environment: https://doc.dpdk.org/guides/sample_app_ug/vm_power_management.html

Power Mgnt tools
    CommsPowerManagement
    dpdk vm_power_manager

#### vcmts-pm
- `vcmts-pm config-platform vcmtsd|pktgen`
    - automatically generate pf to vf mapping?! 
        - *-host-config.sh 
- ` vcmts-pm config-service-groups` 
    --> helm chart values.yaml file generation

##### Test pktgen Lua socket from host
socat - TCP4:10.129.3.239:23000 < hello-world.lua
