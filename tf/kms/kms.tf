resource "google_project_service" "cloudkms" {
  service = "cloudkms.googleapis.com"

  disable_dependent_services = true
}

resource "google_kms_key_ring" "key-ring" {
  name     = "${var.key_ring}"
  location = "${var.location}"
}

resource "google_kms_crypto_key" "key" {
  name     = "key"
  key_ring = "${google_kms_key_ring.key-ring.id}"
}

variable "key_ring" {}
variable "location" {}

output "key" {
  value = "${google_kms_crypto_key.key.id}"
}
