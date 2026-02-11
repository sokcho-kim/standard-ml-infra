output "instance_id" {
  description = "생성된 EC2 인스턴스 ID"
  value       = aws_instance.dev_server.id
}

output "public_ip" {
  description = "EC2 퍼블릭 IP"
  value       = aws_instance.dev_server.public_ip
}
