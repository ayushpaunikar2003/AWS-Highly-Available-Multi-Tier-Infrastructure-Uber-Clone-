variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
}

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "ec2_key_name" {
  description = "The name of the EC2 key pair for SSH access"
  type        = string
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}

