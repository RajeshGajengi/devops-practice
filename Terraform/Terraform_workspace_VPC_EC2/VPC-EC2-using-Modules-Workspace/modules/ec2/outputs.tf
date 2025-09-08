output "public_ip" {
    value = aws_instance.public_instance.public_ip
    description = "public ip of public instance"
}

output "private_ip" {
    value = aws_instance.private_instance.private_ip
    description = "private ip of private instance"
}