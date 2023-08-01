# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "server_ami" {
    most_recent = true
    
    owners = ["099720109477"]
    
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
 resource "aws_instance" "mtc_main" {
     instance_type = var.main_instance_type
     # see the variables.tf file
     ami = data.aws_ami.server_ami.id
     # key_name = ""
     vpc_security_group_ids = [aws_security_group.mtc_sg.id]
     # this is from the networking.tf file
     subnet_id = aws_subnet.mtc_public_subnet[0].id
     # for now use the first instance index 0 but later we will put in a count
     root_block_device {
         volume_size = var.main_vol_size
         # this is a variable in variables.tf
     }
     
     tags = {
         Name = "mtc_main"
     }
 }



# NOTES:
# Ubuntu 20.04 LTS
# aws ec2 describe-images --image-ids ami-04d1dcfb793f6fa37--region us-west-1
#"OwnerId": "099720109477",
#"Name": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517",
# filter on ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server (except date so we get latest; see above)
# The above query to the API should return the AMI that we are looking for.
# actual ami is ami-0568f1c137c5db515

