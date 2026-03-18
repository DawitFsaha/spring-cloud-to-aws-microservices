variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_app_subnet_a" { type = string }
variable "private_app_subnet_b" { type = string }
variable "alb_security_group_id" { type = string }
variable "vpc_link_security_group_id" { type = string }
variable "enable_waf" { type = bool }
