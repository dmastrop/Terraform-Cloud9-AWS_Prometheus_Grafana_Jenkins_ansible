locals {
  azs = data.aws_availability_zones.available.names
}
# this is the locals definition for the availability_zones in the private and public subnet resources defined below
# https://developer.hashicorp.com/terraform/language/values/locals



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones
# can optionally apply filters
data "aws_availability_zones" "available" {}



# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
# use interpolation to concatenate this random_id to the tags used below
# note that random is a different provider from aws and will need to add this executable will be added
# to the .terraform folder when we run terraform init for it.
# random produces a random byte_length number that can be used througout the script
# the name should make it unique for its intended use.
resource "random_id" "random" {
  byte_length = 2
}



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
    #Name = "mtc_vpc"
    Name = "mtc_vpc-${random_id.random.dec}"
    # use the .dec:: "dec (String) The generated id presented in non-padded decimal digits.""
    # aws will be aware of these tags
  }

  lifecycle {
    create_before_destroy = true
    # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
    # this will create a new vpc (if required; for example default in variables.tf changed)
    # BEFORE destroying the old one
    # this will allow the igw to gracefully detach (igw will not be destroyed)
    # from the old vpc and re-attach to the new vpc
    # then the old vpc can be destroyed after this process is complete.
    # without this terraform will not allow the old vpc to be first destroyed because the igw would have no where
    # to re-attach without the new vpc being created. Thus it is imperative that the new vpc be created BEFORE 
    # destroying the old vpc so that the igw is not "orphaned";
    # otherwise the apply will hang and terraform will crash....
    # the PROPER order is first create the new vpc (this lifecycle), then re-attach the existing igw to this new VPC
    # then destroy the old VPC.
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
    #Name = "mtc_igw"
    Name = "mtc_igw-${random_id.random.dec}"
    # see notes above for vpc tag regarding this interpoloation with random.id
  }
}



# aws_route is seprate resource which we will use here
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
# aws_route_table is for inline and not used here
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# the aws_route_table will just have the vpc. The routes will be separately defined in the 
# aws_route resource (not inline in aws_route table)
resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "mtc-public"
  }
}



resource "aws_route" "default_route" {
  route_table_id = aws_route_table.mtc_public_rt.id
  # this is the route table id of the above
  destination_cidr_block = "0.0.0.0/0"
  # this will forward all traffic for outside world out the igw
  gateway_id = aws_internet_gateway.mtc_internet_gateway.id
  # this is the igw defined above.
}



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table
resource "aws_default_route_table" "mtc_private_rt" {
  default_route_table_id = aws_vpc.mtc_vpc.default_route_table_id

  tags = {
    Name = "mtc_private"
  }
}





# This is the multiple count subnet resource definition. Note that another cidr_block has been added in 
# variables.tf file.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# https://developer.hashicorp.com/terraform/language/meta-arguments/count
resource "aws_subnet" "mtc_public_subnet" {
  #count =2
  # this is part of the count meta-argument so that we can add multiple subnets
  # 2 subnets, one for each availability_zone
  # It is better to use the length function on the variables.tf var.public_cidrs variable so that this relationship 
  # is automatically provisioned as the number of cidrs in variables.tf increases or decreases.  The subnets
  # should always be provisioned in accordance with the number of cidr_blocks in the most general scenario....
  # https://developer.hashicorp.com/terraform/language/functions/length
  ## count = length(var.public_cidrs)

  # we will not be using the var.public_cidrs any longer with the new definitions below so change count definition
  # NOTE: This assumes we have one subnet per availability_zone
  count = length(local.azs)

  vpc_id = aws_vpc.mtc_vpc.id

  ## cidr_block = var.public_cidrs[count.index]
  # this variable needs to be defined in variables.tf
  # reference the multiple cidr_blocks that we have now with the [count.index]
  # the first subnet that is created will have index of 0 and the second subnet will have an index of 1
  # these will index into the cidr_blocks in variables.tf accordingly.

  # redefine cidr_block with indexing. For pubic use the count.index
  # for example, with 2 cidr_blocks, index 0 and 1. For 3 cidr_blocks, index 0,1,2
  # for private subnet use length(local.azs) + count.index
  # so for 2 cidr blocks, 2 and 3. For 3 cidr_blocks, 3,4,5
  # NOTE: there is no overlap of private and public subnets
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)

  map_public_ip_on_launch = true
  # Specify true to indicate that instances launched into the subnet should be assigned a public IP address. 

  #availability_zone = data.aws_availability_zones.available.names[0]
  ## availability_zone = data.aws_availability_zones.available.names[count.index]
  # terraform console, we tested this out. There are currently 2 of them available in us-west-1
  # add [count.index] here as well so that we can assign the successive availability_zone to the successive
  # subnet that is being created.
  # Next comment out the above availability_zone definition and use locals to simplify it.
  # https://developer.hashicorp.com/terraform/language/values/locals
  # do the same in private subnet below
  availability_zone = local.azs[count.index]

  # modify the subnet tag so that it corresponds to the count.index +1 (count.index starts at 0 so the tag will
  # start at 1). Use the following interpoloation syntax.
  tags = {
    Name = "mtc-public-${count.index + 1}"
  }
}

# This is the original subnet resource (just a single subnet)  
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
#resource "aws_subnet" "mtc_public_subnet" {
#  vpc_id = aws_vpc.mtc_vpc.id
#  cidr_block = var.public_cidrs
# this variable needs to be defined in variables.tf
#  map_public_ip_on_launch = true
# Specify true to indicate that instances launched into the subnet should be assigned a public IP address. 
#  availability_zone = data.aws_availability_zones.available.names[0]
# terraform console, we tested this out. There are currently 2 of them available in us-west-1

# for multiple subnets it is inefficient to add more resourcce blocks (below)
# it is better to use the count meta-argument as shown above
#resource "aws_subnet" "mtc_public_subnet2" {
#  vpc_id = aws_vpc.mtc_vpc.id
#  cidr_block = var.public_cidrs
# this variable needs to be defined in variables.tf
#  map_public_ip_on_launch = true
# Specify true to indicate that instances launched into the subnet should be assigned a public IP address. 
#  availability_zone = data.aws_availability_zones.available.names[0]
# terraform console, we tested this out

#  tags = {
#    Name = "mtc-public"
#  }






# private subnets (DIY)
# NOTE: all private subnets will default to using the default_route_table specified above
# So no aws_route_table_association needs to be done for private subnets
resource "aws_subnet" "mtc_private_subnet" {
  #count =2
  # this is part of the count meta-argument so that we can add multiple subnets
  # 2 subnets, one for each availability_zone
  # It is better to use the length function on the variables.tf var.public_cidrs variable so that this relationship 
  # is automatically provisioned as the number of cidrs in variables.tf increases or decreases.  The subnets
  # should always be provisioned in accordance with the number of cidr_blocks in the most general scenario....
  # https://developer.hashicorp.com/terraform/language/functions/length
  ## count = length(var.private_cidrs)

  # we will not be using the var.public_cidrs any longer with the new definitions below so change count definition
  # NOTE: This assumes we have one subnet per availability_zone
  count = length(local.azs)

  vpc_id = aws_vpc.mtc_vpc.id

  ## cidr_block = var.private_cidrs[count.index]
  # this variable needs to be defined in variables.tf
  # reference the multiple cidr_blocks that we have now with the [count.index]
  # the first subnet that is created will have index of 0 and the second subnet will have an index of 1
  # these will index into the cidr_blocks in variables.tf accordingly.

  # redefine cidr_block with indexing. For pubic use the count.index
  # for example, with 2 cidr_blocks, index 0 and 1. For 3 cidr_blocks, index 0,1,2
  # for private subnet use length(local.azs) + count.index
  # so for 2 cidr blocks, 2 and 3. For 3 cidr_blocks, 3,4,5
  # NOTE: there is no overlap of private and public subnets
  cidr_block = cidrsubnet(var.vpc_cidr, 8, length(local.azs) + count.index)

  map_public_ip_on_launch = false
  # Specify true to indicate that instances launched into the subnet should be assigned a public IP address. 
  # this is not required on the private subnet. We do not want the instances to have public IP addresses

  #availability_zone = data.aws_availability_zones.available.names[0]
  ## availability_zone = data.aws_availability_zones.available.names[count.index]
  # terraform console, we tested this out. There are currently 2 of them available in us-west-1
  # add [count.index] here as well so that we can assign the successive availability_zone to the successive
  # subnet that is being created.
  # Next comment out the above availability_zone definition and use locals to simplify it.
  # https://developer.hashicorp.com/terraform/language/values/locals
  # do the same in public subnet above
  availability_zone = local.azs[count.index]

  # modify the subnet tag so that it corresponds to the count.index +1 (count.index starts at 0 so the tag will
  # start at 1). Use the following interpoloation syntax.
  tags = {
    Name = "mtc-private-${count.index + 1}"
  }
}



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "mtc_public_assoc" {
  count = length(local.azs)
  # the syntax below can be verified using terraform console, for example
  # > aws_subnet.mtc_public_subnet[0].id
  # "subnet-0bcc23363d47f4d76"
  # splat syntax follows; note in this simple case count.index is 0 and 1:
  ##subnet_id = aws_subnet.mtc_public_subnet.*.id[count.index]

  # the above splat syntax accomplishes the same thing as this below:
  subnet_id      = aws_subnet.mtc_public_subnet[count.index].id
  route_table_id = aws_route_table.mtc_public_rt.id
}
# NOTE: all private subnets will default to using the default_route_table specified above
# So no aws_route_table_association needs to be done for private subnets



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mtc_sg" {
  name        = "public_sg"
  description = "Security gorup for public instances"
  vpc_id      = aws_vpc.mtc_vpc.id
}



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ingress_all" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "-1"
  # this means all protocols: icmp, tcp, udp, etc.....
  
  #cidr_blocks = [var.access_ip, var.cloud9_ip]
  cidr_blocks = [var.access_ip, var.cloud9_ip, [for i in aws_instance.mtc_main[*]: i.public_ip]]
  
  
  # note that cidr_blocks is a list so need the []
  # the access_ip will be my PC address. I am using an
  # expanded CIDR block of 98.234.0.0/16
  # the var.cloud9_ip is a static Elastic IP address.
  security_group_id = aws_security_group.mtc_sg.id
}



resource "aws_security_group_rule" "egress_all" {
  type      = "egress"
  from_port = 0
  to_port   = 65535
  protocol  = "-1"
  # this means all protocols: icmp, tcp, udp, etc.....
  cidr_blocks = ["0.0.0.0/0"]
  # note that cidr_blocks is a list so need the []
  # 0.0.0.0/0 is for all destination addresses outbound. 
  security_group_id = aws_security_group.mtc_sg.id
}


