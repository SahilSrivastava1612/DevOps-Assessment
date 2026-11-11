# Terraform design

The root Terraform design is split into reusable modules:

- `modules/network` – VPC, public/private subnets, IGW, NAT and route tables
- `modules/ecs` – ALB, ECS cluster, Fargate task/service and security groups
- `modules/rds` – private PostgreSQL RDS and RDS security group

The environments consume the same modules with different sizing and reliability settings.

For assessment review without AWS deployment:

```bash
cd infra/envs/dev
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

A real AWS plan requires valid AWS credentials and a real backend configuration.
