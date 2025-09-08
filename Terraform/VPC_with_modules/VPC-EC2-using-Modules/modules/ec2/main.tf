# Create a security group allowing HTTP, SSH, ICMP, and all outbound traffic
resource "aws_security_group" "vpc_sg" {
  name = "MY-VPC-SG"
  vpc_id = var.vpc_id
  description = "Allow HTTP, SSH, ICMP inbound and all outbound traffic"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP Traffic"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH Traffic"
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all ICMP traffic"
  }

  egress  {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all oubound traffic"
  }

  tags = {
    Name = "VPC-SG"
  }

}

# Import an existing SSH key pair into AWS
resource "aws_key_pair" "my_key_pair" {
  key_name = "my-key-pair"
  public_key = file("${var.key_pair}.pub")
}

# Launch an EC2 instance in the public subnet
resource "aws_instance" "public_instance" {
    ami = var.ami
    instance_type = "t2.micro"
    subnet_id = var.public_subnet
    security_groups = [aws_security_group.vpc_sg.id]
    key_name = aws_key_pair.my_key_pair.key_name
    tags = {
      Name = "public-instance"   
    }
}

# Launch an EC2 instance in the private subnet
resource "aws_instance" "private_instance" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = var.private_subnet
    security_groups = [aws_security_group.vpc_sg.id]
    key_name = aws_key_pair.my_key_pair.key_name
    tags = {
      Name = "private-instance"
    }
}

