#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "mtc_vpc" {
  # the mtc_vpc is not for aws, only for terraform
  # add cidr_block variable definition instead of ip address
  cidr_block = var.vpc_cidr
  #cidr_block = "10.123.0.0/16"
  # strings must be in quotes
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mtc_vpc"
    # aws will be aware of these tags
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id
  # need to pull the vpc_id from the vpc resource defined above
  # can see this on State in terraform cloud9
  # OR can see this on 
  # https://us-west-1.console.aws.amazon.com/cloud9/ide/04bc094b80d049aabfd8bb6ba529aac9?region=us-west-1#
  # the actual vpc_id is "vpc-053f4eb691ae6f7ae" but that does not matter
  # because we can read it from the state (above)
  
  tags = {
    Name = "mtc_igw"
  }
}