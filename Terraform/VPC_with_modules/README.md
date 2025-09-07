# 📘 Terraform AWS Infrastructure with Modules

## 📌 Overview

This Terraform project provisions a modular AWS infrastructure that includes:

- A VPC
- Public and private subnets
- Internet Gateway (IGW) & NAT Gateway
- Route tables for public and private subnets
- Security group
- EC2 instances in both public and private subnets
- SSH key pair for secure access

The project follows modular design:
- vpc/ → Creates VPC
- subnet/ → Creates subnets, IGW, NAT GW, and routing
- ec2/ → Creates security group, key pair, and EC2 instances


## 📂 Project Structure
```
terraform-aws-project/
├── main.tf            # Root module calling VPC, Subnet, EC2 modules
├── variables.tf       # Global variables (region, etc.)
├── outputs.tf         # Root outputs
├── provider.tf        # AWS provider configuration
├── terraform.tfvars   # Variable values (optional)
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── subnets/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
### Root Module
- **main.tf**
Calls all modules with required inputs:
```hcl
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr_block = "192.176.0.0/16"
}

module "subnet" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
  public_subnet_cidr = "192.176.0.0/20"
  private_subnet_cidr = "192.176.16.0/20"
  public_az = "us-east-1a"
  private_az = "us-east-1b"
}

module "ec2" {
  source = "./modules/ec2"
  ami = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  vpc_id = module.vpc.vpc_id
  public_subnet = module.subnet.public_subnet_id
  private_subnet = module.subnet.private_subnet_id
  key_pair = "~/.ssh/my-new-key"
}
```

- variables.tf
```hcl
variable "region" {
  default = "us-east-1"
}
```

- provider.tf
```hcl
provider "aws" {
  region = var.region
}
```

- outputs.tf
```hcl
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
```

### VPC Module (modules/vpc)
- main.tf
```hcl
resource "aws_vpc" "my_custom_vpc" {
    cidr_block =  var.vpc_cidr_block
    instance_tenancy = "default"

    tags = {
        Name = "MyCustomVPC"
    }
}
```

- variables.tf
```hcl
variable "vpc_cidr_block" {
  type = string
}
```

- outputs.tf
```hcl
output "vpc_id" {
  value = aws_vpc.my_custom_vpc.id
}
```

### Subnet Module (modules/subnet)
- main.tf
```hcl
# Create a public subnet inside the VPC
resource "aws_subnet" "public_subnet" {
    vpc_id = var.vpc_id
    cidr_block = var.public_subnet_cidr
    availability_zone = var.public_az
    map_public_ip_on_launch = "true"
    tags = {
      Name = "Public-subnet"
    }
}

# Create a private subnet inside the VPC
resource "aws_subnet" "private_subnet" {
    vpc_id = var.vpc_id
    cidr_block = var.private_subnet_cidr
    availability_zone = var.private_az
    tags = {
      Name = "Private-subnet"
    }
}


# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
    vpc_id = var.vpc_id
    tags = {
      Name = "My-IGW"
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
    Name = "Public-RT"
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
      Name = "MyElasticIP"
    }
}

# Create a NAT Gateway in the public subnet for private subnet internet access
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.elastic_ip.allocation_id
  subnet_id = aws_subnet.public_subnet.id
  connectivity_type = "public"
  tags = {
    Name = "MyNatGateway"
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
    Name = "Private-RT"
  }
}

# Associate the private subnet with the private route table 
resource "aws_route_table_association" "private_rt_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}

```
- variables.tf
```hcl

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

```
- outputs.tf
```hcl
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
```

### EC2 Module (modules/ec2)
- main.tf
```hcl
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


```
- variables.tf
```hcl

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
```
- outputs.tf
```hcl
output "public_ip" {
    value = aws_instance.public_instance.public_ip
    description = "public ip of public instance"
}

output "private_ip" {
    value = aws_instance.private_instance.private_ip
    description = "private ip of private instance"
}
```



