module "network" {
  source = "../../modules/network"

  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  app_subnet_cidrs     = var.app_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevOpsAssessment"
  }
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix       = var.name_prefix
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
  cpu               = var.ecs_cpu
  memory            = var.ecs_memory
  desired_count     = var.ecs_desired_count

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevOpsAssessment"
  }
}

module "rds" {
  source = "../../modules/rds"

  name_prefix              = var.name_prefix
  vpc_id                   = module.network.vpc_id
  db_subnet_ids            = module.network.db_subnet_ids
  ecs_security_group_id    = module.ecs.ecs_security_group_id
  db_name                  = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  instance_class            = var.rds_instance_class
  allocated_storage         = var.rds_allocated_storage
  backup_retention_period   = var.rds_backup_retention_period
  deletion_protection       = var.rds_deletion_protection

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevOpsAssessment"
  }
}
