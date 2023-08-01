# https://developer.hashicorp.com/terraform/language/values/variables

variable vpc_cidr {
# this will cause a prompt at runtime if no default is specified
    type = string
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



variable access_ip {
    type = string
    default = "98.234.0.0/16"
    # NOTE an alternate sytax here. If we used this variable as  cidr_blocks = var.access_ip (NOTE: no square brackets)
    # then we would have to specify the following variable defintion here
    ## variable access_ip {
    ##    type = list(string)
    ##    default = ["98.234.0.0/16"] using the square brackets. This is because the cidr_blocks in main.tf is a list so the
    # squre brackets must be present in one way or the other......
    # NOTE: I have expanded the default CIDR access block to 98.234.0.0/16 because internet outages will change the last 2 octets.
}



variable main_instance_type {
    type = string
    default = "t2.micro"
}



variable main_vol_size {
    type = number
    default = 8
    # this is the size in GiB
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
}

