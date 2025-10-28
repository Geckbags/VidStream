# 🚀 Quick Reference Guide - VidStream

## URLs to Access

### Public Pages:
- **Home**: http://localhost:5000/
- **Trending**: http://localhost:5000/trending
- **Leaderboard**: http://localhost:5000/leaderboard
- **Login**: http://localhost:5000/login
- **Register**: http://localhost:5000/register

### User Pages (requires login):
- **Upload Video**: http://localhost:5000/upload
- **Your Profile**: http://localhost:5000/user/YOUR_USERNAME
- **Video View**: http://localhost:5000/video/VIDEO_ID
- **Video Stats**: http://localhost:5000/stats/video/VIDEO_ID

### Admin Pages (requires admin login):
- **Admin Dashboard**: http://localhost:5000/admin
- **Activity Log**: http://localhost:5000/activity-log

---

## Database Commands

### Test Functions:
```sql
-- Get video count for user ID 1
SELECT get_user_video_count(1);

-- Get comment count for user ID 1
SELECT get_user_comment_count(1);

-- Get engagement score for user ID 1
SELECT get_user_engagement_score(1);
```

### Test Procedures:
```sql
-- Video statistics
CALL get_video_stats(1);

-- User activity
CALL get_user_activity('admin');

-- Trending videos (last 30 days, top 10)
CALL get_trending_videos(30, 10);

-- Cleanup old inactive videos (90+ days old with 0 views)
CALL cleanup_inactive_videos(90);
```

### Test Views:
```sql
-- Popular videos
SELECT * FROM popular_videos_view LIMIT 10;

-- User leaderboard
SELECT * FROM user_leaderboard LIMIT 10;

-- Recent activity
SELECT * FROM recent_activity_feed LIMIT 20;
```

### Check Activity Log:
```sql
-- View recent activity
SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 10;

-- View all video uploads
SELECT * FROM activity_log WHERE action_type = 'INSERT' AND table_name = 'videos';

-- View all deletions
SELECT * FROM activity_log WHERE action_type = 'DELETE';
```

---

## Credentials

### Admin Account:
```
Username: admin
Password: admin123
```

### Test User (if you created one):
```
Username: (your username)
Password: (your password)
```

---

## Start/Stop Commands

### Start Application:
```bash
cd /home/geckbags/Programs/DBMS/Youtube_app
source venv/bin/activate
python app.py
```

### Stop Application:
```bash
# Press CTRL+C in the terminal running the app
# Or:
pkill -f "python app.py"
```

### Restart Application:
```bash
pkill -f "python app.py"
cd /home/geckbags/Programs/DBMS/Youtube_app
source venv/bin/activate
python app.py
```

---

## Database Access

### Login to MySQL:
```bash
mysql -u flaskuser -pflaskpass youtube_app
```

### With sudo:
```bash
sudo mysql youtube_app
```

### Show all tables:
```sql
SHOW TABLES;
```

### Check database structure:
```sql
-- Tables
SHOW TABLES;

-- Functions
SHOW FUNCTION STATUS WHERE Db = 'youtube_app';

-- Procedures
SHOW PROCEDURE STATUS WHERE Db = 'youtube_app';

-- Triggers
SHOW TRIGGERS;

-- Views
SHOW FULL TABLES WHERE TABLE_TYPE LIKE 'VIEW';
```

---

## File Locations

### Main Files:
- App: `/home/geckbags/Programs/DBMS/Youtube_app/app.py`
- Schema: `/home/geckbags/Programs/DBMS/Youtube_app/schema.sql`
- Advanced Features: `/home/geckbags/Programs/DBMS/Youtube_app/advanced_features.sql`

### Templates:
- `/home/geckbags/Programs/DBMS/Youtube_app/templates/`

### Static Files:
- CSS: `/home/geckbags/Programs/DBMS/Youtube_app/static/style.css`
- Uploads: `/home/geckbags/Programs/DBMS/Youtube_app/static/uploads/`

---

## Features Summary

### ✅ Implemented Features:

#### User Features:
- [x] User registration
- [x] User login/logout
- [x] Upload videos (thumbnails)
- [x] Comment on videos
- [x] Reply to comments
- [x] @ mention system
- [x] View trending videos
- [x] View leaderboard
- [x] User profiles
- [x] Video statistics

#### Admin Features:
- [x] Admin dashboard
- [x] Delete videos
- [x] Delete comments
- [x] Activity log viewer
- [x] System monitoring

#### Database Features:
- [x] 3 Functions
- [x] 4 Procedures
- [x] 5 Triggers
- [x] 3 Views
- [x] Activity logging

---

## Engagement Score Formula

```
Videos uploaded × 10 points
+ Comments made × 2 points
+ Replies made × 1 point
= Total Engagement Score
```

Example:
- 2 videos = 20 points
- 5 comments = 10 points
- 3 replies = 3 points
- **Total: 33 points**

---

## Troubleshooting

### Can't connect to database:
```bash
# Check MySQL is running
sudo systemctl status mysql

# Check user exists
sudo mysql -e "SELECT User FROM mysql.user WHERE User='flaskuser';"
```

### Port 5000 already in use:
```bash
# Find what's using it
lsof -ti:5000

# Kill it
lsof -ti:5000 | xargs kill
```

### Module not found:
```bash
# Make sure you're in virtual environment
source venv/bin/activate

# Reinstall requirements
pip install -r requirements.txt
```

---

## Need Help?

Check these files for detailed documentation:
- `README.md` - Setup and installation
- `ADVANCED_FEATURES.md` - Database features documentation
- `IMPLEMENTATION_SUMMARY.md` - Complete feature overview

---

**Happy Streaming! 🎬**
