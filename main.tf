provider "helm" {
  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir       = "${path.cwd}/.tmp"
  host          = "${var.name}-${var.app_namespace}.${var.ingress_subdomain}"
  url_endpoint  = "https://${host}"
  password_file = "${path.cwd}/nexus-password.val"
  password      = data.local_file.nexus-password.content
}

resource "null_resource" "nexus-subscription" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-subscription.sh ${var.cluster_type} ${var.operator_namespace} ${var.olm_namespace}"

    environment = {
      TMP_DIR    = local.tmp_dir
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "nexus-instance" {
  depends_on = [null_resource.nexus-subscription]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-instance.sh ${var.cluster_type} ${var.app_namespace} ${var.ingress_subdomain} ${var.name} ${local.password_file}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

data "local_file" "nexus-password" {
  depends_on = [null_resource.nexus-instance]

  filename = local.password_file
}

data "helm_repository" "toolkit-charts" {
  name = "toolkit-charts"
  url  = "https://ibm-garage-cloud.github.io/toolkit-charts/"
}

resource "helm_release" "nexus-config" {
  depends_on = [null_resource.nexus-instance]

  name         = "nexus"
  repository   = data.helm_repository.toolkit-charts.name
  chart        = "tool-config"
  namespace    = var.app_namespace
  force_update = true

  set {
    name  = "url"
    value = local.host
  }

  set {
    name  = "username"
    value = "admin"
  }

  set {
    name  = "password"
    value = local.password
  }
}
