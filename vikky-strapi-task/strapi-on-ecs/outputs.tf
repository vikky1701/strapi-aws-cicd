# Output ALB DNS Name
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.strapi_alb.dns_name
}

# Output VPC ID (using default VPC)
output "vpc_id" {
  description = "ID of the Default VPC"
  value       = data.aws_vpc.default.id
}

# Output ECS Cluster Name
output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.strapi_cluster.name
}

# Output RDS Endpoint
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.strapi_postgres.address
}

# Output Default Subnet IDs
output "subnet_ids" {
  description = "Default subnet IDs used for the deployment"
  value       = slice(data.aws_subnets.default_public.ids, 0, 2)
}

# Output Security Group IDs
output "security_group_ids" {
  description = "Security Group IDs created for the deployment"
  value = {
    alb_sg = aws_security_group.alb_sg.id
    ecs_sg = aws_security_group.ecs_sg.id
    rds_sg = aws_security_group.rds_sg.id
  }
}