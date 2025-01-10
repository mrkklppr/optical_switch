import serial
import time

# Serial port configuration
SERIAL_CONFIG = {
    'PORT': "/dev/serial0",
    'BAUD_RATE': 115200,
    'TIMEOUT': 1
}

def send_command(port_number):
    """Send command to optical switch with input validation and error handling"""
    try:
        # Validate port number
        port_num = int(port_number)
        if not (1 <= port_num <= 999):
            raise ValueError("Port number must be between 1 and 999")

        # Open serial connection using context manager
        with serial.Serial(
            SERIAL_CONFIG['PORT'],
            SERIAL_CONFIG['BAUD_RATE'],
            timeout=SERIAL_CONFIG['TIMEOUT']
        ) as ser:
            command = f"*SW{str(port_num).zfill(3)}\r"
            ser.write(command.encode())

    except Exception as e:
        pass  # Ignore errors

# Main script to send commands in an infinite loop
def main():
    while True:
        for i in range(1, 49):  # Loop through SW001 to SW048
            port_number = str(i)
            send_command(port_number)
            time.sleep(0)  # Add a small delay between commands

if __name__ == "__main__":
    main()
