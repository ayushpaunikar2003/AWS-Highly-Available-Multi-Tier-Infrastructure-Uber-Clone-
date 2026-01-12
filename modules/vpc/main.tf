# --- 1. Create the Main VPC (The "City Walls") ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

# --- 2. Create the Public Subnets (The "Lobby") ---
# These subnets will be connected to the Internet Gateway.
resource "aws_subnet" "public" {
  count             = length(var.public_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = { Name = "${var.project_name}-public-subnet-${count.index + 1}" }
}

# --- 3. Create the Private Subnets (The "Secure Rooms") ---
# We create 4: 2 for apps, 2 for the database.
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[count.index]
  # Use modulo to loop through the 2 AZs (e.g., 0, 1, 0, 1)
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  tags              = { Name = "${var.project_name}-private-subnet-${count.index + 1}" }
}

# --- 4. Create the Internet Gateway (The "Main Entrance") ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# --- 5. Create the Public Route Table ---
# This route table sends all internet traffic (0.0.0.0/0) to the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# Associate our public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- 6. Create NAT Gateways (The "Secure Exit Door") ---
# We create 2 NAT Gateways for high availability, one in each public subnet.
resource "aws_eip" "nat" {
  count      = length(var.public_subnets_cidr)
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnets_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "${var.project_name}-nat-gw-${count.index + 1}" }
}

# --- 7. Create the Private Route Tables ---
# This route table sends all internet traffic (0.0.0.0/0) to a NAT Gateway.
resource "aws_route_table" "private" {
  count  = length(var.private_subnets_cidr)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index % 2].id # Pin to the AZ's NAT GW
  }
  tags = { Name = "${var.project_name}-private-rt-${count.index + 1}" }
}

# Associate our private subnets with their respective private route tables
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}