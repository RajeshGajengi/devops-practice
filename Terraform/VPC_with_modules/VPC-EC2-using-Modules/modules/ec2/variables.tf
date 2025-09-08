
variable "ami" {
  type = string
  description = "Ubuntu Server 24.04 LTS(HVM), SSD Volume Type"
}

variable "instance_type" {
  type = string
  description = "Instance type"
}

variable "public_subnet" {
  description = "subnet of public instance"
}

variable "private_subnet" {
  description = "subnet of private instance"
}

variable "key_pair" {
  description = "key pair"
  type = string
}

variable "vpc_id" {
  description = "vpc for security group"
}