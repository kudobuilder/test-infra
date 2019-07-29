resource "google_project_service" "dns" {
  service = "dns.googleapis.com"

  disable_dependent_services = true
}

resource "google_dns_managed_zone" "zone" {
  name     = var.name
  dns_name = "${var.zone}."
}

resource "google_dns_record_set" "zone" {
  count = length(var.address) > 0 ? 1 : 0

  name = "${var.zone}."
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.zone.name

  rrdatas = var.address
}

variable "zone" {}
variable "name" {}
variable "address" {
  type = list
}

output "nameservers" {
  value = google_dns_managed_zone.zone.name_servers
}
