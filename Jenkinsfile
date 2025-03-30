pipeline {
    agent any

    tools {
        maven 'maven3'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        SONARQUBE_SERVER = 'sonar-server' // The name of your SonarQube server
        SLACK_CHANNEL = 'jenkins-alert' // Slack channel for notifications
        ARTIFACTS_DIR = "target"  // Directory for generated artifacts
        MAVEN_OPTS = '--add-opens java.base/java.lang=ALL-UNNAMED'
    }

    stages {
        // Clean the workspace before starting the build
        stage('Clean Workspace') {
            steps {
                cleanWs()  // Clean the workspace before starting the build
            }
        }
        // Checkout the code from the GitHub repository
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Build the project using Maven and generate artifacts
        stage('Build') {
            steps {
                script {
                    echo 'Building the project...'
                    sh 'mvn clean install'  // Build the project using Maven
                }
            }
        }

        // Stage 3: Run SonarQube analysis to check code quality
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(SONARQUBE_SERVER) {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Java \
                        -Dsonar.java.binaries=. \
                        -Dsonar.projectKey=Java
                    '''
                }
            }
        }

        //  Wait for the Quality Gate to pass or fail
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-token'
                }
            }
        }

        //  Run unit tests and generate test reports in HTML format
        stage('Test') {
            steps {
                script {
                    echo 'Running tests...'
                    sh 'mvn test'  // Run unit tests
                    junit '**/target/surefire-reports/*.xml'  // Publish JUnit test results
                    publishHTML(target: [
                        reportName: 'Test Results',
                        reportDir: 'target/surefire-reports',  // Ensure this is the correct directory for the HTML report
                        reportFiles: 'surefire-report.html',  // Ensure this is the correct file for the HTML report
                        keepAll: true
                    ])
                }
            }
        }
        // Archive generated artifacts for downstream job
        stage('Archive Artifacts') {
            steps {
                script {
                    sh 'ls -al target'  // List the contents of the target directory
                    archiveArtifacts artifacts: 'target/*.war', allowEmptyArchive: false
                }
            }
        }

    }
    post {
        success {
            slackSend (channel: SLACK_CHANNEL, message: "Pipeline completed successfully :tada:", color: 'good')
        }
        failure {
            slackSend (channel: SLACK_CHANNEL, message: "Pipeline failed :x:", color: 'danger')
        }
   }
}
