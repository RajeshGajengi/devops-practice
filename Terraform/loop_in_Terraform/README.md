# Terraform Loops: `count`, `for_each`, and `for`

Terraform provides different looping constructs to efficiently manage resources without duplicating code.
This allows you to dynamically create multiple resources or transform data structures.


## 1️⃣ count:
### Definition
- The `count` meta-argument allows you to create multiple instances of a resource by simply specifying how many times it should be created.
### Why Useful
- Best for when you just need N copies of the same resource.
- Index-based creation (`count.index`) makes it easy to name or reference resources.

### Use Case
- Deploying a fixed number of EC2 instances.
- Creating multiple identical resources like security groups, subnets, etc.

### Example
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myec2" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  count         = 3

  tags = {
    Name = "EC2-${count.index}"
  }
}

```
This creates 3 EC2 instances named `EC2-0`, `EC2-1`, and `EC2-2`.

## 2️⃣ for_each
### Definition
The `for_each` meta-argument lets you create resources for every element in a collection (map, set, or list).

### Why Useful
- More flexible than `count`.
- Lets you manage resources by key-value pairs (map) or unique values (set).
- Resources are identified by their keys, not indexes (safer for changes).

### Use Cases
- Creating EC2 instances from a map of AMIs.
- Deploying multiple resources where each has unique attributes (e.g., tagging with different names).

### Example 1: With Map (Key-Value)
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myec2" {
  for_each      = var.ami_ids
  ami           = each.value
  instance_type = "t2.micro"

  tags = {
    Name = each.key
  }
}

variable "ami_ids" {
  type = map(string)
  default = {
    "ubuntu"  = "ami-0360c520857e3138f"
    "linux-1" = "ami-00ca32bbc84273381"
    "linux-2" = "ami-0a232144cf20a27a5"
  }
}
```
This creates 3 EC2 instances named `ubuntu`, `linux-1`, and `linux-2`.

### Example 2: With List (Converted to Set)
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myec2" {
  for_each      = toset(var.ami_ids)
  ami           = each.value
  instance_type = "t2.micro"

  tags = {
    Name = each.key
  }
}

variable "ami_ids" {
  type = list(string)
  default = [
    "ami-0360c520857e3138f",
    "ami-00ca32bbc84273381",
    "ami-0a232144cf20a27a5"
  ]
}

```
Each element in the list becomes a unique instance.

## 3️⃣ for Expressions
### Definition
- for expressions allow you to transform or filter collections (list, map, set) into new ones.
- Often used in outputs or to create derived values.

### Why Useful
- Clean way to collect attributes (like public IPs of instances).
- Can build lists or maps dynamically.
- Helps in restructuring or filtering data.

### Use Cases
- Getting all public IPs of EC2 instances.
- Creating a map of instance IDs → IPs.
- Filtering values from variables.

### Example 1: List of Public IPs
```hcl
output "instance_public_ips" {
  value       = [for instance in aws_instance.myec2 : instance.public_ip]
  description = "List of public IP addresses of the instances."
}
```
Returns something like:
```
["3.85.12.101", "54.234.77.22", "18.207.13.45"]
```

### Example 2: Map of Instance ID → Public IP
```hcl
output "instance_public_ips" {
  value       = {for instance in aws_instance.myec2 : instance.id => instance.public_ip}
  description = "List of instance IDs mapped to their public IPs."
}
```
Returns something like:
```
{
  "i-0abcd12345" = "3.85.12.101"
  "i-0efgh67890" = "54.234.77.22"
  "i-0ijkl98765" = "18.207.13.45"
}
```

## Quick Comparison
| Loop Type     | Works On       | Best For                              | Example                         |
| ------------- | -------------- | ------------------------------------- | ------------------------------- |
| **count**     | Number         | Fixed number of identical resources   | `count = 3`                     |
| **for\_each** | Map, Set, List | Resources with unique attributes      | Deploy EC2s with different AMIs |
| **for**       | List, Map, Set | Transforming or filtering collections | Collect instance IPs            |


## Summary
- Use count when you know how many identical resources you need.
- Use for_each when creating resources from a map or set (safer and more descriptive).
- Use for expressions when you need to transform or extract data.
