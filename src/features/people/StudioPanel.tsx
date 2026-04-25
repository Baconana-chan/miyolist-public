import { useState, useEffect } from "preact/hooks";
import { useBackHandler } from "../../shared/hooks/useBackHandler";
import { getStudioDetails, toggleFavorite } from "../../shared/api/database";
import { getFavoriteIdCache, isFavoriteEntity, updateFavoriteEntityCache } from "../../shared/favorites";
import { PanelSkeleton } from "../../shared/components/Skeleton";
import type { StudioDetails } from "../../shared/types/app";

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const STUDIO_DETAILS_TTL_MS = 20 * 60 * 1000;
const STUDIO_DETAILS_CACHE = new Map<number, Cached<StudioDetails>>();

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

const STATUS_LABEL: Record<string, string> = {
  FINISHED: "Finished", RELEASING: "Airing", NOT_YET_RELEASED: "Upcoming",
  CANCELLED: "Cancelled", HIATUS: "Hiatus",
};
const FORMAT_LABEL: Record<string, string> = {
  TV: "TV", TV_SHORT: "TV Short", MOVIE: "Movie", SPECIAL: "Special",
  OVA: "OVA", ONA: "ONA", MANGA: "Manga", NOVEL: "Light Novel", ONE_SHOT: "One-shot",
};

function CloseBtn({ onClose }: { onClose: () => void }) {
  return (
    <button
      class="absolute right-4 top-4 z-20 rounded-full border border-white/10 bg-[#111214]/90 p-2 text-[#7a766e] backdrop-blur-sm transition hover:border-white/20 hover:text-[#f1efe7]"
      onClick={onClose}
      title="Close"
    >
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
      </svg>
    </button>
  );
}

function StudioContent({ details, isFavorite, favoritePending, favoriteCount, onToggleFavorite, onMediaClick }: { details: StudioDetails; isFavorite: boolean; favoritePending: boolean; favoriteCount: number | null; onToggleFavorite: () => void; onMediaClick: (id: number) => void }) {
  return (
    <div class="flex flex-col">
      {/* Header */}
      <div class="px-5 pt-12">
        <p class="mb-1 text-[0.72rem] font-bold uppercase tracking-[0.14em] text-[#7ca4be]">Studio</p>
        <h1 class="text-[1.4rem] font-bold text-[#f1efe7]">{details.name}</h1>
        <div class="mt-2 flex flex-wrap items-center gap-2">
          {details.isAnimationStudio && (
            <span class="rounded-full bg-[#d97452]/20 px-2.5 py-0.5 text-[0.72rem] font-semibold text-[#d97452]">
              Animation Studio
            </span>
          )}
          {favoriteCount != null && (
            <span class="text-[0.78rem] text-[#d97452]">♥ {favoriteCount.toLocaleString()}</span>
          )}
          <button
            type="button"
            class={`rounded-full border px-3 py-1.5 text-[0.76rem] font-medium transition ${isFavorite ? "border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] text-[#f1efe7] hover:bg-[rgba(217,116,82,0.24)]" : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"}`}
            onClick={onToggleFavorite}
            disabled={favoritePending}
          >
            {favoritePending ? "Updating…" : isFavorite ? "Remove favourite" : "Add favourite"}
          </button>
        </div>
        {details.siteUrl && (
          <a
            href={details.siteUrl}
            target="_blank"
            rel="noopener noreferrer"
            class="mt-3 inline-flex items-center gap-1.5 text-[0.78rem] text-[#7ca4be] hover:underline"
          >
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
              <polyline points="15 3 21 3 21 9" /><line x1="10" y1="14" x2="21" y2="3" />
            </svg>
            AniList
          </a>
        )}
      </div>

      {/* Media grid */}
      {details.media.length > 0 && (
        <div class="mt-5 px-5">
          <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">
            Works ({details.media.length})
          </p>
          <div class="grid grid-cols-3 gap-2">
            {details.media.map((m) => (
              <button
                key={m.id}
                class="group flex flex-col text-left"
                onClick={() => onMediaClick(m.id)}
              >
                <div class="aspect-2/3 w-full overflow-hidden rounded-lg bg-white/5">
                  {m.coverImage ? (
                    <img src={m.coverImage} alt={m.title} class="h-full w-full object-cover transition group-hover:scale-105" />
                  ) : (
                    <div class="flex h-full w-full items-center justify-center px-1 text-center text-[0.6rem] text-[#5e7a90]">{m.title}</div>
                  )}
                </div>
                <p class="mt-1 line-clamp-2 text-[0.68rem] leading-tight text-[#848076] group-hover:text-[#c8c4bc]">{m.title}</p>
                <div class="flex items-center gap-1.5">
                  {m.format && <span class="text-[0.62rem] text-[#5a5650]">{FORMAT_LABEL[m.format] ?? m.format}</span>}
                  {m.status && (
                    <span class={`text-[0.58rem] font-medium ${m.status === "RELEASING" ? "text-[#6db56d]" : "text-[#5a5650]"}`}>
                      {STATUS_LABEL[m.status] ?? m.status}
                    </span>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      <div class="h-8 shrink-0" />
    </div>
  );
}

export interface StudioPanelProps {
  studioId: number;
  onClose: () => void;
  onMediaClick?: (id: number) => void;
  embedded?: boolean;
}

export function StudioPanel({ studioId, onClose, onMediaClick, embedded = false }: StudioPanelProps) {
  useBackHandler(!embedded, onClose);
  const [details, setDetails] = useState<StudioDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isFavorite, setIsFavorite] = useState(false);
  const [favoritePending, setFavoritePending] = useState(false);
  const [favoriteCount, setFavoriteCount] = useState<number | null>(null);

  useEffect(() => {
    const cached = STUDIO_DETAILS_CACHE.get(studioId);
    if (cached && isFresh(cached.fetchedAt, STUDIO_DETAILS_TTL_MS)) {
      setDetails(cached.data);
      setLoading(false);
      setError(null);
      return;
    }

    setLoading(true); setError(null); setDetails(null);
    getStudioDetails(studioId)
      .then((value) => {
        setDetails(value);
        STUDIO_DETAILS_CACHE.set(studioId, { data: value, fetchedAt: Date.now() });
      })
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }, [studioId]);

  useEffect(() => {
    let cancelled = false;
    getFavoriteIdCache()
      .then((cache) => {
        if (cancelled) return;
        setIsFavorite(isFavoriteEntity(cache, "STUDIO", studioId));
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, [studioId]);

  useEffect(() => {
    setFavoriteCount(details?.favourites ?? null);
  }, [details?.id, details?.favourites]);

  async function handleToggleFavorite() {
    if (!details || favoritePending) return;

    const previousFavorite = isFavorite;
    setFavoritePending(true);
    setError(null);
    try {
      const nextFavorite = await toggleFavorite(details.id, "STUDIO");
      setIsFavorite(nextFavorite);
      setFavoriteCount((prev) => {
        const base = prev ?? details.favourites ?? 0;
        if (nextFavorite === previousFavorite) return base;
        return Math.max(0, base + (nextFavorite ? 1 : -1));
      });
      updateFavoriteEntityCache("STUDIO", details.id, nextFavorite);
    } catch (e) {
      setError(String(e));
    } finally {
      setFavoritePending(false);
    }
  }

  return (
    <div
      class={embedded ? "relative flex h-full min-h-0 w-full" : "fixed inset-0 z-50 flex"}
      onClick={(e) => {
        if (embedded) return;
        if (e.target === e.currentTarget) onClose();
      }}
    >
      {!embedded && <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />}
      <div class={`relative z-10 flex h-full w-full flex-col overflow-y-auto bg-[#111214] ${embedded ? "max-w-none" : "ml-auto max-w-[24rem] shadow-[-4px_0_40px_rgba(0,0,0,0.6)]"}`}>
        <CloseBtn onClose={onClose} />
        {loading && (
          <PanelSkeleton label="Loading studio" kaomojiIndex={2} />
        )}
        {error && !loading && (
          <div class="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
            <p class="text-[0.85rem] text-[#7a766e]">{error}</p>
            <button class="rounded-full border border-white/10 px-4 py-2 text-[0.82rem] text-[#9a9690] hover:text-[#f1efe7]" onClick={onClose}>Close</button>
          </div>
        )}
        {details && !loading && (
          <StudioContent
            details={details}
            isFavorite={isFavorite}
            favoritePending={favoritePending}
            favoriteCount={favoriteCount}
            onToggleFavorite={handleToggleFavorite}
            onMediaClick={(id) => { onMediaClick?.(id); }}
          />
        )}
      </div>
    </div>
  );
}
