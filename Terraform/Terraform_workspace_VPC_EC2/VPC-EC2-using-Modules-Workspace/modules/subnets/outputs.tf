output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gw.allocation_id
}

output "internet_gateway" {
  value = aws_internet_gateway.igw.id
}