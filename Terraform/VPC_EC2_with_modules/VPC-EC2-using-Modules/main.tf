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