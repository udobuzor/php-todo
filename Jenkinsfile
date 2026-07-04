pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        IMAGE_NAME = "udobuzor/php-todo"
        IMAGE_TAG  = "${BRANCH_NAME}-0.0.1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    sh """
                        docker run --network tooling_app_network -d --name test-${BUILD_NUMBER} -p 0:80 ${IMAGE_NAME}:${IMAGE_TAG}
                        sleep 5
                        CONTAINER_PORT=\$(docker port test-${BUILD_NUMBER} 80 | cut -d: -f2)
                        STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:\$CONTAINER_PORT)
                        echo "HTTP status: \$STATUS"
                        if [ "\$STATUS" != "200" ]; then
                            echo "Test failed: expected 200, got \$STATUS"
                            exit 1
                        fi
                    """
                }
            }
            post {
                always {
                    sh "docker stop test-${BUILD_NUMBER} || true"
                    sh "docker rm test-${BUILD_NUMBER} || true"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
                    sh "docker system prune -f || true"
                }
            }
        }
    }
}