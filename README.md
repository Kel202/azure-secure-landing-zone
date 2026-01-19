# Azure Secure Landing Zone (Terraform)


This project demonstrates a production-style Azure secure landing zone
implemented using Terraform under Azure Student subscription constraints.

## Objectives
- Implement a hub-and-spoke network architecture
- Enforce network-level security controls
- Centralize logging and monitoring
- Follow enterprise Terraform best practices

## Constraints
- Azure Student subscription
- No Owner / IAM permissions
- Focus on in-subscription security controls

## Architecture

The solution is based on a secure hub-and-spoke network architecture.

![Architecture Diagram](architecture/architecture-diagram.png)

Detailed design decisions are documented in
[`architecture/architecture.md`](architecture/architecture.md).
