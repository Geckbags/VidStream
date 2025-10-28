# VidStream - YouTube-like Comment System

A modern YouTube-inspired video review and comment system built with Flask and MySQL. Features user authentication, video uploads (thumbnails), commenting system with @ mentions, and admin dashboard for content moderation.

## Features

- 👤 **User Authentication**: Register and login system with secure password hashing
- 🎥 **Video Upload**: Upload videos (thumbnails) with title and description
- 💬 **Comment System**: Comment on videos with real-time discussion
- 🔁 **Reply System**: Reply to comments with @ mention support
- 👑 **Admin Dashboard**: Admin account can delete videos and comments
- 📱 **Modern UI**: Responsive design with dark theme
- 🔒 **Secure**: Password hashing, SQL injection protection, and session management

## Screenshots

The application features:
- Clean, modern dark theme interface
- Video grid layout on homepage
- Detailed video view with comments
- User-friendly upload interface
- Powerful admin dashboard

## Technology Stack

- **Backend**: Python Flask
- **Database**: MySQL
- **Frontend**: HTML5, CSS3, JavaScript
- **Icons**: Font Awesome 6
- **Security**: Werkzeug password hashing

## Prerequisites

Before running this application, make sure you have:

- Python 3.8 or higher
- MySQL Server 5.7 or higher
- pip (Python package manager)

## Installation

### 1. Clone or Download the Project

Navigate to the project directory:
```bash
cd /home/geckbags/Programs/DBMS/Youtube_app
```

### 2. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 3. Set Up MySQL Database

First, create the database:

```bash
mysql -u root -p
```

Then in MySQL prompt:
```sql
CREATE DATABASE youtube_app;
EXIT;
```

Import the schema:
```bash
mysql -u root -p youtube_app < schema.sql
```

### 4. Configure Database Connection

Edit `app.py` and update the database configuration (around line 16):

```python
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'YOUR_MYSQL_PASSWORD',  # Change this!
    'database': 'youtube_app'
}
```

### 5. Create Upload Directory

```bash
mkdir -p static/uploads
```

## Running the Application

Start the Flask development server:

```bash
python app.py
```

The application will be available at: `http://localhost:5000`

## Default Admin Account

The application comes with a pre-configured admin account:

- **Username**: `admin`
- **Password**: `admin123`

⚠️ **Important**: Change the admin password after first login for security!

## Usage Guide

### For Regular Users:

1. **Register**: Create an account at `/register`
2. **Login**: Sign in at `/login`
3. **Upload Video**: Navigate to "Upload" and add a thumbnail image with title/description
4. **View Videos**: Browse all videos on the homepage
5. **Comment**: Click on any video to view and add comments
6. **Reply**: Reply to comments and use @username to mention other users

### For Admins:

1. **Login**: Use the admin account credentials
2. **Access Admin Dashboard**: Click "Admin" in the navigation bar
3. **Manage Videos**: View all videos and delete inappropriate content
4. **Manage Comments**: Monitor and delete comments that violate guidelines

## Project Structure

```
Youtube_app/
├── app.py                  # Main Flask application
├── schema.sql             # Database schema
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── static/
│   ├── style.css         # Main stylesheet
│   └── uploads/          # Uploaded thumbnails
└── templates/
    ├── base.html         # Base template
    ├── index.html        # Homepage
    ├── login.html        # Login page
    ├── register.html     # Registration page
    ├── upload.html       # Upload page
    ├── video.html        # Video view page
    └── admin.html        # Admin dashboard
```

## Database Schema

The application uses 4 main tables:

- **users**: User accounts (regular and admin)
- **videos**: Uploaded videos with thumbnails
- **comments**: Comments on videos
- **replies**: Replies to comments with @ mention support

All tables use proper foreign keys and CASCADE deletion for data integrity.

## Features in Detail

### User Authentication
- Secure password hashing using Werkzeug
- Session-based authentication
- Login/logout functionality
- Protected routes for authenticated users

### Video Management
- Upload thumbnails (PNG, JPG, JPEG, GIF, WEBP)
- Maximum file size: 16MB
- Automatic filename sanitization
- View counter for each video

### Comment System
- Hierarchical comments (comments and replies)
- @ mention system for user tagging
- Timestamp display with "time ago" formatting
- Nested replies display

### Admin Panel
- View all videos and comments
- Delete inappropriate content
- Comprehensive dashboard
- Protected admin-only routes

## Security Features

- Password hashing with Werkzeug
- SQL injection protection with parameterized queries
- Secure file upload with extension validation
- Session-based authentication
- CSRF protection ready
- Input sanitization

## Customization

### Changing Colors

Edit `static/style.css` and modify the CSS variables:

```css
:root {
    --primary-color: #ff0000;      /* Main red color */
    --secondary-color: #065fd4;    /* Blue accent */
    --bg-color: #0f0f0f;          /* Background */
    /* ... more variables ... */
}
```

### Adding More Features

The codebase is modular and easy to extend:
- Add more video metadata in `schema.sql` and `app.py`
- Implement likes/dislikes system
- Add video categories
- Implement search functionality
- Add user profiles

## Troubleshooting

### Database Connection Error
- Verify MySQL is running: `sudo systemctl status mysql`
- Check credentials in `app.py`
- Ensure database exists: `SHOW DATABASES;`

### Upload Issues
- Check directory permissions: `chmod 755 static/uploads`
- Verify file size limits in `app.py`
- Check allowed extensions

### Port Already in Use
- Change port in `app.py`: `app.run(port=5001)`
- Or kill process using port 5000: `lsof -ti:5000 | xargs kill`

## Development

To run in development mode with auto-reload:

```bash
export FLASK_ENV=development
python app.py
```

For production deployment, use a WSGI server like Gunicorn:

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

## Contributing

Feel free to fork this project and add your own features! Some ideas:
- Video player integration
- User profile pages
- Search and filter functionality
- Like/dislike system
- Notifications
- Email verification

## License

This project is created for educational purposes.

## Support

For issues or questions, please check:
1. Database connection is properly configured
2. All dependencies are installed
3. MySQL service is running
4. Upload directory has proper permissions

---

**Developed with ❤️ using Flask and MySQL**
