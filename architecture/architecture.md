# Azure Secure Hub-and-Spoke Architecture

This document describes the logical and network architecture for the
Azure Secure Landing Zone implemented in this repository.

The design follows a hub-and-spoke network topology to centralize
security controls and reduce the attack surface of application workloads.

## Design Principles

- Centralized ingress and egress
- No public IPs on application workloads
- Least-privilege network access
- Separation of concerns between hub and spokes

## Network Topology

- **Hub VNet (10.0.0.0/16)**
  - Azure Firewall / NVA
  - Jump VM for administrative access
  - Central Log Analytics workspace

- **Spoke VNet – Application (10.1.0.0/16)**
  - Application VM
  - Database subnet reserved for future workloads

## Traffic Flow

- Administrative access flows through the Jump VM
- All outbound internet traffic is routed via the Hub VNet
- East-west traffic is explicitly controlled using NSGs

## Constraints

This architecture is implemented under an Azure Student subscription
without Owner or IAM permissions. IAM controls are designed but not
deployed and are documented separately.
