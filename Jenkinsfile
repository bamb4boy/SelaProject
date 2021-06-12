pipeline {
    agent {
        label 'docker_node'
    }
    stages {
        stage("build"){
            steps {
                dir('application'){
                    script {
                    sh "sudo docker build -t bamb4boy/hello_world . "
                    }
                }
            }
        }
        stage("push") {
            steps {
//                 sh "sudo aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 966444541051.dkr.ecr.us-east-2.amazonaws.com"
                sh "sudo docker tag bamb4boy:latest 966444541051.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
                sh "sudo docker push 966444541051.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
            }
        }
        stage("deploy"){
            steps {
                echo 'deploy the application'
            }
        }
    }
}