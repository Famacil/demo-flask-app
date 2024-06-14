pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'demo-flask-app'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'demo-flask-app'
        ECR_REGISTRY = '200568115249.dkr.ecr.us-east-1.amazonaws.com'
        AWS_CREDENTIALS = 'AWS' // Substitua pelo ID correto das suas credenciais AWS
        GITHUB_CREDENTIALS = 'github_ssh_key'
    }

    parameters {
        booleanParam(name: 'DESTROY_INFRA', defaultValue: false, description: 'Destroy infrastructure after deployment')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Famacil/demo-flask-app.git',
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
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                        script {
                            sh '''
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            docker tag ${DOCKER_IMAGE}:latest ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                            '''
                        }
                    }
                }
            }
        }

        stage('Configure Infrastructure') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                        script {
                            sh '''
                            # Create VPC
                            VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region ${AWS_REGION} --query 'Vpc.VpcId' --output text)
                            aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=DemoVPC --region ${AWS_REGION}
                            
                            # Create Subnets
                            SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --region ${AWS_REGION} --query 'Subnet.SubnetId' --output text)
                            aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=DemoSubnet --region ${AWS_REGION}
                            
                            # Create Internet Gateway
                            IGW_ID=$(aws ec2 create-internet-gateway --region ${AWS_REGION} --query 'InternetGateway.InternetGatewayId' --output text)
                            aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region ${AWS_REGION}
                            
                            # Create Route Table
                            RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region ${AWS_REGION} --query 'RouteTable.RouteTableId' --output text)
                            aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region ${AWS_REGION}
                            aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RTB_ID --region ${AWS_REGION}
                            
                            # Create Security Group
                            SG_ID=$(aws ec2 create-security-group --group-name DemoSG --description "Demo security group" --vpc-id $VPC_ID --region ${AWS_REGION} --query 'GroupId' --output text)
                            aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region ${AWS_REGION}
                            
                            # Create ECS Cluster
                            CLUSTER_NAME="demo-flask-cluster"
                            aws ecs create-cluster --cluster-name $CLUSTER_NAME --region ${AWS_REGION}
                            
                            # Register Task Definition
                            TASK_DEFINITION=$(cat <<EOF
                            {
                              "family": "demo-flask-task",
                              "networkMode": "awsvpc",
                              "containerDefinitions": [
                                {
                                  "name": "demo-flask-container",
                                  "image": "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest",
                                  "essential": true,
                                  "memory": 512,
                                  "cpu": 256,
                                  "portMappings": [
                                    {
                                      "containerPort": 80,
                                      "hostPort": 80
                                    }
                                  ]
                                }
                              ],
                              "requiresCompatibilities": [
                                "FARGATE"
                              ],
                              "cpu": "256",
                              "memory": "512"
                            }
                            EOF
                            )
                            echo "$TASK_DEFINITION" > taskdef.json
                            TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://taskdef.json --query 'taskDefinition.taskDefinitionArn' --output text --region ${AWS_REGION})
                            
                            # Create Service
                            SERVICE_NAME="demo-flask-service"
                            aws ecs create-service --cluster $CLUSTER_NAME --service-name $SERVICE_NAME \
                                --task-definition $TASK_DEF_ARN --desired-count 1 --launch-type FARGATE \
                                --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" --region ${AWS_REGION}
                            '''
                        }
                    }
                }
            }
        }

        stage('Destroy Infrastructure') {
            when {
                expression {
                    return params.DESTROY_INFRA == true
                }
            }
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                        script {
                            sh '''
                            # Destroy ECS Service
                            SERVICE_NAME="demo-flask-service"
                            CLUSTER_NAME="demo-flask-cluster"
                            aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --region ${AWS_REGION}
                            aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force --region ${AWS_REGION}
                            
                            # Destroy Task Definition
                            TASK_DEF_FAMILY="demo-flask-task"
                            TASK_DEF_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_DEF_FAMILY --region ${AWS_REGION} --query 'taskDefinitionArns[-1]' --output text)
                            aws ecs deregister-task-definition --task-definition $TASK_DEF_ARN --region ${AWS_REGION}
                            
                            # Destroy ECS Cluster
                            aws ecs delete-cluster --cluster $CLUSTER_NAME --region ${AWS_REGION}
                            
                            # Destroy Security Group
                            SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=DemoSG --region ${AWS_REGION} --query 'SecurityGroups[0].GroupId' --output text)
                            aws ec2 delete-security-group --group-id $SG_ID --region ${AWS_REGION}
                            
                            # Destroy Subnet
                            SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=DemoSubnet --region ${AWS_REGION} --query 'Subnets[0].SubnetId' --output text)
                            aws ec2 delete-subnet --subnet-id $SUBNET_ID --region ${AWS_REGION}
                            
                            # Destroy Internet Gateway
                            IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VPC_ID --region ${AWS_REGION} --query 'InternetGateways[0].InternetGatewayId' --output text)
                            aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region ${AWS_REGION}
                            aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region ${AWS_REGION}
                            
                            # Destroy Route Table
                            RTB_ID=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID --region ${AWS_REGION} --query 'RouteTables[0].RouteTableId' --output text)
                            aws ec2 delete-route-table --route-table-id $RTB_ID --region ${AWS_REGION}
                            
                            # Destroy VPC
                            VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=DemoVPC --region ${AWS_REGION} --query 'Vpcs[0].VpcId' --output text)
                            aws ec2 delete-vpc --vpc-id $VPC_ID --region ${AWS_REGION}
                            '''
                        }
                    }
                }
            }
        }
    }
}
