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
                sh "sudo -i"
                sh "aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 966444541051.dkr.ecr.us-east-2.amazonaws.com"
                sh "docker tag bamb4boy/hello_world:latest 966444541051.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
                sh "docker push 966444541051.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
            }
        }
        stage("deploy"){
            steps {
                sh "sudo -i"
                sh "aws eks update-kubeconfig --name SelaTask-eks --region us-east-2"
                sh "docker pull 966444541051.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
                sh "kubectl create deployment --image=966444541051.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest hello_world_app"
            }
        }
    }
}