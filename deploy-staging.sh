#!/bin/bash

# Define staging server details (modify as necessary)
STAGING_SERVER="<stage-IP>"
STAGING_USER="ubuntu"  #ubuntu
STAGING_DIR="/opt/application"
TOMCAT_DIR="/opt/tomcat"
TOMCAT_VERSION="9.0.58"

echo "Starting deployment to Staging environment..."

# Check if Tomcat is installed on the server
ssh ${STAGING_USER}@${STAGING_SERVER} <<EOF
  if ! [ -x "$(command -v tomcat)" ]; then
    echo "Tomcat is not installed. Installing Tomcat..."
    sudo apt update
    sudo apt install -y openjdk-11-jdk wget
    wget https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
    sudo tar xvf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt
    sudo mv /opt/apache-tomcat-${TOMCAT_VERSION} ${TOMCAT_DIR}
    sudo ln -s ${TOMCAT_DIR}/bin/catalina.sh /usr/bin/tomcat
    echo "Tomcat installed successfully."
  else
    echo "Tomcat is already installed."
  fi
EOF

# Copy WAR file to staging server
scp target/*.war ${STAGING_USER}@${STAGING_SERVER}:${STAGING_DIR}/

# Restart the application on the staging server
ssh ${STAGING_USER}@${STAGING_SERVER} <<EOF
  echo "Stopping staging application..."
  sudo systemctl stop tomcat

  echo "Deploying new version..."
  sudo cp ${STAGING_DIR}/*.war ${TOMCAT_DIR}/webapps/ROOT.war

  echo "Starting staging application..."
  sudo systemctl start tomcat
EOF

echo "Staging deployment complete."
