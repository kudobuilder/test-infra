terraform {
  backend "gcs" {
    bucket = "kudo-tf-state"
    prefix = "terraform/prow"
  }
}

provider "github" {
  token        = "${data.google_kms_secret.github.plaintext}"
  organization = "kudobuilder"
}

provider "google" {
  project = "maestro-229419"
}

provider "kubernetes" {
  host                   = "${module.kubernetes.cluster-address}"
  token                  = "${module.kubernetes.token}"
  cluster_ca_certificate = "${module.kubernetes.cluster-ca}"
}

module "kms" {
  source = "./kms"

  location = "us-central1"
  key_ring = "prow"
}

module "kubernetes" {
  source = "./gke"

  cluster_name = "prow-prod"
  location = "us-east4"
  node_type = "n1-standard-4"
  num_nodes = 4
}

module "flux" {
  source = "./flux"

  config_repo_user = "kudobuilder"
  config_repo = "test-infra"

  slack_token = "${data.google_kms_secret.slack_token.plaintext}"
  slack_channel = "#slack-testing"
}

module "prow" {
  source = "./prow"

  gcs_bucket_name = "kudo-prow-logs"
  github_token    = "${data.google_kms_secret.github.plaintext}"
}

module "kudobuilder-repo" {
  source = "./repo"

  zone      = "prow.kudo.dev"
  prow_hmac = "${module.prow.prow-hmac}"

  repositories = [
    "test-infra",
    "kudo"
  ]
}

data "google_kms_secret" "github" {
  crypto_key = "${module.kms.key}"
  ciphertext = "CiQApyKnkLJQFYv/1RsLMQ3Xr1SdyCEXjiBc9YuHzx6ZzmeYf+8SUQAAIP2M893IqW0UGNa3xYQ+tePOqj41E1a/bDVrBgEr8FmO1UNUbNy6NSU9mziduoZaOH1U9rKlLCfLnNw6QXFtUBwrQvRpx+pdug/PIvsB8A=="
}

data "google_kms_secret" "slack_token" {
  crypto_key = "${module.kms.key}"
  ciphertext = "CiQApyKnkI5fBgUubntPTDm37SjpODZ/GctqWEawsPqZs9ZkGpISdgAAIP2MSlXT5BEHuiSpgC8p34SNlnR5jzwEf3ShOUn5heV9Q9Rib8GQdpxtFd4aF4f3XnYifROHnkW7PVL7NAeb8AeVcZaWwzrvPskWR7xHLq/AbsDNRvUfcWKwkwMK9NUyT6WIgGWplOA68QOEfuCk8MFFotk="
}
