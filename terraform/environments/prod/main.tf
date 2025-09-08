# Production Environment Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "payments-terraform-state-99999999999-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "payments-terraform-locks-99999999999-prod"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "prod"
      Project     = "payments"
      ManagedBy   = "terraform"
    }
  }
}

# Local variables
locals {
  project_name = "payments"
  environment  = "prod"
  aws_region   = "us-west-2"
  
  availability_zones = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  
  # CIDR blocks for prod environment
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  project_name           = local.project_name
  environment           = local.environment
  vpc_cidr              = local.vpc_cidr
  availability_zones    = local.availability_zones
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"
  
  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"
  
  project_name = local.project_name
  environment  = local.environment
}

# ALB Module
module "alb" {
  source = "../../modules/alb"
  
  project_name           = local.project_name
  environment           = local.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"
  
  project_name                = local.project_name
  environment                = local.environment
  aws_region                 = local.aws_region
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  ecs_security_group_id      = module.security_groups.ecs_security_group_id
  backend_repository_url     = module.ecr.backend_repository_url
  frontend_repository_url    = module.ecr.frontend_repository_url
  backend_target_group_arn   = module.alb.backend_target_group_arn
  frontend_target_group_arn  = module.alb.frontend_target_group_arn
  
  # Production environment specific settings
  backend_cpu            = 512
  backend_memory         = 1024
  frontend_cpu           = 256
  frontend_memory        = 512
  backend_desired_count  = 2
  frontend_desired_count = 2
  log_retention_days     = 30
}
