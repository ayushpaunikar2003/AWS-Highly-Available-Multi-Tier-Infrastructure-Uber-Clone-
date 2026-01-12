variable "project_name" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "web_asg_sg_id" { 
  type = string 
}
variable "ec2_key_name" {
  type = string
}