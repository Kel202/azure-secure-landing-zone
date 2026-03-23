# Module: Compute

This module deploys the virtual machines for the 
Azure Secure Landing Zone.

## Resources Deployed

- Jump Host VM (Hub VNet - public subnet)
- Application VM (Spoke VNet - private subnet)
- Network Interfaces
- Public IP for Jump Host only

## Inputs

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `location` | Azure region for deployment | string | yes |
| `resource_group_name` | Name of the compute resource group | string | yes |
| `jump_subnet_id` | Subnet ID for jump host | string | yes |
| `app_subnet_id` | Subnet ID for application VM | string | yes |
| `admin_username` | Admin username for VMs | string | yes |
| `ssh_public_key` | SSH public key for authentication | string | yes |

## Outputs

| Output | Description |
|--------|-------------|
| `jump_vm_public_ip` | Public IP address of jump host |
| `jump_vm_private_ip` | Private IP of jump host |
| `app_vm_private_ip` | Private IP of application VM |

## Security Controls

- Application VM has no public IP address
- SSH key authentication only — password authentication disabled
- Jump host is the only entry point to private workloads
- Follows least-privilege access pattern

## Usage
```hcl
module "compute" {
  source = "../../modules/compute"

  location            = var.location
  resource_group_name = var.compute_resource_group_name
  jump_subnet_id      = module.network.jump_subnet_id
  app_subnet_id       = module.network.app_subnet_id
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
}
```
