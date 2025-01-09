#!/bin/bash

# Update package list and upgrade existing packages
echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and necessary dependencies
echo "Installing Python and dependencies..."
sudo apt install -y python3 python3-pip python3-venv python3-dev libssl-dev libffi-dev build-essential python3-serial

# Create the project directory
echo "Creating project directory..."
mkdir -p ~/optical_switch
sudo chown -R $(whoami):$(whoami) ~/optical_switch
cd ~/optical_switch || { echo "Failed to enter project directory"; exit 1; }

# Copy required project files (ensure the required files are available in the same directory)
echo "Copying project files..."
if [ -f "../app.py" ] && [ -f "../initialize_db.py" ] && [ -f "../create_user.py" ] && [ -d "../static" ] && [ -d "../templates" ]; then
    cp ../app.py .
    cp ../initialize_db.py .
    cp ../create_user.py .
    cp -r ../static .
    cp -r ../templates .
else
    echo "Required files or directories not found. Please ensure all files are present in the parent directory."
    exit 1
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
    echo "Creating user..."
    python3 create_user.py
else
    echo "create_user.py not found. Skipping user creation."
fi

# Enable Raspberry Pi serial interface
echo "Enabling Raspberry Pi serial interface..."
sudo raspi-config nonint do_serial 0 1

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

# Ask the user if they want to reboot the system
read -p "Setup complete. Do you want to reboot now? (yes/no): " REBOOT_ANSWER
if [[ $REBOOT_ANSWER == "yes" || $REBOOT_ANSWER == "y" ]]; then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Setup finished. Please reboot manually if required."
fi
