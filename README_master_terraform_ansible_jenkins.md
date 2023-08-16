This is the master branch and has latest and complete development of the code for this project.

The development_terraform_ansible_intro branch terminates and is frozen after ansible basic playbook
which deploys grafana to local Cloud9 EC2 instance.

The next branch dev_terraform_FULL_ansible terminates and is frozen with ansible EC2 prometheous and granfana deployments
NOTE: the ansible prometheus is manually deployed in this dev_terraform_FULL_ansible branch using:
ansible-playbook -i aws_hosts --private-key /home/ubuntu/.ssh/mtckey playbooks/main-playbook.yml
as this is development code.  Added automatic deployment of prometheous to compute.tf via main-playbook.yml invocation.


Will also add the call from compute.tf to main-playbook.yml in master branch.


The branching is 
development_terraform_ansible_intro: IaC terraform with basic ansible playbook granfana.yml for grafana deployment

dev_terraform_FULL_ansible: builds on development_terraform_ansible_intro with the Iac terraform and with ansible playbook depoloyments to 
aws_instances (EC2) for granfana and prometheous.

master branch has all of the above and latest development code


This master will continue off of the dev_terraform_FULL_ansible and integrate all of the above with jenkins and pipelines, etc......

*******New code in master branch:
- jenkins-playbook.yml is outside of terraform state (not added to compute.tf). This deploys jenkins to the Cloud9 instance
- integration of github and terraform with jenkins 
- Github API app id and credentials added to Jenkins so that Jenkins has access to the github repo for this project
- AWS credentials to jenkins via terraform providers.tf file:  shared_credentials_files=["/home/ubuntu/.aws/credentials"]
- Terraform cloud state access to jenkins via /home/ubuntu/.terrafrom.d/credentials.tfrc.json copied into secret file on Jenkins 
Web console import
- ******Jenkins pipeline via Jenkins WEB UI (called a freestyle project in Jenkins template):********* 
- First add the github repo (https link) and the identification material for the github API app (id, etc)
- add relevant Build steps. Use execute shell.
- This secret file will be used on a pipeline when introducing terraform commands so that Jenkins has access to update the terraform
cloud state. This is done in the Build environment section under the Bindings.
- Comment out the null_resource in compute.tf. We are no longer deploying via ansible through terraform. We will deploy the playbook 
via Jenkins.
_ NOTE: should not run master branch from Cloud9 terminal main workspace. If required to run from Cloud9 terminal run from 
/var/lib/jenkins/workspace directory. This is particularly useful if need to terrform destroy the setup during troublehsooting.
- Add the AWS_SHARED_CREDENTIALS_FILE to the terraform apply third build step.  This step has the terraform apply 
- Next, integrate the ansible null_resource into Jenkins by adding another build step to invoke an ansible playbook
- Very similar to running ansible-playbook -i aws_hosts --private-key /home/ubuntu/.ssh/mtckey playbooks/main-playbook.yml in the terminal
- Thus Jenkins must have the private ssh key and be told where the playbook is and where the inventory is (aws_hosts file)
- This WEB UI run of Jenkins is successful.
- 
-*****Now adapt the above to a Jenkinsfile (using a Multibranch pipeline template in Jenkins)********
-Before running Jenkinsfile with terraform commands need to ensure that credentials are in place
-Also need to ensure that webhook URL is specified in the Developer settings of Github and repository settings also have the webhook
URL, so that Github can connect to Jenkins.  The webhook URL is http://54.215.200.20:8080/github-webhook in Developer settings
and http://54.215.200.20:8080/github-webhook/ (note trailing slash) in the repository settings.
-There is a problem with github connecting to the Jenkins webhook URL. The access list rule must be added in AWS EC2 to
allow the traffic through. The Cloud9/Jenkins EC2 instance had been locked down for only PC to EC2 communication prior to this.
- Next, to run terraform basic commands need to add the TF_CLI_CONFIG_FILE ENV variable to the Jenknsfile
Use the credentials function to reference this token that has already been added to Jenkins configuration as
TF_CLI_CONFIG_FILE = credentials('terrform-cloud-credentials-for-jenkins').  NOTE terrform is misspelled here.
-Add the TF_IN_AUTOMATION ENV variable as well to the top of the pipeline.
-Run the pipleline with a terraform plan
-comment out aws EC2 wait in: command = "printf '\n${self.public_ip}' >> aws_hosts && 
aws ec2 wait instance-status-ok  --instance-ids ${self.id} --region us-west-1" because have not added AWS credentials yet
-Add Apply and Destroy stages to the pipeline and run this.
-Add the ec2 wait outside of terraform compute.tf in the Jenkinsfile and add the AWS_SHARED_CREDENTIALS_FILE ENV var 
-The EC2 wait stage will be added in between the Apply and Destroy.
-Next integrate the Ansible stage into the Jenkinsfile.  Use the ansiblePlaybook plugin
https://plugins.jenkins.io/ansible/
ansiblePlaybook(credentialsId: 'EC2-SSH-key', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
-Add a Destroy stage and add Validate Apply, Validate Ansible and Validate Destroy stages to pause the script for user Abort
or Proceed.
-Add a Post section to Jenkinsfile for destroy if there is an outright Jenkins script failure in Apply, etc.... This way
we no longer have to clean up the infra with /var/log/jenkins/workspace destroy for script failures....
-Add production and development tfvars files.











******In addition to development_terraform_ansible_intro base, Other  development code dev_terraform_FULL_ansible includes the following:***********

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
 
 CREATING another branch dev_terraform_FULL_ansible here and freezing the branch.
 The ansible playbook installs both grafana and prometheus.  
 The prometheus scrape is tested only locally on the EC2 node itself for now.
 In main we will develop this further using prometheus to fuller potential.  We will integrate this project
 with jenkins....
 
 
 



==========================


The information below is from the development_terraform_ansible_intro README.  All of the code
below is included in this master branch as well.  The file structure has been modified heavily and 
the functionality of the development code below in this master branch will not work precisely the same,
hence the need for branching. For baisic terraform IaC and basic ansibile with grafana installation use the development branch below
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