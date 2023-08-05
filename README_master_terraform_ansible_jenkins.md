This is the master branch and has latest and complete development of the code for this project.
The development_terraform_ansible_intro branch terminates and is frozen after ansible basic playbook
which deploys grafana to local Cloud9 EC2 instance.

This master will continue on the development_terraform_ansible_intro and start with integrating the 
basic ansible playbook with the terraform IaC that deploys EC2 aws_instances to EC2.

******Other master development code includes the following:





The information below is from the development_terraform_ansible_intro README.  All of the code
below is included in this master branch as well.  The file structure has been modified heavily and 
the functionality of the development code below in this master branch will not work precisely the same,
hence the need for branching. For baisic terraform IaC and basic ansibile use the development branch below
development_terraform_ansible_intro

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