# Development

To run the tests, run:

```
go run github.com/kudobuilder/kudo/cmd/kubectl-kudo test
```

Tests are written using the [KUDO test harness](https://kudo.dev/docs/testing) and can be found in `test/integration/`.

# Configuration

All Kubernetes manifests live under `cluster/` and `prow-jobs/` and are deployed using [flux](https://github.com/fluxcd/flux) automatically on merge.

See `prow-jobs/prow.yaml` to configure your Prow job.

# Cluster management

The Prow cluster lives on a GKE cluster in the `maestro-229419` project.

## Setup the google cloud CLI

Install the [gcloud CLI](https://cloud.google.com/sdk/gcloud/):

```
gcloud auth login
gcloud auth application-default login
```

## Login

To login to the cluster, run:

```
gcloud container clusters get-credentials prow-prod --region us-east4
```

And then you can run the e2e tests:

```
go run github.com/kudobuilder/kudo/cmd/kubectl-kudo test --config kudo-test-e2e.yaml
```

To login to the `kudo-ci` account, TODO: add login to onelogin.

## Deployment

To deploy run:

```
cd tf/
terraform apply
```

## Secret management

To encrypt a new secret, run this command:

```
echo -n $SECRET |gcloud kms encrypt --project maestro-229419 --location us-central1 --keyring prow --key key --plaintext-file - --ciphertext-file - |base64 -w0 && echo
```

And then create a new `google_kms_secret` resource in Terraform:

```
data "google_kms_secret" "mysecret" {
  crypto_key = "${module.kms.key}"
  ciphertext = "ENCRYPTEDBLOB"
}
```

And then that can be referenced as `${data.google_kms_secret.mysecret.plaintext}`.
