pipeline {
  agent any
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
        sh 'export TF_IN_AUTOMATION=true'
        // note that each stage is isolated in terms of ENV variables.
        // exports must be added to each stage.
        sh ' terraform plan -no-color'
      }    
    }
  }   
}  
// pipeline typically ends with 4 brackets.

      
  
