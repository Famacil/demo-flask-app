pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = '4fe6e8f4-f537-44ca-b68e-d659d93610db'
        GITHUB_CREDENTIALS = 'github_ssh_key'
        AWS_CREDENTIALS = 'AWS' // Substitua pelo ID correto das suas credenciais AWS
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']], // Certifique-se de que esta é a branch correta
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Famacil/demo-flask-app.git', // Usando HTTPS para evitar problemas de SSH
                            credentialsId: "${GITHUB_CREDENTIALS}"
                        ]]
                    ])
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    echo 'Building the project...'
                    sh 'docker build -t demo-flask-app .'
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo 'Running tests...'
                    // Adicione os comandos de teste aqui
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS}", usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                        echo 'Pushing Docker image...'
                        sh 'docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD'
                        sh 'docker tag demo-flask-app $DOCKERHUB_USERNAME/demo-flask-app:latest'
                        sh 'docker push $DOCKERHUB_USERNAME/demo-flask-app:latest'
                    }
                }
            }
        }

        stage('Create ECS Cluster') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                        echo 'Creating ECS cluster...'
                        sh '''
                        aws ecs create-cluster --cluster-name demo-flask-cluster
                        '''
                    }
                }
            }
        }

        stage('Register Task Definition') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                        echo 'Registering task definition...'
                        sh '''
                        aws ecs register-task-definition --family demo-flask-task \
                            --container-definitions name=demo-flask-container,image=$DOCKERHUB_USERNAME/demo-flask-app:latest,essential=true,memory=512,cpu=256 \
                            --network-mode bridge
                        '''
                    }
                }
            }
        }

        stage('Create Service') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                        echo 'Creating ECS service...'
                        sh '''
                        aws ecs create-service --cluster demo-flask-cluster --service-name demo-flask-service \
                            --task-definition demo-flask-task --desired-count 1
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo 'Cleaning up...'
                // Adicione os comandos de limpeza aqui
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
