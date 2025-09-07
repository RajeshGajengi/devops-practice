# Terraform Multi-Environment VPC & EC2 Setup

This Terraform project provisions a VPC, subnets (public & private), Internet Gateway, NAT Gateway, and EC2 instances (public & private) across multiple environments (dev, stage, prod). It demonstrates how to structure infrastructure as code in a modular way, use workspaces with environment-specific tfvars files, and ensure resources are tagged and isolated per environment, making it easier to manage deployments consistently across development, staging, and production.

## 📂 Project Structure
```
terraform-project/
│── main.tf
│── variables.tf
│── provider.tf
│── outputs.tf
│
│── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── subnets/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
│── workspace/
│   ├── dev/dev.tfvars
│   ├── stage/stage.tfvars
│   └── prod/prod.tfvars

```
### Creating the Folder Structure on Server
- Step 1: Create project folder
```bash
mkdir terraform-project
cd terraform-project
```
- Step 2: Create module folders
```sh
mkdir -p modules/vpc modules/subnet modules/ec2
```
- Step 3: Create root files
```sh
touch main.tf variables.tf outputs.tf provider.tf
```
- Step 4: Create module files
```sh
touch modules/vpc/{main.tf,variables.tf,outputs.tf} \
      modules/subnet/{main.tf,variables.tf,outputs.tf} \
      modules/ec2/{main.tf,variables.tf,outputs.tf}
```
Note: we will genrate ssh key pair and with that .pub keypair will launch instance,so to genrate key run below command,
```bash
ssh-keygen -t rsa -b 2000 -f ~/.ssh/my-new-key -N "" -m PEM
```

### Root Configuration Files
**`main.tf`**
  - Calls modules for VPC, subnets, and EC2 instances.
  - Uses variables to pass configuration values.
```hcl
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
}

module "subnet" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_az = var.public_az
  private_az = var.private_az
}

module "ec2" {
  source = "./modules/ec2"
  ami = "ami-0360c520857e3138f"
  instance_type = var.instance_type
  vpc_id = module.vpc.vpc_id
  public_subnet = module.subnet.public_subnet_id
  private_subnet = module.subnet.private_subnet_id
  key_pair = "~/.ssh/my-new-key"
}
```
**`varables.tf`**
  - Defines default values: Region, VPC CIDR, Subnet CIDRs, Availability Zones, Instance type
```hcl
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
```
**`provider.tf`**
Configures the AWS provider:
```hcl
provider "aws" {
  region = var.region
}
```
**`outputs.tf`**
Exports key resource IDs and IPs: VPC ID, Subnet IDs, Internet & NAT Gateway IDs, Public & Private EC2 IPs
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

###  Modules
#### 1. VPC Module (modules/vpc)
  - Creates a custom VPC.
  - Tags resources with the current workspace.
**`main.tf`**
```hcl
resource "aws_vpc" "my_custom_vpc" {
    cidr_block =  var.vpc_cidr_block
    instance_tenancy = "default"

    tags = {
        Name = "${terraform.workspace}-VPC"
    }
}
```
**`variables.tf`**
```hcl
variable "vpc_cidr_block" {
  type = string
}
```
**`outputs.tf`**
```hcl
output "vpc_id" {
  value = aws_vpc.my_custom_vpc.id
}
```

#### 2. Subnet Module (modules/subnet)
  - Creates public & private subnets.
  - Attaches Internet Gateway.
  - Creates NAT Gateway with Elastic IP.
  - Configures route tables for public & private subnets.
**`main.tf`**
```hcl
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

```

**`varibale.tf`**
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
**`outputs.tf`**
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

#### 3. EC2 Module (modules/ec2)
  - Creates a security group allowing HTTP, SSH, ICMP, and outbound traffic.
  - Imports an existing SSH key pair.
  - Launches one EC2 in public subnet and one in private subnet.
**`main.tf`**
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
    Name = "${terraform.workspace}-VPC-SG"
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
    instance_type = var.instance_type
    subnet_id = var.public_subnet
    security_groups = [aws_security_group.vpc_sg.id]
    key_name = aws_key_pair.my_key_pair.key_name
    tags = {
      Name = "${terraform.workspace}-public-instance"   
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
      Name = "${terraform.workspace}-private-instance"
    }
}

```
**`variables.tf`**
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
**`outputs.tf`**
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

### Workspaces & tfvars
📂 **`workspace/dev/dev.tfvars`**
```hcl
vpc_cidr_block = "123.10.0.0/16"
public_subnet_cidr = "123.10.0.0/20"
public_az = "us-east-1a"
private_subnet_cidr = "123.10.16.0/20"
private_az = "us-east-1b"
instance_type = "t2.micro"
```
📂 **`workspace/stage/stage.tfvars`**
```hcl
vpc_cidr_block = "111.110.0.0/16"
public_subnet_cidr = "111.110.0.0/20"
public_az = "us-east-1c"
private_subnet_cidr = "111.110.16.0/20"
private_az = "us-east-1d"
instance_type = "t2.small"
```
📂 **`workspace/prod/prod.tfvars`**
```hcl
vpc_cidr_block = "172.127.0.0/16"
public_subnet_cidr = "172.127.0.0/20"
public_az = "us-east-1e"
private_subnet_cidr = "172.127.16.0/20"
private_az = "us-east-1f"
instance_type = "t2.medium"
```

## 🚀 Workflow
**1. Initialize Terraform**
```bash
terraform init
```
**2. Create & Select Workspaces**
```bash
terraform workspace new dev
terraform workspace new stage
terraform workspace new prod

terraform workspace select dev   # switch to dev
```
**3. Apply Configurations**
```bash
terraform apply -var-file=workspace/dev/dev.tfvars
terraform apply -var-file=workspace/stage/stage.tfvars
terraform apply -var-file=workspace/prod/prod.tfvars
```
**4. Destroy Resources (per workspace)**
```bash
terraform destroy -var-file=workspace/dev/dev.tfvars
```

### ✅ Key Features

- Modular design (VPC, Subnets, EC2).
- Workspace-aware resource naming (${terraform.workspace}).
- Isolated environments (dev, stage, prod).
- Separate variable files for each environment.

### Connectivity Testing:
1. connect to public instance, and run below command to check public instance has internet connectivity or not
   ```bash
   ping 0.0.0.0
   ```
2. Now copy private ip of private instance, and in public instance run below command
```bash
ping <private-ip of private instance>
```
3. We can check internet connectivy for private instance through ssh .
```bash
ssh -i key-pair <username>@<private-ip>
```
copy private key as we created above, past in key-pair file. and make sure it has read only access.
