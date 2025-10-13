-- Migration: Add sync metadata columns for conflict resolution
-- Version: 1.3.0
-- Created: 2025-10-11
-- Description: Adds sync_metadata JSONB column to track device info, timestamps, and source

-- ==================================================================
-- ANIME LISTS TABLE
-- ==================================================================

-- Add sync_metadata column to anime_lists
ALTER TABLE anime_lists 
ADD COLUMN IF NOT EXISTS sync_metadata JSONB DEFAULT NULL;

-- Create index for faster queries on sync_metadata
CREATE INDEX IF NOT EXISTS idx_anime_lists_sync_metadata 
ON anime_lists USING GIN (sync_metadata);

-- Add comment explaining the column
COMMENT ON COLUMN anime_lists.sync_metadata IS 
'JSONB object containing: last_modified (timestamp), device_id (string), device_name (string), source (app/anilist/cloud)';

-- ==================================================================
-- MANGA LISTS TABLE
-- ==================================================================

-- Add sync_metadata column to manga_lists
ALTER TABLE manga_lists 
ADD COLUMN IF NOT EXISTS sync_metadata JSONB DEFAULT NULL;

-- Create index for faster queries on sync_metadata
CREATE INDEX IF NOT EXISTS idx_manga_lists_sync_metadata 
ON manga_lists USING GIN (sync_metadata);

-- Add comment explaining the column
COMMENT ON COLUMN manga_lists.sync_metadata IS 
'JSONB object containing: last_modified (timestamp), device_id (string), device_name (string), source (app/anilist/cloud)';

-- ==================================================================
-- EXAMPLE SYNC_METADATA STRUCTURE
-- ==================================================================
-- {
--   "last_modified": "2025-10-11T15:30:00.000Z",
--   "device_id": "device_abc123",
--   "device_name": "Windows PC",
--   "source": "app"
-- }

-- ==================================================================
-- USAGE NOTES
-- ==================================================================
-- 1. sync_metadata is NULL for old entries (before this migration)
-- 2. New entries should always include sync_metadata
-- 3. When detecting conflicts:
--    - Compare sync_metadata.last_modified timestamps
--    - Use sync_metadata.source to identify where change came from
--    - Use sync_metadata.device_name for user-friendly conflict display
-- 4. Last-Write-Wins strategy uses sync_metadata.last_modified
-- 5. If sync_metadata is NULL, fall back to updated_at or synced_at

-- ==================================================================
-- BACKWARD COMPATIBILITY
-- ==================================================================
-- This migration is non-breaking:
-- - Existing entries without sync_metadata will continue to work
-- - App will fall back to updated_at/synced_at for old entries
-- - New entries will always include sync_metadata

-- ==================================================================
-- ROLLBACK (if needed)
-- ==================================================================
-- To remove the sync_metadata columns:
-- DROP INDEX IF EXISTS idx_anime_lists_sync_metadata;
-- DROP INDEX IF EXISTS idx_manga_lists_sync_metadata;
-- ALTER TABLE anime_lists DROP COLUMN IF EXISTS sync_metadata;
-- ALTER TABLE manga_lists DROP COLUMN IF EXISTS sync_metadata;
