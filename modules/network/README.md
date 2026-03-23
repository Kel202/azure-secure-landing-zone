# Module: Network

This module deploys the hub-and-spoke network infrastructure 
for the Azure Secure Landing Zone.

## Resources Deployed

- Hub Virtual Network
- Spoke Virtual Network
- VNet Peering (Hub <-> Spoke)
- Network Security Groups (Jump, App, Database)
- NSG Rules enforcing least-privilege access
- NSG Diagnostic Settings → Log Analytics Workspace

## Inputs

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `location` | Azure region for deployment | string | yes |
| `resource_group_name` | Name of the network resource group | string | yes |
| `hub_vnet_address_space` | Address space for hub VNet | string | yes |
| `spoke_vnet_address_space` | Address space for spoke VNet | string | yes |
| `log_analytics_workspace_id` | ID of Log Analytics Workspace for diagnostics | string | yes |

## Outputs

| Output | Description |
|--------|-------------|
| `hub_vnet_id` | Resource ID of the hub VNet |
| `spoke_vnet_id` | Resource ID of the spoke VNet |
| `jump_subnet_id` | Resource ID of the jump host subnet |
| `app_subnet_id` | Resource ID of the application subnet |
| `db_subnet_id` | Resource ID of the database subnet |

## Security Controls

- Default deny all inbound rule on all NSGs
- SSH access restricted to jump subnet only
- App subnet accessible only from jump subnet
- Database subnet accessible only from app subnet
- All NSG flow logs sent to centralized Log Analytics Workspace

## Usage
```hcl
module "network" {
  source = "../../modules/network"

  location                     = var.location
  resource_group_name          = var.network_resource_group_name
  hub_vnet_address_space       = "10.0.0.0/16"
  spoke_vnet_address_space     = "10.1.0.0/16"
  log_analytics_workspace_id   = module.monitoring.workspace_id
}
```
