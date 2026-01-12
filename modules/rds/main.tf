# 1. Creates a Subnet Group to tell RDS which private subnets it can use
resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-sng"
  subnet_ids = var.db_subnet_ids
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

# 2. Creates the Primary, Multi-AZ Database (for Reliability)
resource "aws_db_instance" "primary" {
  identifier           = "${var.project_name}-primary-db"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [var.rds_sg_id]
  
  # This is the key setting for High Availability (zero data loss)
  multi_az = true 
  
  # This is required to create a Read Replica
  backup_retention_period = 7 
  
  apply_immediately   = true
  skip_final_snapshot = true
}

# 3. Creates the Read Replica (for Performance Scaling)
resource "aws_db_instance" "replica" {
  identifier          = "${var.project_name}-read-replica"
  instance_class      = "db.t3.micro"
  # Connects this replica to the primary database
  replicate_source_db = aws_db_instance.primary.identifier 
  skip_final_snapshot = true
}