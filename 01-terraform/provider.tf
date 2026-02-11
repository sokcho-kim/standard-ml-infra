terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 팀 협업 시 원격 백엔드 사용 권장
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "standard-ml-infra/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}

provider "aws" {
  region = var.aws_region
}
