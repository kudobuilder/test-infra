# Provision all of the resources necessary for running Flux.

# Flux continuously deploys all resources from `clusters/` and `prow-jobs`.

resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux"
  }
}

resource "kubernetes_secret" "flux" {
  depends_on = ["kubernetes_namespace.flux"]

  metadata {
    name      = "flux-git-deploy"
    namespace = "flux"
  }

  data = {
    identity = "${tls_private_key.github.private_key_pem}"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "fluxcloud" {
  depends_on = ["kubernetes_namespace.flux"]

  metadata {
    name      = "fluxcloud"
    namespace = "flux"
  }

  data = {
    url = "${var.slack_token}"
  }

  type = "Opaque"
}

resource "kubernetes_service_account" "flux" {
  depends_on = ["kubernetes_namespace.flux"]

  metadata {
    name      = "flux"
    namespace = "flux"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "flux" {
  depends_on = ["kubernetes_namespace.flux"]

  metadata {
    name = "flux"
  }

  rule {
    verbs      = ["*"]
    api_groups = ["*"]
    resources  = ["*"]
  }

  rule {
    verbs             = ["*"]
    non_resource_urls = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "flux" {
  depends_on = ["kubernetes_namespace.flux", "kubernetes_service_account.flux"]

  metadata {
    name = "flux"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "flux"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "flux"
  }
}

resource "kubernetes_deployment" "flux" {
  depends_on = ["kubernetes_namespace.flux", "kubernetes_service_account.flux"]

  metadata {
    name      = "flux"
    namespace = "flux"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        name = "flux"
      }
    }

    template {
      metadata {
        labels = {
          name = "flux"
        }
      }

      spec {
        volume {
          name = "git-key"

          secret {
            secret_name  = "flux-git-deploy"
            default_mode = "0400"
          }
        }

        volume {
          name = "git-keygen"

          empty_dir {
            medium = "Memory"
          }
        }

        volume {
          name = "${kubernetes_service_account.flux.default_secret_name}"
          secret {
            secret_name = "${kubernetes_service_account.flux.default_secret_name}"
          }
        }

        container {
          name  = "flux"
          image = "docker.io/weaveworks/flux:1.12.2"
          args = [
            "--memcached-service=",
            "--ssh-keygen-dir=/var/fluxd/keygen",
            "--git-url=git@github.com:${var.config_repo_user}/${var.config_repo}",
            "--git-branch=master",
            "--git-path=prow-jobs",
            "--git-path=cluster",
            "--listen-metrics=:3031",
            "--connect=ws://127.0.0.1:3032"
          ]

          port {
            container_port = 3030
          }

          port {
            container_port = 3031
          }

          resources {
            requests {
              memory = "64Mi"
              cpu    = "50m"
            }
          }

          volume_mount {
            name       = "git-key"
            read_only  = true
            mount_path = "/etc/fluxd/ssh"
          }

          volume_mount {
            name       = "git-keygen"
            mount_path = "/var/fluxd/keygen"
          }

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "${kubernetes_service_account.flux.default_secret_name}"
            read_only  = true
          }

          image_pull_policy = "IfNotPresent"
        }

        container {
          name  = "fluxcloud"
          image = "justinbarrick/fluxcloud:v0.3.6"

          port {
            container_port = 3032
          }

          env {
            name = "SLACK_URL"

            value_from {
              secret_key_ref {
                name = "fluxcloud"
                key  = "url"
              }
            }
          }

          env {
            name  = "SLACK_CHANNEL"
            value = "${var.slack_channel}"
          }

          env {
            name  = "SLACK_USERNAME"
            value = "Flux Deployer"
          }

          env {
            name  = "SLACK_ICON_EMOJI"
            value = ":kubernetes:"
          }

          env {
            name  = "GITHUB_URL"
            value = "https://github.com/${var.config_repo_user}/${var.config_repo}/"
          }

          env {
            name  = "LISTEN_ADDRESS"
            value = ":3032"
          }

          image_pull_policy = "IfNotPresent"
        }

        service_account_name = "flux"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_deployment" "memcached" {
  depends_on = ["kubernetes_namespace.flux"]

  metadata {
    name      = "memcached"
    namespace = "flux"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        name = "memcached"
      }
    }

    template {
      metadata {
        labels = {
          name = "memcached"
        }
      }

      spec {
        container {
          name  = "memcached"
          image = "memcached:1.4.25"
          args  = ["-m 512", "-I 5m", "-p 11211"]

          port {
            name           = "clients"
            container_port = 11211
          }

          image_pull_policy = "IfNotPresent"
        }
      }
    }
  }
}

resource "kubernetes_service" "memcached" {
  depends_on = ["kubernetes_namespace.flux"]

  metadata {
    name      = "memcached"
    namespace = "flux"
  }

  spec {
    port {
      name = "memcached"
      port = 11211
    }

    selector = {
      name = "memcached"
    }
  }
}

variable "config_repo" {}

variable "config_repo_user" {}

variable "slack_channel" {
  default = ""
}

variable "slack_token" {
  default = ""
}
