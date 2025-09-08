terraform {
    backend "s3" {
        bucket         = "mys3-rajesh"
        key            = "terraform.tfstate"
        region         = "us-east-1"
 
    }
}