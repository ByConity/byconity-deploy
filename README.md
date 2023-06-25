# ByConity Deploy

This folder structure of this repo is shown below. See [how to deploy a ByConity cluster in your Kubernetes cluster](https://byconity.github.io/docs/deployment/deploy-k8s) for detail information.

### File Introduction
```-- byconity
|-- Chart.yaml                     # YAML file containing information about the byconity chart
|-- charts
|   |-- fdb-operator               # fbd-operator Chart
|   `-- hdfs                       # hdfs Chart
|-- files                          # Byconity components config file template
|   |-- cnch-config.yaml           # config file template for some significant configurations
|   |-- daemon-manager.yaml        # config file template for daemon-manager
|   |-- resource-manager.yaml      # config file template for resource-manager
|   |-- server.yaml                # config file template for cnch-server
|   |-- tso.yaml                   # config file template for tso
|   |-- users.yaml                 # config file template for user configutation
|   `-- worker.yaml                # config file template for byconity-worker
|-- templates                      # A directory of templates that, when combined with values,
                                   # will generate valid Kubernetes manifest files.
`-- values.yaml                    # The default configuration values for this chart
```

