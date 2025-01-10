#!/bin/bash

# Exit on error
set -e

# Update package list and upgrade packages
echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and necessary dependencies
echo "Installing Python and dependencies..."
sudo apt install -y python3 python3-pip python3-venv python3-dev libssl-dev libffi-dev python3-serial python3-flask python3-flask-sqlalchemy python3-flask-bcrypt

# Set ownership of the current working directory
PROJECT_DIR=$(pwd)
sudo chown -R $(whoami):$(whoami) "$PROJECT_DIR"

# Run database initialization script if present
if [ -f initialize_db.py ]; then
    echo "Initializing the database..."
    python3 initialize_db.py
else
    echo "initialize_db.py not found. Skipping database initialization."
fi

# Run user creation script if present
if [ -f create_user.py ]; then
    echo "Creating user..."
    python3 create_user.py
else
    echo "create_user.py not found. Skipping user creation."
fi

# Create SSL Cert
echo "Creating SSL Cert for HTTPS"
sudo openssl genpkey -algorithm RSA -out server.key
sudo openssl req -new -key server.key -out server.csr
sudo openssl x509 -req -in server.csr -signkey server.key -out server.crt

# Change permissions for SSL files
sudo chmod 444 server.crt
sudo chmod 444 server.key

# Enable Raspberry Pi serial interface
echo "Enabling Raspberry Pi serial interface..."
sudo raspi-config nonint do_serial 0 1

# Set up a systemd service for the Flask app
SERVICE_FILE="/etc/systemd/system/optical_switch.service"
echo "Setting up systemd service..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Optical Switch Flask Application
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/python3 $PROJECT_DIR/app.py

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the service
echo "Enabling and starting the systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable optical_switch.service
sudo systemctl start optical_switch.service

# Prompt for system reboot with default to 'yes'
read -p "Setup complete. Do you want to reboot now? (Y/n): " REBOOT_ANSWER
REBOOT_ANSWER=${REBOOT_ANSWER:-Y}  # Default to 'Y' if no input is provided

if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Setup finished. Please reboot manually if required."
fi
