# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "server_ami" {
    most_recent = true
    
    owners = ["099720109477"]
    
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
    }
}



# NOTES:
# Ubuntu 20.04 LTS
# aws ec2 describe-images --image-ids ami-07655b4bbf3eb3bd0 --region us-west-1
# "OwnerId": "099720109477",
# "Name": "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-20230516",
# filter on ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server (except date so we get latest; see above)
# The above query to the API should return the AMI that we are looking for.
