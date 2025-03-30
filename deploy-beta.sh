#!/bin/bash

# Define beta server details (modify as necessary)
BETA_SERVER="<beta_IP>"
BETA_USER="ubuntu"
BETA_DIR="/opt/application"
TOMCAT_DIR="/opt/tomcat"
TOMCAT_VERSION="9.0.58"

echo "Starting deployment to Beta environment for ${BRANCH_NAME}..."

# Check if Tomcat is installed on the server
ssh ${BETA_USER}@${BETA_SERVER} <<EOF
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

# Copy WAR file to beta server
scp target/*.war ${BETA_USER}@${BETA_SERVER}:${BETA_DIR}/

# Restart the application on the beta server
ssh ${BETA_USER}@${BETA_SERVER} <<EOF
  echo "Stopping beta application..."
  sudo systemctl stop tomcat

  echo "Deploying new version..."
  sudo cp ${BETA_DIR}/*.war ${TOMCAT_DIR}/webapps/ROOT.war

  echo "Starting beta application..."
  sudo systemctl start tomcat
EOF

echo "Beta deployment complete for branch ${BRANCH_NAME}."
