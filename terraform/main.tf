#####################################
# VPC Creation
#####################################
resource "aws_vpc" "main" {
  # CIDR block for the VPC (provided via variables)
  cidr_block = var.vpc_cidr
}

#####################################
# Internet Gateway
#####################################
resource "aws_internet_gateway" "gw" {
  # Attach IGW to the main VPC
  vpc_id = aws_vpc.main.id
}

#####################################
# Public Subnet
#####################################
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  # CIDR block for public subnet (provided via variables)
  cidr_block = var.public_subnet_cidr
  
  # Ensure instances launched here get public IPs
  map_public_ip_on_launch = true
}

#####################################
# Public Route Table
#####################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Default route to Internet via IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#####################################
# Security Group for Kubernetes Node
#####################################
resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.main.id

  # Allow SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow public HTTPS (for GET requests)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow internal traffic for NodePort (POST requests)
  ingress {
    from_port   = 30999     # NodePort range start
    to_port     = 30999     # NodePort range end
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # internal only (VPC CIDR)
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#####################################
# Ubuntu 20.04 AMI Lookup
#####################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu) official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

#####################################
# EC2 Instance
#####################################
resource "aws_instance" "k8s_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  # Place instance in the public subnet
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.key_name

  # Bootstrap script for installing dependencies & microk8s
  user_data = file("${path.module}/../scripts/Installation_K8s_openssl.sh")

  tags = {
    Name = "microk8s-httpbin"
  }
}