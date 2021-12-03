# Intel vCMTS on OpenShift

## Table of Contents

<!-- TOC -->
- [Intel vCMTS on OpenShift](#intel-vcmts-on-openshift)
  - [Introduction](#introduction)
  - [Prerequisities](#prerequisities)
  - [Architecture](#architecture)
  - [Build Container Images](#build-container-images)
    - [vCMTS](#vcmts)
    - [Pktgen](#pktgen)
  - [Installation](#installation)
<!-- TOC -->

## Introduction

This document describes how to build, install and run the Intel vCMTS reference dataplane system on Red Hat OpenShift Container Platform. Intel vCMTS includes a DPDK Pktgen based cable traffic generation system for upstream and downstream traffic simulation.

## Prerequisities

  - Red Hat OpenShift version 4.9
  - Podman
  - Buildah
  - Helm3
  - Intel vCMTS Package

## Architecture

## Build Container Images

Clone this repository.

```
$ git clone https://github.com/openshift-telco/ocp-intel-cvmts
```

Acquire Intel vCMTS package and copy to `ocp-intel-vcmts` directory. 
Example package: `intel-vcmtsd-v21-10-0-beta.tar.gz`.
Edit `build_config` and adjust as needed according to required build versions. Example:

```
$ cat build_config 
# Intel VCMTS package version
VCMTS_VERSION="21.10.0-beta"
# Build directory
VCMTS_ROOT="/usr/src/vcmts"

# Change version with corresponding Intel VCMTS build requirements
DPDK_VERSION="21.02"
DPDK_VERSION_PKTGEN="20.08"
IPSEC_MB_VERSION="0.55"
COLLECTD_VERSION="5.12.0"
PKTGEN_VERSION="19.10.0"
GRAFANA_VERSION="7.2.0"
PROMETHEUS_VERSION="2.0.0"
```

### vCMTSD

Launch build script.

```
$ ./build_vcmts.sh
```

Wait until the script finishes and container is commited to local storage.

```
...
Copying blob 657d43ff9b17 done  
Copying config 7ee089cfa5 done  
Writing manifest to image destination
Storing signatures
7ee089cfa5b61f58817b4b9c3b9e5e2f7bc5f5ca581cfa00ece671f2077a17b9
```

Verify image exists.

```
$ podman images | grep vcmts
localhost/vcmts                                        latest       7ee089cfa5b6  50 seconds ago  259 MB
```

### Pktgen

Launch build script.

```
$ ./build_pktgen.sh
```

Wait until the script finishes and container is commited to local storage.
Verify image exists

```
$ podman images | grep pktgen
localhost/vcmts-pktgen                                        latest       6e52dc9b5abe  50 seconds ago  2.14 GB
```
