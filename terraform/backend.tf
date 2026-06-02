// Backend configured to use GCS. Replace `my-bucket` and `path` with your values.
terraform {
  backend "gcs" {
    bucket = var.remote_state_bucket
    prefix = var.remote_state_prefix
  }
}
