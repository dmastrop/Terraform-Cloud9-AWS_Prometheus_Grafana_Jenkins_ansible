#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "mtc_vpc" {
# the mtc_vpc is not for aws, only for terraform
    cidr_block = "10.123.0.0/16"
    # strings must be in quotes
    enable_dns_hostnames = true
    enable_dns_support = true
    
    tags = {
        Name = "mtc_vpc"
        # aws will be aware of these tags
    }
}