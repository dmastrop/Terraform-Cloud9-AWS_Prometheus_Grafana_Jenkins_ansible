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
grafana ON THE LOCAL CLOUD9 EC2 instance (not the aws_instance that terraform deploys). This is in the /playbooks/granfana.yml
Note that need to modify the AWS security group access list to add my PC ip address or a CIDR block
that covers it so we can hit the granfana instance from the browser.

There is also a grafana-destroy.yml created to teardown the grafana application that is running on
the Cloud9 local instance.   NOTE: must first stop grafana-service BEFORE you can remove the installation. 
It will NOT get removed if the service is not explicitly stopped

This is just development of the ansible base code

We will work on integrating this ansible code into the terraform IaC AWS EC2 scripts in the **main** branch.

*****This branch will be frozen with the basic ansible code deployment to the Cloud9 EC2 instance*****

The latest commits for this branch are listed below

ceb344ada2d6ef96432036e958207f2232ed7e73 (HEAD -> development_terraform_ansible_intro, origin/master) added a grafana-destroy.yml file with relevant changes in the yaml syntax to do the effective destroy of the granfana.yml. NOTE: must first stop grafana-service BEFORE you can remove the installation. It will NOT get removed if the service is not explicitly stoppedgit add .
fe9b37691f38205ed58cc27990191080ff2e136e added ansible.builtin.apt to update apt cache and install Grafana using ansible playbook.  Next use ansible.builtin.systemd to ensure granfana-service is started and that it is enabled (on bootup)
2727b2436569090b5e4afed975f83ad38d053665 added ansible.builtin.apt_key task to download apt key and then added grafana repo to the sources.list with ansible.builtin.apt_repository
ab0f73e5d8927acd42ee0f6df76bbb8307add629 first draft of scaffolding for the granfana.yml ansible playbook
d58c9ddceaba52ad75857d4e2f8c43f11ee8548d  large commit of the null_resource for the remote-provisioner. This remote provisioner uses the cloud9 ssh credentials and public key on EC2 instances to SSH in and update grafana and update a log file as well. The null_resource has a connection block for the ssh and a provisioner block for the remote-provisioner. Make sure to run terraform init as null_resource is a new providergit add .
fdfb231c23f7a242e58e6c4314f8b7390ca76dc3 add variable var.cloud9_ip to the variables.tf and use this in aws_security_group_rule ingress (in networking.tf)  cidr_blocks to allow cloud9 ingress.
f84d8acf70b65d1f6566a9fdbb31d0239f5d2322 variables.tf some restructuring
e983d49a71f17280d9a826dbd19f9919902c712a added user_data to compute.tf, added main-userdata.tpl to provision the Grafana on the EC2 instance, set new_hostname, configure local provisioner to get public ip address and pipe to aws_hosts file on Cloud9 for ssh usage, configure local-exec destroy provisioner to clean aws_hosts upon EC2 termination
33c46d6b64b992455c8958b568bcc391a2e771fa added aws_key_pair resource and key_name to aws_instance and added varibles.tf and terraform.tfvars to support this. This is for ssh keys added to EC instance. Our keys were generated locally on Cloud9 prior using ssh-keygen -t rsa






         ___        ______     ____ _                 _  ___  
        / \ \      / / ___|   / ___| | ___  _   _  __| |/ _ \ 
       / _ \ \ /\ / /\___ \  | |   | |/ _ \| | | |/ _` | (_) |
      / ___ \ V  V /  ___) | | |___| | (_) | |_| | (_| |\__, |
     /_/   \_\_/\_/  |____/   \____|_|\___/ \__,_|\__,_|  /_/ 
 ----------------------------------------------------------------- 


Hi there! Welcome to AWS Cloud9!

To get started, create some files, play with the terminal,
or visit https://docs.aws.amazon.com/console/cloud9/ for our documentation.

Happy coding!
