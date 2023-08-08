This is the dev_terraform_FULL_ansible  branch 
The development_terraform_ansible_intro branch terminates and is frozen after ansible basic playbook
which deploys grafana to local Cloud9 EC2 instance.

After that, the dev_terraform_FULL_ansible branch terminates and is frozen after the prometheus deployment has been added to the existing
grafana blocks in the yaml file. THe yaml file has been renamed from grafana to main-playbook.yml and has a working prometheus deployment per
the notes below. (Both now to aws_instance EC2)

****NOTE: the ansible prometheus is manually deployed in this dev_terraform_FULL_ansible branch using:
ansible-playbook -i aws_hosts --private-key /home/ubuntu/.ssh/mtckey playbooks/main-playbook.yml
as this is development code. (granfana will be re-deployed as well in this playbook)

The grafana deployment on ansible has  been integrated with terraform (Compute.tf) and now deploys to EC2 aws_instance

The master will continue on the dev_terraform_FULL_ansible  and integrate the setup with Jenkins, pipelines, etc.....



******This branch (dev_terraform_FULL_ansible) includes the following which is not included in the first branch (development_terraform_ansible_intro)***********

Basic issue encountered when creating a null_resource to make the call to the granfana.yml playbook (renamed main-playbook.yml 
when prometheus blocks added)

The issue is that the null_resource at the bottom of compute.tf, is run BEFORE all the 
aws_instances or aws_instance is able to take connections. The EC2 instances have to be both 
up and running and able to take connections for grafana ansible playbook to be executed.

Introduced this line to the command below in compute.tf aws_instances block:
command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok  --instance-ids ${self.id} --region us-west-1"
(the second argument after the &&)
Once this was added the null_resource below was executed fine and granfana is installed.
 command = "ansible-playbook -i aws_hosts --key-file /home/ubuntu/.ssh/mtckey playbooks/grafana.yml"
 
 Next coding involved scaffolding the main-playbook.yml (formerly granfana.yml) for installtion of 
 prometheus on the remote EC2 node. This installation is more involved than granfana and requires
 several additional ansible blocks in the yaml file.
 
 CREATING another branch dev_terraform_FULL_ansible here and freezing this branch.
 The ansible playbook installs both grafana and prometheus.  
 The prometheus scrape is tested only locally on the EC2 node itself for now.
 In master branch we will develop this further using prometheus to fuller potential.  We will integrate this project
 with jenkins....
 
 
 This branch (dev_terraform_FULL_ansible) will be frozen at this point.



==========================


The information below is from the development_terraform_ansible_intro README.  All of the code
below is included in this branch  (dev_terraform_FULL_ansible_ and the master branch as well.  The file structure has been modified heavily and 
the functionality of the development code below in this branch vs. the other branches awill not work precisely the same,
hence the need for branching. For baisic terraform IaC and basic ansibile with grafana installation (local Cloud9) use the development branch below
development_terraform_ansible_intro.  For ansible integration wth terraform EC2 instance for granfana and prometheus, use the dev_terraform_FULL_ansible
branch.  For latest use the master branch.

=====================================================================


This branch development_terraform_ansible_intro has the basic terraform IaC with the remote provisioner
The terrafom deploys an aws_instance to AWS (EC2)
The remote provisioner has issues. Granfana is not deployed as an application when it initally runs
after terraform apply so we have to taint the null_resource that has the remote provisioner code
terraform taint null_resource.grafana_update[0]
Once we do this we have to terraform apply again.  Since grafana application is up and running at this point
the remote provisioner can actually do its job: upgrade the grafana image to the latest

This is an inherent problem with provisioners when used with terraform. There is no state tracking by
terraform with provisioners and one can hit these types of issues.....

This is where ansible comes in.  This branch includes the basic development ansible playbook to deploy 
grafana ON THE LOCAL CLOUD9 EC2 instance (not the aws_instance that terraform deploys)
This is just development of the ansible base code

We will work on integrating this ansible code into the terraform IaC AWS EC2 scripts in the **main** branch.

*****This branch will be frozen with the basic ansible code deployment to the Cloud9 EC2 instance*****