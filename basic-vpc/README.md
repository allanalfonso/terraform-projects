# Basic VPC Terraform Project

This project provisions a basic Google Cloud VPC network with default firewall rules, NAT, and a test VM using Terraform.

## Features

- **Custom VPC** named `default` with automatic subnet creation and global dynamic routing.
- **Default firewall rules**:
  - Allow all custom TCP/UDP from `10.128.0.0/9`
  - Allow ICMP from anywhere
  - Allow RDP (TCP 3389) from anywhere
  - Allow SSH (TCP 22) from anywhere
- **Cloud NAT** for outbound internet access without external IPs.
- **Test VM** (Debian 11, e2-micro) for connectivity testing.
- **Private Services Access** (if configured).

## Files

| File             | Purpose                                                      |
|------------------|--------------------------------------------------------------|
| `main.tf`        | Main resources: VPC, firewall rules, NAT, VM, etc.           |
| `variables.tf`   | Input variables (project, region, zone, etc.)                |
| `outputs.tf`     | Outputs for VPC self link and VM internal IP                 |
| `providers.tf`   | Provider configuration (Google provider)                     |
| `terraform.tfvars` | Variable values (project ID, region, zone)                 |
| `versions.tf`    | Terraform version constraint                                 |

## Usage

1. **Set up your Google Cloud credentials** (e.g., `GOOGLE_APPLICATION_CREDENTIALS`).
2. Edit `terraform.tfvars` to set your `project_id`, `region`, and `zone`.
3. Initialize Terraform:
   ```sh
   terraform init
   ```
4. Review the plan:
   ```sh
   terraform plan
   ```
5. Apply the configuration:
   ```sh
   terraform apply
   ```

## Outputs

- **`vpc_self_link`**: The self link of the created VPC network.
- **`test_vm_internal_ip`**: The internal IP address of the test VM.

## Requirements

- [Terraform](https://www.terraform.io/) >= 1.0.0
- Google Cloud account and project
- Sufficient permissions to create networking and compute resources

## Notes

- The VPC is named `default` and uses automatic subnet creation.
- Firewall rules are permissive for demonstration; restrict as needed for production.
- The test VM does **not** have an external IP.

