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
  - [SRIOV Config](#sriov-config)
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

## Architecture


## SRIOV Config

### Resource pools

We need to split virtual functions (VFs) from the same physical function (PF) into multiple resource pools in order to segragate and dedicate traffic per VF for Upstream and Downstream.

## Deploy the application

TODO:
  Create helm chart repository using static pages

#### vCMTS-D

~~~
helm install vcmts . -n vcmts-build
~~~