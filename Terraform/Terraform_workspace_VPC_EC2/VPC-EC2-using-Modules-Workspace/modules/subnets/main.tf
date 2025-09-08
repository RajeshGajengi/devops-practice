# Create a public subnet inside the VPC
resource "aws_subnet" "public_subnet" {
    vpc_id = var.vpc_id
    cidr_block = var.public_subnet_cidr
    availability_zone = var.public_az
    map_public_ip_on_launch = "true"
    tags = {
      Name = "${terraform.workspace}-Public-subnet"
    }
}

# Create a private subnet inside the VPC
resource "aws_subnet" "private_subnet" {
    vpc_id = var.vpc_id
    cidr_block = var.private_subnet_cidr
    availability_zone = var.private_az
    tags = {
      Name = "${terraform.workspace}-Private-subnet"
    }
}


# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
    vpc_id = var.vpc_id
    tags = {
      Name = "${terraform.workspace}-My-IGW"
    }
}

# Create a route table for the public subnet with default route to Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    
  }

  tags = {
    Name = "${terraform.workspace}-Public-RT"
  }
}

# Associate the public subnet with the public route table  
resource "aws_route_table_association" "public_rt_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}


# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "elastic_ip" {
    domain = "vpc"
    tags = {
      Name = "${terraform.workspace}-MyElasticIP"
    }
}

# Create a NAT Gateway in the public subnet for private subnet internet access
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.elastic_ip.allocation_id
  subnet_id = aws_subnet.public_subnet.id
  connectivity_type = "public"
  tags = {
    Name = "${terraform.workspace}-MyNatGateway"
  }
}


# Create a route table for the private subnet with default route to NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${terraform.workspace}-Private-RT"
  }
}

# Associate the private subnet with the private route table 
resource "aws_route_table_association" "private_rt_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}
