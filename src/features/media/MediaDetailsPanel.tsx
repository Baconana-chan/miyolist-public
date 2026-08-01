import { useState, useEffect, useRef } from "preact/hooks";
import { useBackHandler } from "../../shared/hooks/useBackHandler";
import { getMediaDetails, addToLibrary, getFavorites, getFavoriteThemes, getListEntryByMediaId, getThemesForMedia, toggleFavoriteTheme, toggleMediaFavorite, updateListEntry } from "../../shared/api/database";
import { getViewer } from "../../shared/api/auth";
import type { MediaDetails, ListEntry, MediaTheme, ThemeEntry, ThemeVideo } from "../../shared/types/app";
import { AnilistMarkdown, anilistPlainText } from "../../shared/components/AnilistMarkdown";
import { EntryEditModal } from "../../shared/components/EntryEditModal";
import { DropdownSelect } from "../../shared/components/DropdownSelect";
import { PanelSkeleton } from "../../shared/components/Skeleton";
import { CharacterPanel } from "../people/CharacterPanel";
import { StaffPanel } from "../people/StaffPanel";
import { StudioPanel } from "../people/StudioPanel";
import { openUrl } from "@tauri-apps/plugin-opener";

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const MEDIA_DETAILS_TTL_MS = 15 * 60 * 1000;
const MEDIA_ENTRY_TTL_MS = 30 * 1000;
const MEDIA_VIEWER_TTL_MS = 15 * 60 * 1000;
const MEDIA_FAVORITES_TTL_MS = 30 * 1000;
const MEDIA_DETAILS_CACHE = new Map<number, Cached<MediaDetails>>();
const MEDIA_ENTRY_CACHE = new Map<number, Cached<ListEntry | null>>();
let MEDIA_VIEWER_CACHE: Cached<{ scoreFormat: string; animeCustomLists: string[]; mangaCustomLists: string[] }> | null = null;
let MEDIA_FAVORITES_CACHE: Cached<{ animeIds: number[]; mangaIds: number[] }> | null = null;

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

// ─── Themes (OP/ED via AnimeThemes.moe) ──────────────────────────────────────

/** Pick the most audio-friendly video: non-creditless first, lowest resolution. */
function pickBestVideo(entries: ThemeEntry[]): ThemeVideo | null {
  let best: ThemeVideo | null = null;
  for (const entry of entries) {
    for (const video of entry.videos) {
      if (!video.link) continue;
      if (!best) {
        best = video;
        continue;
      }
      const score = (v: ThemeVideo) => (v.nc ? 100_000 : 0) + (v.resolution ?? 1080);
      if (score(video) < score(best)) best = video;
    }
  }
  return best;
}

function ThemesSection({ mediaId }: { mediaId: number }) {
  const [themes, setThemes] = useState<MediaTheme[] | null>(null);
  const [favoriteIds, setFavoriteIds] = useState<Set<number>>(new Set());
  const [favPending, setFavPending] = useState<Set<number>>(new Set());
  const [active, setActive] = useState<MediaTheme | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    let cancelled = false;
    setThemes(null);
    setActive(null);
    getThemesForMedia(mediaId)
      .then((list) => {
        if (!cancelled) setThemes(list);
      })
      .catch(() => {
        if (!cancelled) setThemes([]);
      });
    getFavoriteThemes(mediaId)
      .then((rows) => {
        if (!cancelled) setFavoriteIds(new Set(rows.map((row) => row.themeId)));
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [mediaId]);

  async function toggleFavorite(theme: MediaTheme) {
    if (favPending.has(theme.id)) return;
    setFavPending((prev) => new Set(prev).add(theme.id));
    try {
      const nowFav = await toggleFavoriteTheme(
        mediaId,
        theme.id,
        theme.themeType,
        theme.songTitle,
        theme.artists,
      );
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        if (nowFav) {
          next.add(theme.id);
        } else {
          next.delete(theme.id);
        }
        return next;
      });
    } catch {
      // Best-effort: keep the current star state on failure.
    } finally {
      setFavPending((prev) => {
        const next = new Set(prev);
        next.delete(theme.id);
        return next;
      });
    }
  }

  if (themes === null) {
    return (
      <div class="mt-5 px-5">
        <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Themes</p>
        <div class="h-10 w-full animate-pulse rounded-xl bg-white/4" />
      </div>
    );
  }
  if (themes.length === 0) return null;

  const activeVideo = active ? pickBestVideo(active.entries) : null;

  const playTheme = (theme: MediaTheme) => {
    const video = pickBestVideo(theme.entries);
    const audio = audioRef.current;
    if (!video || !audio) return;

    // Tapping the currently-playing theme pauses it.
    if (active?.id === theme.id && !audio.paused) {
      audio.pause();
      return;
    }
    setActive(theme);
    if (audio.getAttribute("data-theme-id") !== String(theme.id)) {
      audio.setAttribute("data-theme-id", String(theme.id));
      audio.src = video.link;
    }
    audio.play().catch(() => {});
  };

  return (
    <div class="mt-5 px-5 [content-visibility:auto] [contain-intrinsic-size:auto_220px]">
      <div class="mb-2 flex items-center justify-between">
        <p class="text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Themes (OP/ED)</p>
        <span class="text-[0.62rem] text-[#5a5650]">via AnimeThemes.moe</span>
      </div>
      <div class="flex flex-col gap-1.5">
        {themes.map((theme) => {
          const isActive = active?.id === theme.id;
          const episodes = theme.entries[0]?.episodes;
          const isFav = favoriteIds.has(theme.id);
          return (
            <div
              key={theme.id}
              class={`flex w-full items-center gap-3 rounded-xl border px-3 py-2 transition ${
                isActive
                  ? "border-[rgba(217,116,82,0.45)] bg-[rgba(217,116,82,0.1)]"
                  : isFav
                    ? "border-[rgba(217,168,90,0.28)] bg-[rgba(217,168,90,0.06)]"
                    : "border-white/8 bg-white/3 hover:bg-white/6"
              }`}
            >
              <button
                type="button"
                class="flex min-w-0 flex-1 items-center gap-3 text-left"
                onClick={() => playTheme(theme)}
              >
                <span class={`text-base leading-none ${isActive ? "text-[#d97452]" : "text-[#7a746e]"}`}>
                  {isActive ? "⏸" : "▶"}
                </span>
                <span class="min-w-0 flex-1">
                  <span class="block truncate text-sm text-[#e8e3dc]">
                    {theme.themeType}{theme.sequence ?? ""} · {theme.songTitle}
                  </span>
                  <span class="block truncate text-xs text-[#7a746e]">
                    {theme.artists.join(", ") || "Unknown artist"}
                    {episodes ? ` · Ep ${episodes}` : ""}
                  </span>
                </span>
                {theme.entries.length > 1 && (
                  <span class="shrink-0 rounded-full bg-white/6 px-2 py-0.5 text-[0.62rem] text-[#9a9690]">
                    {theme.entries.length} vers
                  </span>
                )}
              </button>
              {/* Favourite star — sibling of the play button so the two never nest. */}
              <button
                type="button"
                class={`shrink-0 rounded-full p-1 text-base leading-none transition ${
                  isFav ? "text-[#d9a85a]" : "text-[#5a5650] hover:text-[#9a9690]"
                } ${favPending.has(theme.id) ? "opacity-40" : ""}`}
                onClick={() => toggleFavorite(theme)}
                title={isFav ? "Remove from favourites" : "Add to favourites"}
                aria-label={isFav ? "Remove from favourites" : "Add to favourites"}
              >
                {isFav ? "★" : "☆"}
              </button>
            </div>
          );
        })}
      </div>
      {/* Always render the <audio> so the ref is valid on the first click;
          hidden until a theme is active. */}
      <audio
        ref={audioRef}
        controls
        preload="none"
        class={`mt-2 w-full ${activeVideo ? "" : "hidden"}`}
      />
    </div>
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const STATUS_LABEL: Record<string, string> = {
  FINISHED:         "Finished",
  RELEASING:        "Airing",
  NOT_YET_RELEASED: "Upcoming",
  CANCELLED:        "Cancelled",
  HIATUS:           "On hiatus",
};

const SITE_COLOR: Record<string, string> = {
  "Crunchyroll":          "#f47521",
  "Netflix":              "#e50914",
  "Funimation":           "#7b2d8b",
  "Amazon Prime Video":   "#00a8e0",
  "Disney+":              "#1133cc",
  "HiDive":               "#0f62d5",
  "HIDIVE":               "#0f62d5",
  "Bilibili":             "#00a0d8",
  "VRV":                  "#4cb6ff",
  "Tubi TV":              "#fa4b16",
  "Apple TV+":            "#a0a0a8",
  "Hulu":                 "#1ce783",
  "ADN":                  "#006dff",
};

const FORMAT_LABEL: Record<string, string> = {
  TV:          "TV",
  TV_SHORT:    "TV Short",
  MOVIE:       "Movie",
  SPECIAL:     "Special",
  OVA:         "OVA",
  ONA:         "ONA",
  MUSIC:       "Music",
  MANGA:       "Manga",
  NOVEL:       "Light Novel",
  ONE_SHOT:    "One-shot",
};

const SOURCE_LABEL: Record<string, string> = {
  ORIGINAL:           "Original",
  MANGA:              "Manga",
  LIGHT_NOVEL:        "Light Novel",
  VISUAL_NOVEL:       "Visual Novel",
  VIDEO_GAME:         "Video game",
  NOVEL:              "Novel",
  DOUJINSHI:          "Doujinshi",
  ANIME:              "Anime",
  WEB_NOVEL:          "Web novel",
  LIVE_ACTION:        "Live action",
  GAME:               "Game",
  COMIC:              "Comic",
  MULTIMEDIA_PROJECT: "Multimedia",
  PICTURE_BOOK:       "Picture book",
  OTHER:              "Other",
};

const RELATION_LABEL: Record<string, string> = {
  PREQUEL:     "Prequel",
  SEQUEL:      "Sequel",
  ALTERNATIVE: "Alternative",
  SPIN_OFF:    "Spin-off",
  ADAPTATION:  "Adaptation",
  SIDE_STORY:  "Side story",
  SUMMARY:     "Summary",
  COMPILATION: "Compilation",
  PARENT:      "Parent",
};

const SEASON_LABEL: Record<string, string> = {
  WINTER: "Winter",
  SPRING: "Spring",
  SUMMER: "Summer",
  FALL:   "Fall",
};

function fmt(val: string | null | undefined, map: Record<string, string>) {
  if (!val) return null;
  return map[val] ?? val.replace(/_/g, " ").toLowerCase().replace(/^\w/, (c) => c.toUpperCase());
}

function num(n: number | null | undefined) {
  if (n == null) return null;
  return n.toLocaleString();
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function StatChip({ label, value, colorClass }: { label: string; value: string; colorClass?: string }) {
  return (
    <div class="flex flex-col items-center rounded-2xl border border-white/7 bg-white/3 px-4 py-2.5">
      <span class={`text-[1.05rem] font-bold leading-none ${colorClass ?? "text-[#f1efe7]"}`}>{value}</span>
      <span class="mt-0.5 text-[0.7rem] text-[#5a5650]">{label}</span>
    </div>
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

const LIBRARY_STATUS_OPTIONS = [
  { value: "current", label: "Watching / Reading" },
  { value: "completed", label: "Completed" },
  { value: "planning", label: "Plan to watch/read" },
  { value: "paused", label: "On hold" },
  { value: "dropped", label: "Dropped" },
  { value: "repeating", label: "Rewatching / Rereading" },
] as const;

// ─── Add to library quick-button ──────────────────────────────────────────────

function QuickAdd({ details, entry, onAdded, scoreFormat, customListNames, onCustomListNamesChange, isFavorite, favoritePending, onToggleFavorite }: { details: MediaDetails; entry: ListEntry | null; onAdded: () => void; scoreFormat: string; customListNames: string[]; onCustomListNamesChange: (names: string[]) => void; isFavorite: boolean; favoritePending: boolean; onToggleFavorite: () => void }) {
  const [adding,  setAdding]  = useState(false);
  const [savingStatus, setSavingStatus] = useState(false);
  const [addStatus, setAddStatus] = useState<string>("planning");
  const [showEdit, setShowEdit] = useState(false);
  const [error,   setError]   = useState<string | null>(null);

  async function handle() {
    setAdding(true);
    setError(null);
    try {
      await addToLibrary(
        details.mediaId,
        details.mediaType.toUpperCase(),
        addStatus,
        details.titleEnglish ?? details.titleRomaji ?? null,
        details.coverImage ?? null,
      );
      onAdded();
    } catch (e) {
      setError(String(e));
    } finally {
      setAdding(false);
    }
  }

  async function handleStatusChange(nextStatus: string) {
    if (!entry || nextStatus === entry.status) return;
    setSavingStatus(true);
    setError(null);
    try {
      await updateListEntry(
        entry.localId,
        entry.mediaId,
        nextStatus,
        entry.score,
        entry.progress,
        entry.progressVolumes,
        entry.repeatCount,
        entry.startedAt,
        entry.completedAt,
        entry.notes,
        entry.customLists,
      );
      onAdded();
    } catch (e) {
      setError(String(e));
    } finally {
      setSavingStatus(false);
    }
  }

  if (entry || details.inLibrary) {
    return (
      <div class="flex flex-col items-start gap-2">
        {entry ? (
          <div class="flex items-center gap-2">
            <DropdownSelect
              options={LIBRARY_STATUS_OPTIONS}
              value={entry.status}
              onChange={handleStatusChange}
              disabled={savingStatus}
              buttonClass="rounded-full border border-[rgba(100,180,100,0.3)] bg-[rgba(100,180,100,0.12)] px-3 py-1.5 text-[0.78rem] font-medium text-[#8ecf8e]"
              menuClass="min-w-54 overflow-hidden rounded-xl border border-white/10 bg-[#1a1b1d] shadow-[-2px_8px_28px_rgba(0,0,0,0.45)]"
            />
            <button
              class="rounded-full border border-white/10 px-3 py-1.5 text-[0.78rem] font-medium text-[#9a9690] transition hover:text-[#f1efe7]"
              onClick={() => setShowEdit(true)}
              disabled={savingStatus}
            >
              Edit entry
            </button>
            <button
              class={`rounded-full border px-3 py-1.5 text-[0.78rem] font-medium transition ${isFavorite ? "border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] text-[#f1efe7] hover:bg-[rgba(217,116,82,0.24)]" : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"}`}
              onClick={onToggleFavorite}
              disabled={savingStatus || favoritePending}
            >
              {favoritePending ? "Updating…" : isFavorite ? "Remove favourite" : "Add favourite"}
            </button>
          </div>
        ) : (
          <div class="flex items-center gap-2">
            <span class="rounded-full border border-[rgba(100,180,100,0.3)] bg-[rgba(100,180,100,0.12)] px-3 py-1.5 text-[0.78rem] font-medium text-[#8ecf8e]">
              In library
            </span>
            <button
              class={`rounded-full border px-3 py-1.5 text-[0.78rem] font-medium transition ${isFavorite ? "border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] text-[#f1efe7] hover:bg-[rgba(217,116,82,0.24)]" : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"}`}
              onClick={onToggleFavorite}
              disabled={favoritePending}
            >
              {favoritePending ? "Updating…" : isFavorite ? "Remove favourite" : "Add favourite"}
            </button>
          </div>
        )}
        {error && <p class="text-[0.72rem] text-red-400">{error}</p>}
        {showEdit && entry && (
          <EntryEditModal
            entry={entry}
            scoreFormat={scoreFormat}
            customListNames={customListNames}
            onCustomListNamesChange={onCustomListNamesChange}
            isFavorite={isFavorite}
            favoritePending={favoritePending}
            onToggleFavorite={onToggleFavorite}
            onClose={() => setShowEdit(false)}
            onSaved={onAdded}
            onDeleted={onAdded}
          />
        )}
      </div>
    );
  }

  return (
    <div class="flex flex-col items-start gap-2">
      <div class="flex items-center gap-2">
        <button
          class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-4 py-1.5 text-[0.82rem] font-bold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.26)] disabled:opacity-50"
          onClick={handle}
          disabled={adding}
        >
          {adding ? "Adding…" : "+ Add to library"}
        </button>
        <DropdownSelect
          options={LIBRARY_STATUS_OPTIONS}
          value={addStatus}
          onChange={setAddStatus}
          disabled={adding}
          buttonClass="rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-[0.78rem] text-[#9a9690]"
          menuClass="min-w-54 overflow-hidden rounded-xl border border-white/10 bg-[#1a1b1d] shadow-[-2px_8px_28px_rgba(0,0,0,0.45)]"
        />
        <button
          class={`rounded-full border px-3 py-1.5 text-[0.78rem] font-medium transition ${isFavorite ? "border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] text-[#f1efe7] hover:bg-[rgba(217,116,82,0.24)]" : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"}`}
          onClick={onToggleFavorite}
          disabled={adding || favoritePending}
        >
          {favoritePending ? "Updating…" : isFavorite ? "Remove favourite" : "Add favourite"}
        </button>
      </div>
      {error && <p class="text-[0.72rem] text-red-400">{error}</p>}
    </div>
  );
}

// ─── Main content ─────────────────────────────────────────────────────────────

function DetailContent({ details, entry, onAdded, scoreFormat, customListNames, onCustomListNamesChange, isFavorite, favoritePending, favoriteCount, onToggleFavorite, onOpenMedia, onOpenCharacter, onOpenStaff, onOpenStudio, onSeeAllRelations, onSeeAllCharacters, onSeeAllStaff, onSeeAllRecommendations }: { details: MediaDetails; entry: ListEntry | null; onAdded: () => void; scoreFormat: string; customListNames: string[]; onCustomListNamesChange: (names: string[]) => void; isFavorite: boolean; favoritePending: boolean; favoriteCount: number | null; onToggleFavorite: () => void; onOpenMedia: (id: number) => void; onOpenCharacter: (id: number) => void; onOpenStaff: (id: number) => void; onOpenStudio: (id: number) => void; onSeeAllRelations: () => void; onSeeAllCharacters: () => void; onSeeAllStaff: () => void; onSeeAllRecommendations: () => void }) {
  const [expanded, setExpanded] = useState(false);

  const title   = details.titleEnglish ?? details.titleRomaji ?? details.titleNative ?? "Unknown";
  const altTitle = details.titleEnglish && details.titleRomaji !== details.titleEnglish
    ? details.titleRomaji
    : null;

  const rawDesc   = details.description ?? null;
  const plainDesc = rawDesc ? anilistPlainText(rawDesc) : null;
  const isLong    = (plainDesc?.length ?? 0) > 280;

  const scoreNum   = details.averageScore != null ? (details.averageScore / 10).toFixed(1) : null;
  const scoreColor =
    details.averageScore == null ? "text-[#f1efe7]" :
    details.averageScore >= 75   ? "text-[#8ecf8e]" :
    details.averageScore >= 55   ? "text-[#d4b86a]" :
                                   "text-[#e08a8a]";

  const mediaStatusLabel = fmt(details.status, STATUS_LABEL);
  const formatLabel      = fmt(details.format,  FORMAT_LABEL);
  const sourceLabel      = fmt(details.source,  SOURCE_LABEL);
  const seasonLabel      = details.season && details.seasonYear
    ? `${fmt(details.season, SEASON_LABEL)} ${details.seasonYear}`
    : details.seasonYear
    ? String(details.seasonYear)
    : null;

  const animStudios = details.studios.filter((s) => s.isAnimationStudio);
  const preferredStudios = animStudios.length ? animStudios : details.studios;
  const allStudios = preferredStudios.filter(
    (studio, index, list) => list.findIndex((candidate) => candidate.id === studio.id) === index,
  );
  const relationItems = details.relations.filter(
    (relation, index, list) => list.findIndex((candidate) => candidate.mediaId === relation.mediaId) === index,
  );
  const recommendationItems = details.recommendations.filter(
    (recommendation, index, list) => list.findIndex((candidate) => candidate.mediaId === recommendation.mediaId) === index,
  );
  const characterItems = details.characters.filter(
    (character, index, list) => list.findIndex((candidate) => candidate.characterId === character.characterId) === index,
  );
  const staffItems = details.staff.filter(
    (staff, index, list) => list.findIndex((candidate) => candidate.staffId === staff.staffId) === index,
  );

  const visibleTags = details.tags.filter((t) => !t.isSpoiler).slice(0, 12);

  return (
    <div class="flex flex-col">
      {/* ── Banner ── */}
      {details.bannerImage ? (
        <div class="relative h-36 shrink-0 overflow-hidden">
          <img
            src={details.bannerImage}
            alt=""
            class="h-full w-full object-cover"
            loading="lazy"
          />
          <div class="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[#111214]" />
        </div>
      ) : (
        <div class="h-10 shrink-0" />
      )}

      {/* ── Cover + title ── */}
      <div class={`relative z-10 flex gap-4 px-5 ${details.bannerImage ? "-mt-14" : "mt-0"}`}>
        {details.coverImage ? (
          <img
            src={details.coverImage}
            alt=""
            class="relative z-10 h-28 w-20 shrink-0 rounded-xl border border-white/10 object-cover shadow-xl"
            loading="lazy"
          />
        ) : (
          <div class="relative z-10 h-28 w-20 shrink-0 rounded-xl border border-white/10 bg-white/8" />
        )}

        <div class="flex min-w-0 flex-col justify-end pb-1">
          {formatLabel && (
            <span class="mb-1 text-[0.72rem] font-medium uppercase tracking-wider text-[#d97452]">
              {formatLabel}
            </span>
          )}
          <h1 class="text-[1.05rem] font-bold leading-snug text-[#f1efe7] line-clamp-3">
            {title}
          </h1>
          {altTitle && (
            <p class="mt-0.5 text-[0.75rem] text-[#5a5650] line-clamp-1">{altTitle}</p>
          )}
        </div>
      </div>

      {/* ── Quick-add / in-library badge ── */}
      <div class="mt-4 px-5">
        <QuickAdd
          details={details}
          entry={entry}
          onAdded={onAdded}
          scoreFormat={scoreFormat}
          customListNames={customListNames}
          onCustomListNamesChange={onCustomListNamesChange}
          isFavorite={isFavorite}
          favoritePending={favoritePending}
          onToggleFavorite={onToggleFavorite}
        />
      </div>

      {/* ── Score / popularity / favourites ── */}
      {(scoreNum || details.popularity || favoriteCount != null) && (
        <div class="mt-4 flex gap-2 px-5">
          {scoreNum && (
            <StatChip label="Score" value={`★ ${scoreNum}`} colorClass={scoreColor} />
          )}
          {details.popularity != null && (
            <StatChip label="Popularity" value={`#${num(details.popularity)}`} />
          )}
          {favoriteCount != null && (
            <StatChip label="Favourites" value={num(favoriteCount)!} />
          )}
        </div>
      )}

      {/* ── Media status + airing badge ── */}
      <div class="mt-4 flex flex-wrap gap-1.5 px-5">
        {mediaStatusLabel && (
          <span class="rounded-full border border-white/8 bg-white/4 px-2.5 py-0.5 text-[0.75rem] text-[#9a9690]">
            {mediaStatusLabel}
          </span>
        )}
        {details.isAdult && (
          <span class="rounded-full border border-red-500/30 bg-red-500/10 px-2.5 py-0.5 text-[0.75rem] text-red-400">
            Adult
          </span>
        )}
        {details.nextAiringEpisode && (
          <span class="rounded-full border border-[rgba(100,180,100,0.3)] bg-[rgba(100,180,100,0.08)] px-2.5 py-0.5 text-[0.75rem] text-[#8ecf8e]">
            Ep {details.nextAiringEpisode.episode} airing in{" "}
            {Math.max(0, Math.ceil((details.nextAiringEpisode.airingAt - Date.now() / 1000) / 86400))}d
          </span>
        )}
      </div>

      {/* ── Description ── */}
      {rawDesc && (
        <div class="mt-5 px-5">
          <div class={`relative text-[0.84rem] leading-relaxed text-[#9a9690] ${!expanded && isLong ? "max-h-[7.5rem] overflow-hidden" : ""}`}>
            <AnilistMarkdown text={rawDesc} />
            {!expanded && isLong && (
              <div class="pointer-events-none absolute bottom-0 left-0 right-0 h-10 bg-gradient-to-t from-[#111214] to-transparent" />
            )}
          </div>
          {isLong && (
            <button
              class="mt-1 text-[0.78rem] text-[#5a5650] hover:text-[#9a9690]"
              onClick={() => setExpanded((e) => !e)}
            >
              {expanded ? "Show less" : "Read more"}
            </button>
          )}
        </div>
      )}

      {/* ── Genres ── */}
      {details.genres.length > 0 && (
        <div class="mt-5 px-5">
          <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Genres</p>
          <div class="flex flex-wrap gap-1.5">
            {details.genres.map((g) => (
              <span key={g} class="rounded-full border border-white/8 bg-white/4 px-2.5 py-0.5 text-[0.78rem] text-[#c8c4bc]">
                {g}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* ── Key info ── */}
      <div class="mt-5 px-5">
        <p class="mb-1 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Details</p>
        <div class="rounded-2xl border border-white/7 bg-white/2 px-4 py-1">
          {details.episodes         != null && <InfoRow label="Episodes"  value={String(details.episodes)} />}
          {details.chapters         != null && <InfoRow label="Chapters"  value={String(details.chapters)} />}
          {details.volumes          != null && <InfoRow label="Volumes"   value={String(details.volumes)} />}
          {details.duration         != null && <InfoRow label="Duration"  value={`${details.duration} min`} />}
          {seasonLabel                       && <InfoRow label="Season"   value={seasonLabel} />}
          {sourceLabel                       && <InfoRow label="Source"   value={sourceLabel} />}
          {allStudios.length > 0 && details.mediaType.toUpperCase() !== "ANIME" && (
            <InfoRow label="Studio" value={allStudios.map((s) => s.name).join(", ")} />
          )}
          {allStudios.length > 0 && details.mediaType.toUpperCase() === "ANIME" && (
            <div class="flex justify-between gap-3 border-b border-white/5 py-2 last:border-0">
              <span class="text-[0.8rem] text-[#5a5650]">Studio</span>
              <div class="flex flex-wrap justify-end gap-1.5">
                {allStudios.map((s) => (
                  <button
                    key={s.id}
                    class="rounded-full border border-white/8 bg-white/4 px-2.5 py-0.5 text-[0.78rem] text-[#c8c4bc] transition hover:border-[#7ca4be]/40 hover:text-[#7ca4be]"
                    onClick={() => onOpenStudio(s.id)}
                    title="Open studio"
                  >
                    {s.name}
                  </button>
                ))}
              </div>
            </div>
          )}
          {details.startDate                 && <InfoRow label="Started"  value={details.startDate} />}
          {details.endDate                   && <InfoRow label="Ended"    value={details.endDate} />}
        </div>
      </div>

      {/* ── Tags ── */}
      {visibleTags.length > 0 && (
        <div class="mt-5 px-5">
          <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Tags</p>
          <div class="flex flex-wrap gap-1.5">
            {visibleTags.map((t) => (
              <span
                key={t.name}
                class="rounded-full border border-white/6 bg-white/3 px-2.5 py-0.5 text-[0.73rem] text-[#848076]"
                title={t.category ?? undefined}
              >
                {t.name}
                {t.rank != null && t.rank >= 80 && (
                  <span class="ml-1 text-[0.65rem] text-[#5a5650]">{t.rank}%</span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* ── Relations ── */}
      {relationItems.length > 0 && (
        <div class="mt-5 px-5 [content-visibility:auto] [contain-intrinsic-size:auto_180px]">
          <div class="mb-2 flex items-center justify-between">
            <p class="text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Related</p>
            {relationItems.length > 5 && (
              <button
                class="text-[0.72rem] text-[#5a5650] transition hover:text-[#9a9690]"
                onClick={onSeeAllRelations}
              >
                See all ({relationItems.length}) →
              </button>
            )}
          </div>
          <div class="-mx-5 flex gap-3 overflow-x-auto px-5 pb-2 [scrollbar-width:none]">
            {relationItems.slice(0, 5).map((r) => (
              <button
                key={r.mediaId}
                class="flex shrink-0 flex-col items-start gap-1.5"
                onClick={() => onOpenMedia(r.mediaId)}
              >
                <div class="relative h-24 w-16 overflow-hidden rounded-xl border border-white/8 bg-white/4">
                  {r.coverImage ? (
                    <img src={r.coverImage} alt="" class="h-full w-full object-cover" loading="lazy" />
                  ) : (
                    <div class="flex h-full items-center justify-center">
                      <span class="text-[0.6rem] text-[#5a5650]">No art</span>
                    </div>
                  )}
                  <span class="absolute inset-x-0 bottom-0 bg-black/70 px-1 py-0.5 text-center text-[0.58rem] leading-tight text-[#9a9690]">
                    {RELATION_LABEL[r.relationType] ?? r.relationType}
                  </span>
                </div>
                <p class="w-16 text-left text-[0.72rem] leading-tight text-[#9a9690] line-clamp-2">{r.title}</p>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── Recommendations ── */}
      {recommendationItems.length > 0 && (
        <div class="mt-5 px-5 [content-visibility:auto] [contain-intrinsic-size:auto_200px]">
          <div class="mb-2 flex items-center justify-between">
            <p class="text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">More like this</p>
            {recommendationItems.length > 5 && (
              <button
                class="text-[0.72rem] text-[#5a5650] transition hover:text-[#9a9690]"
                onClick={onSeeAllRecommendations}
              >
                See all ({recommendationItems.length}) →
              </button>
            )}
          </div>
          <div class="-mx-5 flex gap-3 overflow-x-auto px-5 pb-1 [scrollbar-width:none]">
            {recommendationItems.slice(0, 5).map((rec) => (
              <button
                key={rec.mediaId}
                class="flex shrink-0 flex-col items-start gap-1"
                onClick={() => onOpenMedia(rec.mediaId)}
              >
                <div class="relative h-24 w-16 overflow-hidden rounded-xl border border-white/8 bg-white/4">
                  {rec.coverImage ? (
                    <img src={rec.coverImage} alt="" class="h-full w-full object-cover" loading="lazy" />
                  ) : (
                    <div class="flex h-full items-center justify-center">
                      <span class="text-[0.6rem] text-[#5a5650]">No art</span>
                    </div>
                  )}
                  {rec.meanScore != null && (
                    <span class="absolute right-1 top-1 rounded-md bg-black/75 px-1 py-0.5 text-[0.58rem] font-bold leading-none text-[#8ecf8e]">
                      {(rec.meanScore / 10).toFixed(1)}
                    </span>
                  )}
                </div>
                <p class="w-16 text-left text-[0.72rem] leading-tight text-[#9a9690] line-clamp-2">{rec.title}</p>
                {rec.format && (
                  <p class="text-[0.62rem] text-[#5a5650]">{FORMAT_LABEL[rec.format] ?? rec.format}</p>
                )}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── Themes (OP/ED) ── */}
      {details.mediaType?.toUpperCase() === "ANIME" && (
        <ThemesSection mediaId={details.mediaId} />
      )}

      {/* ── Characters ── */}
      {characterItems.length > 0 && (
        <div class="mt-5 px-5 [content-visibility:auto] [contain-intrinsic-size:auto_170px]">
          <div class="mb-2 flex items-center justify-between">
            <p class="text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Characters</p>
            {characterItems.length > 5 && (
              <button
                class="text-[0.72rem] text-[#5a5650] transition hover:text-[#9a9690]"
                onClick={onSeeAllCharacters}
              >
                See all ({characterItems.length}) →
              </button>
            )}
          </div>
          <div class="-mx-5 flex gap-3 overflow-x-auto px-5 pb-1 [scrollbar-width:none]">
            {characterItems.slice(0, 5).map((c) => (
              <button
                key={c.characterId}
                class="flex shrink-0 flex-col items-start gap-1"
                onClick={() => onOpenCharacter(c.characterId)}
              >
                <div class="h-20 w-14 overflow-hidden rounded-xl border border-white/8 bg-white/4">
                  {c.image ? (
                    <img src={c.image} alt="" class="h-full w-full object-cover" loading="lazy" />
                  ) : (
                    <div class="flex h-full items-center justify-center">
                      <span class="text-[0.6rem] text-[#5a5650]">?</span>
                    </div>
                  )}
                </div>
                <p class="w-14 text-left text-[0.68rem] leading-tight text-[#9a9690] line-clamp-2">{c.name}</p>
                {c.role === "MAIN" && (
                  <span class="rounded-full bg-[rgba(124,164,190,0.18)] px-1.5 py-0.5 text-[0.6rem] font-medium text-[#7ca4be]">Main</span>
                )}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── Staff ── */}
      {staffItems.length > 0 && (
        <div class="mt-5 px-5 [content-visibility:auto] [contain-intrinsic-size:auto_170px]">
          <div class="mb-2 flex items-center justify-between">
            <p class="text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Staff</p>
            {staffItems.length > 5 && (
              <button
                class="text-[0.72rem] text-[#5a5650] transition hover:text-[#9a9690]"
                onClick={onSeeAllStaff}
              >
                See all ({staffItems.length}) →
              </button>
            )}
          </div>
          <div class="-mx-5 flex gap-3 overflow-x-auto px-5 pb-1 [scrollbar-width:none]">
            {staffItems.slice(0, 5).map((s) => (
              <button
                key={s.staffId}
                class="flex shrink-0 flex-col items-start gap-1"
                onClick={() => onOpenStaff(s.staffId)}
              >
                <div class="h-20 w-14 overflow-hidden rounded-xl border border-white/8 bg-white/4">
                  {s.image ? (
                    <img src={s.image} alt="" class="h-full w-full object-cover" loading="lazy" />
                  ) : (
                    <div class="flex h-full items-center justify-center">
                      <span class="text-[0.6rem] text-[#5a5650]">?</span>
                    </div>
                  )}
                </div>
                <p class="w-14 text-left text-[0.68rem] leading-tight text-[#9a9690] line-clamp-2">{s.name}</p>
                {s.role && (
                  <p class="w-14 text-left text-[0.62rem] leading-tight text-[#5a5650] line-clamp-1">{s.role}</p>
                )}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── External Links ── */}
      {details.externalLinks.length > 0 && (() => {
        const streaming = details.externalLinks.filter(l => l.linkType === "STREAMING");
        const others = details.externalLinks.filter(l => l.linkType !== "STREAMING");
        return (
          <div class="mt-5 px-5">
            {streaming.length > 0 && (
              <div>
                <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Watch on</p>
                <div class="flex flex-wrap gap-2">
                  {streaming.map((link) => (
                    <button
                      key={link.url}
                      class="rounded-full border px-3 py-1.5 text-[0.72rem] font-medium transition hover:opacity-75"
                      style={{
                        borderColor: `${SITE_COLOR[link.site] ?? "#3a3830"}70`,
                        color: SITE_COLOR[link.site] ?? "#c8c4bc",
                      }}
                      onClick={() => void openUrl(link.url)}
                    >
                      {link.site}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {others.length > 0 && (
              <div class={streaming.length > 0 ? "mt-3" : ""}>
                <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Links</p>
                <div class="flex flex-wrap gap-1.5">
                  {others.map((link) => (
                    <button
                      key={link.url}
                      class="rounded-full border border-white/8 bg-white/3 px-2.5 py-1 text-[0.65rem] text-[#6a6660] transition hover:text-[#9a9690]"
                      onClick={() => void openUrl(link.url)}
                    >
                      {link.site}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        );
      })()}

      <div class="h-8 shrink-0" />
    </div>
  );
}

// ─── Panel ────────────────────────────────────────────────────────────────────

export interface MediaDetailsPanelProps {
  mediaId: number;
  onClose: () => void;
  /** Called after a successful add-to-library so parent can refresh. */
  onAdded?: () => void;
  embedded?: boolean;
  onOpenMedia?: (id: number) => void;
  onOpenCharacter?: (id: number) => void;
  onOpenStaff?: (id: number) => void;
  onOpenStudio?: (id: number) => void;
}

export function MediaDetailsPanel({
  mediaId,
  onClose,
  onAdded,
  embedded = false,
  onOpenMedia,
  onOpenCharacter,
  onOpenStaff,
  onOpenStudio,
}: MediaDetailsPanelProps) {
  const [history, setHistory] = useState<number[]>([mediaId]);
  const currentId = history[history.length - 1];
  const [details, setDetails] = useState<MediaDetails | null>(null);
  const [entry, setEntry] = useState<ListEntry | null>(null);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState<string | null>(null);
  const [openCharacterId, setOpenCharacterId] = useState<number | null>(null);
  const [openStaffId, setOpenStaffId] = useState<number | null>(null);
  const [openStudioId, setOpenStudioId] = useState<number | null>(null);
  const [castView, setCastView] = useState<"relations" | "characters" | "staff" | "recommendations" | null>(null);
  const [scoreFormat, setScoreFormat] = useState("POINT_10_DECIMAL");
  const [animeCustomLists, setAnimeCustomLists] = useState<string[]>([]);
  const [mangaCustomLists, setMangaCustomLists] = useState<string[]>([]);
  const [isFavorite, setIsFavorite] = useState(false);
  const [favoritePending, setFavoritePending] = useState(false);
  const [favoriteCount, setFavoriteCount] = useState<number | null>(null);

  // Wire system back-gesture / hardware back to close this overlay (mobile)
  // and request fullscreen so the Android status bar doesn't sit on top of
  // the panel header.  Skipped when the panel is embedded inside the
  // multi-pane side sheet on desktop, because there the side-sheet host
  // already manages its own keyboard shortcuts and we don't want to push
  // browser history entries that compete with native Preact-router behaviour.
  useBackHandler(!embedded, onClose);

  // The expanded "see all" cast/recommendations grid lives inside the same
  // panel but covers the visible viewport, so it should also intercept the
  // back gesture independently — pressing back collapses the grid first
  // before falling through to closing the whole panel.
  useBackHandler(castView != null, () => setCastView(null));

  const openMediaTarget = (id: number) => {
    if (onOpenMedia) {
      onOpenMedia(id);
      return;
    }
    setHistory((h) => [...h, id]);
  };

  const openCharacterTarget = (id: number) => {
    if (onOpenCharacter) {
      onOpenCharacter(id);
      return;
    }
    setOpenCharacterId(id);
  };

  const openStaffTarget = (id: number) => {
    if (onOpenStaff) {
      onOpenStaff(id);
      return;
    }
    setOpenStaffId(id);
  };

  const openStudioTarget = (id: number) => {
    if (onOpenStudio) {
      onOpenStudio(id);
      return;
    }
    setOpenStudioId(id);
  };

  const customListNames = details?.mediaType?.toUpperCase() === "MANGA" ? mangaCustomLists : animeCustomLists;

  useEffect(() => {
    if (MEDIA_VIEWER_CACHE && isFresh(MEDIA_VIEWER_CACHE.fetchedAt, MEDIA_VIEWER_TTL_MS)) {
      setScoreFormat(MEDIA_VIEWER_CACHE.data.scoreFormat);
      setAnimeCustomLists(MEDIA_VIEWER_CACHE.data.animeCustomLists);
      setMangaCustomLists(MEDIA_VIEWER_CACHE.data.mangaCustomLists);
      return;
    }

    let cancelled = false;
    getViewer()
      .then((viewer) => {
        if (cancelled) return;
        const data = {
          scoreFormat: viewer.scoreFormat,
          animeCustomLists: viewer.animeCustomLists,
          mangaCustomLists: viewer.mangaCustomLists,
        };
        MEDIA_VIEWER_CACHE = { data, fetchedAt: Date.now() };
        setScoreFormat(data.scoreFormat);
        setAnimeCustomLists(data.animeCustomLists);
        setMangaCustomLists(data.mangaCustomLists);
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!details) {
      setIsFavorite(false);
      return;
    }

    const applyFavoriteState = (animeIds: number[], mangaIds: number[]) => {
      const nextFavorite = details.mediaType.toUpperCase() === "MANGA"
        ? mangaIds.includes(details.mediaId)
        : animeIds.includes(details.mediaId);
      setIsFavorite(nextFavorite);
    };

    if (MEDIA_FAVORITES_CACHE && isFresh(MEDIA_FAVORITES_CACHE.fetchedAt, MEDIA_FAVORITES_TTL_MS)) {
      applyFavoriteState(MEDIA_FAVORITES_CACHE.data.animeIds, MEDIA_FAVORITES_CACHE.data.mangaIds);
      return;
    }

    let cancelled = false;
    getFavorites()
      .then((favorites) => {
        if (cancelled) return;
        const animeIds = favorites.anime.map((item) => item.id);
        const mangaIds = favorites.manga.map((item) => item.id);
        MEDIA_FAVORITES_CACHE = {
          data: { animeIds, mangaIds },
          fetchedAt: Date.now(),
        };
        applyFavoriteState(animeIds, mangaIds);
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, [details]);

  useEffect(() => {
    setFavoriteCount(details?.favourites ?? null);
  }, [details?.mediaId, details?.favourites]);

  async function handleToggleFavorite() {
    if (!details || favoritePending) return;

    const mediaType = details.mediaType.toUpperCase() === "MANGA" ? "MANGA" : "ANIME";
    const previousFavorite = isFavorite;
    setFavoritePending(true);
    setError(null);
    try {
      const nextFavorite = await toggleMediaFavorite(details.mediaId, mediaType);
      setIsFavorite(nextFavorite);
      setFavoriteCount((prev) => {
        const base = prev ?? details.favourites ?? 0;
        if (nextFavorite === previousFavorite) return base;
        return Math.max(0, base + (nextFavorite ? 1 : -1));
      });

      const animeIds = MEDIA_FAVORITES_CACHE?.data.animeIds ?? [];
      const mangaIds = MEDIA_FAVORITES_CACHE?.data.mangaIds ?? [];
      const updatedIds = (mediaType === "MANGA" ? mangaIds : animeIds).filter((id) => id !== details.mediaId);
      if (nextFavorite) updatedIds.push(details.mediaId);
      MEDIA_FAVORITES_CACHE = {
        data: mediaType === "MANGA"
          ? { animeIds, mangaIds: updatedIds }
          : { animeIds: updatedIds, mangaIds },
        fetchedAt: Date.now(),
      };
    } catch (e) {
      setError(String(e));
    } finally {
      setFavoritePending(false);
    }
  }

  const refreshCurrent = (id: number) => {
    getMediaDetails(id)
      .then((value) => {
        setDetails(value);
        MEDIA_DETAILS_CACHE.set(id, { data: value, fetchedAt: Date.now() });
      })
      .catch(() => {});
    getListEntryByMediaId(id)
      .then((value) => {
        setEntry(value);
        MEDIA_ENTRY_CACHE.set(id, { data: value, fetchedAt: Date.now() });
      })
      .catch(() => {
        setEntry(null);
        MEDIA_ENTRY_CACHE.set(id, { data: null, fetchedAt: Date.now() });
      });
  };

  useEffect(() => {
    // Tear down any sub-overlays from the previous media so we never end up
    // with a CharacterPanel / StaffPanel / StudioPanel pointing at a person
    // from the panel the user just navigated away from.  Same for the
    // expanded "see all" cast view.  Without this the previous panel's
    // overlays linger as DOM, contributing to the "panels stacking up" feel
    // on mobile when navigating through related/recommendations.
    setOpenCharacterId(null);
    setOpenStaffId(null);
    setOpenStudioId(null);
    setCastView(null);

    const cachedDetails = MEDIA_DETAILS_CACHE.get(currentId);
    const cachedEntry = MEDIA_ENTRY_CACHE.get(currentId);

    if (cachedDetails && isFresh(cachedDetails.fetchedAt, MEDIA_DETAILS_TTL_MS)) {
      setDetails(cachedDetails.data);
      setLoading(false);
    } else {
      setLoading(true);
      setDetails(null);
    }

    if (cachedEntry && isFresh(cachedEntry.fetchedAt, MEDIA_ENTRY_TTL_MS)) {
      setEntry(cachedEntry.data);
    } else {
      setEntry(null);
    }

    setError(null);

    if (!cachedDetails || !isFresh(cachedDetails.fetchedAt, MEDIA_DETAILS_TTL_MS)) {
      getMediaDetails(currentId)
        .then((value) => {
          setDetails(value);
          MEDIA_DETAILS_CACHE.set(currentId, { data: value, fetchedAt: Date.now() });
        })
        .catch((e) => setError(String(e)))
        .finally(() => setLoading(false));
    }

    if (!cachedEntry || !isFresh(cachedEntry.fetchedAt, MEDIA_ENTRY_TTL_MS)) {
      getListEntryByMediaId(currentId)
        .then((value) => {
          setEntry(value);
          MEDIA_ENTRY_CACHE.set(currentId, { data: value, fetchedAt: Date.now() });
        })
        .catch(() => {
          setEntry(null);
          MEDIA_ENTRY_CACHE.set(currentId, { data: null, fetchedAt: Date.now() });
        });
    }
  }, [currentId]);

  const relationItems = details
    ? details.relations.filter(
        (relation, index, list) => list.findIndex((candidate) => candidate.mediaId === relation.mediaId) === index,
      )
    : [];
  const recommendationItems = details
    ? details.recommendations.filter(
        (recommendation, index, list) => list.findIndex((candidate) => candidate.mediaId === recommendation.mediaId) === index,
      )
    : [];
  const characterItems = details
    ? details.characters.filter(
        (character, index, list) => list.findIndex((candidate) => candidate.characterId === character.characterId) === index,
      )
    : [];
  const staffItems = details
    ? details.staff.filter(
        (staff, index, list) => list.findIndex((candidate) => candidate.staffId === staff.staffId) === index,
      )
    : [];

  return (
    <>
    <div
      class={embedded ? "relative flex h-full min-h-0 w-full" : "fixed inset-0 z-50 flex"}
      onClick={(e) => {
        if (embedded) return;
        if (e.target === e.currentTarget) onClose();
      }}
    >
      {/* Scrim */}
      {!embedded && (
        <div
          class="absolute inset-0 bg-black/60 backdrop-blur-sm"
          onClick={onClose}
        />
      )}

      {/* Drawer — outer wrapper is non-scrolling so the cast overlay covers the visible area */}
      <div class={`relative z-10 flex h-full w-full flex-col bg-[#111214] ${embedded ? "max-w-none" : "ml-auto max-w-[26rem] shadow-[_-4px_0_40px_rgba(0,0,0,0.6)]"}`}>
        {/* Scrollable content */}
        <div
          class="flex h-full flex-col overflow-y-auto [scrollbar-width:thin] [scrollbar-color:#2e2c29_transparent]"
        >
        {/* Close button */}
        <button
          class="absolute right-4 top-4 z-20 rounded-full border border-white/10 bg-[#111214]/90 p-2 text-[#7a766e] backdrop-blur-sm transition hover:border-white/20 hover:text-[#f1efe7]"
          onClick={onClose}
          title="Close"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>

        {/* Back button — shown when navigating via relations */}
        {!onOpenMedia && history.length > 1 && (
          <button
            class="absolute left-4 top-4 z-20 rounded-full border border-white/10 bg-[#111214]/90 p-2 text-[#7a766e] backdrop-blur-sm transition hover:border-white/20 hover:text-[#f1efe7]"
            onClick={() => setHistory((h) => h.slice(0, -1))}
            title="Back"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="19" y1="12" x2="5" y2="12" /><polyline points="12 19 5 12 12 5" />
            </svg>
          </button>
        )}

        {loading && <PanelSkeleton label="Loading media details" kaomojiIndex={4} />}

        {error && !loading && (
          <div class="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
            <p class="text-[0.85rem] text-[#7a766e]">{error}</p>
            <button
              class="rounded-full border border-white/10 px-4 py-2 text-[0.82rem] text-[#9a9690] hover:text-[#f1efe7]"
              onClick={onClose}
            >
              Close
            </button>
          </div>
        )}

        {details && !loading && (
          <DetailContent
            details={details}
            entry={entry}
            scoreFormat={scoreFormat}
            customListNames={customListNames}
            onCustomListNamesChange={(names) => {
              const uniqueNames = Array.from(new Set(names));
              if (details.mediaType.toUpperCase() === "MANGA") {
                setMangaCustomLists(uniqueNames);
                MEDIA_VIEWER_CACHE = {
                  data: {
                    scoreFormat,
                    animeCustomLists,
                    mangaCustomLists: uniqueNames,
                  },
                  fetchedAt: Date.now(),
                };
              } else {
                setAnimeCustomLists(uniqueNames);
                MEDIA_VIEWER_CACHE = {
                  data: {
                    scoreFormat,
                    animeCustomLists: uniqueNames,
                    mangaCustomLists,
                  },
                  fetchedAt: Date.now(),
                };
              }
            }}
            isFavorite={isFavorite}
            favoritePending={favoritePending}
            favoriteCount={favoriteCount}
            onToggleFavorite={handleToggleFavorite}
            onAdded={() => {
              // Refresh details so inLibrary flips to true.
              refreshCurrent(currentId);
              onAdded?.();
            }}
            onOpenMedia={(id) => openMediaTarget(id)}
            onOpenCharacter={(id) => openCharacterTarget(id)}
            onOpenStaff={(id) => openStaffTarget(id)}
            onOpenStudio={(id) => openStudioTarget(id)}
            onSeeAllRelations={() => setCastView("relations")}
            onSeeAllCharacters={() => setCastView("characters")}
            onSeeAllStaff={() => setCastView("staff")}
            onSeeAllRecommendations={() => setCastView("recommendations")}
          />
        )}
        </div>

        {/* ── Full cast overlay — sibling of the scroll container so it covers the visible viewport area ── */}
        {castView != null && details && (
          <div class="absolute inset-0 z-30 flex flex-col overflow-hidden bg-[#111214]">
            <div class="flex shrink-0 items-center gap-3 border-b border-white/6 bg-[#111214] px-4 py-3">
              <button
                class="rounded-full border border-white/10 p-1.5 text-[#7a766e] transition hover:text-[#f1efe7]"
                onClick={() => setCastView(null)}
                title="Back"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <line x1="19" y1="12" x2="5" y2="12" /><polyline points="12 19 5 12 12 5" />
                </svg>
              </button>
              <h2 class="text-[0.9rem] font-semibold text-[#f1efe7]">
                {castView === "relations" ? "Related" : castView === "characters" ? "Characters" : castView === "staff" ? "Staff" : "More like this"}
                <span class="ml-2 text-[0.75rem] font-normal text-[#5a5650]">
                  {castView === "relations" ? relationItems.length : castView === "characters" ? characterItems.length : castView === "staff" ? staffItems.length : recommendationItems.length}
                </span>
              </h2>
            </div>
            <div class="overflow-y-auto [scrollbar-width:thin] [scrollbar-color:#2e2c29_transparent]">
              <div class="grid grid-cols-4 gap-3 p-4">
                {castView === "relations"
                  ? relationItems.map((r) => (
                    <button
                      key={r.mediaId}
                      class="flex flex-col items-start gap-1"
                      onClick={() => { setCastView(null); setHistory((h) => [...h, r.mediaId]); }}
                    >
                      <div class="relative w-full aspect-[2/3] overflow-hidden rounded-xl border border-white/8 bg-white/4">
                        {r.coverImage ? (
                          <img src={r.coverImage} alt="" class="h-full w-full object-cover" loading="lazy" />
                        ) : (
                          <div class="flex h-full items-center justify-center">
                            <span class="text-[0.6rem] text-[#5a5650]">No art</span>
                          </div>
                        )}
                        <span class="absolute inset-x-0 bottom-0 bg-black/70 px-1 py-0.5 text-center text-[0.58rem] leading-tight text-[#9a9690]">
                          {RELATION_LABEL[r.relationType] ?? r.relationType}
                        </span>
                      </div>
                      <p class="w-full text-left text-[0.68rem] leading-tight text-[#9a9690] line-clamp-2">{r.title}</p>
                    </button>
                  ))
                  : castView === "recommendations"
                  ? recommendationItems.map((rec) => (
                    <button
                      key={rec.mediaId}
                      class="flex flex-col items-start gap-1"
                      onClick={() => { setCastView(null); setHistory((h) => [...h, rec.mediaId]); }}
                    >
                      <div class="relative w-full aspect-[2/3] overflow-hidden rounded-xl border border-white/8 bg-white/4">
                        {rec.coverImage ? (
                          <img src={rec.coverImage} alt="" class="h-full w-full object-cover" loading="lazy" />
                        ) : (
                          <div class="flex h-full items-center justify-center">
                            <span class="text-[0.6rem] text-[#5a5650]">No art</span>
                          </div>
                        )}
                        {rec.meanScore != null && (
                          <span class="absolute right-1 top-1 rounded-md bg-black/75 px-1 py-0.5 text-[0.58rem] font-bold leading-none text-[#8ecf8e]">
                            {(rec.meanScore / 10).toFixed(1)}
                          </span>
                        )}
                      </div>
                      <p class="w-full text-left text-[0.68rem] leading-tight text-[#9a9690] line-clamp-2">{rec.title}</p>
                      {rec.format && (
                        <p class="w-full text-left text-[0.6rem] leading-tight text-[#5a5650] line-clamp-1">{FORMAT_LABEL[rec.format] ?? rec.format}</p>
                      )}
                    </button>
                  ))
                  : (castView === "characters" ? characterItems : staffItems).map((item) => {
                  const isChar = castView === "characters";
                  const id = isChar ? (item as typeof characterItems[0]).characterId : (item as typeof staffItems[0]).staffId;
                  return (
                    <button
                      key={id}
                      class="flex flex-col items-start gap-1"
                      onClick={() => {
                        setCastView(null);
                        if (isChar) openCharacterTarget(id);
                        else openStaffTarget(id);
                      }}
                    >
                      <div class="w-full aspect-[2/3] overflow-hidden rounded-xl border border-white/8 bg-white/4">
                        {item.image ? (
                          <img src={item.image} alt="" class="h-full w-full object-cover" loading="lazy" />
                        ) : (
                          <div class="flex h-full items-center justify-center">
                            <span class="text-[0.6rem] text-[#5a5650]">?</span>
                          </div>
                        )}
                      </div>
                      <p class="w-full text-left text-[0.68rem] leading-tight text-[#9a9690] line-clamp-2">{item.name}</p>
                      {item.role && (
                        <p class="w-full text-left text-[0.6rem] leading-tight text-[#5a5650] line-clamp-1">{item.role}</p>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
    {!embedded && openCharacterId != null && (
      <CharacterPanel
        characterId={openCharacterId}
        onClose={() => setOpenCharacterId(null)}
        onMediaClick={(id) => { setOpenCharacterId(null); openMediaTarget(id); }}
      />
    )}
    {!embedded && openStaffId != null && (
      <StaffPanel
        staffId={openStaffId}
        onClose={() => setOpenStaffId(null)}
      />
    )}
    {!embedded && openStudioId != null && (
      <StudioPanel
        studioId={openStudioId}
        onClose={() => setOpenStudioId(null)}
        onMediaClick={(id) => {
          setOpenStudioId(null);
          openMediaTarget(id);
        }}
      />
    )}
    </>
  );
}
