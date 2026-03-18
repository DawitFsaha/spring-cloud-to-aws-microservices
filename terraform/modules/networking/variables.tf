variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "public_subnet_a_cidr" {
  type    = string
  default = "10.42.0.0/24"
}

variable "public_subnet_b_cidr" {
  type    = string
  default = "10.42.1.0/24"
}

variable "private_app_subnet_a_cidr" {
  type    = string
  default = "10.42.10.0/24"
}

variable "private_app_subnet_b_cidr" {
  type    = string
  default = "10.42.11.0/24"
}

variable "private_data_subnet_a_cidr" {
  type    = string
  default = "10.42.20.0/24"
}

variable "private_data_subnet_b_cidr" {
  type    = string
  default = "10.42.21.0/24"
}
