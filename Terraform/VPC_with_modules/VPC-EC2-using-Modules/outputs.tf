output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.subnet.public_subnet_id
}

output "private_subnet_id" {
  value = module.subnet.private_subnet_id
}

output "igw" {
  value = module.subnet.internet_gateway
}

output "nat_gateway" {
  value = module.subnet.nat_gateway_id
}

output "public_instance_ip" {
  value = module.ec2.public_ip
}

output "private_instance_ip" {
  value = module.ec2.private_ip
}