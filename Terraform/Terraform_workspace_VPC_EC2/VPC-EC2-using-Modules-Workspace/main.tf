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