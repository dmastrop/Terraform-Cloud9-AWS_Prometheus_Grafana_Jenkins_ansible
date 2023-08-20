# https://developer.hashicorp.com/terraform/language/values/variables
# NOTE that the Jenkins_development.tfvars and master.tfvars override any values in variables.tf (this file)

### NETWORKING STUFF
variable "vpc_cidr" {
  # this will cause a prompt at runtime if no default is specified
  type    = string
  default = "10.124.0.0/16"
  #default = "10.123.0.0/16"
}



#variable public_cidrs {
#    type = string
#    default = "10.124.1.0/24"
#}

# https://developer.hashicorp.com/terraform/language/meta-arguments/count
# added another cidr_block for the multiple subnets that we have in main.tf
# NOTE: we will not be using this variable anylonger as we switched to using the 
# cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index) and local.awz
# syntax to provision the subnets
#variable public_cidrs {
#    type = list(string)
#    default = ["10.124.1.0/24", "10.124.3.0/24"]
#}



# private cidr blocks
# NOTE: we will not be using this variable anylonger as we switched to using the 
# cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index) and local.awz
# syntax to provision the subnets
#variable private_cidrs {
#    type = list(string)
#    default = ["10.124.11.0/24", "10.124.13.0/24"]
#}

# NOTE: we will not be using thsee private_cidrs and public_cidrs any longer
# we will use the cidrsubnet function. See main.tf file.



### SECURITY STUFF
variable "access_ip" {
  type    = string
  default = "98.234.0.0/16"
  # NOTE an alternate sytax here. If we used this variable as  cidr_blocks = var.access_ip (NOTE: no square brackets)
  # then we would have to specify the following variable defintion here
  ## variable access_ip {
  ##    type = list(string)
  ##    default = ["98.234.0.0/16"] using the square brackets. This is because the cidr_blocks in main.tf (networking.tf) is a list so the
  # squre brackets must be present in one way or the other......
  # NOTE: I have expanded the default CIDR access block to 98.234.0.0/16 because internet outages will change the last 2 octets.
  # We had an internet outage a week ago! and I found this out....
}

variable "cloud9_ip" {
  type    = string
  default = "54.215.200.20/32"
  # note that this is an Elastic IP address manually bound to the cloud9 EC2 instance
  # we need a static ip on the Cloud9 so that we can set in ingress security group rule on the EC2 aws_instance(s)
  # to allow SSH traffic. This will permit us to SSH to the aws_instance(s)
  # the security group rule is aws_security_group_rule in networking.tf file.
  # add var.cloud9_ip to the cidr_blocks that are allowed ingress access to aws_intance(s)
}

variable "all_ips" {
  type = string
  default = 0.0.0.0/0
  # this is an all source ip address for a temporary fix for the ansible.builtin.uri issue that requires source ip of public_ips of 
  # EC2 instances to be added to run the url to the appliations. Otherwise the traffic fails with failure code -1.
  # Ideally this needs to be locked down to just the public_ips of the EC2 instances.
}





### aws_instance AND COMPUTE STUFF
variable "main_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "main_vol_size" {
  type    = number
  default = 8
  # this is the size in GiB
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
}

# using this varaible for the count on EC2 instances implementation
# we need this because count = length(local.azs) is only good for number of subnets (1 per availability zone)
# since we can have multiple EC2 instances in each subnet we need a different type of number and this is it:
variable "main_instance_count" {
  type    = number
  default = 1
}



#### SSH STUFF
# see terraform.tfvars for the actual values 
variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}




