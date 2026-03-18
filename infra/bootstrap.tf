provider "helm" {
  kubernetes = {
    host                   = yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["clusters"][0]["cluster"]["server"]
    client_certificate     = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["users"][0]["user"]["client-key-data"])
    cluster_ca_certificate = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["clusters"][0]["cluster"]["certificate-authority-data"])
  }
}

provider "kubernetes" {
  host                   = yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["clusters"][0]["cluster"]["server"]
  client_certificate     = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["users"][0]["user"]["client-key-data"])
  cluster_ca_certificate = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)["clusters"][0]["cluster"]["certificate-authority-data"])
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.5.3"
  namespace  = "argocd"

  values = [
    yamlencode({
      global = {
        domain = "argocd.local"
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
      server = {
        service = {
          type         = "NodePort"
          nodePortHttp = 30080
        }
      }
    })
  ]
}

resource "null_resource" "app_of_apps" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<-EOT
      echo '${talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw}' > /tmp/kubeconfig-temp
      sleep 30
      kubectl --kubeconfig=/tmp/kubeconfig-temp apply -f ${path.module}/bootstrap-app.yaml
      rm /tmp/kubeconfig-temp
    EOT
  }

  triggers = {
    applicationset_hash = filemd5("${path.module}/../manifests/applicationsets.yaml")
  }
}

