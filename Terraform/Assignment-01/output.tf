output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "flask_url" {
  description = "URL to access Flask backend"
  value       = "http://${aws_instance.app_server.public_ip}:${var.flask_port}"
}

output "express_url" {
  description = "URL to access Express frontend"
  value       = "http://${aws_instance.app_server.public_ip}:${var.express_port}"
}