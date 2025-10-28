# Configuration Template
# Copy this file to config.py and update with your settings

class Config:
    # Flask Settings
    SECRET_KEY = 'your-secret-key-change-this-in-production'
    DEBUG = True
    HOST = '0.0.0.0'
    PORT = 5000
    
    # Database Settings
    DB_HOST = 'localhost'
    DB_USER = 'root'
    DB_PASSWORD = ''  # Change this to your MySQL password
    DB_NAME = 'youtube_app'
    
    # Upload Settings
    UPLOAD_FOLDER = 'static/uploads'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
    
    # Application Settings
    SITE_NAME = 'VidStream'
    VIDEOS_PER_PAGE = 20
    COMMENTS_PER_PAGE = 50
