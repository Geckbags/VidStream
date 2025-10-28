# 🧪 Testing Guide - Advanced Database Features

Test data has been added! Here's how to test all the triggers, procedures, and functions.

---

## 📊 TEST FUNCTIONS

### 1. Test `get_user_video_count()`
**What it does:** Counts how many videos a user has uploaded

```sql
-- Test for user john_doe (should have 3 videos)
SELECT get_user_video_count(
    (SELECT user_id FROM users WHERE username = 'john_doe')
) AS john_video_count;

-- Test for all users
SELECT 
    username,
    get_user_video_count(user_id) AS video_count
FROM users
WHERE is_admin = FALSE
ORDER BY video_count DESC;
```

**Expected:** You'll see video counts for each user.

---

### 2. Test `get_user_comment_count()`
**What it does:** Counts total comments by a user

```sql
-- Test for a specific user
SELECT get_user_comment_count(
    (SELECT user_id FROM users WHERE username = 'jane_smith')
) AS jane_comment_count;

-- Test for all users
SELECT 
    username,
    get_user_comment_count(user_id) AS comment_count
FROM users
WHERE is_admin = FALSE
ORDER BY comment_count DESC;
```

**Expected:** Shows comment counts per user.

---

### 3. Test `get_user_engagement_score()`
**What it does:** Calculates engagement score (videos×10 + comments×2 + replies)

```sql
-- Test engagement score for one user
SELECT 
    username,
    get_user_video_count(user_id) AS videos,
    get_user_comment_count(user_id) AS comments,
    get_user_engagement_score(user_id) AS engagement_score
FROM users
WHERE username = 'john_doe';

-- Compare all users
SELECT 
    username,
    get_user_engagement_score(user_id) AS score
FROM users
WHERE is_admin = FALSE
ORDER BY score DESC;
```

**Expected:** john_doe should have high engagement (he has 3 videos = 30 points + comments + replies).

---

## 🔧 TEST PROCEDURES

### 1. Test `get_video_stats()`
**What it does:** Shows complete statistics for a video

```sql
-- Get stats for video ID 1
CALL get_video_stats(1);

-- Try different videos
CALL get_video_stats(4);  -- React Hooks Tutorial (should have most views)
```

**Expected Output:**
- video_id
- title
- views
- uploaded_by (username)
- total_comments
- total_replies
- created_at

---

### 2. Test `get_user_activity()`
**What it does:** Complete user profile with all stats

```sql
-- Get activity for john_doe
CALL get_user_activity('john_doe');

-- Try other users
CALL get_user_activity('jane_smith');
CALL get_user_activity('bob_wilson');
```

**Expected Output:**
- user_id
- username
- email
- total_videos
- total_views
- total_comments
- total_replies
- engagement_score

---

### 3. Test `get_trending_videos()`
**What it does:** Find most popular videos from recent days

```sql
-- Get top 5 trending videos from last 30 days
CALL get_trending_videos(30, 5);

-- Get top 10 from last 7 days
CALL get_trending_videos(7, 10);

-- All videos from last 3 days
CALL get_trending_videos(3, 100);
```

**Expected:** Videos sorted by views (React Hooks should be #1 with 3200 views).

---

### 4. Test `cleanup_inactive_videos()`
**What it does:** Deletes old videos with 0 views (maintenance)

```sql
-- This won't delete anything since all test videos have views
CALL cleanup_inactive_videos(90);

-- To actually test it, first insert a zero-view old video:
INSERT INTO videos (title, description, thumbnail_path, user_id, views, created_at)
VALUES ('Old Unused Video', 'Test', 'old.jpg', 
    (SELECT user_id FROM users WHERE username = 'john_doe'), 
    0, 
    DATE_SUB(NOW(), INTERVAL 100 DAY));

-- Now cleanup will delete it
CALL cleanup_inactive_videos(90);
```

**Expected:** Shows count of deleted videos.

---

## ⚡ TEST TRIGGERS

### 1. Test `after_video_insert` Trigger
**What it does:** Logs every video upload

```sql
-- Insert a new video (trigger fires automatically)
INSERT INTO videos (title, description, thumbnail_path, user_id)
VALUES ('New Test Video', 'Testing trigger', 'test.jpg', 
    (SELECT user_id FROM users WHERE username = 'john_doe'));

-- Check the activity log
SELECT * FROM activity_log 
WHERE action_type = 'INSERT' AND table_name = 'videos'
ORDER BY created_at DESC 
LIMIT 5;
```

**Expected:** See log entry: "Video uploaded: New Test Video"

---

### 2. Test `after_comment_insert` Trigger
**What it does:** Logs every comment

```sql
-- Add a comment (trigger fires automatically)
INSERT INTO comments (video_id, user_id, content)
VALUES (1, 
    (SELECT user_id FROM users WHERE username = 'jane_smith'),
    'This is a test comment for trigger!');

-- Check the log
SELECT * FROM activity_log 
WHERE action_type = 'INSERT' AND table_name = 'comments'
ORDER BY created_at DESC 
LIMIT 5;
```

**Expected:** See log entry: "Comment added on video_id: 1"

---

### 3. Test `before_video_delete` Trigger
**What it does:** Logs video details before deletion

```sql
-- Delete a video (trigger logs it first)
DELETE FROM videos WHERE title = 'New Test Video';

-- Check the log
SELECT * FROM activity_log 
WHERE action_type = 'DELETE' AND table_name = 'videos'
ORDER BY created_at DESC 
LIMIT 5;
```

**Expected:** See log with video details: "Video deleted: New Test Video (Views: 0)"

---

### 4. Test `before_user_delete` Trigger
**What it does:** PREVENTS deleting admin users

```sql
-- Try to delete admin (should FAIL)
DELETE FROM users WHERE username = 'admin';

-- Try to delete regular user (should SUCCEED)
DELETE FROM users WHERE username = 'charlie_brown';
```

**Expected:** 
- Admin deletion fails with error: "Cannot delete admin user"
- Regular user deletion succeeds

---

### 5. Test `before_video_update` Trigger
**What it does:** Prevents view count from decreasing

```sql
-- Try to decrease views (trigger prevents it)
UPDATE videos 
SET views = 100 
WHERE title = 'React Hooks Tutorial';

-- Check if views stayed the same (should still be 3200)
SELECT title, views FROM videos WHERE title = 'React Hooks Tutorial';

-- Increase views (this should work)
UPDATE videos 
SET views = 3500 
WHERE title = 'React Hooks Tutorial';

SELECT title, views FROM videos WHERE title = 'React Hooks Tutorial';
```

**Expected:** Views can increase but never decrease!

---

## 👁️ TEST VIEWS

### 1. Test `popular_videos_view`
**What it does:** Shows videos ranked by engagement

```sql
-- Get top 10 most engaging videos
SELECT * FROM popular_videos_view LIMIT 10;

-- Show specific columns
SELECT 
    title, 
    uploader, 
    views, 
    comment_count, 
    engagement_score 
FROM popular_videos_view
ORDER BY engagement_score DESC;
```

**Expected:** React Hooks Tutorial should rank high (most views + comments).

---

### 2. Test `user_leaderboard`
**What it does:** Ranks users by engagement

```sql
-- Top users by engagement
SELECT * FROM user_leaderboard LIMIT 10;

-- Show detailed breakdown
SELECT 
    username,
    total_videos,
    total_views,
    total_comments,
    engagement_score
FROM user_leaderboard
ORDER BY engagement_score DESC;
```

**Expected:** john_doe should rank high (has 3 videos).

---

### 3. Test `recent_activity_feed`
**What it does:** Shows recent activity across platform

```sql
-- Last 20 activities
SELECT * FROM recent_activity_feed LIMIT 20;

-- Only video uploads
SELECT * FROM recent_activity_feed 
WHERE activity_type = 'video' 
LIMIT 10;

-- Only comments
SELECT * FROM recent_activity_feed 
WHERE activity_type = 'comment' 
LIMIT 10;
```

**Expected:** Mixed feed of videos, comments, and replies.

---

## 🌐 TEST IN WEB APPLICATION

### Visit these URLs:

1. **Trending Page:** http://localhost:5000/trending
   - Should show videos sorted by views
   - React Hooks Tutorial should be #1

2. **Leaderboard:** http://localhost:5000/leaderboard
   - Users ranked by engagement
   - john_doe should be at top

3. **User Profile:** http://localhost:5000/user/john_doe
   - Shows all stats for john_doe
   - See his 3 videos listed

4. **Activity Log (Admin):** http://localhost:5000/activity-log
   - Login as admin first
   - See all logged activities from triggers

---

## 🎯 QUICK TEST SEQUENCE

**Run these commands in order to see everything:**

```sql
-- 1. Test all functions at once
SELECT 
    u.username,
    get_user_video_count(u.user_id) AS videos,
    get_user_comment_count(u.user_id) AS comments,
    get_user_engagement_score(u.user_id) AS score
FROM users u
WHERE u.is_admin = FALSE
ORDER BY score DESC;

-- 2. Test stored procedure
CALL get_video_stats(4);

-- 3. Test trending
CALL get_trending_videos(30, 5);

-- 4. Test user activity
CALL get_user_activity('john_doe');

-- 5. Check activity log (from triggers)
SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 10;

-- 6. Test views
SELECT * FROM popular_videos_view LIMIT 5;
SELECT * FROM user_leaderboard LIMIT 5;
SELECT * FROM recent_activity_feed LIMIT 10;

-- 7. Test trigger by inserting
INSERT INTO comments (video_id, user_id, content)
VALUES (1, (SELECT user_id FROM users WHERE username = 'jane_smith'), 
    'Testing trigger now!');

-- Check if it was logged
SELECT * FROM activity_log WHERE table_name = 'comments' 
ORDER BY created_at DESC LIMIT 1;
```

---

## 📊 CURRENT DATABASE STATS

```sql
-- See what's in the database
SELECT 
    (SELECT COUNT(*) FROM users WHERE is_admin = FALSE) AS total_users,
    (SELECT COUNT(*) FROM videos) AS total_videos,
    (SELECT COUNT(*) FROM comments) AS total_comments,
    (SELECT COUNT(*) FROM replies) AS total_replies,
    (SELECT COUNT(*) FROM activity_log) AS logged_activities;
```

---

## 🎮 INTERACTIVE TESTING

### Access MySQL shell:
```bash
mysql -u flaskuser -pflaskpass youtube_app
```

### Then run any of the commands above!

---

## 📝 Expected Results Summary

**Functions:**
- ✅ `get_user_video_count()` - Returns integer count
- ✅ `get_user_comment_count()` - Returns integer count
- ✅ `get_user_engagement_score()` - Returns calculated score

**Procedures:**
- ✅ `get_video_stats()` - Returns result set with 7 columns
- ✅ `get_user_activity()` - Returns result set with 10 columns
- ✅ `get_trending_videos()` - Returns sorted video list
- ✅ `cleanup_inactive_videos()` - Returns deletion count

**Triggers:**
- ✅ `after_video_insert` - Auto-logs to activity_log
- ✅ `after_comment_insert` - Auto-logs to activity_log
- ✅ `before_video_delete` - Auto-logs before deletion
- ✅ `before_user_delete` - Prevents admin deletion
- ✅ `before_video_update` - Prevents view decrease

**Views:**
- ✅ `popular_videos_view` - Queryable like a table
- ✅ `user_leaderboard` - Queryable like a table
- ✅ `recent_activity_feed` - Queryable like a table

---

**Have fun testing! 🚀**
