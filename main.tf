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
  name  = "dev-server-disk"
  image = google_compute_image.dev_image.id
  size  = 10
  type  = "pd-ssd"
  zone  = var.compute_zone
}

resource "google_compute_image" "dev_image" {
  name = "base-os"  
  family  = "debian-9"
  project = "debian-cloud"
}


resource "google_compute_network" "dev-env-network" {
  name = "dev-compute-name"
}

resource "google_compute_subnetwork" "dev-env-sub-network" {
  name = "dev-subnet"
  region = var.compute_region
  private_ip_google_access = true
  ip_cidr_range = "10.0.0.0/22"
  network = google_compute_network.dev-env-network.id
}
