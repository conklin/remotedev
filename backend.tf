terraform {
  backend "gcs" {
   config = {
    prefix  = "terraform/state"
    bucket  = "remote-dev-boot-strapper-2ca89e63a0d6"
    }
  }
}