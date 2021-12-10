# Intel vCMTS on OpenShift

## Table of Contents

<!-- TOC -->
- [Intel vCMTS on OpenShift](#intel-vcmts-on-openshift)
  - [Introduction](#introduction)
  - [Prerequisities](#prerequisities)
  - [Architecture](#architecture)
  - [Build Container Images](#build-container-images)
    - [Pipeline Build](#pipeline-build)
    - [Local Build](#local-build)
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
  - OpenShift Container Storage

## Architecture

## Build Container Images

### Pipeline Build

#### HTTP Server

The HTTP server is meant to provide the vCMTS tarball. This is where the pipeline will fetch it to build the containers.

The `/var/www/html/` folder is persistent, so the data copied there will remain even if the pod is deleted.

In order to copy the released .tar.gz into the HTTP Server, the following commands can be used:

Create the HTTP server:
~~~
$ oc create -f httpd/httpd.yaml
~~~

Find the pod name:
~~~
$ oc get pods -n vcmts-build -l app=http-server
NAME                           READY   STATUS    RESTARTS   AGE
http-server-6469986b9f-h4t2n   1/1     Running   0          22h
~~~

Copy the tarball onto the pod:
~~~
$ oc cp intel-vcmts-image.tar http-server-6469986b9f-xrrcm:/var/www/html/ -n vcmts-build
~~~

#### OpenShift Pipeline

##### Authentication to git repository
In order for the pipeline to authenticate to the Github repository, you must provide have a key-pair with the public key in your Github account, and load the private key into the OpenShift project.

See the `github-auth-secret_EXAMPLE.yaml` and replace `YOUR_BASE64_ENCODED_PRIVATE_KEY` with your encoded private key.

Then apply the secret:
~~~
$ oc create -f pipeline/github-auth-secret_EXAMPLE.yaml
~~~

##### Authentication to internal image registry

~~~
oc policy add-role-to-user registry-editor -z pipeline -n vcmts-build
~~~

##### Pipeline share workspace
In order to pass data between the pipeline tasks, a shared workspace is setup.

~~~
oc apply -f pipeline/vcmts-build-workspace-pvc.yaml
~~~

##### Pipeline tasks
The pipeline is comprised of 4 tasks, as follow:

![Architecture](https://raw.githubusercontent.com/openshift-telco/ocp-intel-vcmts/main/images/pipeline-overview.png)

The details for the `get-vcmts-archive` and `build-*` tasks are in `pipeline/tasks` folder

Create the tasks:

~~~
$ oc create -f pipeline/tasks/build-container.yaml
$ oc create -f pipeline/tasks/get-vcmts-archive.yaml
~~~

##### Pipeline
The pipeline supports the following parameters, with their according default value.
Cuztomize as needed.

    - default: 'http-server.vcmts-build:8080'
      name: HTTP_SERVER
      type: string
    - default: 21.10.0
      description: Intel VCMTS package version
      name: VCMTS_VERSION
      type: string
    - default: 'image-registry.openshift-image-registry.svc:5000'
      name: REGISTRY_URL
      type: string


Create the pipeline:

~~~
$ oc create -f pipeline/pipeline.yaml
~~~


### Local Build

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
VCMTS_VERSION="21.10.0"
# Registry to use to store the built image
REGISTRY_URL="localhost"
```

#### vCMTSD

Launch build script.

```
$ . build_config
$ ./build_vcmts.sh
```

Wait until the script finishes and container is commited to the specified repository.

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

#### Pktgen

Launch build script.

```
$ . build_config
$ ./build_pktgen.sh
```

Wait until the script finishes and container is commited to local storage.
Verify image exists

```
$ podman images | grep pktgen
localhost/vcmts-pktgen                                        latest       6e52dc9b5abe  50 seconds ago  2.14 GB
```
