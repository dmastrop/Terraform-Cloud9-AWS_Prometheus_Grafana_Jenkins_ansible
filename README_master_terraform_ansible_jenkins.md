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

*******New code in master branch:*******
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


-*****Now adapt the above to a Jenkinsfile (using a Multibranch pipeline template in Jenkins)********
- Before running Jenkinsfile with terraform commands need to ensure that credentials are in place
- Also need to ensure that webhook URL is specified in the Developer settings of Github and repository settings also have the webhook
URL, so that Github can connect to Jenkins.  The webhook URL is http://54.215.200.20:8080/github-webhook in Developer settings
and http://54.215.200.20:8080/github-webhook/ (note trailing slash) in the repository settings.
- There is a problem with github connecting to the Jenkins webhook URL. The access list rule must be added in AWS EC2 to
allow the traffic through. The Cloud9/Jenkins EC2 instance had been locked down for only PC to EC2 communication prior to this.
- Next, to run terraform basic commands need to add the TF_CLI_CONFIG_FILE ENV variable to the Jenknsfile
Use the credentials function to reference this token that has already been added to Jenkins configuration as
TF_CLI_CONFIG_FILE = credentials('terrform-cloud-credentials-for-jenkins').  NOTE terrform is misspelled here.
- Add the TF_IN_AUTOMATION ENV variable as well to the top of the pipeline.
- Run the pipleline with a terraform plan
- comment out aws EC2 wait in: command = "printf '\n${self.public_ip}' >> aws_hosts && 
aws ec2 wait instance-status-ok  --instance-ids ${self.id} --region us-west-1" because have not added AWS credentials yet
- Add Apply and Destroy stages to the pipeline and run this.
- Add the ec2 wait outside of terraform compute.tf in the Jenkinsfile and add the AWS_SHARED_CREDENTIALS_FILE ENV var 
- The EC2 wait stage will be added in between the Apply and Destroy.
- Next integrate the Ansible stage into the Jenkinsfile.  Use the ansiblePlaybook plugin
https://plugins.jenkins.io/ansible/
ansiblePlaybook(credentialsId: 'EC2-SSH-key', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
- Add a Destroy stage and add Validate Apply, Validate Ansible and Validate Destroy stages to pause the script for user Abort
or Proceed.
- Add a Post section to Jenkinsfile for destroy if there is an outright Jenkins script failure in Apply, etc.... This way
we no longer have to clean up the infra with /var/log/jenkins/workspace destroy for script failures....
- ***Branched the master to master_through_lesson78_Post to save this setup. Freeze this branch.****
- Add production and development tfvars files. Name these master.tfvars and Jenkins_development.tfvars.  master is for production
and Jenkins_development is for dev environment. Names must be the same as the git BRANCH NAME. Prod is on 10.124.0.0/16 CIDR block and Jenkins_development is on 
10.123.0.0/16 CIDR block
- Now branch the master to Jenkins_development branch and add decision logic into the Jenkinsfile in the Jenkins_development
branch that is specific for development environment (We need to Validate each step in the Jenkinsfile but we won't be doing this in
the production master branch)
- Merge the Jenkins_development branch into the master (production)
- At this point the BRANCH_NAME env variable added to Jenkinsfile accomplishes two objectives: first we can run the terraform apply and plan and destroy
based upon the BRANCH_NAME for proper deployment and cleanup of proper CIDR block, and any other tfvars variables specific to branch.
Next, we can use the "when" beforeInput true logic in the Apply validate and the Ansible validate so that only development branch will
do an Apply and Ansible validate.  Destroy validate will be performed for both development and master branches.
- Add Aborted logic to Post in Jenkinsfile.
- JQ:  use JQ to glean the aws_instance ids that are deployed via the terraform job.  We can use this info to narrow down the ec2 wait between
the Apply and Ansible stages: Wait only for the instances that have been deployed on the job and not all of the instances in the entire aws region.
- JQ:  use the jenkins pipeline script generator to make this: terraform show -json | jq -r '.values'.'root_module'.'resources[] | select(.type == "aws_instance").values.id'
compatible with Jenkinsfile syntax.
- JQ:  the full script that needs to be converted is:
aws ec2 wait instance-status-ok --instance-ids $(terraform show -json | jq -r '.values'.'root_module'.'resources[] | select(.type == "aws_instance").values.id') --region us-west-1
- Incorporate the above into Jenkinsfile EC2 wait stage
- Remove the local provisioners in compute.tf that are being used to generate the aws_hosts EC2 inventory list of ip addresses that are used by the ansible stage
for the deployment of Granfana and Prometheus
- Always best to avoid provisioners if possible as they are NOT in terraform state.
- Add a new output to the compute.tf called "instance_ips". This is a listing of the ip addresses of all of the EC2 instances in the terraform deployment
- JQ: next create the syntax for the aws_hosts from the above output "instance_ips". json/JQ can reformat the above in suitable format to pipe into aws_hosts file
- JQ: the original syntax needs to be passed through the Jenkins pipeline syntax generator.
- The full script that needs to be converted is below:
printf "\n$(terraform output -json instance_ips | jq -r '.[]')" >> aws_hosts
- Insert line breaks and convert and then insert this shell script into the new Jenkins stage called 'Inventory aws_hosts generator stage'
- The ip inventory list will be piped into aws_hosts file for use by ansibile for application deployment.
- Add compute.tf output for instance_ids to be used to simplify the EC2 wait stage in Jenkinsfile
- Use the output instance_ids and terraform output in place of terraform show in the EC2 wait stage of Jenkinsfile.
- JQ: The unconverted syntax is: aws ec2 wait instance-status-ok --instance-ids $(terraform output -json instance_ids | jq -r '.[]') --region us-west-1
- JQ: The Jenkins pipeline converted shell command syntax is obtained from the Jenkins pipeline syntax converter tool and has been inserted into the Jenkinsfile
in the EC2 wait stage.
- prototype the ansible code for testing the apps with ansible playbook using ansible.builtin.uri.  Troubleshoot access list issues when initating the playbook
from the Cloud9 IDE.  It requires source ip of public_ips to be added to the security group rules.  For now just use source 0.0.0.0/0
- optimize the ansible code that is used for testing the apps with ansible.builtin.dict and use a loop as well.  The dictionary is defined in the vars:
- incorporate this working ansible playbook clip into main-playbook.yml and test this out.














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
 
 This branch will be frozen as well.
 



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