-- MiyoList Supabase Database Schema
-- Run this in your Supabase SQL Editor

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    avatar TEXT,
    banner_image TEXT,
    about TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create anime lists table
CREATE TABLE IF NOT EXISTS anime_lists (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    media_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    score DOUBLE PRECISION,
    progress INT DEFAULT 0,
    repeat INT,
    notes TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    media JSONB,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create manga lists table
CREATE TABLE IF NOT EXISTS manga_lists (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    media_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    score DOUBLE PRECISION,
    progress INT DEFAULT 0,
    progress_volumes INT,
    repeat INT,
    notes TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    media JSONB,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create favorites table
CREATE TABLE IF NOT EXISTS favorites (
    user_id BIGINT PRIMARY KEY,
    data JSONB NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_anime_lists_user_id ON anime_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_anime_lists_status ON anime_lists(status);
CREATE INDEX IF NOT EXISTS idx_manga_lists_user_id ON manga_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_manga_lists_status ON manga_lists(status);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE anime_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE manga_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (since we're using anon key)
-- In production, you might want to implement proper authentication

-- Users policies
DROP POLICY IF EXISTS "Allow public read access to users" ON users;
CREATE POLICY "Allow public read access to users" ON users
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert to users" ON users;
CREATE POLICY "Allow public insert to users" ON users
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update to users" ON users;
CREATE POLICY "Allow public update to users" ON users
    FOR UPDATE USING (true);

-- Anime lists policies
DROP POLICY IF EXISTS "Allow public read access to anime_lists" ON anime_lists;
CREATE POLICY "Allow public read access to anime_lists" ON anime_lists
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert to anime_lists" ON anime_lists;
CREATE POLICY "Allow public insert to anime_lists" ON anime_lists
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update to anime_lists" ON anime_lists;
CREATE POLICY "Allow public update to anime_lists" ON anime_lists
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow public delete from anime_lists" ON anime_lists;
CREATE POLICY "Allow public delete from anime_lists" ON anime_lists
    FOR DELETE USING (true);

-- Manga lists policies
DROP POLICY IF EXISTS "Allow public read access to manga_lists" ON manga_lists;
CREATE POLICY "Allow public read access to manga_lists" ON manga_lists
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert to manga_lists" ON manga_lists;
CREATE POLICY "Allow public insert to manga_lists" ON manga_lists
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update to manga_lists" ON manga_lists;
CREATE POLICY "Allow public update to manga_lists" ON manga_lists
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow public delete from manga_lists" ON manga_lists;
CREATE POLICY "Allow public delete from manga_lists" ON manga_lists
    FOR DELETE USING (true);

-- Favorites policies
DROP POLICY IF EXISTS "Allow public read access to favorites" ON favorites;
CREATE POLICY "Allow public read access to favorites" ON favorites
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert to favorites" ON favorites;
CREATE POLICY "Allow public insert to favorites" ON favorites
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update to favorites" ON favorites;
CREATE POLICY "Allow public update to favorites" ON favorites
    FOR UPDATE USING (true);

-- Verify tables were created
SELECT 
    table_name,
    table_type
FROM 
    information_schema.tables
WHERE 
    table_schema = 'public'
    AND table_name IN ('users', 'anime_lists', 'manga_lists', 'favorites')
ORDER BY 
    table_name;
