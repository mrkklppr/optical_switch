from app import app, db

with app.app_context():
    db.create_all()  # Create all tables in the database
    print("Database tables created!")
