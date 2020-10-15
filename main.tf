provider "google" {
  project     = var.project_id
  region      = var.compute_region
}

resource "google_compute_instance_template" "dev_env_server_template" {
  name        = "dev-server-template"

  labels = {
    environment = "dev"
  }

  machine_type         = "n1-standard-1"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source      = google_compute_disk.dev_disk.name
    auto_delete = false
    boot        = false
  }

  network_interface {
    network = "default"
  }

#   service_account {
#     scopes = ["userinfo-email", "compute-ro", "storage-ro"]
#   }
}

resource "google_compute_disk" "dev_disk" {
  name  = "existing-disk"
  image = data.google_compute_image.dev_image.self_link
  size  = 10
  type  = "pd-ssd"
  zone  = "us-central1-a"
}

data "google_compute_image" "dev_image" {
  family  = "debian-9"
  project = "debian-cloud"
}
