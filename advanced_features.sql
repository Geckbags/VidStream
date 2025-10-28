-- Advanced Database Features: Triggers, Procedures, and Functions
-- Run this after schema.sql to add advanced features

USE youtube_app;

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Function 1: Calculate total videos by user
DELIMITER //
DROP FUNCTION IF EXISTS get_user_video_count//
CREATE FUNCTION get_user_video_count(user_id_param INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE video_count INT;
    SELECT COUNT(*) INTO video_count
    FROM videos
    WHERE user_id = user_id_param;
    RETURN video_count;
END//
DELIMITER ;

-- Function 2: Calculate total comments by user
DELIMITER //
DROP FUNCTION IF EXISTS get_user_comment_count//
CREATE FUNCTION get_user_comment_count(user_id_param INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE comment_count INT;
    SELECT COUNT(*) INTO comment_count
    FROM comments
    WHERE user_id = user_id_param;
    RETURN comment_count;
END//
DELIMITER ;

-- Function 3: Get user engagement score (videos + comments + replies)
DELIMITER //
DROP FUNCTION IF EXISTS get_user_engagement_score//
CREATE FUNCTION get_user_engagement_score(user_id_param INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_engagement INT;
    DECLARE video_count INT;
    DECLARE comment_count INT;
    DECLARE reply_count INT;
    
    SELECT COUNT(*) INTO video_count FROM videos WHERE user_id = user_id_param;
    SELECT COUNT(*) INTO comment_count FROM comments WHERE user_id = user_id_param;
    SELECT COUNT(*) INTO reply_count FROM replies WHERE user_id = user_id_param;
    
    SET total_engagement = (video_count * 10) + (comment_count * 2) + reply_count;
    RETURN total_engagement;
END//
DELIMITER ;

-- ============================================================
-- PROCEDURES
-- ============================================================

-- Procedure 1: Get video statistics
DELIMITER //
DROP PROCEDURE IF EXISTS get_video_stats//
CREATE PROCEDURE get_video_stats(IN video_id_param INT)
BEGIN
    SELECT 
        v.video_id,
        v.title,
        v.views,
        u.username AS uploaded_by,
        COUNT(DISTINCT c.comment_id) AS total_comments,
        COUNT(DISTINCT r.reply_id) AS total_replies,
        v.created_at
    FROM videos v
    JOIN users u ON v.user_id = u.user_id
    LEFT JOIN comments c ON v.video_id = c.video_id
    LEFT JOIN replies r ON c.comment_id = r.comment_id
    WHERE v.video_id = video_id_param
    GROUP BY v.video_id, v.title, v.views, u.username, v.created_at;
END//
DELIMITER ;

-- Procedure 2: Get user activity summary
DELIMITER //
DROP PROCEDURE IF EXISTS get_user_activity//
CREATE PROCEDURE get_user_activity(IN username_param VARCHAR(50))
BEGIN
    DECLARE user_id_var INT;
    
    SELECT user_id INTO user_id_var FROM users WHERE username = username_param LIMIT 1;
    
    SELECT 
        u.user_id,
        u.username,
        u.email,
        u.is_admin,
        u.created_at AS member_since,
        COUNT(DISTINCT v.video_id) AS total_videos,
        COALESCE(SUM(v.views), 0) AS total_views,
        COUNT(DISTINCT c.comment_id) AS total_comments,
        COUNT(DISTINCT r.reply_id) AS total_replies,
        get_user_engagement_score(u.user_id) AS engagement_score
    FROM users u
    LEFT JOIN videos v ON u.user_id = v.user_id
    LEFT JOIN comments c ON u.user_id = c.user_id
    LEFT JOIN replies r ON u.user_id = r.user_id
    WHERE u.user_id = user_id_var
    GROUP BY u.user_id, u.username, u.email, u.is_admin, u.created_at;
END//
DELIMITER ;

-- Procedure 3: Clean up old data (delete videos with zero views older than certain days)
DELIMITER //
DROP PROCEDURE IF EXISTS cleanup_inactive_videos//
CREATE PROCEDURE cleanup_inactive_videos(IN days_old INT)
BEGIN
    DECLARE deleted_count INT;
    
    SELECT COUNT(*) INTO deleted_count
    FROM videos
    WHERE views = 0 
    AND created_at < DATE_SUB(NOW(), INTERVAL days_old DAY);
    
    DELETE FROM videos
    WHERE views = 0 
    AND created_at < DATE_SUB(NOW(), INTERVAL days_old DAY);
    
    SELECT CONCAT('Deleted ', deleted_count, ' inactive videos') AS result;
END//
DELIMITER ;

-- Procedure 4: Get trending videos (most viewed in last N days)
DELIMITER //
DROP PROCEDURE IF EXISTS get_trending_videos//
CREATE PROCEDURE get_trending_videos(IN days_param INT, IN limit_param INT)
BEGIN
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
    WHERE v.created_at >= DATE_SUB(NOW(), INTERVAL days_param DAY)
    GROUP BY v.video_id, v.title, v.thumbnail_path, v.views, u.username, v.created_at
    ORDER BY v.views DESC, comment_count DESC
    LIMIT limit_param;
END//
DELIMITER ;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Create activity log table for triggers
CREATE TABLE IF NOT EXISTS activity_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    user_id INT,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger 1: Log video uploads
DELIMITER //
DROP TRIGGER IF EXISTS after_video_insert//
CREATE TRIGGER after_video_insert
AFTER INSERT ON videos
FOR EACH ROW
BEGIN
    INSERT INTO activity_log (action_type, table_name, record_id, user_id, details)
    VALUES ('INSERT', 'videos', NEW.video_id, NEW.user_id, 
            CONCAT('Video uploaded: ', NEW.title));
END//
DELIMITER ;

-- Trigger 2: Log video deletions
DELIMITER //
DROP TRIGGER IF EXISTS before_video_delete//
CREATE TRIGGER before_video_delete
BEFORE DELETE ON videos
FOR EACH ROW
BEGIN
    INSERT INTO activity_log (action_type, table_name, record_id, user_id, details)
    VALUES ('DELETE', 'videos', OLD.video_id, OLD.user_id, 
            CONCAT('Video deleted: ', OLD.title, ' (Views: ', OLD.views, ')'));
END//
DELIMITER ;

-- Trigger 3: Log comment creation
DELIMITER //
DROP TRIGGER IF EXISTS after_comment_insert//
CREATE TRIGGER after_comment_insert
AFTER INSERT ON comments
FOR EACH ROW
BEGIN
    INSERT INTO activity_log (action_type, table_name, record_id, user_id, details)
    VALUES ('INSERT', 'comments', NEW.comment_id, NEW.user_id, 
            CONCAT('Comment added on video_id: ', NEW.video_id));
END//
DELIMITER ;

-- Trigger 4: Prevent deleting admin users
DELIMITER //
DROP TRIGGER IF EXISTS before_user_delete//
CREATE TRIGGER before_user_delete
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    IF OLD.is_admin = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete admin user';
    END IF;
END//
DELIMITER ;

-- Trigger 5: Auto-update view count validation
DELIMITER //
DROP TRIGGER IF EXISTS before_video_update//
CREATE TRIGGER before_video_update
BEFORE UPDATE ON videos
FOR EACH ROW
BEGIN
    -- Ensure views never decrease
    IF NEW.views < OLD.views THEN
        SET NEW.views = OLD.views;
    END IF;
END//
DELIMITER ;

-- ============================================================
-- VIEWS (Bonus: Useful for reporting)
-- ============================================================

-- View 1: Popular videos with engagement metrics
CREATE OR REPLACE VIEW popular_videos_view AS
SELECT 
    v.video_id,
    v.title,
    v.description,
    v.thumbnail_path,
    u.username AS uploader,
    v.views,
    COUNT(DISTINCT c.comment_id) AS comment_count,
    COUNT(DISTINCT r.reply_id) AS reply_count,
    (v.views + COUNT(DISTINCT c.comment_id) * 5 + COUNT(DISTINCT r.reply_id) * 2) AS engagement_score,
    v.created_at
FROM videos v
JOIN users u ON v.user_id = u.user_id
LEFT JOIN comments c ON v.video_id = c.video_id
LEFT JOIN replies r ON c.comment_id = r.comment_id
GROUP BY v.video_id, v.title, v.description, v.thumbnail_path, u.username, v.views, v.created_at
ORDER BY engagement_score DESC;

-- View 2: User leaderboard
CREATE OR REPLACE VIEW user_leaderboard AS
SELECT 
    u.user_id,
    u.username,
    COUNT(DISTINCT v.video_id) AS total_videos,
    COALESCE(SUM(v.views), 0) AS total_views,
    COUNT(DISTINCT c.comment_id) AS total_comments,
    COUNT(DISTINCT r.reply_id) AS total_replies,
    get_user_engagement_score(u.user_id) AS engagement_score
FROM users u
LEFT JOIN videos v ON u.user_id = v.user_id
LEFT JOIN comments c ON u.user_id = c.user_id
LEFT JOIN replies r ON u.user_id = r.user_id
WHERE u.is_admin = FALSE
GROUP BY u.user_id, u.username
ORDER BY engagement_score DESC;

-- View 3: Recent activity feed
CREATE OR REPLACE VIEW recent_activity_feed AS
SELECT 
    'video' AS activity_type,
    v.video_id AS item_id,
    v.title AS content,
    u.username,
    v.created_at
FROM videos v
JOIN users u ON v.user_id = u.user_id
UNION ALL
SELECT 
    'comment' AS activity_type,
    c.comment_id AS item_id,
    LEFT(c.content, 100) AS content,
    u.username,
    c.created_at
FROM comments c
JOIN users u ON c.user_id = u.user_id
UNION ALL
SELECT 
    'reply' AS activity_type,
    r.reply_id AS item_id,
    LEFT(r.content, 100) AS content,
    u.username,
    r.created_at
FROM replies r
JOIN users u ON r.user_id = u.user_id
ORDER BY created_at DESC
LIMIT 50;

-- ============================================================
-- Test the functions and procedures
-- ============================================================

-- Test queries (run these to verify everything works)
-- SELECT get_user_video_count(1) AS video_count;
-- SELECT get_user_comment_count(1) AS comment_count;
-- SELECT get_user_engagement_score(1) AS engagement_score;
-- CALL get_video_stats(1);
-- CALL get_user_activity('admin');
-- CALL get_trending_videos(30, 10);
-- SELECT * FROM popular_videos_view LIMIT 10;
-- SELECT * FROM user_leaderboard LIMIT 10;
-- SELECT * FROM recent_activity_feed LIMIT 20;
-- SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 10;

-- ============================================================
-- Grant permissions to flaskuser
-- ============================================================

GRANT EXECUTE ON FUNCTION youtube_app.get_user_video_count TO 'flaskuser'@'localhost';
GRANT EXECUTE ON FUNCTION youtube_app.get_user_comment_count TO 'flaskuser'@'localhost';
GRANT EXECUTE ON FUNCTION youtube_app.get_user_engagement_score TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.get_video_stats TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.get_user_activity TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.get_trending_videos TO 'flaskuser'@'localhost';
GRANT EXECUTE ON PROCEDURE youtube_app.cleanup_inactive_videos TO 'flaskuser'@'localhost';
GRANT SELECT ON youtube_app.activity_log TO 'flaskuser'@'localhost';
GRANT SELECT ON youtube_app.popular_videos_view TO 'flaskuser'@'localhost';
GRANT SELECT ON youtube_app.user_leaderboard TO 'flaskuser'@'localhost';
GRANT SELECT ON youtube_app.recent_activity_feed TO 'flaskuser'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Advanced database features installed successfully!' AS status;
