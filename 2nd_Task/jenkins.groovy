def lastCommit
def latestVersion

pipeline {

    agent {
        label 'docker_node'
    }

    stages {
        stage('Build Docker image') {
            steps {
                dir('coronadata'){
                    script {
                        println("Getting commit id and latest Version")
                        _lastCommit = sh script: "git log | head -1 | awk '{print '\$2'}' | cut -c1-6", returnStdout: true
                        _latestVersion = sh script: "git branch -r | cut -d '/' -f2 | grep 0. | sort -r | head -1", returnStdout: true
                        lastCommit = _lastCommit.trim()
                        latestVersion = _latestVersion.trim()
                        println("Latest Version seen is ${latestVersion}")
                        println("Latest commit seen is ${lastCommit}")
                        sh "sudo docker build -t bamb4boy/coronadata:${latestVersion}-${lastCommit} . "
                    }
                }
            }
        }
        stage('Test Docker image') {
            steps {
                dir('coronadata/tests') {
                    script{
                        try {
                            sh "./basic.test.sh"
                        } catch (err) {
                            println("Error thrown on test file execution")
                            currentBuild.result = 'ABORTED'
                            error('Error thrown on test file execution')
                        }
                    }
                }
            }
        }
        stage('Upload image to repository') {
            steps {
                sh "sudo docker push bamb4boy/coronadata:${latestVersion}-${lastCommit}"
            }
        }
        stage('Deploy to Prod') {
            steps {
                script {
                    dir('deployment') {
                        sh "sudo /usr/bin/ansible-playbook -i inventory.ini coronadata.yml --extra-vars tag=${latestVersion}-${lastCommit}"
                    }
                }

            }
        }
    }
}