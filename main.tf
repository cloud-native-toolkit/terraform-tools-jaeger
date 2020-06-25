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
  gitops_dir             = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_dir              = "${local.gitops_dir}/jaeger"
  global_config          = {
    clusterType = var.cluster_type
    ingressSubdomain = var.ingress_subdomain
    tlsSecretName = var.tls_secret_name
  }
  jaeger_operator_config = {
    olmNamespace = var.olm_namespace
    operatorNamespace = var.operator_namespace
  }
  tool_config   = {
    url = local.url_endpoint
    applicationMenu = true
    displayName = "Jaeger"
    otherConfig = {
      agent_host = "jaeger-agent.${var.app_namespace}"
      agent_port = "6832"
    }
  }
}

resource "null_resource" "setup-chart" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.gitops_dir}/artifactory && cp -R ${path.module}/chart/artifactory/* ${local.chart_dir}"
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

resource "local_file" "jaeger-values" {
  depends_on = [null_resource.setup-chart, null_resource.delete-consolelink]

  content  = yamlencode({
    global = local.global_config
    jaeger-operator = local.jaeger_operator_config
    tool-config = local.tool_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.jaeger-values.filename}"
  }
}

resource "helm_release" "jaeger" {
  depends_on = [local_file.jaeger-values]
  count = var.mode != "setup" ? 1 : 0

  name              = "jaeger"
  chart             = local.chart_dir
  namespace         = var.app_namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
