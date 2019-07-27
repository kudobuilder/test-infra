resource "google_service_account" "dns" {
  account_id = "dnsservice"
}

resource "google_service_account_key" "dns" {
  service_account_id = "${google_service_account.dns.name}"
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"

    labels = {
      "certmanager.k8s.io/disable-validation" = "true"
    }
  }
}

resource "kubernetes_secret" "dns" {
  depends_on = ["kubernetes_namespace.cert-manager"]

  metadata {
    name      = "gcp-service-account"
    namespace = "cert-manager"
  }

  data = {
    "service-account.json" = "${base64decode(google_service_account_key.dns.private_key)}"
  }

  type = "Opaque"
}

resource "google_project_iam_binding" "dns-admin" {
  role = "roles/dns.admin"

  members = [
    "serviceAccount:${google_service_account.dns.email}"
  ]
}
