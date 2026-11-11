aws_region = "ap-south-1"
environment = "dev"
name_prefix = "devops-assessment-dev"

vpc_cidr = "10.10.0.0/16"

azs = [
  "ap-south-1a",
  "ap-south-1b"
]

public_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

app_subnet_cidrs = [
  "10.10.11.0/24",
  "10.10.12.0/24"
]

db_subnet_cidrs = [
  "10.10.21.0/24",
  "10.10.22.0/24"
]

db_name     = "appdb"
db_username = "appadmin"
# Replace this only in a local untracked tfvars file for a real AWS plan.
# Do not commit real credentials.
db_password = "CHANGE_ME_TO_A_SECRET"

rds_instance_class          = "db.t4g.micro"
rds_allocated_storage       = 20
rds_backup_retention_period = 3
rds_deletion_protection     = false

ecs_cpu          = 256
ecs_memory       = 512
ecs_desired_count = 1
