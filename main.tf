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
  image = "ubuntu-1804-bionic-v20201014"
  size  = 10
  type  = "pd-ssd"
  zone  = var.compute_zone
}

# resource "google_compute_image" "dev_image" {
#   name = "base-os"  
#   family  = "debian-9"
#   project = "debian-cloud"
# }


resource "google_compute_instance_from_template" "dev_server_instance" {
  name = "dev-server"
  source_instance_template = google_compute_instance_template.dev_env_server_template.id
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

resource "google_compute_router" "router" {
  name    = "my-router"
  network = google_compute_network.dev-env-network.name
  region  = google_compute_subnetwork.dev-env-sub-network.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_project_service" "enable_identity_aware_proxy" {
  service = "iap.googleapis.com"
}


resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.dev-env-network.name
  
  # https://cloud.google.com/iap/docs/using-tcp-forwarding#before_you_begin  
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "22"]
  }
}

resource "google_iap_brand" "project_brand" {
  support_email     = var.iap_members[0]
  application_title = "Cloud IAP protected Application"
}

resource "google_iap_tunnel_instance_iam_binding" "enable_iap" {  
  instance = google_compute_instance_from_template.dev_server_instance.name
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.iap_members
}
