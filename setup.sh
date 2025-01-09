#!/bin/bash

# Update package list and upgrade existing packages
echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and necessary dependencies
echo "Installing Python and dependencies..."
sudo apt install -y python3 python3-dev python3-pip libssl-dev libffi-dev build-essential

# Install required Python packages via apt
echo "Installing Flask, Flask-SQLAlchemy, Flask-Bcrypt, and pyserial via apt..."
sudo apt install -y python3-flask python3-flask-sqlalchemy python3-flask-bcrypt python3-pyserial

# Enable the Raspberry Pi serial interface
echo "Enabling Raspberry Pi serial interface..."
if ! grep -q "enable_uart=1" /boot/config.txt; then
    echo "enable_uart=1" | sudo tee -a /boot/config.txt
else
    echo "Serial interface already enabled in /boot/config.txt."
fi

# Disable serial console to free the serial port
echo "Disabling serial console..."
sudo systemctl stop serial-getty@ttyS0.service
sudo systemctl disable serial-getty@ttyS0.service
sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service

# Create the project directory
echo "Creating project directory..."
mkdir -p ~/optical_switch
sudo chown -R $(whoami):$(whoami) ~/optical_switch
cd ~/optical_switch

# Run the database initialization script
if [ -f initialize_db.py ]; then
    echo "Initializing the database..."
    python3 initialize_db.py
else
    echo "initialize_db.py not found. Skipping database initialization."
fi

# Run the user creation script
if [ -f create_user.py ]; then
    echo "Running user creation script..."
    python3 create_user.py
else
    echo "create_user.py not found. Skipping user creation."
fi

# Generate a self-signed SSL certificate for HTTPS
echo "Generating a self-signed SSL certificate..."
CERT_DIR=~/optical_switch
SSL_KEY=${CERT_DIR}/server.key
SSL_CERT=${CERT_DIR}/server.crt

if [ ! -f "${SSL_KEY}" ] || [ ! -f "${SSL_CERT}" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${SSL_KEY}" -out "${SSL_CERT}" \
        -subj "/C=US/ST=YourState/L=YourCity/O=YourOrganization/CN=localhost"
    echo "SSL certificate generated at ${SSL_CERT}."
else
    echo "SSL certificate already exists."
fi

# Set up a systemd service to run the Flask app in the background
echo "Setting up systemd service..."
SERVICE_FILE="/etc/systemd/system/optical_switch.service"
sudo tee $SERVICE_FILE > /dev/null <<EOL
[Unit]
Description=Optical Switch Flask Application
After=network.target

[Service]
User=${USER}
WorkingDirectory=/home/${USER}/optical_switch
ExecStart=/usr/bin/python3 /home/${USER}/optical_switch/app.py

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the service
echo "Enabling and starting the systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable optical_switch.service
sudo systemctl start optical_switch.service

echo "Setup complete. The Optical Switch Flask app is now running with HTTPS."

# Ask the user if they want to reboot
read -p "Do you want to reboot the Raspberry Pi now? (yes/no): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^(yes|y)$ ]]; then
    echo "Rebooting the Raspberry Pi..."
    sudo reboot
else
    echo "Reboot skipped. Please reboot manually to apply all changes."
fi
