from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import mysql.connector
from mysql.connector import Error
import os
from datetime import datetime
from functools import wraps
import re

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this-in-production'
app.config['UPLOAD_FOLDER'] = 'static/uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'flaskuser',
    'password': 'flaskpass',  # Change this to your MySQL password
    'database': 'youtube_app'
}

def get_db_connection():
    """Create and return a database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def login_required(f):
    """Decorator to require login"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to require admin privileges"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('login'))
        if not session.get('is_admin'):
            flash('Admin privileges required.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    """Homepage showing all videos"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return render_template('index.html', videos=[])
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT v.*, u.username 
        FROM videos v 
        JOIN users u ON v.user_id = u.user_id 
        ORDER BY v.created_at DESC
    """)
    videos = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('index.html', videos=videos)

@app.route('/register', methods=['GET', 'POST'])
def register():
    """User registration"""
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        
        # Validation
        if not username or not email or not password:
            flash('All fields are required.', 'danger')
            return redirect(url_for('register'))
        
        if password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return redirect(url_for('register'))
        
        if len(password) < 6:
            flash('Password must be at least 6 characters.', 'danger')
            return redirect(url_for('register'))
        
        conn = get_db_connection()
        if not conn:
            flash('Database connection error', 'danger')
            return redirect(url_for('register'))
        
        cursor = conn.cursor()
        
        # Check if username or email exists
        cursor.execute("SELECT * FROM users WHERE username = %s OR email = %s", (username, email))
        if cursor.fetchone():
            flash('Username or email already exists.', 'danger')
            cursor.close()
            conn.close()
            return redirect(url_for('register'))
        
        # Create user
        password_hash = generate_password_hash(password)
        cursor.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
            (username, email, password_hash)
        )
        conn.commit()
        cursor.close()
        conn.close()
        
        flash('Registration successful! Please log in.', 'success')
        return redirect(url_for('login'))
    
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('Username and password are required.', 'danger')
            return redirect(url_for('login'))
        
        conn = get_db_connection()
        if not conn:
            flash('Database connection error', 'danger')
            return redirect(url_for('login'))
        
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['is_admin'] = user['is_admin']
            flash(f'Welcome back, {user["username"]}!', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password.', 'danger')
            return redirect(url_for('login'))
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """User logout"""
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('index'))

@app.route('/upload', methods=['GET', 'POST'])
@login_required
def upload():
    """Upload a video (thumbnail)"""
    if request.method == 'POST':
        title = request.form.get('title')
        description = request.form.get('description')
        
        if not title:
            flash('Title is required.', 'danger')
            return redirect(url_for('upload'))
        
        # Check if file was uploaded
        if 'thumbnail' not in request.files:
            flash('No file uploaded.', 'danger')
            return redirect(url_for('upload'))
        
        file = request.files['thumbnail']
        
        if file.filename == '':
            flash('No file selected.', 'danger')
            return redirect(url_for('upload'))
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            # Add timestamp to filename to avoid conflicts
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"{timestamp}_{filename}"
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
            # Create upload folder if it doesn't exist
            os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
            
            file.save(filepath)
            
            # Save to database
            conn = get_db_connection()
            if not conn:
                flash('Database connection error', 'danger')
                return redirect(url_for('upload'))
            
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO videos (title, description, thumbnail_path, user_id) VALUES (%s, %s, %s, %s)",
                (title, description, filename, session['user_id'])
            )
            conn.commit()
            cursor.close()
            conn.close()
            
            flash('Video uploaded successfully!', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid file type. Please upload an image file.', 'danger')
            return redirect(url_for('upload'))
    
    return render_template('upload.html')

@app.route('/video/<int:video_id>')
def video(video_id):
    """View a specific video with comments"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('index'))
    
    cursor = conn.cursor(dictionary=True)
    
    # Get video details
    cursor.execute("""
        SELECT v.*, u.username 
        FROM videos v 
        JOIN users u ON v.user_id = u.user_id 
        WHERE v.video_id = %s
    """, (video_id,))
    video = cursor.fetchone()
    
    if not video:
        flash('Video not found.', 'danger')
        cursor.close()
        conn.close()
        return redirect(url_for('index'))
    
    # Increment view count
    cursor.execute("UPDATE videos SET views = views + 1 WHERE video_id = %s", (video_id,))
    conn.commit()
    
    # Get comments with replies
    cursor.execute("""
        SELECT c.*, u.username 
        FROM comments c 
        JOIN users u ON c.user_id = u.user_id 
        WHERE c.video_id = %s 
        ORDER BY c.created_at DESC
    """, (video_id,))
    comments = cursor.fetchall()
    
    # Get replies for each comment
    for comment in comments:
        cursor.execute("""
            SELECT r.*, u.username, m.username as mentioned_username
            FROM replies r 
            JOIN users u ON r.user_id = u.user_id 
            LEFT JOIN users m ON r.mentioned_user_id = m.user_id
            WHERE r.comment_id = %s 
            ORDER BY r.created_at ASC
        """, (comment['comment_id'],))
        comment['replies'] = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('video.html', video=video, comments=comments)

@app.route('/video/<int:video_id>/comment', methods=['POST'])
@login_required
def add_comment(video_id):
    """Add a comment to a video"""
    content = request.form.get('content')
    
    if not content or not content.strip():
        flash('Comment cannot be empty.', 'danger')
        return redirect(url_for('video', video_id=video_id))
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('video', video_id=video_id))
    
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO comments (video_id, user_id, content) VALUES (%s, %s, %s)",
        (video_id, session['user_id'], content)
    )
    conn.commit()
    cursor.close()
    conn.close()
    
    flash('Comment added successfully!', 'success')
    return redirect(url_for('video', video_id=video_id))

@app.route('/comment/<int:comment_id>/reply', methods=['POST'])
@login_required
def add_reply(comment_id):
    """Add a reply to a comment"""
    content = request.form.get('content')
    video_id = request.form.get('video_id')
    
    if not content or not content.strip():
        flash('Reply cannot be empty.', 'danger')
        return redirect(url_for('video', video_id=video_id))
    
    # Extract @username mentions
    mentioned_user_id = None
    mention_match = re.search(r'@(\w+)', content)
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('video', video_id=video_id))
    
    cursor = conn.cursor(dictionary=True)
    
    if mention_match:
        mentioned_username = mention_match.group(1)
        cursor.execute("SELECT user_id FROM users WHERE username = %s", (mentioned_username,))
        mentioned_user = cursor.fetchone()
        if mentioned_user:
            mentioned_user_id = mentioned_user['user_id']
    
    cursor.execute(
        "INSERT INTO replies (comment_id, user_id, content, mentioned_user_id) VALUES (%s, %s, %s, %s)",
        (comment_id, session['user_id'], content, mentioned_user_id)
    )
    conn.commit()
    cursor.close()
    conn.close()
    
    flash('Reply added successfully!', 'success')
    return redirect(url_for('video', video_id=video_id))

@app.route('/admin')
@admin_required
def admin():
    """Admin dashboard"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return render_template('admin.html', videos=[], comments=[])
    
    cursor = conn.cursor(dictionary=True)
    
    # Get all videos
    cursor.execute("""
        SELECT v.*, u.username 
        FROM videos v 
        JOIN users u ON v.user_id = u.user_id 
        ORDER BY v.created_at DESC
    """)
    videos = cursor.fetchall()
    
    # Get all comments
    cursor.execute("""
        SELECT c.*, u.username, v.title as video_title 
        FROM comments c 
        JOIN users u ON c.user_id = u.user_id 
        JOIN videos v ON c.video_id = v.video_id
        ORDER BY c.created_at DESC
    """)
    comments = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin.html', videos=videos, comments=comments)

@app.route('/admin/delete/video/<int:video_id>', methods=['POST'])
@admin_required
def delete_video(video_id):
    """Delete a video (admin only)"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('admin'))
    
    cursor = conn.cursor(dictionary=True)
    
    # Get thumbnail path before deletion
    cursor.execute("SELECT thumbnail_path FROM videos WHERE video_id = %s", (video_id,))
    video = cursor.fetchone()
    
    if video:
        # Delete video from database
        cursor.execute("DELETE FROM videos WHERE video_id = %s", (video_id,))
        conn.commit()
        
        # Delete thumbnail file
        thumbnail_path = os.path.join(app.config['UPLOAD_FOLDER'], video['thumbnail_path'])
        if os.path.exists(thumbnail_path):
            os.remove(thumbnail_path)
        
        flash('Video deleted successfully!', 'success')
    else:
        flash('Video not found.', 'danger')
    
    cursor.close()
    conn.close()
    
    return redirect(url_for('admin'))

@app.route('/admin/delete/comment/<int:comment_id>', methods=['POST'])
@admin_required
def delete_comment(comment_id):
    """Delete a comment (admin only)"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('admin'))
    
    cursor = conn.cursor()
    cursor.execute("DELETE FROM comments WHERE comment_id = %s", (comment_id,))
    conn.commit()
    cursor.close()
    conn.close()
    
    flash('Comment deleted successfully!', 'success')
    return redirect(url_for('admin'))

@app.route('/stats/video/<int:video_id>')
def video_stats(video_id):
    """View detailed video statistics using stored procedure"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('index'))
    
    cursor = conn.cursor(dictionary=True)
    
    # Call stored procedure
    cursor.callproc('get_video_stats', [video_id])
    
    # Fetch results
    stats = None
    for result in cursor.stored_results():
        stats = result.fetchone()
    
    cursor.close()
    conn.close()
    
    if not stats:
        flash('Video not found.', 'danger')
        return redirect(url_for('index'))
    
    return render_template('video_stats.html', stats=stats)

@app.route('/user/<username>')
def user_profile(username):
    """View user profile and activity using stored procedure"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('index'))
    
    cursor = conn.cursor(dictionary=True)
    
    # Call stored procedure
    cursor.callproc('get_user_activity', [username])
    
    # Fetch results
    user_activity = None
    for result in cursor.stored_results():
        user_activity = result.fetchone()
    
    if not user_activity:
        cursor.close()
        conn.close()
        flash('User not found.', 'danger')
        return redirect(url_for('index'))
    
    # Get user's videos
    cursor.execute("""
        SELECT v.*, COUNT(c.comment_id) as comment_count
        FROM videos v
        LEFT JOIN comments c ON v.video_id = c.video_id
        WHERE v.user_id = %s
        GROUP BY v.video_id
        ORDER BY v.created_at DESC
    """, (user_activity['user_id'],))
    user_videos = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('user_profile.html', user=user_activity, videos=user_videos)

@app.route('/trending')
def trending():
    """View trending videos using stored procedure"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return render_template('trending.html', videos=[])
    
    cursor = conn.cursor(dictionary=True)
    
    # Get trending videos - direct query with all needed fields
    cursor.execute("""
        SELECT 
            v.video_id,
            v.title,
            v.thumbnail_path,
            v.views,
            u.username,
            COUNT(DISTINCT c.comment_id) AS comment_count,
            v.created_at
        FROM videos v
        JOIN users u ON v.user_id = u.user_id
        LEFT JOIN comments c ON v.video_id = c.video_id
        WHERE v.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY v.video_id, v.title, v.thumbnail_path, v.views, u.username, v.created_at
        ORDER BY v.views DESC, comment_count DESC
        LIMIT 20
    """)
    trending_videos = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('trending.html', videos=trending_videos)

@app.route('/leaderboard')
def leaderboard():
    """View user leaderboard using view"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return render_template('leaderboard.html', users=[])
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM user_leaderboard LIMIT 50")
    users = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('leaderboard.html', users=users)

@app.route('/activity-log')
@admin_required
def activity_log():
    """View activity log (admin only)"""
    conn = get_db_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return render_template('activity_log.html', logs=[])
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 100")
    logs = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('activity_log.html', logs=logs)

@app.template_filter('timeago')
def timeago_filter(timestamp):
    """Convert timestamp to time ago format"""
    if not timestamp:
        return ''
    
    now = datetime.now()
    diff = now - timestamp
    
    seconds = diff.total_seconds()
    
    if seconds < 60:
        return 'just now'
    elif seconds < 3600:
        minutes = int(seconds / 60)
        return f'{minutes} minute{"s" if minutes > 1 else ""} ago'
    elif seconds < 86400:
        hours = int(seconds / 3600)
        return f'{hours} hour{"s" if hours > 1 else ""} ago'
    elif seconds < 604800:
        days = int(seconds / 86400)
        return f'{days} day{"s" if days > 1 else ""} ago'
    elif seconds < 2592000:
        weeks = int(seconds / 604800)
        return f'{weeks} week{"s" if weeks > 1 else ""} ago'
    else:
        return timestamp.strftime('%B %d, %Y')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
