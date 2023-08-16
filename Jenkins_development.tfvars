vpc_cidr = "10.123.0.0/16"
# use the CIDR block 10.123.0.0/16 for the development deployment to AWS
# production (master) will use 10.124.0.0/16 CIDR block

key_name = "mtc_key"
# key_name is the name for the key PAIR.
public_key_path = "/home/ubuntu/.ssh/mtckey.pub"
# mtckey.pub is the public key.  (The private key is mtckey)

# NOTES: note the key_name and the public_key_path are used in compute.tf resource "aws_key_pair" "mtc_auth"
# which also assigns key_name = aws_key_pair.mtc_auth.id (or .key_name) to the aws_instance