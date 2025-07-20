# Output the test VM's internal IP address
output "test_vm_internal_ip" {
  description = "The internal IP address of the test VM."
  value       = google_compute_instance.test_vm.network_interface[0].network_ip
}