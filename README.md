# Intel vCMTS on OpenShift

## Table of Contents

<!-- TOC -->
- [Introduction](#introduction)
- [Prerequisities](#prerequisities)
- [Build Container Images](#build-container-images)
- [Network Setup](#network-setup)
- [Monitoring](#monitoring)
- [Deploy the application](#deploy-the-application)
<!-- TOC -->

## Introduction

This document describes how to build, install and run the Intel vCMTS reference dataplane system on Red Hat OpenShift Container Platform. Intel vCMTS includes a DPDK Pktgen based cable traffic generation system for upstream and downstream traffic simulation.

## Prerequisities

  - Intel vCMTS Package
  - Red Hat OpenShift version 4.8.20
  - Red Hat OpenShift Data Foundation
  - Red Hat OpenShift Pipeline
  - Podman / Buildah (for local build only)
  - Helm 3 (for local build only)

## Build Container Images
They are two ways to build the vCMTS related applications, please see [build options](build/README.md).

## Network Setup

#### SRIOV Resource pools

We need to split virtual functions (VFs) from the same physical function (PF) into multiple resource pools in order to segragate and dedicate traffic per VF for Upstream and Downstream.

Each PF is divided into 8 VFs:
- even VFs are be for upstream traffic
- odd VFs are for downstream traffic

Find the manifest in the [config/sriov folder](config/sriov).

## Monitoring

Setup OpenShift Prometheus to scrape user projects metrics
```
oc apply -f config/monitoring/prometheus-enable-user-workload.yaml
```

Load vCMTS Grafana Dashboard
```
oc kustomize config/monitoring/dashboards | oc apply -f -
```

Create Grafana Instance
```
oc create -f config/monitoring/grafana.yaml
```

Configure Grafna to use OpenShift thanos as proxy data source to retrieve prometheus data.
```
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount -n vcmts-build
BEARER_TOKEN=$(oc serviceaccounts get-token grafana-serviceaccount -n vcmts-build)

echo "apiVersion: integreatly.org/v1alpha1
kind: GrafanaDataSource
metadata:
  name: prometheus-grafanadatasource
  namespace: vcmts-build
spec:
  datasources:
    - access: proxy
      editable: true
      isDefault: true
      jsonData:
        httpHeaderName1: 'Authorization'
        timeInterval: 5s
        tlsSkipVerify: true
      name: prometheus
      secureJsonData:
        httpHeaderValue1: 'Bearer ${BEARER_TOKEN}'
      type: prometheus
      url: 'https://thanos-querier.openshift-monitoring.svc.cluster.local:9091'
  name: prometheus-grafanadatasource.yaml" | oc apply -f -
```

Deploy collectd and collectd-exporter, along with OpenShift Prometheus metrics scrapper `ServiceMonitor`
```
oc create -f deploy/test-pod/collectd.yaml
```

## Deploy the application

TODO:
  Create helm chart repository using static pages

#### vCMTS-D

~~~
helm install vcmts . -n vcmts-build
helm uninstall vcmts -n vcmts-build
~~~

#### pktgen

~~~
helm install pktgen . -n vcmts-build
helm uninstall pktgen -n vcmts-build
~~~