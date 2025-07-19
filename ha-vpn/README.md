# HA VPN Terraform Configuration

This directory contains Terraform code to deploy a highly available (HA) VPN between two Google Cloud VPCs: a "vpc-demo" network and an "on-prem" network. The configuration uses Google Cloud HA VPN gateways, Cloud Routers, dynamic BGP routing, and creates test VM instances in each network.

## Features

- Creates two VPCs: `vpc-demo` and `on-prem` using the [terraform-google-modules/network/google](https://registry.terraform.io/modules/terraform-google-modules/network/google/latest) module.
- Deploys HA VPN gateways in both VPCs.
- Configures Cloud Routers with BGP for dynamic route exchange.
- Establishes redundant VPN tunnels between the VPCs.
- Configures BGP peers and interfaces for each tunnel.
- Sets up firewall rules for internal and SSH/ICMP access.
- Deploys a test VM in each VPC subnet.

## File Structure

- [`gcp.tf`](gcp.tf): Defines the `vpc-demo` VPC, subnets, firewall rules, and test VMs.
- [`onprem.tf`](onprem.tf): Defines the `on-prem` VPC, subnets, firewall rules, and test VMs.
- [`ha-vpn.tf`](ha-vpn.tf): Configures HA VPN gateways, VPN tunnels, Cloud Routers, BGP interfaces, and peers.
- [`variables.tf`](variables.tf): Input variables for project, region, and zone.
- [`providers.tf`](providers.tf): Provider configuration.
- [`versions.tf`](versions.tf): Terraform version constraint.

## Usage

1. **Set up your environment:**
   - Install [Terraform](https://www.terraform.io/downloads.html)
   - Authenticate with Google Cloud (`gcloud auth application-default login`)

2. **Configure variables:**
   - Copy `terraform.tfvars.example` to `terraform.tfvars` (if provided) or create your own.
   - Set `project_id`, `region`, and `zone` in [`terraform.tfvars`](ha-vpn/terraform.tfvars).

3. **Initialize Terraform:**
   ```sh
   terraform init
   ```

4. **Review the plan:**
   ```sh
   terraform plan
   ```

5. **Apply the configuration:**
   ```sh
   terraform apply
   ```

## Notes

- The VPN shared secret is set as `"[SHARED_SECRET]"` in [`ha-vpn.tf`](ha-vpn/ha-vpn.tf). Replace this with a secure value before applying.
- Firewall rules are permissive for demonstration. Restrict source ranges for production.
- The configuration uses modules from the Terraform Registry for VPC and firewall management.
- All resources are created in the region `us-central1` unless otherwise specified.

## Cleanup

To destroy all resources:

```sh
terraform destroy
```

## References

- [Google Cloud HA VPN Documentation](https://cloud.google.com/network-connectivity/docs/vpn/how-to/creating-ha-vpn)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [terraform-google-modules/network](https://github.com/terraform-google-modules/terraform-google-network)

---
