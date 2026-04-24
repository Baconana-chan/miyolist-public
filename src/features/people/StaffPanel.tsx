import { useState, useEffect } from "preact/hooks";
import { getStaffDetails, toggleFavorite } from "../../shared/api/database";
import { getFavoriteIdCache, isFavoriteEntity, updateFavoriteEntityCache } from "../../shared/favorites";
import type { StaffDetails } from "../../shared/types/app";
import { AnilistMarkdown, anilistPlainText } from "../../shared/components/AnilistMarkdown";
import { PanelSkeleton } from "../../shared/components/Skeleton";

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const STAFF_DETAILS_TTL_MS = 20 * 60 * 1000;
const STAFF_DETAILS_CACHE = new Map<number, Cached<StaffDetails>>();

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

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

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div class="flex justify-between gap-3 border-b border-white/5 py-2 last:border-0">
      <span class="text-[0.8rem] text-[#5a5650]">{label}</span>
      <span class="text-right text-[0.82rem] font-medium text-[#c8c4bc]">{value}</span>
    </div>
  );
}

function StaffContent({ details, isFavorite, favoritePending, favoriteCount, onToggleFavorite, onCharacterClick }: { details: StaffDetails; isFavorite: boolean; favoritePending: boolean; favoriteCount: number | null; onToggleFavorite: () => void; onCharacterClick: (id: number) => void }) {
  const [expanded, setExpanded] = useState(false);
  const rawDesc   = details.description ?? null;
  const plainDesc = rawDesc ? anilistPlainText(rawDesc) : null;
  const isLong    = (plainDesc?.length ?? 0) > 300;

  return (
    <div class="flex flex-col">
      {/* Header */}
      <div class="flex gap-4 px-5 pt-5">
        {details.image ? (
          <img src={details.image} alt={details.nameFull ?? ""} class="h-32 w-24 shrink-0 rounded-xl object-cover" />
        ) : (
          <div class="flex h-32 w-24 shrink-0 items-center justify-center rounded-xl bg-white/5 text-3xl font-bold text-[#d97452]">
            {details.nameFull?.[0]?.toUpperCase() ?? "?"}
          </div>
        )}
        <div class="min-w-0 flex-1 pt-2">
          <p class="mb-1 text-[0.72rem] font-bold uppercase tracking-[0.14em] text-[#d97452]">Staff</p>
          <h1 class="text-[1.25rem] font-bold leading-tight text-[#f1efe7]">
            {details.nameFull ?? "Unknown"}
          </h1>
          {details.nameNative && (
            <p class="mt-0.5 text-[0.85rem] text-[#848076]">{details.nameNative}</p>
          )}
          {details.primaryOccupations.length > 0 && (
            <p class="mt-1 text-[0.75rem] text-[#7ca4be]">{details.primaryOccupations.join(", ")}</p>
          )}
          <div class="mt-1.5 flex flex-wrap items-center gap-2">
            {favoriteCount != null && (
              <p class="text-[0.78rem] text-[#d97452]">♥ {favoriteCount.toLocaleString()}</p>
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
        </div>
      </div>

      {/* Info */}
      {(details.gender || details.age != null || details.dateOfBirth || details.dateOfDeath) && (
        <div class="mt-5 px-5">
          <p class="mb-1 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Info</p>
          <div class="rounded-2xl border border-white/7 bg-white/2 px-4 py-1">
            {details.gender          && <InfoRow label="Gender"        value={details.gender} />}
            {details.age != null     && <InfoRow label="Age"           value={String(details.age)} />}
            {details.dateOfBirth     && <InfoRow label="Date of birth" value={details.dateOfBirth} />}
            {details.dateOfDeath     && <InfoRow label="Date of death" value={details.dateOfDeath} />}
          </div>
        </div>
      )}

      {/* Description */}
      {rawDesc && (
        <div class="mt-5 px-5">
          <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">About</p>
          <div class={`relative text-[0.85rem] leading-relaxed text-[#b5b0a5] ${!expanded && isLong ? "max-h-30 overflow-hidden" : ""}`}>
            <AnilistMarkdown text={rawDesc} />
            {!expanded && isLong && (
              <div class="pointer-events-none absolute bottom-0 left-0 right-0 h-10 bg-linear-to-t from-[#111214] to-transparent" />
            )}
          </div>
          {isLong && (
            <button
              class="mt-1.5 text-[0.78rem] text-[#7ca4be] underline-offset-2 hover:underline"
              onClick={() => setExpanded((v) => !v)}
            >
              {expanded ? "Show less" : "Show more"}
            </button>
          )}
        </div>
      )}

      {/* Voiced Characters */}
      {details.characters.length > 0 && (
        <div class="mt-5 px-5">
          <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">
            Characters ({details.characters.length})
          </p>
          <div class="grid grid-cols-4 gap-2">
            {details.characters.map((c) => (
              <button
                key={c.id}
                class="group flex flex-col items-center text-center"
                onClick={() => onCharacterClick(c.id)}
              >
                <div class="h-16 w-16 overflow-hidden rounded-full bg-white/5">
                  {c.image ? (
                    <img src={c.image} alt={c.name} class="h-full w-full object-cover transition group-hover:scale-105" />
                  ) : (
                    <div class="flex h-full w-full items-center justify-center text-[0.6rem] text-[#5e7a90]">?</div>
                  )}
                </div>
                <p class="mt-1 line-clamp-2 text-[0.65rem] leading-tight text-[#848076] group-hover:text-[#c8c4bc]">{c.name}</p>
              </button>
            ))}
          </div>
        </div>
      )}

      <div class="h-8 shrink-0" />
    </div>
  );
}

export interface StaffPanelProps {
  staffId: number;
  onClose: () => void;
  onCharacterClick?: (id: number) => void;
  embedded?: boolean;
}

export function StaffPanel({ staffId, onClose, onCharacterClick, embedded = false }: StaffPanelProps) {
  const [details, setDetails] = useState<StaffDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isFavorite, setIsFavorite] = useState(false);
  const [favoritePending, setFavoritePending] = useState(false);
  const [favoriteCount, setFavoriteCount] = useState<number | null>(null);

  useEffect(() => {
    const cached = STAFF_DETAILS_CACHE.get(staffId);
    if (cached && isFresh(cached.fetchedAt, STAFF_DETAILS_TTL_MS)) {
      setDetails(cached.data);
      setLoading(false);
      setError(null);
      return;
    }

    setLoading(true); setError(null); setDetails(null);
    getStaffDetails(staffId)
      .then((value) => {
        setDetails(value);
        STAFF_DETAILS_CACHE.set(staffId, { data: value, fetchedAt: Date.now() });
      })
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }, [staffId]);

  useEffect(() => {
    let cancelled = false;
    getFavoriteIdCache()
      .then((cache) => {
        if (cancelled) return;
        setIsFavorite(isFavoriteEntity(cache, "STAFF", staffId));
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, [staffId]);

  useEffect(() => {
    setFavoriteCount(details?.favourites ?? null);
  }, [details?.id, details?.favourites]);

  async function handleToggleFavorite() {
    if (!details || favoritePending) return;

    const previousFavorite = isFavorite;
    setFavoritePending(true);
    setError(null);
    try {
      const nextFavorite = await toggleFavorite(details.id, "STAFF");
      setIsFavorite(nextFavorite);
      setFavoriteCount((prev) => {
        const base = prev ?? details.favourites ?? 0;
        if (nextFavorite === previousFavorite) return base;
        return Math.max(0, base + (nextFavorite ? 1 : -1));
      });
      updateFavoriteEntityCache("STAFF", details.id, nextFavorite);
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
          <PanelSkeleton label="Loading staff" kaomojiIndex={1} />
        )}
        {error && !loading && (
          <div class="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
            <p class="text-[0.85rem] text-[#7a766e]">{error}</p>
            <button class="rounded-full border border-white/10 px-4 py-2 text-[0.82rem] text-[#9a9690] hover:text-[#f1efe7]" onClick={onClose}>Close</button>
          </div>
        )}
        {details && !loading && (
          <StaffContent
            details={details}
            isFavorite={isFavorite}
            favoritePending={favoritePending}
            favoriteCount={favoriteCount}
            onToggleFavorite={handleToggleFavorite}
            onCharacterClick={(id) => { onCharacterClick?.(id); }}
          />
        )}
      </div>
    </div>
  );
}
