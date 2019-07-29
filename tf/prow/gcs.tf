variable "gcs_bucket_name" {}

resource "google_storage_bucket" "prow" {
  name = "${var.gcs_bucket_name}"
}

resource "google_service_account" "prow" {
  account_id = "prowservice"
}

resource "google_service_account_key" "prow" {
  service_account_id = "${google_service_account.prow.name}"
}

resource "kubernetes_secret" "prow-gcs" {
  depends_on = ["kubernetes_namespace.prow-tests"]

  metadata {
    name      = "gcs-service-account"
    namespace = "prow-tests"
  }

  data = {
    "service-account.json" = "${base64decode(google_service_account_key.prow.private_key)}"
  }

  type = "Opaque"
}

resource "google_storage_bucket_iam_binding" "public-prow" {
  bucket  = "${google_storage_bucket.prow.name}"
  role    = "roles/storage.objectViewer"
  members = ["allUsers"]
}

resource "google_storage_bucket_iam_binding" "upload" {
  bucket  = "${google_storage_bucket.prow.name}"
  role    = "roles/storage.objectAdmin"
  members = ["serviceAccount:${google_service_account.prow.email}"]
}

resource "google_project_service" "storage-api" {
  service = "storage-api.googleapis.com"

  disable_dependent_services = true
}
