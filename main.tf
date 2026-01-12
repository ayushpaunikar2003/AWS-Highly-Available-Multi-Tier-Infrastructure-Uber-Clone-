provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

# No longer needed, as we're not using a Bastion Host IP
# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }

# 1. Build the Network
module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  vpc_cidr              = "10.0.0.0/16"
  public_subnets_cidr   = ["10.0.1.0/24", "10.0.2.0/24"]
  # Create 4 private subnets: 2 for apps, 2 for DB
  private_subnets_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.201.0/24", "10.0.202.0/24"]
  availability_zones    = slice(data.aws_availability_zones.available.names, 0, 2)
}

# 2. Create ALL Security Groups
module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# 3. Create the EXTERNAL Load Balancer (ALB)
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# 4. Create the NEW INTERNAL Load Balancer (ILB)
module "ilb" {
  source = "./modules/ilb"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  # Place the ILB in the app private subnets
  private_subnet_ids = slice(module.vpc.private_subnet_ids, 0, 2) 
  ilb_sg_id          = module.security_groups.ilb_sg_id
}

# 5. Create the Public Web Tier (Tier 1)
module "web_tier" {
  source = "./modules/web_asg" # Renamed from bastion_ha

  project_name      = var.project_name
  public_subnet_ids = module.vpc.public_subnet_ids
  web_asg_sg_id     = module.security_groups.web_asg_sg_id # Renamed variable
  ec2_key_name      = var.ec2_key_name
}

# 6. Create the Private App Tier (Tier 2)
module "app_tier" {
  source = "./modules/app_asg" # Renamed from asg

  project_name       = var.project_name
  app_asg_sg_id      = module.security_groups.app_asg_sg_id # Renamed variable
  private_subnet_ids = slice(module.vpc.private_subnet_ids, 0, 2)
  ec2_key_name       = var.ec2_key_name
}

# 7. Create the RDS Database Tier (Tier 3)
module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  # Place the DB in its own dedicated private subnets
  db_subnet_ids      = slice(module.vpc.private_subnet_ids, 2, 4) 
  rds_sg_id          = module.security_groups.rds_sg_id
  db_username        = var.db_username
  db_password        = var.db_password
}


# --- FINAL WIRING ---

# 8. Attach the WEB_TIER ASG to the EXTERNAL ALB's Target Group
resource "aws_autoscaling_attachment" "alb_attachment" {
  autoscaling_group_name = module.web_tier.asg_name # <-- Changed
  lb_target_group_arn    = module.alb.target_group_arn
}

# 9. Attach the APP_TIER ASG to the INTERNAL ILB's Target Group
resource "aws_autoscaling_attachment" "ilb_attachment" {
  autoscaling_group_name = module.app_tier.asg_name # <-- Changed
  lb_target_group_arn    = module.ilb.app_tier_target_group_arn # <-- New
}