resource "aws_vpc" "my_custom_vpc" {
    cidr_block =  var.vpc_cidr_block
    instance_tenancy = "default"

    tags = {
        Name = "${terraform.workspace}-VPC"
    }
}