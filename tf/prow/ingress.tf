resource "kubernetes_ingress" "ing" {
  depends_on = ["kubernetes_namespace.prow"]

  metadata {
    name      = "ing"
    namespace = "prow"

    annotations = {
      "certmanager.k8s.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    tls {
      hosts       = ["prow.kudo.dev"]
      secret_name = "prow-cert"
    }

    rule {
      host = "prow.kudo.dev"

      http {
        path {
          path = "/"

          backend {
            service_name = "deck"
            service_port = "80"
          }
        }

        path {
          path = "/hook"

          backend {
            service_name = "hook"
            service_port = "8888"
          }
        }
      }
    }
  }
}

variable "hostname" {}

output "address" {
  value = [
    for lb in kubernetes_ingress.ing.load_balancer_ingress:
      lb.ip
  ]
}
