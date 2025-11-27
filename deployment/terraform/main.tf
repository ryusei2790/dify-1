terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Static External IP
resource "google_compute_address" "dify_static_ip" {
  name         = "${var.instance_name}-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

# Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "${var.instance_name}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dify-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "${var.instance_name}-allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dify-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.instance_name}-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dify-server"]
}

# Compute Engine Instance
resource "google_compute_instance" "dify_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["dify-server"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.dify_static_ip.address
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : ""
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    domain_name = var.domain_name
    email       = var.email
  })

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.environment
    application = "dify"
  }
}

# Additional persistent disk for data
resource "google_compute_disk" "dify_data_disk" {
  name = "${var.instance_name}-data"
  type = "pd-standard"
  zone = var.zone
  size = var.data_disk_size
}

resource "google_compute_attached_disk" "dify_data_disk_attachment" {
  disk     = google_compute_disk.dify_data_disk.id
  instance = google_compute_instance.dify_instance.id
}
