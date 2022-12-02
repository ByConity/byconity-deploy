# ByConity Deploy

This repos demonstrates how to deploy a ByConity cluster in your Kubernetes cluster.

## Deploy local to try a demo

### Prerequisites

- Install and setup [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) in your local environment
- Install [helm](https://helm.sh/) in your local environment
- Install [kind](https://kind.sigs.k8s.io/) and [Docker](https://www.docker.com/)

### Use Kind to configure a local Kubernetes cluster

> Warning: kind is not designed for production use.
> Note for macOS users: you may need to [increase the memory available](https://docs.docker.com/desktop/get-started/#resources) for containers (recommend 6 GB).

This would create a 1-control-plane, 3-worker Kubernetes cluster.

```bash
kind create cluster --config examples/kind/kind-byconity.yaml
```

Test to ensure the local kind cluster is ready:

```bash
kubectl cluster-info
```

### Initialize the Byconity demo cluster

```bash
# Install with fdb CRD first
helm upgrade --install --create-namespace --namespace byconity -f ./examples/kind/values-kind.yaml byconity ./chart/byconity --set fdb.enabled=false

# Install with fdb cluster
helm upgrade --install --create-namespace --namespace byconity -f ./examples/kind/values-kind.yaml byconity ./chart/byconity
```

Wait until all the pods are ready.

```bash
kubectl -n byconity get po
```

Let's try it out!

```
$ kubectl -n byconity exec -it sts/byconity-server -- bash
root@byconity-server-0:/# clickhouse client

172.16.1.1 :)
```

## Deploy in your self-built Kubernetes

### Prerequisites

- Install and setup [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) in your local environment
- Install [helm](https://helm.sh/) in your local environment

### Prepare your own helm values files

You may copy from ./chart/byconity/values.yaml and modify some fields like:

- storageClassName
- timezone
- replicas for server/worker
- hdfs storage request

### Prepare your storage provider

For best [TCO](https://en.wikipedia.org/wiki/Total_cost_of_ownership) with performance, local disks are preferred to be used with ByConity servers and workers.

You may use storage providers like [OpenEBS local PV](https://openebs.io/docs/concepts/localpv).

### Initialize the Byconity cluster

```bash
# Install with fdb CRD first
helm upgrade --install --create-namespace --namespace byconity -f ./your/custom/values.yaml byconity ./chart/byconity --set fdb.enabled=false

# Install with fdb cluster
helm upgrade --install --create-namespace --namespace byconity -f ./your/custom/values.yaml byconity ./chart/byconity
```

Wait until all the pods are ready.

```bash
kubectl -n byconity get po
```

Let's try it out!

```
$ kubectl -n byconity exec -it sts/byconity-server -- bash
root@byconity-server-0:/# clickhouse client

172.16.1.1 :)
```

## Test

### Run some SQLs to test

```sql
create database test;
USE test;
drop table if exists test.lc;
create table test.lc (b LowCardinality(String)) engine=CnchMergeTree order by b;
insert into test.lc select '0123456789' from numbers(100000000);
select count(), b from test.lc group by b;
drop table if exists test.lc;
drop database test;
```
