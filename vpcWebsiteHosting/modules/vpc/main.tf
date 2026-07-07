#VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge(var.tags,{Name = "${var.environment_name}-vpc"})
  lifecycle{
    prevent_destroy = false
  }
}
#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags,{Name = "${var.environment_name}-igw"}) 
}

#Public Subnet
resource "aws_subnet" "public" {
  for_each={for idx, az in local.azs : az => local.public_subnets[idx]}
  vpc_id = aws_vpc.main.id
  cidr_block = each.value
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = merge(var.tags,{Name = "${var.environment_name}-public-${each.key}"})
  
}

#Private Subnet
resource "aws_subnet" "private" {
  for_each={for idx, az in local.azs : az => local.private_subnets[idx]}
  vpc_id = aws_vpc.main.id
  cidr_block = each.value
  availability_zone = each.key
  tags = merge(var.tags,{Name = "${var.environment_name}-private-${each.key}"})
  
}

#Elastic IP for Nat Gateway
resource "aws_eip" "nat" {
 tags = merge(var.tags,{Name = "${var.environment_name}-nat-eip"}) 
}
#Nat Gateway
resource "aws_nat_gateway" "nat" {
  depends_on = [aws_internet_gateway.igw]
  allocation_id = aws_eip.nat.id
  subnet_id = values(aws_subnet.public)[0].id
  tags = merge(var.tags,{Name = "${var.environment_name}-nat-gateway"}) 
}

#Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags,{Name = "${var.environment_name}-public-rt"})
  
}

#Public Route Table Association to Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_rt.id
  
}

#Private Roubte Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = merge(var.tags,{Name = "${var.environment_name}-private-rt"})
  
}

#Private Route Table Association to Private Subnet
resource "aws_route_table_association" "private_rt_assoc" {
  for_each = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_rt.id
  
}

# ALB Security Group (Public facing)
resource "aws_security_group" "alb_sg" {
  name_prefix       = "${var.environment_name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Inbound rules
  ingress {
    description = "Allow HTTP traffic from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Inbound rules for HTTPS
#   ingress {
#     description = "Allow HTTPS traffic from internet"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
# }

  # Outbound rules (health checks)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {Name = "${var.environment_name}-alb-sg"
  Environment = var.environment_name}

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Security Group (Private, no internet access)
resource "aws_security_group" "ec2_sg"{
  name_prefix = "${var.environment_name}-ec2-sg"
  description = "Security group for Private EC2 instances accessible only through ALB"
  vpc_id = aws_vpc.main.id

  # Inbound rules only from ALB security group
  ingress {
    description = "Allow traffic from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {Name = "${var.environment_name}-ec2-sg"
  Environment = var.environment_name}

  lifecycle {
    create_before_destroy = true
  }
}
