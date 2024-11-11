output "ecs_load_balancer_dns_name" {
  description = "ECS load balancer DNS name"
  value       = aws_lb.this.dns_name
}
