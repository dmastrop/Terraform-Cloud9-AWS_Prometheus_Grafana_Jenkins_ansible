# https://developer.hashicorp.com/terraform/language/providers/requirements
# https://developer.hashicorp.com/terraform/language/providers/configuration
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# my cloud9 is on us-west-1 as well (EC instance)
provider "aws" {
  region = "us-west-1"
}
