provider "helm" {
  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir       = "${path.cwd}/.tmp"
  host          = "${var.name}-${var.app_namespace}.${var.ingress_subdomain}"
  url_endpoint  = "https://${host}"
}

resource "null_resource" "jaeger-subscription" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-subscription.sh ${var.cluster_type} ${var.operator_namespace} ${var.olm_namespace}"

    environment = {
      TMP_DIR    = local.tmp_dir
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "jaeger-instance" {
  depends_on = [null_resource.jaeger-subscription]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-instance.sh ${var.cluster_type} ${var.app_namespace} ${var.ingress_subdomain} ${var.name}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

data "helm_repository" "toolkit-charts" {
  name = "toolkit-charts"
  url  = "https://ibm-garage-cloud.github.io/toolkit-charts/"
}

resource "helm_release" "jaeger-config" {
  depends_on = [null_resource.jaeger-instance]

  name         = "jaeger"
  repository   = data.helm_repository.toolkit-charts.name
  chart        = "tool-config"
  namespace    = var.app_namespace
  force_update = true

  set {
    name  = "url"
    value = local.host
  }
}
