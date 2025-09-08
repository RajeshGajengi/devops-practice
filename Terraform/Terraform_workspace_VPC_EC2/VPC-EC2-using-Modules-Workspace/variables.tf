variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  default = "192.176.0.0/16"
}

variable "public_subnet_cidr" {
  default = "192.176.0.0/20"
}

variable "private_subnet_cidr" {
  default = "192.176.16.0/20"
}

variable "public_az" {
  default = "us-east-1a"
}

variable "private_az" {
  default = "us-east-1b"
}

variable "instance_type" {
  default = "t2.micro"
}