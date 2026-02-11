variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입 (팀 표준: t3.medium)"
  type        = string
  default     = "t3.medium"
}

variable "owner" {
  description = "리소스 소유자 이름 (태그용)"
  type        = string
  default     = "YourName"
}
