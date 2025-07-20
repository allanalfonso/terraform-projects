# Define variables for project ID and region
variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
  default     = "us-central1" # You can change this default to your preferred region
}

variable "reserved_range_name" {
  description = "The name for the IP range reserved for Private Services Access."
  type        = string
  default     = "google-managed-services-default" # Default name for the reserved IP range
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a" # You can change this default to your preferred zone
}
