variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1" //Frankfurt, Germany 
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.10.1.0/24"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
  default     = "terraform-Keypair"   # 👈 This is your key pair name must create it in AWS in key value of EC2
}
