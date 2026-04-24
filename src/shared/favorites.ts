import { getFavorites } from "./api/database";

export type FavoriteEntityType = "ANIME" | "MANGA" | "CHARACTER" | "STAFF" | "STUDIO";

type FavoriteIdCache = {
  animeIds: number[];
  mangaIds: number[];
  characterIds: number[];
  staffIds: number[];
  studioIds: number[];
};

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const FAVORITES_TTL_MS = 30 * 1000;
let FAVORITES_CACHE: Cached<FavoriteIdCache> | null = null;

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

function uniqueIds(ids: number[]) {
  return Array.from(new Set(ids));
}

export async function getFavoriteIdCache(force = false): Promise<FavoriteIdCache> {
  if (!force && FAVORITES_CACHE && isFresh(FAVORITES_CACHE.fetchedAt, FAVORITES_TTL_MS)) {
    return FAVORITES_CACHE.data;
  }

  const favorites = await getFavorites();
  const data = {
    animeIds: uniqueIds(favorites.anime.map((item) => item.id)),
    mangaIds: uniqueIds(favorites.manga.map((item) => item.id)),
    characterIds: uniqueIds(favorites.characters.map((item) => item.id)),
    staffIds: uniqueIds(favorites.staff.map((item) => item.id)),
    studioIds: uniqueIds(favorites.studios.map((item) => item.id)),
  };

  FAVORITES_CACHE = {
    data,
    fetchedAt: Date.now(),
  };

  return data;
}

export function isFavoriteEntity(data: FavoriteIdCache, targetType: FavoriteEntityType, targetId: number): boolean {
  switch (targetType) {
    case "ANIME":
      return data.animeIds.includes(targetId);
    case "MANGA":
      return data.mangaIds.includes(targetId);
    case "CHARACTER":
      return data.characterIds.includes(targetId);
    case "STAFF":
      return data.staffIds.includes(targetId);
    case "STUDIO":
      return data.studioIds.includes(targetId);
  }
}

export function updateFavoriteEntityCache(targetType: FavoriteEntityType, targetId: number, isFavorite: boolean) {
  if (!FAVORITES_CACHE) return;

  const next = { ...FAVORITES_CACHE.data };
  const key = targetType === "ANIME"
    ? "animeIds"
    : targetType === "MANGA"
    ? "mangaIds"
    : targetType === "CHARACTER"
    ? "characterIds"
    : targetType === "STAFF"
    ? "staffIds"
    : "studioIds";

  const values = next[key].filter((id) => id !== targetId);
  if (isFavorite) values.push(targetId);
  next[key] = uniqueIds(values);

  FAVORITES_CACHE = {
    data: next,
    fetchedAt: Date.now(),
  };
}