use std::{fs, path::PathBuf};

use tauri::{AppHandle, Manager};

pub fn foundation_summary() -> crate::models::FoundationModule {
    crate::models::FoundationModule {
        name: "Cache".into(),
        summary: "Cover images are downloaded once and stored locally so the library works without a live AniList connection.".into(),
        status: "ready".into(),
    }
}

// ─── Paths ────────────────────────────────────────────────────────────────────

fn image_cache_dir(app: &AppHandle) -> Result<PathBuf, String> {
    let base = app.path().app_data_dir().map_err(|e| e.to_string())?;
    let dir = base.join("image_cache");
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    Ok(dir)
}

/// Derive a stable, filesystem-safe filename from a URL.
/// Uses the final path segment (e.g. `bx21-YCDoj1EkAxFn.jpg`) which is
/// unique for AniList CDN assets.  Falls back to an FNV-1a hash string
/// when no segment can be extracted.
fn url_to_filename(url: &str) -> String {
    // Strip query string first.
    let path_part = url.split('?').next().unwrap_or(url);
    let segment = path_part
        .split('/')
        .rfind(|s| !s.is_empty())
        .unwrap_or("unknown");

    // Keep only safe characters; replace everything else with '_'.
    let safe: String = segment
        .chars()
        .map(|c| {
            if c.is_alphanumeric() || c == '-' || c == '.' {
                c
            } else {
                '_'
            }
        })
        .collect();

    if safe.is_empty() {
        format!("{:x}", fnv1a(url))
    } else {
        // Prefix with a short hash to prevent collisions between different
        // CDN subdomains that serve a file with the same last segment.
        format!("{:08x}-{safe}", fnv1a(url))
    }
}

/// Minimal FNV-1a 32-bit hash — no external dependencies.
fn fnv1a(s: &str) -> u32 {
    let mut hash: u32 = 0x811c9dc5;
    for byte in s.bytes() {
        hash ^= byte as u32;
        hash = hash.wrapping_mul(0x01000193);
    }
    hash
}

// ─── Public API ───────────────────────────────────────────────────────────────

/// Returns `(count, total_bytes)` for the image cache directory.
pub fn image_cache_stats(app: &AppHandle) -> Result<(i64, i64), String> {
    let dir = image_cache_dir(app)?;
    let mut count = 0i64;
    let mut bytes = 0i64;
    for e in fs::read_dir(&dir).map_err(|e| e.to_string())?.flatten() {
        if let Ok(meta) = e.metadata() {
            if meta.is_file() {
                count += 1;
                bytes += meta.len() as i64;
            }
        }
    }
    Ok((count, bytes))
}

/// Returns the local filesystem path for a cached image, or `None` if the
/// URL has not been cached yet.
pub fn get_cached_image_path(app: &AppHandle, url: &str) -> Result<Option<String>, String> {
    let dir = image_cache_dir(app)?;
    let filename = url_to_filename(url);
    let path = dir.join(&filename);
    if path.exists() {
        Ok(Some(path.to_string_lossy().to_string()))
    } else {
        Ok(None)
    }
}

/// Downloads a single image and stores it in the cache directory.
/// Returns the local filesystem path.  If the image is already cached
/// the download is skipped and the existing path is returned.
#[allow(dead_code)]
pub fn cache_image(app: &AppHandle, url: &str) -> Result<String, String> {
    let dir = image_cache_dir(app)?;
    let filename = url_to_filename(url);
    let path = dir.join(&filename);

    if path.exists() {
        return Ok(path.to_string_lossy().to_string());
    }

    let bytes = reqwest::blocking::get(url)
        .map_err(|e| format!("fetch {url}: {e}"))?
        .bytes()
        .map_err(|e| format!("read {url}: {e}"))?;

    fs::write(&path, &bytes).map_err(|e| e.to_string())?;
    Ok(path.to_string_lossy().to_string())
}

/// Prefetches all non-cached cover images for library entries.
/// Runs synchronously; callers that want background behaviour should
/// spawn a thread before calling this.  Returns the number of images
/// that were newly downloaded.
pub fn prefetch_library_covers(app: &AppHandle) -> Result<i64, String> {
    let urls = crate::db::get_all_cover_urls(app)?;
    let dir = image_cache_dir(app)?;
    let mut downloaded = 0i64;

    for url in urls {
        if !crate::anilist::is_online() {
            break;
        }

        let filename = url_to_filename(&url);
        let path = dir.join(&filename);
        if path.exists() {
            continue;
        }
        if let Ok(bytes) = reqwest::blocking::get(&url).and_then(|r| r.bytes()) {
            let _ = fs::write(&path, &bytes);
            downloaded += 1;
        }
    }
    Ok(downloaded)
}

/// Removes all files from the image cache directory.
pub fn clear_image_cache(app: &AppHandle) -> Result<i64, String> {
    let dir = image_cache_dir(app)?;
    let mut removed = 0i64;
    for e in fs::read_dir(&dir).map_err(|e| e.to_string())?.flatten() {
        if e.metadata().map(|m| m.is_file()).unwrap_or(false) {
            let _ = fs::remove_file(e.path());
            removed += 1;
        }
    }
    Ok(removed)
}
