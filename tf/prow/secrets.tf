# Provision the Prow namespace and necessary secrets.

resource "kubernetes_namespace" "prow" {
  metadata {
    name = "prow"
  }
}

resource "kubernetes_config_map" "prow-env-config" {
  depends_on = ["kubernetes_namespace.prow"]

  metadata {
    name      = "prow-env-config"
    namespace = "prow"
  }

  data = {
    GITHUB_URL = "https://api.github.com"
  }
}

resource "random_string" "prow-hmac" {
  length  = 30
  special = false
}

resource "kubernetes_secret" "prow-hmac" {
  depends_on = ["kubernetes_namespace.prow"]

  metadata {
    name      = "hmac-token"
    namespace = "prow"
  }

  data = {
    hmac = "${random_string.prow-hmac.result}"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "oauth-token" {
  depends_on = ["kubernetes_namespace.prow"]

  metadata {
    name      = "oauth-token"
    namespace = "prow"
  }

  data = {
    oauth = "${var.github_token}"
  }

  type = "Opaque"
}

variable "github_token" {}

output "prow-hmac" {
  value = "${random_string.prow-hmac.result}"
}
