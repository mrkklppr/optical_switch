#!/bin/bash

# Update package list and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Install Python and necessary dependencies
sudo apt install -y python3-pip python3-venv python3-dev libssl-dev libffi-dev build-essential

# Create the project directory
mkdir ~/optical_switch
cd ~/optical_switch

# Clone the repository or copy the app files (assuming you have it as a zip or repo)
# For example:
# git clone https://your-repo-url.git .
# OR copy all the necessary files into the directory.

# Set up Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install -r requirements.txt

# Run the database initialization script
echo "Initializing the database..."
python3 initialize_db.py

# Run the user creation script
echo "Creating admin user..."
python3 create_user.py

# Set up a systemd service to run the Flask app in the background
echo "[Unit]
Description=Optical Switch Flask Application
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/optical_switch
Environment=PATH=/home/pi/optical_switch/venv/bin
ExecStart=/home/pi/optical_switch/venv/bin/python3 /home/pi/optical_switch/app.py

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/optical_switch.service

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable optical_switch.service
sudo systemctl start optical_switch.service

echo "Setup complete. The Optical Switch Flask app is now running."
