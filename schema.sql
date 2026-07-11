CREATE DATABASE IF NOT EXISTS silverconnect CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE silverconnect;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  avatar CHAR(1) DEFAULT 'S',
  status ENUM('online','offline') DEFAULT 'offline',
  language VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS groups_tb (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(50) NOT NULL,
  color_class VARCHAR(100) NOT NULL,
  description TEXT,
  members_count INT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_groups (
  user_id INT NOT NULL,
  group_id INT NOT NULL,
  PRIMARY KEY (user_id, group_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES groups_tb(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  content TEXT NOT NULL,
  room VARCHAR(100) NOT NULL DEFAULT 'general',
  image_url VARCHAR(500) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  event_date DATE NOT NULL,
  event_time VARCHAR(20) NOT NULL,
  venue VARCHAR(200) NOT NULL,
  description TEXT,
  icon_class VARCHAR(50) DEFAULT 'fa-calendar',
  going_count INT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS event_rsvps (
  user_id INT NOT NULL,
  event_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, event_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS medicines (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  dosage VARCHAR(100) NOT NULL,
  med_time VARCHAR(10) NOT NULL,
  food VARCHAR(100) DEFAULT 'After breakfast',
  taken BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS health_tips (
  id INT AUTO_INCREMENT PRIMARY KEY,
  icon VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO health_tips (icon, title, description) VALUES
('fa-droplet', 'Stay Hydrated', 'Drink 8 glasses of water daily to maintain good health and energy levels.'),
('fa-person-walking', 'Walk Daily', 'A 20-minute walk improves heart health, mood, and joint flexibility.'),
('fa-carrot', 'Eat Colorful', 'Include 5 servings of fruits & vegetables each day for vital nutrients.'),
('fa-bed', 'Sleep Well', 'Aim for 7-8 hours of restful sleep every night for body repair.'),
('fa-brain', 'Stay Active', 'Learn something new daily. Puzzles, games, and reading keep your mind sharp.'),
('fa-hand-holding-heart', 'Connect Daily', 'Talk to a friend or family member every day. Social connections boost longevity.');

INSERT IGNORE INTO groups_tb (name, icon, color_class, description, members_count) VALUES
('Garden Club', 'fa-seedling', 'from-emerald-400 to-green-600', 'Share gardening tips, plant pictures, and seasonal advice', 24),
('Yoga & Meditation', 'fa-spa', 'from-violet-400 to-purple-600', 'Morning yoga sessions, breathing exercises, and mindfulness', 31),
('Bhajan Sandhya', 'fa-music', 'from-rose-400 to-pink-600', 'Devotional songs, spiritual talks, and community singing', 18),
('Cooking Circle', 'fa-utensils', 'from-orange-400 to-red-500', 'Share recipes, cooking tips, and traditional food stories', 27),
('Book Lovers', 'fa-book', 'from-sky-400 to-blue-600', 'Discuss books, share stories, and exchange reading recommendations', 15),
('Walking Group', 'fa-person-walking', 'from-teal-400 to-emerald-600', 'Daily morning walks in the park. All fitness levels welcome!', 22);

CREATE TABLE IF NOT EXISTS friendships (
  user_id1 INT NOT NULL,
  user_id2 INT NOT NULL,
  requester_id INT NOT NULL,
  status ENUM('pending','accepted') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id1, user_id2),
  FOREIGN KEY (user_id1) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id2) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS group_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_id INT NOT NULL,
  user_id INT NOT NULL,
  content TEXT NOT NULL,
  image_url VARCHAR(500) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES groups_tb(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS videos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category VARCHAR(100) NOT NULL,
  title VARCHAR(200) NOT NULL,
  youtube_id VARCHAR(20) NOT NULL,
  description TEXT,
  icon VARCHAR(50) DEFAULT 'fa-video',
  color_class VARCHAR(100) DEFAULT 'from-primary-400 to-amber-500'
) ENGINE=InnoDB;

INSERT IGNORE INTO videos (category, title, youtube_id, description, icon, color_class) VALUES
('Yoga & Exercise', 'Gentle Yoga for Seniors', 'hJbRpHZr_d0', 'A gentle 20-minute yoga routine perfect for senior citizens', 'fa-spa', 'from-violet-400 to-purple-600'),
('Yoga & Exercise', 'Chair Exercises for Elderly', 'UJ7v5pQvMYM', 'Easy seated exercises to improve mobility and strength', 'fa-person-walking', 'from-violet-400 to-purple-600'),
('Yoga & Exercise', 'Morning Stretch Routine', 'r1gDHCmXx2Y', 'Simple morning stretches to start your day fresh', 'fa-sun', 'from-violet-400 to-purple-600'),
('Devotional', 'Popular Bhajans Collection', 'U7iLgSgnmb0', 'Soothing devotional bhajans for daily prayer', 'fa-music', 'from-rose-400 to-pink-600'),
('Devotional', 'Peaceful Mantra Chanting', 'U2aNXZPRkaA', 'Calming mantra meditation for inner peace', 'fa-om', 'from-rose-400 to-pink-600'),
('Devotional', 'Evening Aarti', 'uFck6s-ZgYI', 'Traditional evening aarti with beautiful visuals', 'fa-fire', 'from-rose-400 to-pink-600'),
('Cooking', 'Healthy Recipes for Seniors', 'c3p-NZ3PN8c', 'Nutritious and easy-to-make meals for healthy aging', 'fa-utensils', 'from-orange-400 to-red-500'),
('Cooking', 'Low Oil Indian Cooking', 'F3x7sLJjlso', 'Delicious low-oil versions of traditional Indian dishes', 'fa-leaf', 'from-orange-400 to-red-500'),
('Gardening', 'Gardening Tips for Beginners', 'QqNHPpW5MDc', 'Easy gardening tips to grow your own vegetables and flowers', 'fa-seedling', 'from-emerald-400 to-green-600'),
('Gardening', 'Container Gardening Ideas', 'jCnfN_bSAbU', 'Grow plants in small spaces with container gardening', 'fa-tree', 'from-emerald-400 to-green-600'),
('Health Talks', 'Heart Health Tips', 'L_cglacLw8M', 'Important tips for maintaining a healthy heart in golden years', 'fa-heart-pulse', 'from-sky-400 to-blue-600'),
('Health Talks', 'Managing Blood Pressure Naturally', 'gN5Wf8eOaqg', 'Natural ways to manage blood pressure through diet and lifestyle', 'fa-droplet', 'from-sky-400 to-blue-600');

INSERT IGNORE INTO events (title, event_date, event_time, venue, description, icon_class, going_count) VALUES
('Morning Yoga in the Park', '2026-07-12', '6:30 AM', 'Central Park', 'Start your day with gentle yoga surrounded by nature. Bring your mat!', 'fa-sun', 12),
('Bhajan Evening', '2026-07-14', '6:00 PM', 'Community Hall, Sector 5', 'An evening of devotional songs and spiritual fellowship.', 'fa-moon', 18),
('Health Checkup Camp', '2026-07-16', '9:00 AM', 'SilverConnect Wellness Center', 'Free blood pressure, sugar, and general health checkup for seniors.', 'fa-stethoscope', 24),
('Gardening Workshop', '2026-07-20', '10:00 AM', 'Botanical Garden', 'Learn seasonal planting, composting, and organic gardening tips.', 'fa-seedling', 9),
('Tea & Talk Session', '2026-07-25', '4:00 PM', 'SilverConnect Cafe', 'An informal gathering to share stories, laughter, and tea with friends.', 'fa-mug-saucer', 15);
