output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

# EC2 Public IP
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance running MicroK8s"
  value       = aws_instance.k8s_instance.public_ip
}

# Optional: Security Group ID (for reference/debugging)
output "security_group_id" {
  description = "Security Group ID attached to the EC2 instance"
  value       = aws_security_group.k8s_sg.id
}
