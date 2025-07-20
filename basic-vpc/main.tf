# Create a custom VPC network
resource "google_compute_network" "default_vpc" {
  name                    = "default"
  auto_create_subnetworks = true     # Corresponds to "Subnet Creation Mode: Automatic"
  routing_mode            = "GLOBAL" # Corresponds to "Dynamic Routing Mode: Global"

  description = "Default VPC network created by Terraform with automatic subnet creation and global routing."
}

# Firewall rule: allow-custom (allowing all TCP and UDP from any Google Cloud region)
resource "google_compute_firewall" "allow_custom" {
  name        = "default-allow-custom"
  network     = google_compute_network.default_vpc.id
  description = "Allows all custom TCP and UDP connections on the 'default' VPC."

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.128.0.0/9"]
}

# Firewall rule: allow-icmp
resource "google_compute_firewall" "allow_icmp" {
  name        = "default-allow-icmp"
  network     = google_compute_network.default_vpc.id
  description = "Allows ICMP traffic on the 'default' VPC."

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

# Firewall rule: allow-rdp
resource "google_compute_firewall" "allow_rdp" {
  name        = "default-allow-rdp"
  network     = google_compute_network.default_vpc.id
  description = "Allows RDP (port 3389 TCP) traffic on the 'default' VPC."

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Firewall rule: allow-ssh
resource "google_compute_firewall" "allow_ssh" {
  name        = "default-allow-ssh"
  network     = google_compute_network.default_vpc.id
  description = "Allows SSH (port 22 TCP) traffic on the 'default' VPC."

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a Cloud Router for NAT
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.default_vpc.id
  project = var.project_id
  description = "Cloud Router for NAT services."
}

# Configure NAT on the Cloud Router for global NAT
resource "google_compute_router_nat" "cloud_nat_uscentral1" {
  name                          = "cloud-nat-uscentral1" # Changed the name here
  router                        = google_compute_router.nat_router.name
  region                        = google_compute_router.nat_router.region
  nat_ip_allocate_option        = "AUTO_ONLY" # Automatically allocate NAT IP addresses
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Enable NAT for all primary and secondary ranges of all subnetworks

  project = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY" # Log errors for NAT connections
  }
}

# Create a VM instance for testing
resource "google_compute_instance" "test_vm" {
  name         = "test-vm"
  machine_type = "e2-micro" 
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # Using a stable Debian image
    }
  }

  network_interface {
    network = google_compute_network.default_vpc.id
    # Removed access_config block so the VM does not get an external IP.
  }

  allow_stopping_for_update = true # Allows the instance to be stopped for updates
  
  description = "Test VM created by Terraform."
}