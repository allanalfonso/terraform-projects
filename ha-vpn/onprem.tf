module "on-prem" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.1"

  project_id   = var.project_id
  network_name = "on-prem"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "on-prem-subnet1"
      subnet_ip     = "192.168.1.0/24"
      subnet_region = "us-central1"
    }
  ]
}

module "firewall_rules-on-prem" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.on-prem.network_name

  ingress_rules = [{
    name                    = "on-prem-allow-custom"
    description             = null
    disabled                = null
    priority                = 1000
    source_ranges           = ["192.168.0.0/16"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
      },
      {
        protocol = "udp"
        ports    = ["0-65535"]
      },
      {
        protocol = "icmp"
        ports    = []
    }]
    deny = []
    },
    {
      name                    = "on-prem-allow-ssh-icmp"
      description             = null
      disabled                = null
      priority                = 1000
      source_ranges           = ["0.0.0.0/0"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
        },
        {
          protocol = "icmp"
          ports    = []
      }]
      deny = []
  }]
}




resource "google_compute_instance" "on-prem-instance1" {
  name         = "on-prem-instance1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = module.on-prem.network_name
    subnetwork = module.on-prem.subnets_names[0]
  }
}

