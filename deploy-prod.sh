#!/bin/bash

# Define production server details (modify as necessary)
PROD_SERVER="<prod_ip>"
PROD_USER="ubuntu"
PROD_DIR="/opt/application"
TOMCAT_DIR="/opt/tomcat"
TOMCAT_VERSION="9.0.58"

echo "Starting deployment to Production environment..."

# Check if Tomcat is installed on the server
ssh ${PROD_USER}@${PROD_SERVER} <<EOF
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

# Copy WAR file to production server
scp target/*.war ${PROD_USER}@${PROD_SERVER}:${PROD_DIR}/

# Restart the application on the production server
ssh ${PROD_USER}@${PROD_SERVER} <<EOF
  echo "Stopping production application..."
  sudo systemctl stop tomcat

  echo "Deploying new version..."
  sudo cp ${PROD_DIR}/*.war ${TOMCAT_DIR}/webapps/ROOT.war

  echo "Starting production application..."
  sudo systemctl start tomcat
EOF

echo "Production deployment complete."
