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

# Main script to send commands in alternating patterns
def main():
    while True:
        # First pattern: 1, 26, 3, 28, ...
        for i in range(1, 25):
            port_number_1 = str(i)  # First row
            port_number_2 = str(i + 24)  # Second row

            send_command(port_number_1)  # Send command to first row port
            time.sleep(0.001)  # Add a small delay

            send_command(port_number_2)  # Send command to second row port
            time.sleep(0.001)  # Add a small delay

        # Second pattern: 25, 2, 27, 4, ...
        for i in range(1, 25):
            port_number_1 = str(i + 24)  # Second row
            port_number_2 = str(i)  # First row

            send_command(port_number_1)  # Send command to second row port
            time.sleep(0.001)  # Add a small delay

            send_command(port_number_2)  # Send command to first row port
            time.sleep(0.001)  # Add a small delay

if __name__ == "__main__":
    main()
