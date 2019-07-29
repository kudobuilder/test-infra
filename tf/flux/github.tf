# Generate a SSH key for Flux to use with Github.
resource "tls_private_key" "github" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# Add the Flux deploy key to the Prow Github repository.
resource "github_repository_deploy_key" "flux_deploy_key" {
  title      = "flux deploy key"
  repository = "${var.config_repo}"
  key        = "${tls_private_key.github.public_key_openssh}"
  read_only  = "false"
}
