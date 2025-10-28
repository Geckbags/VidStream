# Advanced Database Features Documentation

This document explains all the **triggers**, **procedures**, **functions**, and **views** implemented in the VidStream YouTube Comment System.

---

## 📊 Database Functions (3)

### 1. `get_user_video_count(user_id)`
**Purpose:** Calculate the total number of videos uploaded by a user.

**Parameters:**
- `user_id_param` (INT): The ID of the user

**Returns:** INT - Count of videos

**Usage:**
```sql
SELECT get_user_video_count(1) AS video_count;
```

---

### 2. `get_user_comment_count(user_id)`
**Purpose:** Calculate the total number of comments made by a user.

**Parameters:**
- `user_id_param` (INT): The ID of the user

**Returns:** INT - Count of comments

**Usage:**
```sql
SELECT get_user_comment_count(1) AS comment_count;
```

---

### 3. `get_user_engagement_score(user_id)`
**Purpose:** Calculate a user's overall engagement score based on their activity.

**Formula:** `(videos × 10) + (comments × 2) + replies`

**Parameters:**
- `user_id_param` (INT): The ID of the user

**Returns:** INT - Engagement score

**Usage:**
```sql
SELECT get_user_engagement_score(1) AS engagement_score;
```

---

## 🔧 Stored Procedures (4)

### 1. `get_video_stats(video_id)`
**Purpose:** Get comprehensive statistics for a specific video.

**Parameters:**
- `video_id_param` (INT): The ID of the video

**Returns:** Result set with:
- video_id
- title
- views
- uploaded_by (username)
- total_comments
- total_replies
- created_at

**Usage:**
```sql
CALL get_video_stats(1);
```

**Used in:** `/stats/video/<id>` route

---

### 2. `get_user_activity(username)`
**Purpose:** Get complete activity summary for a user.

**Parameters:**
- `username_param` (VARCHAR): The username

**Returns:** Result set with:
- user_id
- username
- email
- is_admin
- member_since
- total_videos
- total_views
- total_comments
- total_replies
- engagement_score

**Usage:**
```sql
CALL get_user_activity('admin');
```

**Used in:** `/user/<username>` route

---

### 3. `get_trending_videos(days, limit)`
**Purpose:** Get the most viewed videos from the last N days.

**Parameters:**
- `days_param` (INT): Number of days to look back
- `limit_param` (INT): Maximum number of results

**Returns:** Result set with videos sorted by views and engagement

**Usage:**
```sql
CALL get_trending_videos(30, 10);
```

**Used in:** `/trending` route

---

### 4. `cleanup_inactive_videos(days_old)`
**Purpose:** Delete videos with zero views older than specified days (maintenance).

**Parameters:**
- `days_old` (INT): Age threshold in days

**Returns:** Message with count of deleted videos

**Usage:**
```sql
CALL cleanup_inactive_videos(90);
```

**Admin maintenance procedure**

---

## ⚡ Triggers (5)

### 1. `after_video_insert`
**Event:** AFTER INSERT on `videos` table

**Purpose:** Log all video uploads to activity_log

**Action:** Automatically creates a log entry when a video is uploaded

**Example log entry:**
```
Action: INSERT
Table: videos
Details: "Video uploaded: My Amazing Video"
```

---

### 2. `before_video_delete`
**Event:** BEFORE DELETE on `videos` table

**Purpose:** Log video deletions before they happen

**Action:** Records video details before deletion for audit trail

**Example log entry:**
```
Action: DELETE
Table: videos
Details: "Video deleted: Spam Video (Views: 5)"
```

---

### 3. `after_comment_insert`
**Event:** AFTER INSERT on `comments` table

**Purpose:** Log all new comments

**Action:** Creates activity log entry for each new comment

**Example log entry:**
```
Action: INSERT
Table: comments
Details: "Comment added on video_id: 1"
```

---

### 4. `before_user_delete`
**Event:** BEFORE DELETE on `users` table

**Purpose:** Prevent deletion of admin users

**Action:** Raises error if attempting to delete an admin account

**Protection:** Ensures at least one admin always exists

---

### 5. `before_video_update`
**Event:** BEFORE UPDATE on `videos` table

**Purpose:** Ensure view counts never decrease

**Action:** If new views < old views, keep old value

**Data Integrity:** Prevents view count manipulation

---

## 👁️ Views (3)

### 1. `popular_videos_view`
**Purpose:** Show videos ranked by engagement score

**Columns:**
- video_id
- title
- description
- uploader (username)
- views
- comment_count
- reply_count
- engagement_score (calculated)
- created_at

**Formula:** `engagement_score = views + (comments × 5) + (replies × 2)`

**Usage:**
```sql
SELECT * FROM popular_videos_view LIMIT 10;
```

---

### 2. `user_leaderboard`
**Purpose:** Rank users by their engagement score

**Columns:**
- user_id
- username
- total_videos
- total_views
- total_comments
- total_replies
- engagement_score (from function)

**Sorted by:** engagement_score DESC

**Excludes:** Admin users

**Usage:**
```sql
SELECT * FROM user_leaderboard LIMIT 50;
```

**Used in:** `/leaderboard` route

---

### 3. `recent_activity_feed`
**Purpose:** Show recent activity across the platform

**Combines:**
- Video uploads
- New comments
- New replies

**Columns:**
- activity_type ('video', 'comment', or 'reply')
- item_id
- content
- username
- created_at

**Sorted by:** created_at DESC

**Limit:** 50 most recent items

**Usage:**
```sql
SELECT * FROM recent_activity_feed;
```

---

## 📝 Activity Log Table

**Created by triggers to track all system activity**

**Structure:**
```sql
CREATE TABLE activity_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    action_type VARCHAR(50),  -- INSERT, UPDATE, DELETE
    table_name VARCHAR(50),   -- Which table was affected
    record_id INT,            -- ID of affected record
    user_id INT,              -- Who performed the action
    details TEXT,             -- Human-readable description
    created_at TIMESTAMP
);
```

**Accessed via:** `/activity-log` route (admin only)

---

## 🌐 Flask Routes Using Advanced Features

### New Routes Added:

1. **`/trending`** - Shows trending videos using `get_trending_videos()` procedure
2. **`/leaderboard`** - Shows user rankings using `user_leaderboard` view
3. **`/user/<username>`** - User profiles using `get_user_activity()` procedure
4. **`/stats/video/<id>`** - Video statistics using `get_video_stats()` procedure
5. **`/activity-log`** - Activity audit log (admin only)

---

## 🔐 Permissions

All procedures and functions have been granted to `flaskuser`:

```sql
GRANT EXECUTE ON FUNCTION youtube_app.get_user_video_count TO 'flaskuser'@'localhost';
GRANT EXECUTE ON FUNCTION youtube_app.get_user_comment_count TO 'flaskuser'@'localhost';
GRANT EXECUTE ON FUNCTION youtube_app.get_user_engagement_score TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.get_video_stats TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.get_user_activity TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.get_trending_videos TO 'flaskuser'@'localhost';
GRANT SELECT ON youtube_app.activity_log TO 'flaskuser'@'localhost';
-- etc.
```

---

## 📈 Benefits

### Triggers:
✅ **Automatic audit logging** - No code changes needed  
✅ **Data integrity** - Prevent invalid operations  
✅ **Activity tracking** - Complete audit trail

### Procedures:
✅ **Complex queries simplified** - Reusable business logic  
✅ **Better performance** - Compiled and optimized  
✅ **Consistent results** - Same logic everywhere

### Functions:
✅ **Reusable calculations** - Use in SELECT statements  
✅ **Encapsulation** - Hide complexity  
✅ **Type safety** - Defined return types

### Views:
✅ **Simplified queries** - Complex joins abstracted  
✅ **Security** - Hide underlying table structure  
✅ **Consistency** - Same data format everywhere

---

## 🧪 Testing the Features

### Test Functions:
```sql
-- Test engagement score
SELECT 
    username,
    get_user_video_count(user_id) AS videos,
    get_user_comment_count(user_id) AS comments,
    get_user_engagement_score(user_id) AS score
FROM users;
```

### Test Procedures:
```sql
-- Get video stats
CALL get_video_stats(1);

-- Get user activity
CALL get_user_activity('admin');

-- Get trending videos (last 7 days, top 5)
CALL get_trending_videos(7, 5);
```

### Test Triggers:
```sql
-- Upload a video and check activity_log
INSERT INTO videos (title, description, thumbnail_path, user_id) 
VALUES ('Test Video', 'Test', 'test.jpg', 1);

SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 5;
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

---

## 🎯 Summary

**Total Advanced Features Implemented:**
- ✅ **3 Functions** (user metrics and calculations)
- ✅ **4 Procedures** (complex operations and reporting)
- ✅ **5 Triggers** (automatic logging and validation)
- ✅ **3 Views** (simplified queries and reporting)
- ✅ **1 Activity Log Table** (audit trail)
- ✅ **5 New Routes** (leveraging advanced features)

All requirements met and exceeded! 🚀
