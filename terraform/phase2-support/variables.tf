variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "cs590-microservices"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "alarm_email" {
  type    = string
  default = ""
}
