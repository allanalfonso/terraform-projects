module "vpc-demo" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.1"

  project_id   = var.project_id
  network_name = "vpc-demo"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "vpc-demo-subnet1"
      subnet_ip     = "10.1.1.0/24"
      subnet_region = "us-central1"
    },
    {
      subnet_name   = "vpc-demo-subnet2"
      subnet_ip     = "10.2.1.0/24"
      subnet_region = "us-east1"
    }
  ]
}

module "firewall_rules-vpc-demo" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.vpc-demo.network_name


  ingress_rules = [{
    name                    = "vpc-demo-allow-custom"
    description             = null
    disabled                = null
    priority                = 1000
    source_ranges           = ["10.0.0.0/8"]
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
      name                    = "vpc-demo-allow-ssh-icmp"
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




resource "google_compute_instance" "vpc-demo-instance1" {
  name         = "vpc-demo-instance1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = module.vpc-demo.network_name
    subnetwork = module.vpc-demo.subnets_names[0]
  }
}

resource "google_compute_instance" "vpc-demo-instance2" {
  name         = "vpc-demo-instance2"
  machine_type = "e2-micro"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = module.vpc-demo.network_name
    subnetwork = module.vpc-demo.subnets_names[1]
  }
}


