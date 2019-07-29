data "google_client_config" "default" {}

resource "google_container_cluster" "cluster" {
  name     = "${var.cluster_name}"
  location = "${var.location}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "pool1" {
  name       = "${var.cluster_name}-pool1"
  location   = "${var.location}"
  cluster    = "${google_container_cluster.cluster.name}"
  node_count = "${var.num_nodes}"

  node_config {
    machine_type = "${var.node_type}"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

variable "cluster_name" {}

variable "location" {
  default = "us-central1"
}

variable "num_nodes" {
  default = 4
  type    = number
}

variable "node_type" {
  default = "n1-standard-1"
}

output "cluster-address" {
  value = "${google_container_cluster.cluster.endpoint}"
}

output "token" {
  value = "${data.google_client_config.default.access_token}"
}

output "cluster-ca" {
  value = "${base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)}"
}
