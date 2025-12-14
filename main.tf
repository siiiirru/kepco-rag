terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC 모듈
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  
  tags = var.common_tags
}

# Security Groups 모듈
module "security_groups" {
  source = "./modules/security"
  
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  
  tags = var.common_tags
}



# CloudWatch 모듈
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  project_name = var.project_name
  
  tags = var.common_tags
}

# Bedrock 모듈
module "bedrock" {
  source = "./modules/bedrock"
  
  project_name = var.project_name
  
  tags = var.common_tags
}

# IAM 모듈
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  
  tags = var.common_tags
}

# ALB 모듈
module "alb" {
  source = "./modules/alb"
  
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]
  project_name       = var.project_name
  
  tags = var.common_tags
}

# EC2 모듈 (프라이빗 서브넷)
module "ec2" {
  source = "./modules/ec2"
  
  subnet_id              = module.vpc.private_subnet_ids[0]
  security_group_ids     = [module.security_groups.ec2_sg_id]
  iam_instance_profile   = module.iam.instance_profile_name
  target_group_arn       = module.alb.target_group_arn
  bedrock_agent_id       = module.bedrock.agent_id
  bedrock_agent_alias_id = module.bedrock.agent_alias_id
  project_name           = var.project_name
  
  tags = var.common_tags
}

module "cloudtrail" {
  source = "./modules/cloudtrail"
}