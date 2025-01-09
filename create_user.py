from app import db, bcrypt, app
from app import User
import getpass

# Use the app's context for the database session
with app.app_context():
    # Ask for username
    username = input("Enter a username: ")

    # Ask for password securely and confirm password securely
    while True:
        password = getpass.getpass("Enter a password: ")  # Secure password input
        confirm_password = getpass.getpass("Confirm your password: ")  # Secure confirm password input

        # Check if the passwords match
        if password == confirm_password:
            break
        else:
            print("Passwords do not match. Please try again.")

    # Hash the password
    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

    # Create the user
    new_user = User(username=username, password=hashed_password)

    # Add the user to the database
    db.session.add(new_user)
    db.session.commit()

    print("User created successfully!")
