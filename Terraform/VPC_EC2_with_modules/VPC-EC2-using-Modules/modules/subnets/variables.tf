
variable "vpc_id" {
    type = string  
}

variable "public_subnet_cidr" {
  description = "public subnet cidr block"
}

variable "private_subnet_cidr" {
  description = "private subnet Cidr block "
}

variable "public_az" {
  default = "Availabilty zone of public subnet"
}

variable "private_az" {
  description = "Availabilty zone of private subnet"
}
