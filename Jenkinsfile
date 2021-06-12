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
        stage("test") {
            steps {
                echo 'testing the application'
            }
        }
        stage("deploy"){
            steps {
                echo 'deploy the application'
            }
        }
    }
}