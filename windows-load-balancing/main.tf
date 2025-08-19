# Define the Google Compute Network (VPC)
resource "google_compute_network" "windows_vpc" {
  # Name for your VPC network
  name = "windows-vpc"

  # Set to true for automatic subnet creation mode
  auto_create_subnetworks = false

  # Set to GLOBAL for global routing mode
  routing_mode = "GLOBAL"

  # Optional: Description for the VPC network
  description = "VPC network for Windows instances with automatic subnets and global routing mode."

  # Optional: Tags for the network (e.g., for organization or billing)
  # tags = ["project-vpc", "environment-dev"]
}

# Define a firewall rule for health checks
resource "google_compute_firewall" "fw_allow_health_checks" {
  # Name for the firewall rule
  name = "fw-allow-health-checks"

  # The network this firewall rule applies to.
  # It references the 'my_vpc_network' defined above.
  network = google_compute_network.windows_vpc.name

  # Description for the firewall rule
  description = "Allows Google Cloud health check probes."

  # Direction of the traffic: INGRESS means incoming connections
  direction = "INGRESS"

  # List of source IP ranges for the health check probes.
  # These are standard Google Cloud health check IP ranges.
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  # Target service accounts or network tags to apply this rule to.
  # Instances with this tag will allow health check traffic.
  target_tags = ["allow-health-checks"]

  # Define the allowed protocols and ports
  allow {
    protocol = "tcp"
    # Only allow TCP traffic on port 80 for health checks
    ports = ["80"]
  }

  # Optional: Allow ICMP for basic connectivity checks (ping)
  allow {
    protocol = "icmp"
  }
}

# Define a firewall rule for internal VPC traffic
resource "google_compute_firewall" "fw_allow_internal" {
  name        = "fw-allow-internal"
  network     = google_compute_network.windows_vpc.name
  description = "Allows all TCP, UDP, and ICMP traffic within the VPC's private IP ranges."
  direction   = "INGRESS"
  # Source ranges for common private IP address spaces.
  # This allows communication between instances within the VPC.
  source_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
  allow {
    protocol = "tcp"
    ports    = ["0-65535"] # All TCP ports
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"] # All UDP ports
  }
  allow {
    protocol = "icmp"
  }
}

# Define a firewall rule for RDP access
resource "google_compute_firewall" "fw_allow_rdp" {
  name        = "fw-allow-rdp"
  network     = google_compute_network.windows_vpc.name
  description = "Allows RDP access (TCP port 3389)."
  direction   = "INGRESS"
  # IMPORTANT: In production, restrict source_ranges to trusted IPs only (e.g., your office IP).
  source_ranges = ["0.0.0.0/0"] # WARNING: This allows RDP from anywhere. Restrict for production!
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
}

# Define a firewall rule for SSH access
resource "google_compute_firewall" "fw_allow_ssh" {
  name        = "fw-allow-ssh"
  network     = google_compute_network.windows_vpc.name
  description = "Allows SSH access (TCP port 22)."
  direction   = "INGRESS"
  # IMPORTANT: In production, restrict source_ranges to trusted IPs only (e.g., your office IP).
  source_ranges = ["0.0.0.0/0"] # WARNING: This allows SSH from anywhere. Restrict for production!
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Define a Cloud Router for NAT in us-central1
resource "google_compute_router" "cloud_router_nat_us_central1" {
  # Name for the Cloud Router
  name = "nat-router-us1"

  # The region where the router will be deployed
  region = var.region

  # The network this router is associated with
  network = google_compute_network.windows_vpc.name

  # Optional: Description for the Cloud Router
  description = "Cloud Router for NAT in us-central1"
}

# Define the NAT configuration for the Cloud Router in us-central1
resource "google_compute_router_nat" "router_nat_gateway_us_central1" {
  # Name for the NAT gateway
  name = "nat-config-gateway-us1"

  # The router to which this NAT configuration belongs
  router = google_compute_router.cloud_router_nat_us_central1.name

  # The region where the router is located
  region = google_compute_router.cloud_router_nat_us_central1.region

  # How IP addresses are allocated for NAT.
  # 'AUTO_ONLY' means Google Cloud automatically allocates NAT IPs.
  nat_ip_allocate_option = "AUTO_ONLY"

  # Which subnetwork IP ranges to NAT.
  # 'ALL_SUBNETWORKS_ALL_IP_RANGES' means all primary and secondary IP ranges of all subnets will use NAT.
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Logging for NAT (optional, recommended for troubleshooting)
  log_config {
    enable = false # Set to true to enable logging
    filter = "ERRORS_ONLY"
  }
}

# Define a firewall rule for HTTP access
resource "google_compute_firewall" "fw_allow_http" {
  name        = "fw-allow-http"
  network     = google_compute_network.windows_vpc.name
  description = "Allows HTTP traffic (TCP port 80)."
  direction   = "INGRESS"
  # Allows from any source. For production, you might want to restrict this
  # to specific IP ranges, like those of a load balancer.
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# Define a subnet for the application instances and internal load balancer
resource "google_compute_subnetwork" "app_subnet" {
  name          = "app-subnet"
  ip_cidr_range = "10.130.0.0/24" # Ensure this CIDR range is available in your VPC
  network       = google_compute_network.windows_vpc.id
  region        = var.region
  description   = "Subnet for Windows instances and the internal LB forwarding rule."
}

# Define an Instance Template for Windows Server
resource "google_compute_instance_template" "windows_server_template" {
  name         = "windows-server-template"
  machine_type = "e2-medium"
  description  = "Instance template for Windows Server 2019 DC."

  # Boot disk configuration
  disk {
    source_image = "windows-cloud/windows-server-2019-dc-v20250813"
    auto_delete  = true
    boot         = true
    disk_size_gb = 50
    disk_type    = "pd-standard"
  }

  # Network interface
  network_interface {
    subnetwork = google_compute_subnetwork.app_subnet.id
    # No access_config, instances will not have public IPs and will use the NAT Gateway
  }

  # Tags for firewall rules.
  # "allow-http" for web traffic.
  # "allow-health-checks" for load balancer health checks.
  # "allow-rdp" for management access.
  tags = ["allow-http", "allow-health-checks", "allow-rdp"]

  # Metadata to specify a startup script from a GCS bucket
  metadata = {
    windows-startup-script-url = "gs://windows-startup-scripts-and-config-files-praxis-practice-341316/boot-start-up-script.ps1"
  }

  # Service account for the instance. Defines API access.
  # The devstorage.read_only scope is required to fetch the startup script from GCS.
  service_account {
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
  }
}

# Define a Health Check for the Managed Instance Group
resource "google_compute_health_check" "windows_http_health_check" {
  name        = "windows-http-health-check"
  description = "HTTP health check for Windows web servers"

  # TCP health check on port 80
  tcp_health_check {
    port = 80
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Define a Managed Instance Group (MIG) for Windows Servers
resource "google_compute_instance_group_manager" "windows_mig" {
  name               = "windows-mig"
  zone               = var.zone
  base_instance_name = "windows-server"
  target_size        = 2

  # Use the instance template defined above
  version {
    instance_template = google_compute_instance_template.windows_server_template.id
    name              = "v1"
  }

  # Define a named port for the load balancer to use
  named_port {
    name = "http"
    port = 80
  }

  # Configure autohealing with the health check
  auto_healing_policies {
    health_check      = google_compute_health_check.windows_http_health_check.id
    initial_delay_sec = 300 # Wait 5 minutes before starting health checks on new instances
  }

  # Ensure the new MIG is created before the old one is destroyed during updates
  lifecycle {
    create_before_destroy = true
  }
}

# Define an Autoscaler for the Windows Managed Instance Group
resource "google_compute_autoscaler" "windows_mig_autoscaler" {
  name   = "windows-mig-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.windows_mig.id

  autoscaling_policy {
    min_replicas    = 1
    max_replicas    = 2
    cooldown_period = 60

    load_balancing_utilization {
      target = 0.8 # Target 80% load balancing utilization
    }
  }
}

# --- Regional Internal Application Load Balancer ---

# A proxy-only subnet is required for regional internal Application Load Balancers.
# It is used by the Envoy proxies that Google manages.
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "proxy-only-subnet"
  ip_cidr_range = "10.129.0.0/24" # This range must be available in the VPC.
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.windows_vpc.id
  region        = var.region
  description   = "Proxy-only subnet for the regional internal Application Load Balancer."
}

# Define the Backend Service for the Internal Load Balancer
resource "google_compute_region_backend_service" "windows_internal_backend" {
  name                  = "windows-internal-backend"
  region                = var.region
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group           = google_compute_instance_group_manager.windows_mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.windows_http_health_check.id]
}

# Define the URL Map to route traffic to the backend service
resource "google_compute_region_url_map" "internal_lb_url_map" {
  name            = "internal-lb-url-map"
  region          = var.region
  description     = "URL map for the internal application load balancer"
  default_service = google_compute_region_backend_service.windows_internal_backend.id
}

# Define the Target HTTP Proxy
resource "google_compute_region_target_http_proxy" "internal_lb_http_proxy" {
  name        = "internal-lb-http-proxy"
  region      = var.region
  description = "Target HTTP proxy for the internal load balancer"
  url_map     = google_compute_region_url_map.internal_lb_url_map.id
}

# Define the Forwarding Rule
resource "google_compute_forwarding_rule" "internal_lb_forwarding_rule" {
  name                  = "internal-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_protocol           = "TCP"
  network               = google_compute_network.windows_vpc.id
  subnetwork            = google_compute_subnetwork.app_subnet.id
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.internal_lb_http_proxy.id
  allow_global_access   = true # Allow clients from any region in the VPC to access the LB
}
