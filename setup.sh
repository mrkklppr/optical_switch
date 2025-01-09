#!/bin/bash

# Update package list and upgrade existing packages
echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and necessary dependencies
echo "Installing Python and dependencies..."
sudo apt install -y python3-pip python3-venv python3-dev libssl-dev libffi-dev build-essential

# Create the project directory
echo "Creating project directory..."
mkdir -p ~/optical_switch
sudo chown -R $(whoami):$(whoami) ~/optical_switch
cd ~/optical_switch

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
if python3 -m venv venv; then
    echo "Virtual environment created successfully."
else
    echo "Failed to create virtual environment. Exiting."
fi

# Activate the virtual environment
if [ -f venv/bin/activate ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
else
    echo "Virtual environment activation script not found. Exiting."
fi

# Install required Python packages
if [ -f requirements.txt ]; then
    echo "Installing Python packages from requirements.txt..."
    pip install -r requirements.txt
else
    echo "requirements.txt not found. Skipping Python package installation."
fi

# Run the database initialization script
if [ -f initialize_db.py ]; then
    echo "Initializing the database..."
    python3 initialize_db.py
else
    echo "initialize_db.py not found. Skipping database initialization."
fi

# Run the user creation script
if [ -f create_user.py ]; then
    echo "Creating admin user..."
    python3 create_user.py
else
    echo "create_user.py not found. Skipping admin user creation."
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
Environment=PATH=/home/${USER}/optical_switch/venv/bin
ExecStart=/home/${USER}/optical_switch/venv/bin/python3 /home/${USER}/optical_switch/app.py

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the service
echo "Enabling and starting the systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable optical_switch.service
sudo systemctl start optical_switch.service

echo "Setup complete. The Optical Switch Flask app is now running."
