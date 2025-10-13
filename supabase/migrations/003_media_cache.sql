-- Таблица для кеширования публичной информации о медиа (аниме/манга)
-- Используется для уменьшения количества запросов к AniList API

CREATE TABLE IF NOT EXISTS media_cache (
  id INTEGER PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('ANIME', 'MANGA')),
  title_romaji TEXT,
  title_english TEXT,
  title_native TEXT,
  description TEXT,
  cover_image TEXT,
  banner_image TEXT,
  episodes INTEGER,
  chapters INTEGER,
  volumes INTEGER,
  status TEXT,
  format TEXT,
  genres TEXT[], -- Array of genre names
  average_score NUMERIC(4,2),
  popularity INTEGER,
  season TEXT,
  season_year INTEGER,
  source TEXT,
  studios TEXT[], -- Array of studio names
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  trailer TEXT,
  synonyms TEXT[], -- Array of alternative titles
  duration INTEGER, -- Episode duration in minutes
  cached_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_media_cache_type ON media_cache(type);
CREATE INDEX IF NOT EXISTS idx_media_cache_cached_at ON media_cache(cached_at);
CREATE INDEX IF NOT EXISTS idx_media_cache_title_romaji ON media_cache(title_romaji);
CREATE INDEX IF NOT EXISTS idx_media_cache_title_english ON media_cache(title_english);

-- Full-text search индекс для поиска по названиям
CREATE INDEX IF NOT EXISTS idx_media_cache_search ON media_cache 
  USING GIN (to_tsvector('english', COALESCE(title_romaji, '') || ' ' || COALESCE(title_english, '') || ' ' || COALESCE(title_native, '')));

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_media_cache_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического обновления updated_at
DROP TRIGGER IF EXISTS trigger_update_media_cache_updated_at ON media_cache;
CREATE TRIGGER trigger_update_media_cache_updated_at
BEFORE UPDATE ON media_cache
FOR EACH ROW
EXECUTE FUNCTION update_media_cache_updated_at();

-- RLS (Row Level Security) политики
ALTER TABLE media_cache ENABLE ROW LEVEL SECURITY;

-- Политика: все пользователи могут читать кеш
CREATE POLICY "Anyone can read media cache"
ON media_cache FOR SELECT
TO public
USING (true);

-- Политика: только аутентифицированные пользователи могут записывать в кеш
CREATE POLICY "Authenticated users can insert/update media cache"
ON media_cache FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Комментарии к таблице и колонкам
COMMENT ON TABLE media_cache IS 'Cache for public anime/manga information from AniList';
COMMENT ON COLUMN media_cache.id IS 'AniList media ID';
COMMENT ON COLUMN media_cache.type IS 'Media type: ANIME or MANGA';
COMMENT ON COLUMN media_cache.cached_at IS 'When this record was first cached';
COMMENT ON COLUMN media_cache.updated_at IS 'When this record was last updated';
COMMENT ON COLUMN media_cache.duration IS 'Episode duration in minutes (for anime only)';
