pipeline {
// https://www.jenkins.io/doc/book/pipeline/jenkinsfile/
// comment merge

  agent any
  
  // insert ENV vars here so that they are global to the entire Jenkinsfile rather than specific to a stage.
  // https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#setting-environment-variables
  environment {
    TF_IN_AUTOMATION= 'true'
    
    TF_CLI_CONFIG_FILE = credentials('terrform-cloud-credentials-for-jenkins')
    // ****NOTE name has misspelled terrform. Must use this same name. terrform-cloud-credentials-for-jenkins
    // this was added as part of Jenkins security configuration from the /home/ubuntu/.terrafrom.d/credentials.tfrc.json 
    // this was named terrform-cloud-credentials-for-jenkins in Jenkins.
    // we can use the credentials() function to reference this credential that has already been added to Jenkins Security
    // this token will be assigned as the TF_CLI_CONFIG_FILE ENV variable.  This will work throughout the pipeline steps below.
    
    AWS_SHARED_CREDENTIALS_FILE='/home/ubuntu/.aws/credentials'
    // need to add this here so that the ec2 wait can be moved from the compute.tf file and into this Jenkinsfile. See below
    // we are adding the ec2 wait so that the instances are up prior to an ansible instantiation of grafana and prometheus.
    // otherwise the installation of these apps will fail!  Addd this stage between the Apply and the Destroy. See below....
    
  }
  
  stages {
    stage('Init') {
      steps {
        sh 'ls'
        //sh 'export TF_IN_AUTOMATION=true'
        // this export is no longer needed. It has been added to the top of this pipeline. See above.
        sh 'terraform init -no-color'
        
        sh 'cat $BRANCH_NAME.tfvars'
        // BRANCH_NAME is a reserved variable by Jenkins. We will see the contents of the Jenkins_development.tfvars file
        // when this cat is run in the development branch and we will see contenxts of the master.tfvars file when this cat
        // is run in production branch master.
        
        // the terraform plugin for jenkinsfiles is dated but we could have used that here to natively run the 
        // terraform commands here.
      }
    }  
    // stages typically end at 2 curly brackets down.
    
    
    
    
    stage('Plan') {
      steps {
        // sh 'export TF_IN_AUTOMATION=true'
        // this export is no longer needed. It has been moved to the top of the pipeline configuraton (see above)
        
        // note that each stage is isolated in terms of ENV variables.
        // exports must be added to each stage.
        
        //sh 'terraform plan -no-color'
        
        sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
        // this will run the plan with the BRANCH_NAME.tfvars file. For development this is Jenkins_development.tfvars
        // and for production this is master.tfvars. This must be done for the apply and destroy below as well.
        
      }    
    }
    
    
    
    
    stage('Validate Apply') {
    
      when {
      // https://www.jenkins.io/doc/book/pipeline/syntax/#when
      // only validate apply when branch is dev and make sure you evaluate before the input below so that we can abort it
      // if required. In dev branch we want the input, and in master branch we do not want the input.
      // When branch is development, the input will be hit. 
        beforeInput true
        branch "Jenkins_development"
      }
      
      input {
      // instead of steps we will use input
      message "Do you want to apply this terraform plan?"
      ok "Apply this plan."
      // can either apply the plan or abort
      }
      
      // can't have a stage without any steps so insert the step below
      steps {
        echo 'Apply Accepted'
      }
    }
    
    
    
    
    stage('Apply') {
      steps {
        sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        // this will run the apply with the BRANCH_NAME.tfvars file. For development this is Jenkins_development.tfvars
        // and for production this is master.tfvars. This must be done for the destroy below as well and the plan above.
      
        //sh 'terraform apply -auto-approve -no-color'
        // intentional failure (below) to test out post function below
        // Note a comment change does not institue a trigger for Jenkins to rebuild even if pushed to repo
        // this is unlike Github actions scripting.
        //sh 'terraform apply -auto-approve -no-color -var-file="test5.tfvars"'
      }
    }
    
    
    
    
    stage('Inventory aws_hosts generator stage') {
      steps {
        // This inventory list in aws_hosts was formerly created with local provisioners in compute.tf.  This is moved to Jenkinsfile
        // and by using JQ the inventory list can be created for use by ansible stage below for deployment of Grafana and Prometheus.
        // inserted the shell script below after passing the original syntax through the Jenkins pipeline generator.
        sh '''printf \\
        "\\n$(terraform output -json instance_ips | jq -r \'.[]\')" \\
        >> aws_hosts'''
      }
    }
    
    
    
    
    stage('EC2 Wait') {
      steps {
        // https://jqlang.github.io/jq/manual/#select
        sh '''aws ec2 wait instance-status-ok \\
        --instance-ids $(terraform output -json instance_ids | jq -r \'.[]\') \\
        --region us-west-1'''
        
      //comment out the below. Use the output created in compute.tf "instance_ids" along with JQ and terraform output to get the aws_instance ids for the 
      // aws ec2 wait command. Incorporate this into the command.  The JQ syntax is 
      // terraform output -json instance_ids | jq -r '.[]'    This replaces the terraform show command in the older implementation (too complex)
      // the new code is above.  
        //sh '''aws ec2 wait instance-status-ok \\
        //--instance-ids $(terraform show -json | jq -r \'.values\'.\'root_module\'.\'resources[] | select(.type == "aws_instance").values.id\') \\
        //--region us-west-1'''
      
      
      // Comment out the below and use the JQ script above so that there will be wait only on deployed EC2 instances 
      // Note that the original syntax is passed through the Jenkins pipeline syntax generator and results in the above syntax.
        //sh 'aws ec2 wait instance-status-ok --region us-west-1'
        // this will wait on all EC2 instances in the region. Not efficient but will do for now....
        // we are doing this after the apply because the ansible deployment of granfana and prometheus will
        // occur after this and the EC2 instances have to be fully up prior to attempting to install the applications....
      }
    }
    
    
    
    
    stage('Validate Ansible') {
    
      when {
      // https://www.jenkins.io/doc/book/pipeline/syntax/#when
      // only validate ansible when branch is dev and make sure you evaluate before the input below so that we can abort it
      // if required. In dev branch we want the input, and in master branch we do not want the input.
      // When branch is development, the input will be hit. 
        beforeInput true
        branch "Jenkins_development"
      }
      
      input {
      // instead of steps we will use input
      message "Do you want to run ansible playbook?"
      ok "Run ansible playbook on this terraform infra."
      // can either apply the plan or abort
      }
      
      // can't have a stage without any steps so insert the step below
      steps {
        echo 'Ansible deployment accepted'
      }
    }
    
    
    
    
    stage('Ansible') {
      steps {
        ansiblePlaybook(credentialsId: 'EC2-SSH-key', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
        // ansiblePlaybook(credentialsId: 'private_key', inventory: 'inventories/a/hosts', playbook: 'my_playbook.yml'
        // the private_key name is the name assigned to teh EC2 ssh key in Jenkins not the name in the Cloud9 directory
        // (but they are referring to the same SSH private key, just different names)
        // this should bootstrap EC2 instance with grafana and prometheus
        // https://plugins.jenkins.io/ansible/
        // the ansiblePlaybook is essentially running ansible-playbook -i aws_hosts --key-file <> playbooks/main-playbook.yml 
        // OR ansible-playbook -i aws_hosts --private-key <> playbooks/main-playbook.yml against each EC2 instance in the 
        // aws_hosts inventory list.  This was formerly done in the null_resource of commpute.tf
      }
    }
    
    
    
    
    stage('Validate Destroy') {
    
      // for the Destroy we will still have the validation in both dev and master production environments.
      // so do not insert the when directive here.
      
      input {
      // instead of steps we will use input
      message "Do you want to destroy this terraform infra?"
      ok "Destroy this terraform infra."
      // can either apply the plan or abort
      }
      
      // can't have a stage without any steps so insert the step below
      steps {
        echo 'Destroy Accepted'
      }
    }
    
    
    
    
    stage('Destroy') {
      steps {
        sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        // this will run the destroy with the BRANCH_NAME.tfvars file. For development this is Jenkins_development.tfvars
        // and for production this is master.tfvars.  This is what we did for the apply and plan above as well.
      
        //sh 'terraform destroy -auto-approve -no-color'
      }
    }        
  } 
  
  
  
  
  post {
  // https://www.jenkins.io/doc/pipeline/tour/post/
    success {
      echo 'Success edit8'
    }
    
    failure {
      //sh 'terraform destroy -auto-approve -no-color'
      
      sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
      // this will run the Post destroy with the BRANCH_NAME.tfvars file. For development this is Jenkins_development.tfvars
      // and for production this is master.tfvars.  This is what we did for the destory, apply and plan above as well.
    }
    
    aborted {
    // https://www.jenkins.io/doc/book/glossary/#build-status
      sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
    }
  }
} 


      
  
