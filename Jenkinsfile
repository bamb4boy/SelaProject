#done
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
//                 sh "aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin userid.dkr.ecr.us-east-2.amazonaws.com"
                sh "sudo docker tag bamb4boy/hello_world:latest userid.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
                sh "sudo docker push userid.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
            }
        }
        stage("deploy"){
            steps {
                sh "sudo aws eks update-kubeconfig --name SelaTask-eks --region us-east-2"
                sh "sudo docker pull userid.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest"
                sh "sudo kubectl create deployment --image=userid.dkr.ecr.us-east-2.amazonaws.com/selataskecr:latest helloworld"
            }
        }
    }
}
