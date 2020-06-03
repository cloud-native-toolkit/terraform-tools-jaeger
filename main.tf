provider "helm" {
  version = ">= 1.0.0"

  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir       = "${path.cwd}/.tmp"
  host          = "${var.name}-${var.app_namespace}.${var.ingress_subdomain}"
  url_endpoint  = "https://${local.host}"
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
    command = "${path.module}/scripts/deploy-instance.sh ${var.cluster_type} ${var.app_namespace} ${var.ingress_subdomain} ${var.name} ${var.tls_secret_name}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=jaeger || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "jaeger-config" {
  depends_on = [null_resource.jaeger-instance, null_resource.delete-consolelink]

  name         = "jaeger"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "tool-config"
  namespace    = var.app_namespace
  force_update = true

  set {
    name  = "url"
    value = local.url_endpoint
  }

  set {
    name  = "applicationMenu"
    value = var.cluster_type != "kubernetes"
  }

  set {
    name  = "ingressSubdomain"
    value = var.ingress_subdomain
  }

  set {
    name  = "displayName"
    value = "Jaeger"
  }
}
