terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

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
  version    = "5.51.6"
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

resource "kubernetes_manifest" "applicationset" {
  depends_on = [helm_release.argocd]
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "homelab-apps"
      namespace = "argocd"
    }
    spec = {
      generators = [{
        git = {
          repoURL = "https://github.com/wmag19/homelab.git"
          revision = "HEAD"
          directories = [{
            path = "manifests/*"
          }]
        }
      }]
      template = {
        metadata = {
          name = "{{path.basename}}"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = "https://github.com/your-username/homelab.git"
            targetRevision = "HEAD"
            path           = "{{path}}"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path.basename}}"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    }
  }
}