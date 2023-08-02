# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "server_ami" {
    most_recent = true
    
    owners = ["099720109477"]
    
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}






# this is the single count EC2 resource definition. See below for multiple count EC2 resource definition
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
## resource "aws_instance" "mtc_main" {
 ##    instance_type = var.main_instance_type
     # see the variables.tf file
##     ami = data.aws_ami.server_ami.id
     # key_name = ""
##     vpc_security_group_ids = [aws_security_group.mtc_sg.id]
     # this is from the networking.tf file
##     subnet_id = aws_subnet.mtc_public_subnet[0].id
     # for now use the first instance index 0 but later we will put in a count
 ##    root_block_device {
 ##        volume_size = var.main_vol_size
         # this is a variable in variables.tf
 ##    }
     
##     tags = {
##         Name = "mtc_main"
##     }
## }



# NOTES:
# Ubuntu 20.04 LTS
# aws ec2 describe-images --image-ids ami-04d1dcfb793f6fa37 --region us-west-1
#"OwnerId": "099720109477",
#"Name": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517",
# filter on ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server (except date so we get latest; see above)
# The above query to the API should return the AMI that we are looking for.
# actual ami is ami-0568f1c137c5db515   This ami is the latest version of 20.04.



# CONVERT the EC2 instance resource above to a counted EC2 instance resource
# Note that the number of subnets is based on the nunber of availability_zones, but count = length(local.azs) cannot be used here
# since we can have multiple EC2 instances in each subnet. We need to use the var.main_instance_count

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
# use interpolation to concatenate this random_id to the tags used below
# note that random is a different provider from aws and will need to add this executable will be added
# to the .terraform folder when we run terraform init for it.
# random produces a random byte_length number that can be used througout the script
# the name shoud make it unique for its intended use.
resource "random_id" "mtc_compute_node_id" {
  byte_length = 2
  count = var.main_instance_count
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
 resource "aws_instance" "mtc_main" {
     count = var.main_instance_count
     # note that this "count" definition is local to this resource only
     instance_type = var.main_instance_type
     # see the variables.tf file
     ami = data.aws_ami.server_ami.id
     # key_name = ""
     vpc_security_group_ids = [aws_security_group.mtc_sg.id]
     # this is from the networking.tf file
     #subnet_id = aws_subnet.mtc_public_subnet[0].id
     # for now use the first instance index 0 but later we will put in a count
     subnet_id = aws_subnet.mtc_public_subnet[count.index].id
     root_block_device {
         volume_size = var.main_vol_size
         # this is a variable in variables.tf
     }
     
     tags = {
         Name = "mtc_main-${random_id.mtc_compute_node_id[count.index].dec}"
         # random resource is different name from that used in networking.tf.  The use here is indexed by count.index
         # A new random number will be created based on the count.index number.  Note that if count=2 (Number of EC2 instances)
         # that the index will be 0 (subnet 0) and 1 (subnet 1). So first instance will go into subnet 0 with name random[0] 
         # and second instance into subnet 1 with name random[1]
         # if count=4 (var.main_instance_count) then index is 0,1,2,3 and these map to subnet 0, subnet 1, subnet 2, and subnet 3.  
         # Since we do not have subnet 2 and 3 this will fail. So the subnetting should be based upon the local(azs) since we have 
         # 1 subnet for each availability zone.
     }
 }