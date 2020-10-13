terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.remote_dev_boot_strapper_storage_bucket
  }
}