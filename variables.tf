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
variable public_cidrs {
    type = list(string)
    default = ["10.124.1.0/24", "10.124.3.0/24"]
}

# private cidr blocks
variable private_cidrs {
    type = list(string)
    default = ["10.124.11.0/24", "10.124.13.0/24"]
}