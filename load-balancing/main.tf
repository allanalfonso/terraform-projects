# Define the Google Compute Network (VPC)
resource "google_compute_network" "my_vpc_network" {
  # Name for your VPC network
  name = "my-auto-vpc"

  # Set to true for automatic subnet creation mode
  auto_create_subnetworks = true

  # Set to GLOBAL for global routing mode
  routing_mode = "GLOBAL"

  # Optional: Description for the VPC network
  description = "VPC network with automatic subnets and global routing mode."

  # Optional: Tags for the network (e.g., for organization or billing)
  # tags = ["project-vpc", "environment-dev"]
}

# Define a firewall rule for health checks
resource "google_compute_firewall" "fw_allow_health_checks" {
  # Name for the firewall rule
  name = "fw-allow-health-checks"

  # The network this firewall rule applies to.
  # It references the 'my_vpc_network' defined above.
  network = google_compute_network.my_vpc_network.name

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
  network     = google_compute_network.my_vpc_network.name
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
  network     = google_compute_network.my_vpc_network.name
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
  network     = google_compute_network.my_vpc_network.name
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
  region = "us-central1"

  # The network this router is associated with
  network = google_compute_network.my_vpc_network.name

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

# NEW: Define a Cloud Router for NAT in europe-west4
resource "google_compute_router" "cloud_router_nat_europe_west4" {
  name        = "nat-router-eu4"
  region      = "europe-west4" # Region for the new MIG
  network     = google_compute_network.my_vpc_network.name
  description = "Cloud Router for NAT in europe-west4"
}

# NEW: Define the NAT configuration for the Cloud Router in europe-west4
resource "google_compute_router_nat" "router_nat_gateway_europe_west4" {
  name                               = "nat-config-gateway-eu4"
  router                             = google_compute_router.cloud_router_nat_europe_west4.name
  region                             = google_compute_router.cloud_router_nat_europe_west4.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

# Define a Managed Instance Template
resource "google_compute_instance_template" "mywebserver_template" {
  # Name for the instance template
  name = "mywebserver-template"

  # Machine type (e.g., e2-micro, n1-standard-1)
  machine_type = "e2-micro"

  # Series for the machine type (e.g., "e2" for e2-micro)
  # This is inferred by the machine_type but can be explicitly set if needed for specific families
  # or to ensure a particular CPU platform.
  # The 'e2' series is generally implicitly understood from 'e2-micro'.

  # Disk configuration
  disk {
    source_image = "debian-cloud/debian-11" # Using Debian 11 for apt-get
    auto_delete  = true
    boot         = true
  }

  # Network interfaces
  network_interface {
    # Use the name of the automatically created VPC network
    network = google_compute_network.my_vpc_network.name

    # REMOVED the access_config {} block here to ensure no external IP is assigned.
  }

  # Network tags to apply to instances created from this template
  tags = ["allow-health-checks"]

  # Metadata for the instance, including startup script
  metadata = {
    # The startup script to run when the instance starts
    startup-script = <<-EOF
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y apache2
      sudo service apache2 start
      sudo update-rc.d apache2 enable
    EOF
  }

  # Optional: Service account for the instance (recommended for production)
  # service_account {
  #   email  = "your-service-account@your-gcp-project-id.iam.gserviceaccount.com" # REPLACE with your service account email
  #   scopes = ["cloud-platform"]
  # }

  # Optional: Can configure advanced options like min_cpu_platform
  # min_cpu_platform = "Intel Haswell"
}

# Define a Health Check for the Managed Instance Group
resource "google_compute_health_check" "http_health_check" {
  # Name for the health check
  name = "http-health-check"

  # Description for the health check
  description = "HTTP health check for web servers"

  # TCP health check parameters
  tcp_health_check {
    port = 80 # As requested
  }

  # Optional: Configure check interval and timeout (default values shown)
  check_interval_sec  = 5 # How often to perform the check
  timeout_sec         = 5 # How long to wait for a response
  healthy_threshold   = 2 # Number of consecutive successful checks for a healthy status
  unhealthy_threshold = 2 # Number of consecutive failed checks for an unhealthy status
}

# Define a Managed Instance Group (MIG)
resource "google_compute_instance_group_manager" "us_1_mig" {
  # Name for the Managed Instance Group
  name = "us-1-mig"

  # The zone where the MIG will be deployed (for zonal MIGs)
  zone = "us-central1-a"

  # Base instance name for instances in this group
  base_instance_name = "webserver-instance-us"

  # Target size for the MIG (initial number of instances)
  # This will be overridden by autoscaling by the google_compute_autoscaler resource
  target_size = 1 # Set an initial target size, autoscaler will manage this dynamically

  # Define the instance template using a 'version' block
  version {
    instance_template = google_compute_instance_template.mywebserver_template.id
    # A name for this version; can be anything descriptive.
    name = "v1-initial"
  }

  # Define a named port for the instance group, which can be referenced by backend services
  named_port {
    name = "http" # The name of the port (e.g., 'http', 'https')
    port = 80     # The port number corresponding to the named port
  }

  # Autohealing policies for the MIG, which includes health check configuration
  auto_healing_policies {
    # Reference to the health check resource defined above
    health_check = google_compute_health_check.http_health_check.id
    # Initial delay in seconds before applying health checks to new instances
    initial_delay_sec = 60
  }

  # Ensure the MIG is created before the old one is destroyed during updates
  lifecycle {
    create_before_destroy = true
  }
}

# Define a Google Compute Autoscaler for the Managed Instance Group
resource "google_compute_autoscaler" "us_1_autoscaler" {
  # Name for the autoscaler
  name = "us-1-mig-autoscaler"

  # The zone where the autoscaler is located (must match the MIG's zone)
  zone = google_compute_instance_group_manager.us_1_mig.zone

  # Target MIG for this autoscaler
  target = google_compute_instance_group_manager.us_1_mig.id

  # Autoscaling policy
  autoscaling_policy {
    # Minimum number of instances in the group
    min_replicas = 1
    # Maximum number of instances in the group
    max_replicas = 2

    # Cool down period in seconds after an autoscaling event
    cooldown_period = 60

    # Load balancing utilization metric for autoscaling
    load_balancing_utilization {
      # Target utilization percentage (0.0 to 1.0)
      target = 0.8 # 80% utilization
    }



    # Optional: CPU utilization for autoscaling (can be used with load_balancing_utilization)
    # cpu_utilization {
    #   target = 0.6
    # }
  }
  # Explicit dependency on the health check to ensure it is created before the autoscaler
  depends_on = [
    google_compute_health_check.http_health_check # Explicit dependency on the health check
  ]
}

# Define the second Managed Instance Group (MIG)
resource "google_compute_instance_group_manager" "notus_1_mig" {
  name               = "notus-1-mig"
  zone               = "europe-west4-c" # Different zone as requested
  base_instance_name = "webserver-instance-notus1"
  target_size        = 1 # Initial target size, autoscaler will manage this dynamically

  version {
    instance_template = google_compute_instance_template.mywebserver_template.id
    name              = "v1-initial-europe"
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.id
    initial_delay_sec = 60
  }

  # Ensure the MIG is created before the old one is destroyed during updates
  lifecycle {
    create_before_destroy = true
  }
}

# Define a Google Compute Autoscaler for the second Managed Instance Group
resource "google_compute_autoscaler" "notus_1_autoscaler" {
  name   = "notus-1-mig-autoscaler"
  zone   = google_compute_instance_group_manager.notus_1_mig.zone
  target = google_compute_instance_group_manager.notus_1_mig.id

  autoscaling_policy {
    min_replicas    = 1
    max_replicas    = 2
    cooldown_period = 60
    load_balancing_utilization {
      target = 0.8 # 80% utilization
    }
  }
  # Explicit dependency on the health check to ensure it is created before the autoscaler
  depends_on = [
    google_compute_health_check.http_health_check # Explicit dependency on the health check
  ]
}


# --- Global HTTP Load Balancer Resources ---

# Define the Backend Service for the Managed Instance Group
resource "google_compute_backend_service" "http_backend" { # Renamed resource
  name        = "http-backend"                             # New name for the backend service
  protocol    = "HTTP"                                     # The protocol used to communicate with the backends
  timeout_sec = 10                                         # How long to wait for a response from the backend
  port_name   = "http"

  # Reference the health check for the backend service
  health_checks = [google_compute_health_check.http_health_check.id]

  # Explicitly depend on the Health Check and Managed Instance Groups
  # This ensures the health check is fully ready and MIGs' named ports are propagated
  depends_on = [
    google_compute_health_check.http_health_check, # Explicit dependency on the health check
    google_compute_instance_group_manager.us_1_mig,
    google_compute_instance_group_manager.notus_1_mig,
  ]

  # Add the managed instance group as a backend
  backend {
    group = google_compute_instance_group_manager.us_1_mig.instance_group # Link to the MIG's instance group
    # Reference the named port from the MIG
    balancing_mode        = "RATE" # Set balancing mode to Rate
    max_rate_per_instance = 50     # Maximum 50 RPS per instance
    capacity_scaler       = 1.0    # 100% capacity
  }

  # Add the second managed instance group as a backend
  backend {
    group                 = google_compute_instance_group_manager.notus_1_mig.instance_group # Link to the second MIG
    balancing_mode        = "RATE"
    max_rate_per_instance = 50
    capacity_scaler       = 1.0
  }

  # Optional: Connection Draining
  connection_draining_timeout_sec = 300 # 5 minutes

  # Optional: Load Balancing Scheme (EXTERNAL for global load balancers)
  load_balancing_scheme = "EXTERNAL"
}

# Define the URL Map
resource "google_compute_url_map" "webserver_url_map" {
  name        = "http-lb"
  description = "URL map for webserver backend"
  # Default service points to the backend service (updated reference)
  default_service = google_compute_backend_service.http_backend.id
}

# Define the Target HTTP Proxy
resource "google_compute_target_http_proxy" "webserver_http_proxy" {
  name        = "webserver-http-proxy"
  description = "Target HTTP proxy for webserver"
  url_map     = google_compute_url_map.webserver_url_map.id # Link to the URL map
}

# Define the Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "webserver_forwarding_rule" {
  name        = "webserver-forwarding-rule"
  ip_protocol = "TCP"                                                    # Load balancer listens for TCP traffic
  port_range  = "80"                                                     # Load balancer listens on port 80
  target      = google_compute_target_http_proxy.webserver_http_proxy.id # Link to the HTTP proxy
  # By default, without an explicit 'ip_address' block, it will use an ephemeral IP.
  # For a static IP, you would define a google_compute_global_address resource and reference its self_link here.
  ip_version = "IPV4" # Specify IPv4 as requested
}

# Define a single VM for stress testing
resource "google_compute_instance" "stress_test_vm" {
  name         = "stress-test"
  machine_type = "e2-micro"
  zone         = "us-central1-c" # Consistent with the specified zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # A standard Debian image
    }
  }

  network_interface {
    network = google_compute_network.my_vpc_network.name
    # An empty access_config block assigns an ephemeral external IP.
    # Remove this block entirely if no external IP is desired.
    access_config {
    }
  }

  # Metadata for the instance, including startup script
  metadata = {
    # The startup script to run when the instance starts
    startup-script = <<-EOF
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y apache2
      sudo service apache2 start
      sudo update-rc.d apache2 enable
    EOF
  }

  # Optional: Add tags if you want to apply specific firewall rules to this VM
  # tags = ["stress-test-vm", "allow-ssh"]
  # metadata = {
  #   startup-script = "echo 'Hello from stress test VM!' > /var/www/html/index.html"
  # }
}
