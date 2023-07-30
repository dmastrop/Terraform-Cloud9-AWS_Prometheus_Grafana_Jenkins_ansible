# https://developer.hashicorp.com/terraform/language/values/variables

variable vpc_cidr {
# this will cause a prompt at runtime
    type = string
    default = "10.124.0.0/16"
    #default = "10.123.0.0/16"
}

variable public_cidrs {
    type = string
    default = "10.124.1.0/24"
}