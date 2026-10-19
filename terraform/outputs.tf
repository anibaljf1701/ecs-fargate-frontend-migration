output "frontend_url" {
  description = "URL pública del frontend"
  value       = "http://${aws_lb.main.dns_name}"
}