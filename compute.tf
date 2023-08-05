# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
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
  count       = var.main_instance_count
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
# this resource will be used in the aws_instance resource below
# these variables below are defined in variables.tf with values in terraform.tfvars
resource "aws_key_pair" "mtc_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "mtc_main" {
  count = var.main_instance_count
  # note that this "count" definition is local to this resource only
  instance_type = var.main_instance_type
  # see the variables.tf file
  ami      = data.aws_ami.server_ami.id
  key_name = aws_key_pair.mtc_auth.id
  # this aws_key_pair is defined above. .id is the key pair name. You can also use .key_name as well
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  # this is from the networking.tf file
  #subnet_id = aws_subnet.mtc_public_subnet[0].id
  # for now use the first instance index 0 but later we will put in a count
  subnet_id = aws_subnet.mtc_public_subnet[count.index].id
  
  ## Comment out the user_data. We are integrating ansible with terraform and will not need user_data
  ## do deploy the grafana on the EC2 instances
  ## user_data = templatefile("./main-userdata.tpl", { new_hostname = "mtc_main-${random_id.mtc_compute_node_id[count.index].dec}" })
  # template file https://developer.hashicorp.com/terraform/language/functions/templatefile
  # main-userdata.tpl start grafana up on the EC2 instance that has been deployed.
  ##root_block_device {
  ##  volume_size = var.main_vol_size
    # this is a variable in variables.tf
  }

  ##tags = {
  ##  Name = "mtc_main-${random_id.mtc_compute_node_id[count.index].dec}"
    # random resource is different name from that used in networking.tf.  The use here is indexed by count.index
    # A new random number will be created based on the count.index number.  Note that if count=2 (Number of EC2 instances)
    # that the index will be 0 (subnet 0) and 1 (subnet 1). So first instance will go into subnet 0 with name random[0] 
    # and second instance into subnet 1 with name random[1]
    # if count=4 (var.main_instance_count) then index is 0,1,2,3 and these map to subnet 0, subnet 1, subnet 2, and subnet 3.  
    # Since we do not have subnet 2 and 3 this will fail. So the subnetting should be based upon the local(azs) since we have 
    # 1 subnet for each availability zone.
  ##}



  # this is a local provsioner, i.e. it is embedded in the aws_instance resource object.
  # Thus the self object can be used
  # https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
  # https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
  # this provisioner is executed locally whenever a new aws_instance is created.  the command will be run.
  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts"
    # note that single quotes around what we are passing into the aws_hosts file
    # the aws_hosts file is local on Cloud9 development instance where we are running terraform.
  }

  # https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
    # regex expression is used above
    # sed is linux. It will perform the operation on the aws_hosts file.
    # Any line beginnin with a number [0-9] will be removed  /d at the end means delete the line.
    # last is the filename that the sed operation will be performed on....
  }
}



# this is a remote provisioner
# https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
# note that unlike the local provisioner it is not embedded in the aws_instance, thus the self object will
# not work here.
# This null_resource can be applied, tainted, etc just like any other resource.

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
##resource "null_resource" "grafana_update" {
  # this needs to be run for each instance, so we need to provide the count of instances
##  count = var.main_instance_count

  # https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
##  provisioner "remote-exec" {
    # this remote provisioner will upgrade grafana, create a log and then create a log entry in the log file indicating
    # that granfana was updated.
 ##   inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I upgraded Grafana' >> upgrade.log"]
 ## }

  # this is the connection block, i.e. how we will connect to the EC2 instance to run the inline command above
  # this is included in the null_resource along with the remote-exec provisioner block above
  # https://developer.hashicorp.com/terraform/language/resources/provisioners/connection
##  connection {
##    type        = "ssh"
##    user        = "ubuntu"
##    private_key = file("/home/ubuntu/.ssh/mtckey")
    # this is the local cloud9 directory and will provide the credentials to connect to the EC2 instance.
    # note that on cloud9 we have the public private key pair that we created ssh-keygen -t rsa /home/ubuntu/.ssh
    # also note that the public key is on each EC instance per key_name = aws_key_pair.mtc_auth.id and 
    # resource "aws_key_pair" "mtc_auth" with the path defined in terraform.tfvars file key_name = "mtc_key"
    # key_name is the name for the key PAIR.
    # public_key_path = "/home/ubuntu/.ssh/mtckey.pub"   So each EC2 instance has the public key mtc_key.
##    host = aws_instance.mtc_main[count.index].public_ip
    # we cannot use the self object here for host. This remote provisioner is in a null_resource and not the 
    # aws_instance resource (the local-provisioner is in the aws_instance resource and can use the self object)
##  }
##}