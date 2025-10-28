-- Test Data for VidStream
-- This file adds sample data to test triggers, procedures, and functions

USE youtube_app;

-- Insert test users
INSERT INTO users (username, email, password_hash, is_admin) VALUES
('john_doe', 'john@example.com', 'scrypt:32768:8:1$test1234', FALSE),
('jane_smith', 'jane@example.com', 'scrypt:32768:8:1$test1234', FALSE),
('bob_wilson', 'bob@example.com', 'scrypt:32768:8:1$test1234', FALSE),
('alice_jones', 'alice@example.com', 'scrypt:32768:8:1$test1234', FALSE),
('charlie_brown', 'charlie@example.com', 'scrypt:32768:8:1$test1234', FALSE);

-- Get user IDs for reference
SET @user1 = (SELECT user_id FROM users WHERE username = 'john_doe');
SET @user2 = (SELECT user_id FROM users WHERE username = 'jane_smith');
SET @user3 = (SELECT user_id FROM users WHERE username = 'bob_wilson');
SET @user4 = (SELECT user_id FROM users WHERE username = 'alice_jones');
SET @user5 = (SELECT user_id FROM users WHERE username = 'charlie_brown');

-- Insert test videos (using placeholder thumbnails)
INSERT INTO videos (title, description, thumbnail_path, user_id, views, created_at) VALUES
('Python Tutorial for Beginners', 'Learn Python programming from scratch', 'thumb1.jpg', @user1, 1500, DATE_SUB(NOW(), INTERVAL 2 DAY)),
('JavaScript ES6 Features', 'Modern JavaScript features explained', 'thumb2.jpg', @user2, 2300, DATE_SUB(NOW(), INTERVAL 5 DAY)),
('MySQL Database Design', 'Best practices for database design', 'thumb3.jpg', @user1, 890, DATE_SUB(NOW(), INTERVAL 10 DAY)),
('React Hooks Tutorial', 'Complete guide to React Hooks', 'thumb4.jpg', @user3, 3200, DATE_SUB(NOW(), INTERVAL 1 DAY)),
('Node.js REST API', 'Building REST APIs with Node.js', 'thumb5.jpg', @user2, 1100, DATE_SUB(NOW(), INTERVAL 7 DAY)),
('CSS Grid Layout', 'Master CSS Grid in 30 minutes', 'thumb6.jpg', @user4, 750, DATE_SUB(NOW(), INTERVAL 15 DAY)),
('Docker Basics', 'Getting started with Docker', 'thumb7.jpg', @user5, 2800, DATE_SUB(NOW(), INTERVAL 3 DAY)),
('Git Workflow', 'Professional Git workflow strategies', 'thumb8.jpg', @user1, 1650, DATE_SUB(NOW(), INTERVAL 6 DAY)),
('Flask Web Development', 'Build web apps with Flask', 'thumb9.jpg', @user3, 980, DATE_SUB(NOW(), INTERVAL 12 DAY)),
('MongoDB Crash Course', 'NoSQL database introduction', 'thumb10.jpg', @user4, 2100, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- Get video IDs
SET @vid1 = (SELECT video_id FROM videos WHERE title = 'Python Tutorial for Beginners');
SET @vid2 = (SELECT video_id FROM videos WHERE title = 'JavaScript ES6 Features');
SET @vid3 = (SELECT video_id FROM videos WHERE title = 'MySQL Database Design');
SET @vid4 = (SELECT video_id FROM videos WHERE title = 'React Hooks Tutorial');
SET @vid5 = (SELECT video_id FROM videos WHERE title = 'Node.js REST API');

-- Insert test comments
INSERT INTO comments (video_id, user_id, content, created_at) VALUES
(@vid1, @user2, 'Great tutorial! Very helpful for beginners.', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@vid1, @user3, 'Clear explanations, thanks!', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@vid1, @user4, 'Could you make a part 2?', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@vid2, @user1, 'ES6 features are game changers!', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(@vid2, @user5, 'Arrow functions changed my life', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(@vid3, @user2, 'This helped me with my project', DATE_SUB(NOW(), INTERVAL 9 DAY)),
(@vid4, @user5, 'useState and useEffect are so powerful', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@vid4, @user1, 'Best React tutorial I have seen', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@vid4, @user2, 'Can you cover custom hooks next?', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@vid5, @user3, 'Express makes it so easy!', DATE_SUB(NOW(), INTERVAL 6 DAY));

-- Get comment IDs
SET @comment1 = (SELECT comment_id FROM comments WHERE content = 'Great tutorial! Very helpful for beginners.');
SET @comment2 = (SELECT comment_id FROM comments WHERE content = 'Clear explanations, thanks!');
SET @comment3 = (SELECT comment_id FROM comments WHERE content = 'Could you make a part 2?');
SET @comment4 = (SELECT comment_id FROM comments WHERE content = 'Best React tutorial I have seen');

-- Insert test replies with @ mentions
INSERT INTO replies (comment_id, user_id, content, mentioned_user_id, created_at) VALUES
(@comment1, @user1, '@jane_smith Thank you so much! Part 2 coming soon.', @user2, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@comment3, @user1, '@alice_jones Yes! Working on it now.', @user4, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@comment4, @user3, '@john_doe Thanks! Glad it helped.', @user1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@comment2, @user1, '@bob_wilson Happy to help!', @user3, DATE_SUB(NOW(), INTERVAL 1 DAY));

SELECT 'Test data inserted successfully!' AS status;
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_videos FROM videos;
SELECT COUNT(*) AS total_comments FROM comments;
SELECT COUNT(*) AS total_replies FROM replies;
