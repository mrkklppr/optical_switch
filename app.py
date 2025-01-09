from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from functools import wraps
import serial
import os
from datetime import timedelta

app = Flask(__name__)

# Enhanced security configuration
app.config.update(
    SECRET_KEY=os.urandom(32),  # Generate a random secret key
    PERMANENT_SESSION_LIFETIME=timedelta(minutes=5),  # Session timeout
    SESSION_COOKIE_SECURE=True,  # Cookies only sent over HTTPS
    SESSION_COOKIE_HTTPONLY=True,  # Prevent JavaScript access to session cookie
    SESSION_COOKIE_SAMESITE='Lax',  # CSRF protection
)

# Database configuration
app.config.update(
    SQLALCHEMY_DATABASE_URI='sqlite:///users.db',
    SQLALCHEMY_TRACK_MODIFICATIONS=False
)

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

# Serial port configuration
SERIAL_CONFIG = {
    'PORT': "/dev/serial0",
    'BAUD_RATE': 115200,
    'TIMEOUT': 1
}

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    
    def __repr__(self):
        return f"User('{self.username}')"

# Login decorator for protecting routes
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            flash('Please log in first', 'error')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def send_command(port_number):
    """Send command to optical switch with input validation and error handling"""
    try:
        if port_number == "off":
            with serial.Serial(
                SERIAL_CONFIG['PORT'],
                SERIAL_CONFIG['BAUD_RATE'],
                timeout=SERIAL_CONFIG['TIMEOUT']
            ) as ser:
                command = "*SW000\r"  # Command to turn off the switch
                ser.write(command.encode())

                response = ser.readline().decode().strip()
                return {
                    'success': True,
                    'message': "Command sent successfully. Switch turned off.",
                    'response': response
                }

        port_num = int(port_number)
        if not (1 <= port_num <= 999):
            raise ValueError("Port number must be between 1 and 999")

        with serial.Serial(
            SERIAL_CONFIG['PORT'],
            SERIAL_CONFIG['BAUD_RATE'],
            timeout=SERIAL_CONFIG['TIMEOUT']
        ) as ser:
            command = f"*SW{str(port_num).zfill(3)}\r"
            ser.write(command.encode())

            response = ser.readline().decode().strip()
            return {
                'success': True,
                'message': f"Command sent successfully. Port {port_num} configured.",
                'response': response
            }

    except ValueError as ve:
        return {
            'success': False,
            'message': f"Command failed. Invalid input: {str(ve)}"
        }
    except serial.SerialException as se:
        return {
            'success': False,
            'message': f"Command failed. Serial port error: {str(se)}"
        }
    except Exception as e:
        return {
            'success': False,
            'message': f"Command failed. Unexpected error: {str(e)}"
        }

@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'username' in session:
        return redirect(url_for('index'))
        
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        
        if not username or not password:
            flash('Please provide both username and password', 'error')
            return render_template('login.html')
        
        user = User.query.filter_by(username=username).first()
        
        if user and bcrypt.check_password_hash(user.password, password):
            session.permanent = True  # Use permanent session with timeout
            session['username'] = username
            flash('Successfully logged in', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials', 'error')
    
    return render_template('login.html')

@app.route('/', methods=['GET', 'POST'])
@login_required
def index():
    result_message = None
    if request.method == 'POST':
        port_number = request.form.get('port', '')
        result = send_command(port_number)
        
        # Pass only the 'message' field to the template
        result_message = result['message']
        
        # Flash the message
        flash(result_message, 'success' if result['success'] else 'error')

    return render_template('index.html', result=result_message)

@app.route('/logout')
@login_required
def logout():
    session.clear()  # Clear entire session
    flash('Successfully logged out', 'success')
    return redirect(url_for('login'))

# Error handlers
@app.errorhandler(404)
def not_found_error(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()  # Roll back db session in case of errors
    return render_template('500.html'), 500

if __name__ == '__main__':
    # Create database tables
    with app.app_context():
        db.create_all()
    
    # SSL context with modern cipher configuration
    ssl_context = (
        'server.crt',
        'server.key'
    )
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False,  # Disable debug mode in production
        ssl_context=ssl_context
    )
