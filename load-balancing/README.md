# Global HTTP Load Balancer with Managed Instance Groups (MIGs) on Google Cloud

This Terraform configuration deploys a global HTTP load balancer on Google Cloud Platform (GCP) with two Managed Instance Groups (MIGs) in different regions, NAT gateways, firewall rules, and a stress test VM.

## Features

- **VPC Network**: Creates a VPC in auto mode with global routing.
- **Firewall Rules**: Allows health checks, internal traffic, SSH, and RDP (for demo purposes).
- **Cloud NAT**: Provides outbound internet access for instances without external IPs in both `us-central1` and `europe-west4`.
- **Instance Template**: Deploys Apache web servers on Debian 11.
- **Managed Instance Groups**: 
  - `us-1-mig` in `us-central1-a`
  - `notus-1-mig` in `europe-west4-c`
  - Both with autoscaling and autohealing.
- **Health Check**: TCP health check on port 80.
- **Global HTTP Load Balancer**: 
  - Backend service with both MIGs.
  - URL map, HTTP proxy, and global forwarding rule on port 80.
- **Stress Test VM**: Single VM with Apache for testing.

## Usage

1. **Prerequisites**
   - [Terraform](https://www.terraform.io/downloads.html) installed.
   - GCP project and billing enabled.
   - Application Default Credentials set up (`gcloud auth application-default login`).

2. **Configure Variables**
   - If using variables, create a `terraform.tfvars` file or set variables as needed.

3. **Initialize Terraform**
   ```sh
   terraform init
   ```

4. **Review the Plan**
   ```sh
   terraform plan
   ```

5. **Apply the Configuration**
   ```sh
   terraform apply
   ```

6. **Access the Load Balancer**
   - After apply, find the external IP from the `google_compute_global_forwarding_rule.webserver_forwarding_rule` output.
   - Visit `http://<EXTERNAL_IP>` in your browser.

## Notes

- **Security**: SSH and RDP are open to the world for demonstration. Restrict `source_ranges` in production.
- **No External IPs**: MIG instances do not have external IPs; outbound access is via Cloud NAT.
- **Health Checks**: Firewall allows Google health check IPs on port 80.
- **Autoscaling**: Each MIG can scale between 1 and 2 instances based on load.

## Cleanup

To remove all resources:

```sh
terraform destroy
```

## References

- [Google Cloud Load Balancing](https://cloud.google.com/load-balancing/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud NAT](https://cloud.google.com/nat/docs/overview)

---