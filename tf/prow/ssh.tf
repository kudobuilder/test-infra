resource "kubernetes_namespace" "prow-tests" {
  metadata {
    name = "prow-tests"
  }
}

resource "github_user_ssh_key" "prow_key" {
  title = "prow"
  key   = "${chomp(tls_private_key.prow_github.public_key_openssh)}"
}

resource "tls_private_key" "prow_github" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "kubernetes_secret" "prow_ssh" {
  metadata {
    name      = "ssh-secret"
    namespace = "prow-tests"
  }

  type = "Opaque"

  data = {
    id_ecdsa = "${tls_private_key.prow_github.private_key_pem}"
  }
}
