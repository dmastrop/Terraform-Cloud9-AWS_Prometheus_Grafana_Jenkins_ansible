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
  # publish aws cloud9 ephemeral credentials to terraform and thus jenkins
  # jenkins will be able to apply resources to AWS
  shared_credentials_file="/home/ubuntu/.aws/credentials"
}
