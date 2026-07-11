CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  avatar TEXT DEFAULT 'S',
  status TEXT DEFAULT 'offline' CHECK(status IN ('online','offline')),
  language TEXT DEFAULT 'en',
  created_at TEXT DEFAULT (datetime('now','localtime'))
);

CREATE TABLE IF NOT EXISTS groups_tb (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color_class TEXT NOT NULL,
  description TEXT,
  members_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_groups (
  user_id INTEGER NOT NULL,
  group_id INTEGER NOT NULL,
  PRIMARY KEY (user_id, group_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES groups_tb(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  room TEXT NOT NULL DEFAULT 'general',
  image_url TEXT DEFAULT NULL,
  created_at TEXT DEFAULT (datetime('now','localtime')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  event_date TEXT NOT NULL,
  event_time TEXT NOT NULL,
  venue TEXT NOT NULL,
  description TEXT,
  icon_class TEXT DEFAULT 'fa-calendar',
  going_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS event_rsvps (
  user_id INTEGER NOT NULL,
  event_id INTEGER NOT NULL,
  created_at TEXT DEFAULT (datetime('now','localtime')),
  PRIMARY KEY (user_id, event_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS medicines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  med_time TEXT NOT NULL,
  food TEXT DEFAULT 'After breakfast',
  taken INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now','localtime')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS health_tips (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  icon TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL
);

INSERT OR IGNORE INTO health_tips (icon, title, description) VALUES
('fa-droplet', 'Stay Hydrated', 'Drink 8 glasses of water daily to maintain good health and energy levels.'),
('fa-person-walking', 'Walk Daily', 'A 20-minute walk improves heart health, mood, and joint flexibility.'),
('fa-carrot', 'Eat Colorful', 'Include 5 servings of fruits & vegetables each day for vital nutrients.'),
('fa-bed', 'Sleep Well', 'Aim for 7-8 hours of restful sleep every night for body repair.'),
('fa-brain', 'Stay Active', 'Learn something new daily. Puzzles, games, and reading keep your mind sharp.'),
('fa-hand-holding-heart', 'Connect Daily', 'Talk to a friend or family member every day. Social connections boost longevity.');

INSERT OR IGNORE INTO groups_tb (name, icon, color_class, description, members_count) VALUES
('Garden Club', 'fa-seedling', 'from-emerald-400 to-green-600', 'Share gardening tips, plant pictures, and seasonal advice', 24),
('Yoga & Meditation', 'fa-spa', 'from-violet-400 to-purple-600', 'Morning yoga sessions, breathing exercises, and mindfulness', 31),
('Bhajan Sandhya', 'fa-music', 'from-rose-400 to-pink-600', 'Devotional songs, spiritual talks, and community singing', 18),
('Cooking Circle', 'fa-utensils', 'from-orange-400 to-red-500', 'Share recipes, cooking tips, and traditional food stories', 27),
('Book Lovers', 'fa-book', 'from-sky-400 to-blue-600', 'Discuss books, share stories, and exchange reading recommendations', 15),
('Walking Group', 'fa-person-walking', 'from-teal-400 to-emerald-600', 'Daily morning walks in the park. All fitness levels welcome!', 22);

CREATE TABLE IF NOT EXISTS friendships (
  user_id1 INTEGER NOT NULL,
  user_id2 INTEGER NOT NULL,
  requester_id INTEGER NOT NULL,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending','accepted')),
  created_at TEXT DEFAULT (datetime('now','localtime')),
  PRIMARY KEY (user_id1, user_id2),
  FOREIGN KEY (user_id1) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id2) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS group_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT DEFAULT NULL,
  created_at TEXT DEFAULT (datetime('now','localtime')),
  FOREIGN KEY (group_id) REFERENCES groups_tb(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS videos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  youtube_id TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT 'fa-video',
  color_class TEXT DEFAULT 'from-primary-400 to-amber-500'
);

INSERT OR IGNORE INTO videos (category, title, youtube_id, description, icon, color_class) VALUES
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

INSERT OR IGNORE INTO events (title, event_date, event_time, venue, description, icon_class, going_count) VALUES
('Morning Yoga in the Park', '2026-07-12', '6:30 AM', 'Central Park', 'Start your day with gentle yoga surrounded by nature. Bring your mat!', 'fa-sun', 12),
('Bhajan Evening', '2026-07-14', '6:00 PM', 'Community Hall, Sector 5', 'An evening of devotional songs and spiritual fellowship.', 'fa-moon', 18),
('Health Checkup Camp', '2026-07-16', '9:00 AM', 'SilverConnect Wellness Center', 'Free blood pressure, sugar, and general health checkup for seniors.', 'fa-stethoscope', 24),
('Gardening Workshop', '2026-07-20', '10:00 AM', 'Botanical Garden', 'Learn seasonal planting, composting, and organic gardening tips.', 'fa-seedling', 9),
('Tea & Talk Session', '2026-07-25', '4:00 PM', 'SilverConnect Cafe', 'An informal gathering to share stories, laughter, and tea with friends.', 'fa-mug-saucer', 15);
