data "terraform_remote_state" "state" {
  backend = "gcs"
  config = {
    prefix  = "terraform/state"
    bucket  = var.remote_dev_boot_strapper_storage_bucket
  }
}

