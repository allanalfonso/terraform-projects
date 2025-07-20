# Optional: Output the self_link of the created VPC for easy reference
output "vpc_self_link" {
  description = "The self_link of the created VPC network."
  value       = google_compute_network.my_vpc_network.self_link
}

# Optional: Output the name of the created VPC
output "vpc_name" {
  description = "The name of the created VPC network."
  value       = google_compute_network.my_vpc_network.name
}

# Optional: Output the name of the created health check firewall rule
output "health_check_firewall_rule_name" {
  description = "The name of the created health check firewall rule."
  value       = google_compute_firewall.fw_allow_health_checks.name
}

# Output the name of the created Cloud Router
output "cloud_router_name_us_central1" {
  description = "The name of the Cloud Router in us-central1."
  value       = google_compute_router.cloud_router_nat_us_central1.name
}

# Output the name of the created NAT Gateway
output "nat_gateway_name_us_central1" {
  description = "The name of the NAT Gateway in us-central1."
  value       = google_compute_router_nat.router_nat_gateway_us_central1.name
}

# Output the name of the Cloud Router in europe-west4
output "cloud_router_name_europe_west4" {
  description = "The name of the Cloud Router in europe-west4."
  value       = google_compute_router.cloud_router_nat_europe_west4.name
}

# Output the name of the NAT Gateway in europe-west4
output "nat_gateway_name_europe_west4" {
  description = "The name of the NAT Gateway in europe-west4."
  value       = google_compute_router_nat.router_nat_gateway_europe_west4.name
}

# Output the name of the created Instance Template
output "instance_template_name" {
  description = "The name of the created Managed Instance Template."
  value       = google_compute_instance_template.mywebserver_template.name
}

# Output the name of the created Health Check
output "health_check_name" {
  description = "The name of the created Health Check."
  value       = google_compute_health_check.http_health_check.name
}

# Output the name of the first Managed Instance Group
output "us_1_managed_instance_group_name" {
  description = "The name of the first Managed Instance Group."
  value       = google_compute_instance_group_manager.us_1_mig.name
}

# Output the name of the first Autoscaler
output "us_1_autoscaler_name" {
  description = "The name of the first Autoscaler."
  value       = google_compute_autoscaler.us_1_autoscaler.name
}

# Output the name of the second Managed Instance Group
output "notus_1_managed_instance_group_name" {
  description = "The name of the second Managed Instance Group."
  value       = google_compute_instance_group_manager.notus_1_mig.name
}

# Output the name of the second Autoscaler
output "notus_1_autoscaler_name" {
  description = "The name of the second Autoscaler."
  value       = google_compute_autoscaler.notus_1_autoscaler.name
}

# Output the name of the created Internal Firewall rule
output "internal_firewall_rule_name" {
  description = "The name of the created internal firewall rule."
  value       = google_compute_firewall.fw_allow_internal.name
}

# Output the name of the created RDP Firewall rule
output "rdp_firewall_rule_name" {
  description = "The name of the created RDP firewall rule."
  value       = google_compute_firewall.fw_allow_rdp.name
}

# Output the name of the created SSH Firewall rule
output "ssh_firewall_rule_name" {
  description = "The name of the created SSH firewall rule."
  value       = google_compute_firewall.fw_allow_ssh.name
}

# Output the name of the created Backend Service
output "backend_service_name" {
  description = "The name of the created Backend Service."
  value       = google_compute_backend_service.http_backend.name
}

# Output the IP address of the Global Load Balancer
output "load_balancer_ip_address" {
  description = "The IP address of the Global HTTP Load Balancer."
  value       = google_compute_global_forwarding_rule.webserver_forwarding_rule.ip_address
}

# Output the name of the stress test VM
output "stress_test_vm_name" {
  description = "The name of the created stress test VM."
  value       = google_compute_instance.stress_test_vm.name
}

# Output the external IP address of the stress test VM
output "stress_test_vm_external_ip" {
  description = "The external IP address of the stress test VM."
  value       = google_compute_instance.stress_test_vm.network_interface[0].access_config[0].nat_ip
}
