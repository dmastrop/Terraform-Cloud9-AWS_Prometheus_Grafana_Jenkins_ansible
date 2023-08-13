pipeline {
// https://www.jenkins.io/doc/book/pipeline/jenkinsfile/

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
        sh 'export TF_IN_AUTOMATION=true'
        sh 'terraform init -no-color'
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
        
        sh 'terraform plan -no-color'
      }    
    }
    
    stage('Validate Apply') {
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
        sh 'terraform apply -auto-approve -no-color'
      }
    }
    
    stage('EC2 Wait') {
      steps {
        sh 'aws ec2 wait instance-status-ok --region us-west-1'
        // this will wait on all EC2 instances in the region. Not efficient but will do for now....
        // we are doing this after the apply because the ansible deployment of granfana and prometheus will
        // occur after this and the EC2 instances have to be fully up prior to attempting to install the applications....
      }
    }
    
    stage('Ansbile') {
      steps {
        ansiblePlaybook(credentialsId: 'EC2-SSH-key', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
        // ansiblePlaybook(credentialsId: 'private_key', inventory: 'inventories/a/hosts', playbook: 'my_playbook.yml'
        // the private_key name is the name assigned to teh EC2 ssh key in Jenkins not the name in the Cloud9 directory
        // this should bootstrap EC2 instance with grafana and prometheus
        // https://plugins.jenkins.io/ansible/
      }
    }
    
    stage('Destroy') {
      steps {
        sh 'terraform destroy -auto-approve -no-color'
      }
    }        
  }   
}  
// pipeline typically ends with 4 brackets......

      
  
