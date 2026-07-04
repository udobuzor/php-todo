pipeline {
<<<<<<< HEAD
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        IMAGE_NAME = "<your-dockerhub-username>/php-todo"
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
=======
    agent {label 'slave'}

    parameters {
        choice(
            name: 'environment',
            choices: ['dev', 'staging', 'uat'],
            description: 'Select environment to deploy to'
        )
    }

    stages {
        stage("Initial cleanup") {
            steps {
                dir("${WORKSPACE}") {
                    deleteDir()
                }
            }
        }
        stage('Checkout SCM') {
            steps {
                git branch: 'main',
                url: 'https://github.com/udobuzor/php-todo.git'
            }
        }
        stage('Prepare Dependencies') {
            steps {
                sh 'mv .env.sample .env'
                sh 'composer install'
                sh 'php artisan migrate'
                sh 'php artisan db:seed'
                sh 'php artisan key:generate'
            }
        }
        stage('Execute Unit Tests') {
            steps {
                sh './vendor/bin/phpunit'
            }
        }
        stage('Code Analysis') {
            steps {
                sh 'phploc app/ --log-csv build/logs/phploc.csv'
            }
        }
        stage('SonarQube Quality Gate') {
            environment {
                scannerHome = tool 'SonarQubeScanner'
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=php-todo \
                        -Dsonar.sources=app/ \
                        -Dsonar.php.exclusions=**/vendor/**
                    """
                }
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Package Artifact') {
            steps {
                sh 'zip -qr php-todo.zip ${WORKSPACE}/*'
            }
        }
        stage('Upload Artifact to Artifactory') {
            steps {
                script {
                    def server = Artifactory.server 'artifactory-server'
                    def uploadSpec = """{
                        "files": [{
                            "pattern": "php-todo.zip",
                            "target": "php-todo/",
                            "props": "type=zip;status=ready"
                        }]
                    }"""
                    server.upload spec: uploadSpec
                }
            }
        }
        stage('Deploy to Environment') {
            steps {
                build job: 'udo-ansible-config-mgt/main',
                parameters: [[$class: 'StringParameterValue',
                name: 'inventory', value: "${params.environment}"]],
                propagate: false,
                wait: true
>>>>>>> d9a52dc2711f4d608ac94dc572d170b18aad366d
            }
        }
    }
}
