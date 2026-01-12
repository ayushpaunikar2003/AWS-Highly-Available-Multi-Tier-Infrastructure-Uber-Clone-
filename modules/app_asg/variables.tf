variable "project_name" {
  type = string
}
variable "app_asg_sg_id" { 
  type = string 
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "ec2_key_name" {
  type = string
}