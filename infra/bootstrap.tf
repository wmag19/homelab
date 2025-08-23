provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
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
  version    = "8.3.0"
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
          type = "NodePort"
          nodePortHttp = 30080
        }
      }
    })
  ]
}

resource "null_resource" "apply_applicationset" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = "sleep 30 && kubectl apply -f ${path.module}/../manifests/applicationset.yaml"
  }

  triggers = {
    applicationset_hash = filemd5("${path.module}/../manifests/applicationset.yaml")
  }
}

