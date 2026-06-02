/*
 Minimal network module skeleton for GCP.
*/
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.network_name}-private"
  ip_cidr_range = var.private_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}
