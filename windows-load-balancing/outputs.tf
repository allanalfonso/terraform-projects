# Output the internal IP address of the load balancer
output "internal_lb_ip_address" {
  description = "The internal IP address of the Application Load Balancer."
  value       = google_compute_forwarding_rule.internal_lb_forwarding_rule.ip_address
}
