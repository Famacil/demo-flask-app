pipeline {
    agent any

    environment {
        // IDs das credenciais
        DOCKER_HUB_CREDENTIALS = '4fe6e8f4-f537-44ca-b68e-d659d93610db'
        GITHUB_CREDENTIALS = 'github_ssh_key'
        AWS_CREDENTIALS = 'aws_credentials_id' // Substitua pelo ID correto das suas credenciais AWS
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    // Usando uma sintaxe correta para o git checkout
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        userRemoteConfigs: [[
                            url: 'git@github.com:Famacil/demo-flask-app.git',
                            credentialsId: "${GITHUB_CREDENTIALS}"
                        ]]
                    ])
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    // Comandos para construir o seu projeto
                    echo 'Building the project...'
                    sh 'docker build -t demo-flask-app .'
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    // Comandos para testar o seu projeto
                    echo 'Running tests...'
                    // Adicione os comandos de teste aqui
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS}", usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                        // Comandos para empurrar a imagem Docker para um registro
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
                    withCredentials([aws(credentialsId: "${AWS_CREDENTIALS}")]) {
                        // Comandos para criar um cluster ECS
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
                    withCredentials([aws(credentialsId: "${AWS_CREDENTIALS}")]) {
                        // Comandos para registrar a definição da tarefa no ECS
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
                    withCredentials([aws(credentialsId: "${AWS_CREDENTIALS}")]) {
                        // Comandos para criar um serviço ECS
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
                // Passos que devem ser executados sempre, como limpar recursos
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
