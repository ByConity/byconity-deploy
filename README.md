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

### Delete or stop ByConity from your Kubernetes cluster

```bash
helm uninstall --namespace byconity byconity
```

In case you want to stop it temporarily stop it on your machine

```bash
docker stop byconity-cluster-control-plane byconity-cluster-worker byconity-cluster-worker2 byconity-cluster-worker3
```

## Deploy in your self-built Kubernetes

### How to deploy or buy a Kubernetes cluster?

You can get information here: [Production environment](https://kubernetes.io/docs/setup/production-environment/)

### Prerequisites

- Install and setup [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) in your local environment
- Install [helm](https://helm.sh/) in your local environment

### Prepare your storage provider

For best [TCO](https://en.wikipedia.org/wiki/Total_cost_of_ownership) with performance, local disks are preferred to be used with ByConity servers and workers.

> Storage for ByConity servers and workers is for disk cache only, you can delete them any time.

You may use storage providers like [OpenEBS local PV](https://openebs.io/docs/concepts/localpv).

### Prepare your own helm values files

You may copy from ./chart/byconity/values.yaml and modify some fields like:

- storageClassName
- timezone
- replicas for server/worker
- hdfs storage request

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
CREATE DATABASE IF NOT EXISTS test;
USE test;
DROP TABLE IF EXISTS test.lc;
CREATE TABLE test.lc (b LowCardinality(String)) engine=CnchMergeTree ORDER BY b;
INSERT INTO test.lc SELECT '0123456789' FROM numbers(100000000);
SELECT count(), b FROM test.lc group by b;
DROP TABLE IF EXISTS test.lc;
DROP DATABASE test;
```

## Update your Byconity cluster

### Add new virtual warehouses

Assume you want to add 2 virtual warehouses for your users, 5 replicas for `my-new-vw-default` to read and 2 replicas for `my-new-vw-write` to write.

Modify your values.yaml

```yaml
byconity:
  virtualWarehouses:
    ...

    - <<: *defaultWorker
      name: my-new-vw-default
      replicas: 5
    - <<: *defaultWorker
      name: my-new-vw-write
      replicas: 2
```

Apply your helm release with your new values

```bash
helm upgrade --install --create-namespace --namespace byconity -f ./your/custom/values.yaml byconity ./chart/byconity
```

Run `CREATE WAREHOUSE` DDL to create logic virtual warehouse in Byconity

```sql
CREATE WAREHOUSE IF NOT EXISTS `my-new-vw-default` SETTINGS num_workers = 0, type = 'Read';
CREATE WAREHOUSE IF NOT EXISTS `my-new-vw-write` SETTINGS num_workers = 0, type = 'Write';
```

Done. Let's create a table and use your new virtual warehouse now!

```sql
-- Create a table with SETTINGS cnch_vw_default = 'my-new-vw-default', cnch_vw_write = 'my-new-vw-write'
CREATE DATABASE IF NOT EXISTS test;
CREATE TABLE test.lc2 (b LowCardinality(String)) engine=CnchMergeTree
ORDER BY b
SETTINGS cnch_vw_default = 'my-new-vw-default', cnch_vw_write = 'my-new-vw-write';

-- Check if the table has the new settings
SHOW CREATE TABLE test.lc2;
```
