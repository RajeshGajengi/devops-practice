# Terraform EC2 with Remote State in S3

This project demonstrates how to provision an EC2 instance on AWS using Terraform and store the Terraform state file (tfstate) in an S3 bucket for remote state management.

## 📌 What is Terraform State?

- Terraform uses a state file (terraform.tfstate) to keep track of the resources it manages.
- By default, this state file is stored locally in your project directory.
- For team collaboration or better reliability, it’s recommended to store the state remotely, such as in an Amazon S3 bucket.

## 📂 File Structure
```
├── main.tf   # Terraform configuration (provider, EC2, backend)
```

## ⚙️ Project Setup
### 1. Provider Configuration
```hcl
provider "aws" {
  region = "us-east-1"
}
```
This sets AWS as the provider and specifies the region (us-east-1).

### 2. EC2 Instance Resource
```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t2.micro"

  tags = {
    Name = "myec2"
  }
}
```
This creates a t2.micro EC2 instance using the specified AMI.
  - **`ami`**: Amazon Machine Image ID (here it’s Amazon Linux/Ubuntu depending on AMI).
  - **`instance_type`**: Instance size (free-tier eligible).
  - **`tags`**: Adds a name tag for easier identification.
### 3. Remote State Backend (S3)
```hcl
terraform {
  backend "s3" {
    bucket = "mys3-rajesh"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```
This configures Terraform to store the state file in an S3 bucket:
  - **`bucket`**: Name of your S3 bucket (mys3-bcuket).
  - **`key`**: Path inside the bucket where the state file will be stored (terraform.tfstate).
  - **`region`**: AWS region where the bucket is located.

✅ Now, Terraform operations (plan, apply, destroy) will update the state in S3, not locally.

## 🚀 How to Use
#### Step 1: Create S3 Bucket
Manually create an S3 bucket in AWS (or using AWS CLI):
```bash
aws s3 mb s3://mys3-rajesh --region us-east-1
```
#### Step 2: Initialize Terraform
Run:
```bash
terraform init
```
This will:
  - Download provider plugins.
  - Configure the S3 backend.
#### Step 3: Plan Infrastructure
```bash
terraform plan
```
Shows what resources will be created.
#### Step 4: Apply Infrastructure
```bash
terraform apply
```
Creates the EC2 instance and stores the state in S3.

#### Step 5: Verify State in S3
- Go to your AWS Console → S3 → mys3-rajesh bucket.
- You’ll see a file named terraform.tfstate.


✅ Benefits of Remote State in S3
  - Centralized state management (useful for teams).
  - Prevents accidental local state file deletion.
  - Enables state locking when combined with DynamoDB (to avoid race conditions).





