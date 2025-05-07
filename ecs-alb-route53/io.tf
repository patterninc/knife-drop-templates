variable "name" {
  type        = string
  description = "Name of the resource"
}



variable "container_port" {
  type        = number
  description = "Container port"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "region" {
  type        = string
  description = "AWS region"
}
