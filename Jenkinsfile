pipeline {
    agent any

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
            when {
                branch pattern: "^develop*|^hotfix*|^release*|^main*",
                comparator: "REGEXP"
            }
            environment {
                scannerHome = tool 'SonarQubeScanner'
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh "${scannerHome}/bin/sonar-scanner"
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
                            "target": "<your-artifactory-repo>/php-todo",
                            "props": "type=zip;status=ready"
                        }]
                    }"""
                    server.upload spec: uploadSpec
                }
            }
        }

        stage('Deploy to Dev Environment') {
            steps {
                build job: 'ansible-project/main',
                parameters: [[$class: 'StringParameterValue',
                name: 'env', value: 'dev']],
                propagate: false,
                wait: true
            }
        }
    }
}
