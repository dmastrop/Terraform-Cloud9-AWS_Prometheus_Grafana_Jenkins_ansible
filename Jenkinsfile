pipeline {
  agent any
  // insert ENV vars here so that they are global to the entire Jenkinsfile rather than specific to a stage.
  environment {
    TF_IN_AUTOMATION= 'true'
    TF_CLI_CONFIG_FILE = credentials('terraform-cloud-credentials-for-jenkins')
    // this was added as part of Jenkins security configuration from the /home/ubuntu/.terrafrom.d/credentials.tfrc.json 
    // this was named terraform-cloud-credentials-for-jenkins in Jenkins.
    // we can use the credentials() function to reference this credential that has already been added to Jenkins Security
    // this token will be assigned as the TF_CLI_CONFIG_FILE ENV variable.  This will work throughout the pipeline steps below.
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
        
        sh ' terraform plan -no-color'
      }    
    }
  }   
}  
// pipeline typically ends with 4 brackets.....

      
  
