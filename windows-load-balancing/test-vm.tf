# Define a VM for testing
resource "google_compute_instance" "testing_vm" {
  name         = "testing-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_subnet.id
    # Assign an ephemeral public IP for testing purposes
    access_config {}
  }

  # No backup policy is configured, which meets the "no backups" requirement.
  # Tags can be added if specific firewall rules need to apply, e.g., tags = ["allow-ssh"]
}