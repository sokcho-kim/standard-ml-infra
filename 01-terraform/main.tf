resource "aws_instance" "dev_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04
  instance_type = var.instance_type

  tags = {
    Name    = "ML-Dev-Server-Standard"
    Owner   = var.owner
    Project = "standard-ml-infra"
  }
}
