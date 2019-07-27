# Generate Prow HMAC secret for Github webhooks.

# Add webhooks for each Github repository in the "repositories" variable so that
# Prow is notified of events.
resource "github_repository_webhook" "prow" {
  count      = "${length(var.repositories)}"
  repository = "${element(var.repositories, count.index)}"

  configuration {
    url          = "https://${var.zone}/hook"
    content_type = "json"
    insecure_ssl = false
    secret       = "${var.prow_hmac}"
  }

  active = true

  events = ["*"]
}

variable "repositories" {
  default = []
  type    = "list"
}

variable "zone" {}
variable "prow_hmac" {}
