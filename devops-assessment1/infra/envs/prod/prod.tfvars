aws_region = "ap-south-1"
environment = "prod"
name_prefix = "devops-assessment-prod"

vpc_cidr = "10.20.0.0/16"

azs = [
  "ap-south-1a",
  "ap-south-1b"
]

public_subnet_cidrs = [
  "10.20.1.0/24",
  "10.20.2.0/24"
]

app_subnet_cidrs = [
  "10.20.11.0/24",
  "10.20.12.0/24"
]

db_subnet_cidrs = [
  "10.20.21.0/24",
  "10.20.22.0/24"
]

db_name     = "appdb"
db_username = "appadmin"
# Replace this only in a local untracked tfvars file for a real AWS plan.
# Do not commit real credentials.
db_password = "CHANGE_ME_TO_A_SECRET"

rds_instance_class          = "db.t4g.small"
rds_allocated_storage       = 50
rds_backup_retention_period = 14
rds_deletion_protection     = true

ecs_cpu          = 512
ecs_memory       = 1024
ecs_desired_count = 2
