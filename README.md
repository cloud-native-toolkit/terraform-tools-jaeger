# Jaeger terraform module

![Latest release](https://img.shields.io/github/v/release/ibm-garage-cloud/terraform-tools-jaeger?sort=semver) ![Verify and release module](https://github.com/ibm-garage-cloud/terraform-tools-jaeger/workflows/Verify%20and%20release%20module/badge.svg)

Terraform module that will install Jaeger into the cluster via an operator.

## Supported platforms

This module supports the following Kubernetes distros

- Kubernetes
- OCP 3.11
- OCP 4.3

For both Kubernetes and OCP

## Module dependencies

- Cluster
- OLM

## Software dependencies

- kubectl
- helm terraform provider (provided by the terraform infrastructure)

## Example usage

```hcl-terraform
module "dev_tools_jaeger" {
  source = "github.com/ibm-garage-cloud/terraform-tools-jaeger.git?ref=v1.0.0"

  cluster_config_file = module.dev_cluster.config_file_path
  cluster_type        = module.dev_cluster.type
  app_namespace       = module.dev_cluster_namespaces.tools_namespace_name
  ingress_subdomain   = module.dev_cluster.ingress_hostname
  olm_namespace       = module.dev_software_olm.olm_namespace
  operator_namespace  = module.dev_software_olm.target_namespace
  name                = "jaeger"
}
```
