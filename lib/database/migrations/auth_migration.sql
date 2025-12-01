CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'client',
  status TEXT DEFAULT 'pending',
  rating REAL DEFAULT 0,
  vehicle TEXT,
  device_id TEXT,
  created_at TEXT NOT NULL,
  last_login TEXT,
  deleted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
