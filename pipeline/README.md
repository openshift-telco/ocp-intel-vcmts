# OpenShift Pipeline

## Authentication to the repository
In order for the pipeline to authenticate to the Github repository, you must provide have a key-pair with the public key in your Github account, and load the private key into the OpenShift project.

See the `github-auth-secret_EXAMPLE.yaml` and replace `YOUR_BASE64_ENCODED_PRIVATE_KEY` with your encoded private key.

## Pipeline parameters
The pipeline supports the following parameters, with their according default value.
Cuztomize as needed.

    - default: 'http-server.vcmts-build:8080'
      name: HTTP_SERVER
      type: string
    - default: 21.10.0
      description: Intel VCMTS package version
      name: VCMTS_VERSION
      type: string
    - default: /usr/src/vcmts
      description: Build directory
      name: VCMTS_ROOT
      type: string
    - default: '21.02'
      description: Change version with corresponding Intel VCMTS build requirements
      name: DPDK_VERSION
      type: string
    - default: '20.08'
      name: DPDK_VERSION_PKTGEN
      type: string
    - default: '0.55'
      name: IPSEC_MB_VERSION
      type: string
    - default: 5.12.0
      name: COLLECTD_VERSION
      type: string
    - default: 19.10.0
      name: PKTGEN_VERSION
      type: string
    - default: 7.2.0
      name: GRAFANA_VERSION
      type: string
    - default: 2.0.0
      name: PROMETHEUS_VERSION
      type: string