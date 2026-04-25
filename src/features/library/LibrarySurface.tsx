import { useState, useEffect, useCallback, useMemo, useRef } from "preact/hooks";
import { getAppSettings, getLibrarySnapshot, getListEntries, syncUserLists, incrementEpisodeProgress } from "../../shared/api/database";
import { getViewer } from "../../shared/api/auth";
import { EntryEditModal } from "../../shared/components/EntryEditModal";
import { DropdownSelect } from "../../shared/components/DropdownSelect";
import { KaomojiLoadingText, MediaCardSkeleton } from "../../shared/components/Skeleton";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";
import type { AuthSessionStatus, LibrarySnapshot, ListEntry, ScreenId } from "../../shared/types/app";
import { ConflictResolutionDialog } from "./ConflictResolutionDialog";
import { formatScore } from "../../shared/scoreFormat";

// ─── Types ────────────────────────────────────────────────────────────────────

type MediaKind      = "anime" | "manga" | "novel";
type ListStatus     = "all" | "watching" | "completed" | "planning" | "paused" | "dropped";
type SortKey        = "updated" | "title" | "score" | "progress" | "repeat";
type SortDir        = "asc" | "desc";
type ViewStyle      = "list" | "compact" | "grid";
type ScoreFilter    = "any" | "scored" | "unscored";
type ProgressFilter = "any" | "not-started" | "in-progress";

const MEDIA_KINDS: { id: MediaKind; label: string }[] = [
  { id: "anime",  label: "Anime"        },
  { id: "manga",  label: "Manga"        },
  { id: "novel",  label: "Light Novel"  },
];

const MEDIA_KIND_QUERY: Record<MediaKind, string> = {
  anime: "ANIME",
  manga: "MANGA",
  novel: "NOVEL",
};

const STATUS_TABS: { id: ListStatus; animeLabel: string; mangaLabel: string }[] = [
  { id: "all",       animeLabel: "All",       mangaLabel: "All"       },
  { id: "watching",  animeLabel: "Watching",  mangaLabel: "Reading"   },
  { id: "completed", animeLabel: "Completed", mangaLabel: "Completed" },
  { id: "planning",  animeLabel: "Planning",  mangaLabel: "Planning"  },
  { id: "paused",    animeLabel: "On hold",   mangaLabel: "On hold"   },
  { id: "dropped",   animeLabel: "Dropped",   mangaLabel: "Dropped"   },
];

const STATUS_QUERY: Record<ListStatus, string | undefined> = {
  all:       undefined,
  watching:  "current",
  completed: "completed",
  planning:  "planning",
  paused:    "paused",
  dropped:   "dropped",
};

const STATUS_COLORS: Record<string, string> = {
  current:   "bg-[rgba(100,180,100,0.18)] text-[#8ecf8e]",
  repeating: "bg-[rgba(100,180,100,0.18)] text-[#8ecf8e]",
  completed: "bg-[rgba(90,140,210,0.18)] text-[#8ab4f0]",
  planning:  "bg-[rgba(180,150,80,0.18)] text-[#d4b86a]",
  paused:    "bg-[rgba(160,100,200,0.18)] text-[#c09ee0]",
  dropped:   "bg-[rgba(210,80,80,0.18)] text-[#e08a8a]",
};

const SORT_OPTIONS: { key: SortKey; label: string; defaultDir: SortDir }[] = [
  { key: "updated",  label: "Last updated",    defaultDir: "desc" },
  { key: "title",    label: "Title",           defaultDir: "asc"  },
  { key: "score",    label: "Score",           defaultDir: "desc" },
  { key: "progress", label: "Progress",        defaultDir: "desc" },
  { key: "repeat",   label: "Times rewatched", defaultDir: "desc" },
];

const PAGE_SIZE = 50;

interface LibrarySurfaceProps {
  session: AuthSessionStatus;
  onNavigate: (screen: ScreenId) => void;
  onEntryEdited?: () => void;
}

type LibraryMetaCache = {
  snapshot: LibrarySnapshot | null;
  scoreFormat: string;
  animeCustomLists: string[];
  mangaCustomLists: string[];
};

const LIBRARY_VIEW_CACHE = new Map<string, ListEntry[]>();
let LIBRARY_META_CACHE: LibraryMetaCache | null = null;

export function invalidateLibraryCache() {
  LIBRARY_VIEW_CACHE.clear();
  LIBRARY_META_CACHE = null;
}

type SyncMessageTone = "neutral" | "warning" | "error";

function formatSyncFailure(error: unknown): { message: string; tone: SyncMessageTone } {
  const raw = String(error ?? "");
  const upper = raw.toUpperCase();

  if (
    upper.includes("[VIEWER_FETCH_FAILED]")
    && upper.includes("403")
    && raw.toLowerCase().includes("temporarily disabled")
  ) {
    return {
      message: "AniList API is temporarily disabled on AniList's side (HTTP 403). This is an upstream incident, not an app issue.",
      tone: "warning",
    };
  }

  if (upper.includes("[OFFLINE]")) {
    return {
      message: "No internet connection. Check your network and try syncing again.",
      tone: "warning",
    };
  }

  if (upper.includes("[RATE_LIMITED]")) {
    return {
      message: "AniList temporarily rate-limited requests. Please try again in a moment.",
      tone: "warning",
    };
  }

  if (upper.includes("[HTTP_ERROR]")) {
    return {
      message: "AniList API returned an error. This is most likely on AniList's side, not the app.",
      tone: "warning",
    };
  }

  return {
    message: `Sync failed: ${raw}`,
    tone: "error",
  };
}

// ─── Empty state ─────────────────────────────────────────────────────────────

function EmptyState({ onNavigate }: { onNavigate: (screen: ScreenId) => void }) {
  return (
    <div class="flex flex-col items-center justify-center gap-5 py-20 text-center">
      <div class="rounded-[1.4rem] border border-white/7 bg-white/3 p-5">
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor"
          stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="text-[#5e7a90]">
          <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
          <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
        </svg>
      </div>
      <div>
        <h2 class="text-[1.25rem] font-bold text-[#f1efe7]">Library is empty</h2>
        <p class="mt-1.5 max-w-[32ch] text-[0.88rem] leading-relaxed text-[#848076]">
          Find anime and manga on AniList to start building your local library.
        </p>
      </div>
      <button
        class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-5 py-2.5 text-[0.88rem] font-bold text-[#f1efe7] transition hover:-translate-y-px hover:bg-[rgba(217,116,82,0.26)]"
        onClick={() => onNavigate("search")}
      >
        Discover &amp; add media
      </button>
    </div>
  );
}

// ─── Entry row ────────────────────────────────────────────────────────────────

function EntryRow({ entry, mediaKind, scoreFormat, onEdit, onDetails, onProgressChange, compact = false }: {
  entry: ListEntry;
  mediaKind: MediaKind;
  scoreFormat: string;
  onEdit: (e: ListEntry) => void;
  onDetails: (id: number) => void;
  onProgressChange: (mediaId: number, delta: number) => void;
  compact?: boolean;
}) {
  const statusColor = STATUS_COLORS[entry.status] ?? "bg-white/8 text-[#9a9690]";
  const statusLabel = entry.status.charAt(0).toUpperCase() + entry.status.slice(1);
  const progressMax = entry.episodesOrChapters;
  const progressText = progressMax
    ? `${entry.progress} / ${progressMax}`
    : entry.progress > 0 ? String(entry.progress) : null;
  const progressUnit = mediaKind === "anime" ? "ep" : "ch";
  const canDecrement = entry.progress > 0;
  const canIncrement = progressMax == null || entry.progress < progressMax;

  return (
    <div
      class={`group flex min-w-0 items-center overflow-hidden border border-white/7 bg-white/3 transition hover:bg-white/5 cursor-pointer ${compact ? "gap-3 rounded-xl px-3 py-2" : "gap-4 rounded-2xl px-4 py-3"}`}
      onClick={() => onDetails(entry.mediaId)}
    >
      {!compact && (entry.coverImage ? (
        <img src={entry.coverImage} alt="" class="h-14 w-10 shrink-0 rounded-lg object-cover" loading="lazy" />
      ) : (
        <div class="h-14 w-10 shrink-0 rounded-lg bg-white/8" />
      ))}

      <div class="min-w-0 flex-1">
        <p class={`truncate font-semibold text-[#f1efe7] ${compact ? "text-[0.84rem]" : "text-[0.92rem]"}`}>{entry.title}</p>
        <div class="mt-0.5 flex flex-wrap items-center gap-x-2 text-[0.77rem] text-[#7a766e]">
          {progressText && <span>{progressText} {progressUnit}</span>}
          {entry.score != null && entry.score > 0 && (
            <span class="inline-flex items-center gap-0.5 text-[#d4b86a]">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 2l2.9 6.9L22 10l-5.5 4.8L18 22l-6-3.5L6 22l1.5-7.2L2 10l7.1-1.1L12 2z" />
              </svg>
              {formatScore(entry.score, scoreFormat)}
            </span>
          )}
          {entry.isDirty && <span class="text-[#d97452]">not synced</span>}
        </div>
      </div>

      <div class="flex shrink-0 items-center gap-1.5">
        <span class={`rounded-full px-2.5 py-0.5 text-[0.72rem] font-medium ${statusColor}`}>
          {statusLabel}
        </span>
        {/* ─ progress quick-controls ─ */}
        <button
          class={`rounded-full border border-white/0 p-1 text-[#5a5650] opacity-0 transition group-hover:opacity-100 hover:border-white/10 hover:text-[#f1efe7] ${!canDecrement ? "pointer-events-none opacity-0!" : ""}`}
          onClick={(e) => { e.stopPropagation(); onProgressChange(entry.mediaId, -1); }}
          title="−1"
        >
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="5" y1="12" x2="19" y2="12" /></svg>
        </button>
        <button
          class={`rounded-full border border-white/0 p-1 text-[#5a5650] opacity-0 transition group-hover:opacity-100 hover:border-white/10 hover:text-[#d97452] ${!canIncrement ? "pointer-events-none opacity-0!" : ""}`}
          onClick={(e) => { e.stopPropagation(); onProgressChange(entry.mediaId, 1); }}
          title="+1"
        >
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
        </button>
        <button
          class="rounded-full border border-white/0 p-1.5 text-[#5a5650] opacity-0 transition group-hover:opacity-100 hover:border-white/10 hover:text-[#f1efe7]"
          onClick={(e) => { e.stopPropagation(); onEdit(entry); }}
          title="Edit"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
          </svg>
        </button>
      </div>
    </div>
  );
}

// ─── Grid card ───────────────────────────────────────────────────────────────

function EntryGridCard({ entry, mediaKind, scoreFormat, onEdit, onDetails, onProgressChange }: {
  entry: ListEntry;
  mediaKind: MediaKind;
  scoreFormat: string;
  onEdit: (e: ListEntry) => void;
  onDetails: (id: number) => void;
  onProgressChange: (mediaId: number, delta: number) => void;
}) {
  const statusColor = STATUS_COLORS[entry.status] ?? "bg-white/8 text-[#9a9690]";
  const progressMax = entry.episodesOrChapters;
  const pct = progressMax && progressMax > 0
    ? Math.min(100, Math.round((entry.progress / progressMax) * 100))
    : null;

  return (
    <div
      class="group relative flex flex-col overflow-hidden rounded-xl border border-white/7 bg-white/3 cursor-pointer transition hover:bg-white/5"
      onClick={() => onDetails(entry.mediaId)}
    >
      {/* Cover */}
      <div class="relative aspect-[2/3] w-full shrink-0 bg-white/5">
        {entry.coverImage && (
          <img src={entry.coverImage} alt="" class="absolute inset-0 h-full w-full object-cover" loading="lazy" />
        )}
        {entry.score != null && entry.score > 0 && (
          <span class="absolute right-1.5 top-1.5 inline-flex items-center gap-0.5 rounded-full bg-[rgba(30,30,30,0.82)] px-1.5 py-0.5 text-[0.62rem] font-bold text-[#d4b86a] backdrop-blur-sm">
            <svg width="9" height="9" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12 2l2.9 6.9L22 10l-5.5 4.8L18 22l-6-3.5L6 22l1.5-7.2L2 10l7.1-1.1L12 2z" />
            </svg>
            {formatScore(entry.score, scoreFormat)}
          </span>
        )}
        <span class={`absolute bottom-1.5 left-1.5 rounded-full px-1.5 py-0.5 text-[0.6rem] font-semibold ${statusColor}`}>
          {entry.status.charAt(0).toUpperCase() + entry.status.slice(1)}
        </span>
      </div>

      {/* Info */}
      <div class="flex flex-col gap-1 p-2">
        <p class="line-clamp-2 text-[0.75rem] font-semibold leading-snug text-[#f1efe7]">{entry.title}</p>

        {pct !== null && (
          <div class="h-0.5 w-full overflow-hidden rounded-full bg-white/10">
            <div class="h-full rounded-full bg-[rgba(217,116,82,0.7)]" style={{ width: `${pct}%` }} />
          </div>
        )}

        <div class="flex items-center justify-between">
          <span class="text-[0.68rem] text-[#7a766e]">
            {entry.progress > 0
              ? `${entry.progress}${progressMax ? `/${progressMax}` : ""} ${mediaKind === "anime" ? "ep" : "ch"}`
              : "Not started"}
          </span>
          <div class="flex items-center gap-0.5">
            {(progressMax == null || entry.progress < progressMax) && (
              <button
                class="rounded p-0.5 text-[#5a5650] opacity-0 transition group-hover:opacity-100 hover:text-[#d97452]"
                onClick={(e) => { e.stopPropagation(); onProgressChange(entry.mediaId, 1); }}
                title="+1"
              >
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
              </button>
            )}
            <button
              class="rounded p-0.5 text-[#5a5650] opacity-0 transition group-hover:opacity-100 hover:text-[#f1efe7]"
              onClick={(e) => { e.stopPropagation(); onEdit(entry); }}
              title="Edit"
            >
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Library surface ─────────────────────────────────────────────────────────

export function LibrarySurface({ onNavigate, onEntryEdited }: LibrarySurfaceProps) {
  const [snapshot,        setSnapshot]        = useState<LibrarySnapshot | null>(null);
  const [entries,         setEntries]         = useState<ListEntry[]>([]);
  const [scoreFormat,     setScoreFormat]     = useState("POINT_10_DECIMAL");
  const [animeCustomLists, setAnimeCustomLists] = useState<string[]>([]);
  const [mangaCustomLists, setMangaCustomLists] = useState<string[]>([]);
  const [mediaKind,       setMediaKind]       = useState<MediaKind>("anime");
  const [activeStatus,    setActiveStatus]    = useState<ListStatus>("all");
  const [searchQuery,     setSearchQuery]     = useState("");
  const [sortKey,         setSortKey]         = useState<SortKey>("updated");
  const [sortDir,         setSortDir]         = useState<SortDir>("desc");
  const [viewStyle,       setViewStyle]       = useState<ViewStyle>("list");
  const [showFilters,     setShowFilters]     = useState(false);
  // ── Filter state ──
  const [filterScore,     setFilterScore]     = useState<ScoreFilter>("any");
  const [filterScoreMin,  setFilterScoreMin]  = useState(1);
  const [filterScoreMax,  setFilterScoreMax]  = useState(10);
  const [filterProgress,  setFilterProgress]  = useState<ProgressFilter>("any");
  const [filterUnsynced,  setFilterUnsynced]  = useState(false);
  const [filterHasNotes,  setFilterHasNotes]  = useState(false);
  // ── UI state ──
  const [loading,         setLoading]         = useState(true);
  const [syncing,         setSyncing]         = useState(false);
  const [syncMsg,         setSyncMsg]         = useState<string | null>(null);
  const [syncMsgTone,     setSyncMsgTone]     = useState<SyncMessageTone>("neutral");
  const [editEntry,       setEditEntry]       = useState<ListEntry | null>(null);
    const [showConflictDialog, setShowConflictDialog] = useState(false);
  const [detailsId,       setDetailsId]       = useState<number | null>(null);
  const [page,            setPage]            = useState(0);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    LIBRARY_META_CACHE = {
      snapshot,
      scoreFormat,
      animeCustomLists,
      mangaCustomLists,
    };
  }, [snapshot, scoreFormat, animeCustomLists, mangaCustomLists]);

  const loadData = useCallback(async (kind: MediaKind, status: ListStatus, force = false) => {
    const cacheKey = `${kind}:${status}`;
    if (!force && LIBRARY_META_CACHE && LIBRARY_VIEW_CACHE.has(cacheKey)) {
      setSnapshot(LIBRARY_META_CACHE.snapshot);
      setScoreFormat(LIBRARY_META_CACHE.scoreFormat || "POINT_10_DECIMAL");
      setAnimeCustomLists(LIBRARY_META_CACHE.animeCustomLists || []);
      setMangaCustomLists(LIBRARY_META_CACHE.mangaCustomLists || []);
      setEntries(LIBRARY_VIEW_CACHE.get(cacheKey) ?? []);
      setLoading(false);
      return;
    }

    setLoading(true);
    let nextSnapshot: LibrarySnapshot | null = null;
    let nextEntries: ListEntry[] = [];
    let nextScoreFormat = "POINT_10_DECIMAL";
    let nextAnimeCustomLists: string[] = [];
    let nextMangaCustomLists: string[] = [];

    // Fetch snapshot and entries independently so an error in one does not
    // hide the other. Errors are logged to the browser console for diagnosis.
    const snapPromise = getLibrarySnapshot().then((snap) => {
      nextSnapshot = snap;
      setSnapshot(snap);
    }).catch((e) => {
      console.error("[Library] snapshot error:", e);
    });
    const listPromise = getListEntries(MEDIA_KIND_QUERY[kind], STATUS_QUERY[status])
      .then((list) => {
        nextEntries = list;
        setEntries(list);
        LIBRARY_VIEW_CACHE.set(cacheKey, list);
      })
      .catch((e) => {
        console.error("[Library] getListEntries error:", e);
        nextEntries = [];
        setEntries([]);
      });
    const settingsPromise = getAppSettings()
      .then((s) => {
        nextScoreFormat = s.scoreFormat || "POINT_10_DECIMAL";
        setScoreFormat(nextScoreFormat);
      })
      .catch((e) => {
        console.error("[Library] getAppSettings error:", e);
      });
    const viewerPromise = getViewer()
      .then((viewer) => {
        nextAnimeCustomLists = viewer.animeCustomLists || [];
        nextMangaCustomLists = viewer.mangaCustomLists || [];
        setAnimeCustomLists(nextAnimeCustomLists);
        setMangaCustomLists(nextMangaCustomLists);
      })
      .catch((e) => {
        console.error("[Library] getViewer error:", e);
      });
    await Promise.all([snapPromise, listPromise, settingsPromise, viewerPromise]);

    LIBRARY_VIEW_CACHE.set(cacheKey, nextEntries);
    LIBRARY_META_CACHE = {
      snapshot: nextSnapshot,
      scoreFormat: nextScoreFormat,
      animeCustomLists: nextAnimeCustomLists,
      mangaCustomLists: nextMangaCustomLists,
    };
    setLoading(false);
  }, []);

  const modalCustomListNames = useMemo(() => {
    if (!editEntry) return [];
    return editEntry.mediaType.toUpperCase() === "ANIME"
      ? animeCustomLists
      : mangaCustomLists;
  }, [editEntry, animeCustomLists, mangaCustomLists]);
  const editEntryMediaType = editEntry?.mediaType.toUpperCase();

  useEffect(() => {
    setSearchQuery("");
    loadData(mediaKind, activeStatus);
  }, [mediaKind, activeStatus, loadData]);

  const filteredEntries = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    let list = q ? entries.filter((e) => e.title.toLowerCase().includes(q)) : entries;

    // Score filter
    if (filterScore === "scored") {
      list = list.filter((e) => e.score != null && e.score > 0 && e.score >= filterScoreMin && e.score <= filterScoreMax);
    } else if (filterScore === "unscored") {
      list = list.filter((e) => e.score == null || e.score === 0);
    }

    // Progress filter
    if (filterProgress === "not-started") {
      list = list.filter((e) => e.progress === 0);
    } else if (filterProgress === "in-progress") {
      list = list.filter((e) => e.progress > 0 && (e.episodesOrChapters == null || e.progress < e.episodesOrChapters));
    }

    // Toggle filters
    if (filterUnsynced) list = list.filter((e) => e.isDirty);
    if (filterHasNotes) list = list.filter((e) => !!e.notes?.trim());

    list = [...list].sort((a, b) => {
      let cmp = 0;
      if (sortKey === "title") {
        cmp = a.title.localeCompare(b.title);
      } else if (sortKey === "score") {
        cmp = (a.score ?? -1) - (b.score ?? -1);
      } else if (sortKey === "progress") {
        cmp = a.progress - b.progress;
      } else if (sortKey === "repeat") {
        cmp = a.repeatCount - b.repeatCount;
      } else {
        cmp = a.updatedAt < b.updatedAt ? -1 : a.updatedAt > b.updatedAt ? 1 : 0;
      }
      return sortDir === "asc" ? cmp : -cmp;
    });

    return list;
  }, [entries, searchQuery, sortKey, sortDir, filterScore, filterScoreMin, filterScoreMax, filterProgress, filterUnsynced, filterHasNotes]);

  // Reset to first page whenever the filtered result set changes.
  useEffect(() => { setPage(0); }, [searchQuery, sortKey, sortDir, filterScore, filterScoreMin, filterScoreMax, filterProgress, filterUnsynced, filterHasNotes, mediaKind, activeStatus]);

  // Scroll the list back to top on page change.  On desktop the inner
  // `contentRef` is the scroll container; on mobile (≤900px) the inner
  // overflow is released and the AppShell's `<main>` scrolls instead, so
  // we walk up to the nearest scrollable ancestor as a fallback.
  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;
    el.scrollTo({ top: 0, behavior: "instant" });
    const outer = el.closest("main");
    outer?.scrollTo({ top: 0, behavior: "instant" });
  }, [page]);

  const pageCount       = Math.ceil(filteredEntries.length / PAGE_SIZE);
  const paginatedEntries = useMemo(
    () => filteredEntries.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE),
    [filteredEntries, page],
  );

  function handleSortChange(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      const opt = SORT_OPTIONS.find((o) => o.key === key)!;
      setSortKey(key);
      setSortDir(opt.defaultDir);
    }
  }

  const activeFilterCount = useMemo(() => {
    let n = 0;
    if (filterScore !== "any")    n++;
    if (filterProgress !== "any") n++;
    if (filterUnsynced)           n++;
    if (filterHasNotes)           n++;
    return n;
  }, [filterScore, filterProgress, filterUnsynced, filterHasNotes]);

  function resetFilters() {
    setFilterScore("any");
    setFilterScoreMin(1);
    setFilterScoreMax(10);
    setFilterProgress("any");
    setFilterUnsynced(false);
    setFilterHasNotes(false);
  }

  async function handleProgressChange(mediaId: number, delta: number) {
    try {
      const newProgress = await incrementEpisodeProgress(mediaId, delta);
      setEntries((prev) => {
        const next = prev.map((e) => e.mediaId === mediaId ? { ...e, progress: newProgress, isDirty: true } : e);
        LIBRARY_VIEW_CACHE.set(`${mediaKind}:${activeStatus}`, next);
        return next;
      });
      onEntryEdited?.();
    } catch (e) {
      console.error("[Library] incrementEpisodeProgress error:", e);
    }
  }

  async function handleSync() {
    setSyncing(true);
    setSyncMsg(null);
    setSyncMsgTone("neutral");
    try {
      const result = await syncUserLists();
      const parts: string[] = [];
      if (result.pushed > 0)    parts.push(`↑ ${result.pushed} uploaded`);
      if (result.synced > 0)    parts.push(`↓ ${result.synced} synced`);
      if (result.failed > 0)    parts.push(`${result.failed} failed`);
      if (result.conflicts > 0) parts.push(`⚠ ${result.conflicts} conflict${result.conflicts > 1 ? "s" : ""}`);
      const tag = result.isDelta ? " (delta)" : "";
      const baseMsg = parts.length ? parts.join(" · ") + tag : "Up to date";
      setSyncMsg(
        result.conflicts > 0
          ? baseMsg + " — click to resolve"
          : baseMsg
      );
      setSyncMsgTone("neutral");
      if (result.conflicts > 0) setShowConflictDialog(true);
      await loadData(mediaKind, activeStatus, true);
      setTimeout(() => {
        setSyncMsg(null);
        setSyncMsgTone("neutral");
      }, 4000);
    } catch (e) {
      const failure = formatSyncFailure(e);
      setSyncMsg(failure.message);
      setSyncMsgTone(failure.tone);
    } finally {
      setSyncing(false);
    }
  }

  const isKindEmpty = !loading && entries.length === 0 && !searchQuery;
  const globalEmpty = !loading && (snapshot ? snapshot.totalEntries === 0 : entries.length === 0);
  const dirtyCount = useMemo(() => entries.filter((e) => e.isDirty).length, [entries]);

  const tabLabel = (tab: typeof STATUS_TABS[number]) =>
    mediaKind === "anime" ? tab.animeLabel : tab.mangaLabel;

  const paginationBar = pageCount > 1 && (
    <div class="mt-4 flex items-center justify-center gap-2 pb-2">
      <button
        class="rounded-lg border border-white/8 bg-white/4 px-3 py-1.5 text-[0.82rem] text-[#9a9690] transition hover:border-white/15 hover:text-[#f1efe7] disabled:opacity-30"
        disabled={page === 0}
        onClick={() => setPage((p) => p - 1)}
      >
        ←
      </button>
      <span class="min-w-[6rem] text-center text-[0.82rem] text-[#5a5650]">
        {page + 1} / {pageCount}
      </span>
      <button
        class="rounded-lg border border-white/8 bg-white/4 px-3 py-1.5 text-[0.82rem] text-[#9a9690] transition hover:border-white/15 hover:text-[#f1efe7] disabled:opacity-30"
        disabled={page >= pageCount - 1}
        onClick={() => setPage((p) => p + 1)}
      >
        →
      </button>
    </div>
  );

  return (
    // On mobile (≤900px) we collapse this from a fixed-height flex column
    // into a normal flow so the AppShell's `<main>` scroll handles the whole
    // surface — that lets the header / kind tabs / toolbar scroll away with
    // the content instead of permanently eating ~50% of a phone viewport.
    // Desktop keeps the original split: fixed header above, scrollable list
    // below.
    <div class="flex h-full flex-col max-[900px]:h-auto max-[900px]:min-h-full">
      {/* ── Header ────────────────────────────────────────────────────── */}
      <header class="shrink-0 px-8 pt-8 pb-0 max-[900px]:px-4 max-[900px]:pt-4">
        <div class="flex items-center justify-between">
          <h1 class="text-[2rem] font-bold leading-[1.05] tracking-[-0.03em] text-[#f1efe7]">
            Library
          </h1>
          <div class="flex items-center gap-2">
            {syncMsg && (
              <span class={`max-w-[48ch] rounded-full border px-3 py-1.5 text-[0.78rem] ${
                syncMsgTone === "warning"
                  ? "border-[rgba(212,184,106,0.45)] bg-[rgba(212,184,106,0.12)] text-[#d4b86a]"
                  : syncMsgTone === "error"
                    ? "border-[rgba(224,138,138,0.45)] bg-[rgba(224,138,138,0.12)] text-[#e08a8a]"
                    : "border-white/10 bg-white/4 text-[#7a766e]"
              }`}>
                {syncMsg}
              </span>
            )}
            {!syncMsg && dirtyCount > 0 && (
              <span class="flex items-center gap-1 text-[0.78rem] text-[#c4924a]" title={`${dirtyCount} unsaved change${dirtyCount > 1 ? "s" : ""} pending upload`}>
                <span class="h-1.5 w-1.5 rounded-full bg-[#d97452] animate-pulse" />
                {dirtyCount} pending
              </span>
            )}
            <button
              class="rounded-full border border-white/10 px-3.5 py-2 text-[0.84rem] font-medium text-[#9a9690] transition hover:border-white/20 hover:text-[#f1efe7] disabled:opacity-40"
              onClick={handleSync}
              disabled={syncing}
              title="Sync with AniList"
            >
              {syncing ? "Syncing…" : "↻ Sync"}
            </button>
            <button
              class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-4 py-2 text-[0.87rem] font-bold text-[#f1efe7] transition hover:-translate-y-px hover:bg-[rgba(217,116,82,0.26)]"
              onClick={() => onNavigate("search")}
            >
              + Add
            </button>
          </div>
        </div>

        {/* ── Media kind pills ──────────────────────────────────────── */}
        <div class="mt-4 flex gap-1.5">
          {MEDIA_KINDS.map(({ id, label }) => (
            <button
              key={id}
              class={`rounded-full px-4 py-1.5 text-[0.83rem] font-semibold transition ${
                mediaKind === id
                  ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]"
                  : "text-[#7a766e] hover:text-[#d4d0c8]"
              }`}
              onClick={() => { setMediaKind(id); setActiveStatus("all"); }}
            >
              {label}
              {id === "anime" && snapshot && (
                <span class="ml-1.5 text-[0.7rem] opacity-60">{snapshot.animeEntries}</span>
              )}
              {id === "manga" && snapshot && (
                <span class="ml-1.5 text-[0.7rem] opacity-60">{snapshot.mangaEntries}</span>
              )}
            </button>
          ))}
        </div>
      </header>

      {/* ── Status tabs ───────────────────────────────────────────────── */}
      {!globalEmpty && (
        <div class="shrink-0 border-b border-white/7 px-8 pt-4">
          <div class="flex gap-0.5">
            {STATUS_TABS.map((tab) => {
              const active = activeStatus === tab.id;
              return (
                <button
                  key={tab.id}
                  class={`border-b-2 px-3 pb-3 pt-0 text-[0.87rem] font-medium transition ${
                    active
                      ? "border-[#d97452] text-[#f1efe7]"
                      : "border-transparent text-[#7a766e] hover:text-[#d4d0c8]"
                  }`}
                  onClick={() => setActiveStatus(tab.id)}
                >
                  {tabLabel(tab)}
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* ── Toolbar: search · sort · filters · view ───────────────── */}
      {!globalEmpty && entries.length > 0 && (
        <div class="shrink-0 px-8 pt-4">
          <div class="flex flex-wrap gap-2">
            {/* Search input */}
            <div class="relative min-w-[180px] flex-1">
              <svg
                class="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#5a5650]"
                width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
              >
                <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              <input
                id="library-search"
                name="librarySearch"
                type="text"
                placeholder={`Search ${mediaKind === "anime" ? "anime" : mediaKind === "manga" ? "manga" : "light novels"}…`}
                class="w-full rounded-xl border border-white/8 bg-white/4 py-2 pl-8 pr-3 text-[0.87rem] text-[#f1efe7] placeholder-[#5a5650] focus:border-white/15 focus:outline-none"
                value={searchQuery}
                onInput={(e) => setSearchQuery((e.target as HTMLInputElement).value)}
              />
              {searchQuery && (
                <button
                  class="absolute right-2.5 top-1/2 -translate-y-1/2 text-[#5a5650] hover:text-[#f1efe7]"
                  onClick={() => setSearchQuery("")}
                >
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </button>
              )}
            </div>

            {/* Sort selector */}
            <div class="relative flex shrink-0 items-center">
              <DropdownSelect
                options={SORT_OPTIONS.map((o) => ({ value: o.key, label: o.label }))}
                value={sortKey}
                onChange={(v) => handleSortChange(v as SortKey)}
                buttonClass="appearance-none rounded-xl border border-white/8 bg-white/4 py-2 pl-3 pr-7 text-[0.83rem] text-[#9a9690]"
                menuClass="min-w-44 overflow-hidden rounded-xl border border-white/10 bg-[#17191b] shadow-[-2px_8px_28px_rgba(0,0,0,0.45)]"
              />
              <button
                class="absolute right-1.5 top-1/2 -translate-y-1/2 text-[#5a5650] hover:text-[#f1efe7] transition"
                onClick={() => setSortDir((d) => (d === "asc" ? "desc" : "asc"))}
                title={sortDir === "asc" ? "Ascending" : "Descending"}
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  {sortDir === "asc"
                    ? <path d="M12 19V5M5 12l7-7 7 7" />
                    : <path d="M12 5v14M5 12l7 7 7-7" />
                  }
                </svg>
              </button>
            </div>

            {/* Filters toggle */}
            <button
              class={`flex shrink-0 items-center gap-1.5 rounded-xl border px-3 py-2 text-[0.83rem] transition ${
                showFilters || activeFilterCount > 0
                  ? "border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.12)] text-[#f1efe7]"
                  : "border-white/8 bg-white/4 text-[#9a9690] hover:text-[#f1efe7]"
              }`}
              onClick={() => setShowFilters((v) => !v)}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="4" y1="6" x2="20" y2="6" />
                <line x1="8" y1="12" x2="16" y2="12" />
                <line x1="11" y1="18" x2="13" y2="18" />
              </svg>
              Filters
              {activeFilterCount > 0 && (
                <span class="flex h-4 w-4 items-center justify-center rounded-full bg-[rgba(217,116,82,0.8)] text-[0.62rem] font-bold text-white">
                  {activeFilterCount}
                </span>
              )}
            </button>

            {/* View style toggle */}
            <div class="flex shrink-0 items-center gap-0.5 rounded-xl border border-white/8 bg-white/4 p-1">
              {/* List */}
              <button
                title="List view"
                onClick={() => setViewStyle("list")}
                class={`rounded-lg p-1.5 transition ${viewStyle === "list" ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]" : "text-[#5a5650] hover:text-[#f1efe7]"}`}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="5" width="18" height="3" rx="1" /><rect x="3" y="11" width="18" height="3" rx="1" /><rect x="3" y="17" width="18" height="3" rx="1" />
                </svg>
              </button>
              {/* Compact */}
              <button
                title="Compact view"
                onClick={() => setViewStyle("compact")}
                class={`rounded-lg p-1.5 transition ${viewStyle === "compact" ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]" : "text-[#5a5650] hover:text-[#f1efe7]"}`}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="12" x2="21" y2="12" /><line x1="3" y1="18" x2="21" y2="18" />
                </svg>
              </button>
              {/* Grid */}
              <button
                title="Grid view"
                onClick={() => setViewStyle("grid")}
                class={`rounded-lg p-1.5 transition ${viewStyle === "grid" ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]" : "text-[#5a5650] hover:text-[#f1efe7]"}`}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" />
                  <rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Filter panel ──────────────────────────────────────────────── */}
      {!globalEmpty && entries.length > 0 && showFilters && (
        <div class="shrink-0 px-8 pt-3">
          <div class="flex flex-wrap gap-x-6 gap-y-3 rounded-xl border border-white/8 bg-white/3 p-4">

            {/* Score filter */}
            <div class="flex flex-col gap-1.5">
              <p class="text-[0.68rem] font-bold uppercase tracking-wider text-[#5a5650]">Score</p>
              <div class="flex gap-1">
                {(["any", "scored", "unscored"] as ScoreFilter[]).map((v) => (
                  <button
                    key={v}
                    class={`rounded-lg px-2.5 py-1 text-xs transition ${filterScore === v ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]" : "bg-white/5 text-[#9a9690] hover:text-[#f1efe7]"}`}
                    onClick={() => setFilterScore(v)}
                  >
                    {v === "any" ? "Any" : v === "scored" ? "Scored" : "Unscored"}
                  </button>
                ))}
              </div>
              {filterScore === "scored" && (
                <div class="flex items-center gap-1.5">
                  <input
                    type="number" min={1} max={10} step={0.5} value={filterScoreMin}
                    class="w-14 rounded-lg border border-white/8 bg-white/5 px-2 py-1 text-center text-[0.8rem] text-[#f1efe7] focus:outline-none"
                    onInput={(e) => setFilterScoreMin(Number((e.target as HTMLInputElement).value))}
                  />
                  <span class="text-xs text-[#5a5650]">–</span>
                  <input
                    type="number" min={1} max={10} step={0.5} value={filterScoreMax}
                    class="w-14 rounded-lg border border-white/8 bg-white/5 px-2 py-1 text-center text-[0.8rem] text-[#f1efe7] focus:outline-none"
                    onInput={(e) => setFilterScoreMax(Number((e.target as HTMLInputElement).value))}
                  />
                </div>
              )}
            </div>

            {/* Progress filter */}
            <div class="flex flex-col gap-1.5">
              <p class="text-[0.68rem] font-bold uppercase tracking-wider text-[#5a5650]">Progress</p>
              <div class="flex flex-wrap gap-1">
                {(["any", "not-started", "in-progress"] as ProgressFilter[]).map((v) => (
                  <button
                    key={v}
                    class={`rounded-lg px-2.5 py-1 text-xs transition ${filterProgress === v ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]" : "bg-white/5 text-[#9a9690] hover:text-[#f1efe7]"}`}
                    onClick={() => setFilterProgress(v)}
                  >
                    {v === "any" ? "Any" : v === "not-started" ? "Not started" : "In progress"}
                  </button>
                ))}
              </div>
            </div>

            {/* Toggle filters */}
            <div class="flex flex-col gap-1.5">
              <p class="text-[0.68rem] font-bold uppercase tracking-wider text-[#5a5650]">Show only</p>
              <div class="flex flex-wrap gap-1.5">
                {([
                  { label: "Unsynced",  value: filterUnsynced, set: setFilterUnsynced  },
                  { label: "Has notes", value: filterHasNotes,  set: setFilterHasNotes  },
                ] as const).map(({ label, value, set }) => (
                  <button
                    key={label}
                    class={`flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs transition ${value ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]" : "bg-white/5 text-[#9a9690] hover:text-[#f1efe7]"}`}
                    onClick={() => set(!value)}
                  >
                    <span class={`flex h-3.5 w-3.5 items-center justify-center rounded border ${value ? "border-[#d97452] bg-[rgba(217,116,82,0.4)]" : "border-white/20"}`}>
                      {value && (
                        <svg width="8" height="8" viewBox="0 0 8 8" fill="none">
                          <path d="M1 4l2 2 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                      )}
                    </span>
                    {label}
                  </button>
                ))}
              </div>
            </div>

            {/* Reset */}
            {activeFilterCount > 0 && (
              <div class="flex items-end">
                <button
                  class="text-xs text-[#7a766e] transition hover:text-[#e08a8a]"
                  onClick={resetFilters}
                >
                  Reset filters
                </button>
              </div>
            )}
          </div>
        </div>
      )}
      {/* ── Content ───────────────────────────────────────────────────── */}
      <div
        ref={contentRef}
        // `max-[900px]:overflow-visible` releases the inner scroll on phones
        // so the surrounding AppShell `<main>` becomes the single scrolling
        // container — without this the header above stays pinned and the
        // list only gets ~50% of the viewport height.
        class={`flex-1 overflow-y-auto overflow-x-hidden py-4 max-[900px]:overflow-visible max-[900px]:flex-none ${viewStyle === "grid" ? "px-6 max-[900px]:px-3" : "px-8 max-[900px]:px-4"}`}
      >
        {loading ? (
          <div class="space-y-3">
            <KaomojiLoadingText label="Loading your library" index={0} />
            <div class="grid gap-2">
              {Array.from({ length: 6 }).map((_, i) => (
                <MediaCardSkeleton key={i} />
              ))}
            </div>
          </div>
        ) : globalEmpty ? (
          <EmptyState onNavigate={onNavigate} />
        ) : isKindEmpty ? (
          <p class="py-16 text-center text-[0.9rem] text-[#7a766e]">
            No {mediaKind === "anime" ? "anime" : mediaKind === "manga" ? "manga" : "light novels"} in{" "}
            {activeStatus === "all" ? "your library" : "this status"} yet.
          </p>
        ) : filteredEntries.length === 0 ? (
          <p class="py-16 text-center text-[0.9rem] text-[#7a766e]">
            {searchQuery ? `No results for "${searchQuery}"` : "No entries match the active filters."}
            {activeFilterCount > 0 && (
              <button class="ml-1.5 text-[#d97452] hover:underline" onClick={resetFilters}>Reset filters</button>
            )}
          </p>
        ) : viewStyle === "grid" ? (
          <>
            <div class="grid gap-3" style="grid-template-columns: repeat(auto-fill, minmax(120px, 1fr))">
              {paginatedEntries.map((entry) => (
                <EntryGridCard
                  key={entry.localId}
                  entry={entry}
                  mediaKind={mediaKind}
                  scoreFormat={scoreFormat}
                  onEdit={setEditEntry}
                  onDetails={setDetailsId}
                  onProgressChange={handleProgressChange}
                />
              ))}
            </div>
            {paginationBar}
          </>
        ) : (
          <>
            <div class={`grid ${viewStyle === "compact" ? "gap-1" : "gap-2"}`}>
              {paginatedEntries.map((entry) => (
                <EntryRow
                  key={entry.localId}
                  entry={entry}
                  mediaKind={mediaKind}
                  scoreFormat={scoreFormat}
                  onEdit={setEditEntry}
                  onDetails={setDetailsId}
                  onProgressChange={handleProgressChange}
                  compact={viewStyle === "compact"}
                />
              ))}
            </div>
            {(searchQuery || activeFilterCount > 0) && filteredEntries.length < entries.length && (
              <p class="pt-2 text-center text-[0.78rem] text-[#5a5650]">
                {filteredEntries.length} of {entries.length} entries match
              </p>
            )}
            {paginationBar}
          </>
        )}
      </div>

      {/* ── Edit modal ────────────────────────────────────────────────── */}
      {editEntry && (
        <EntryEditModal
          entry={editEntry}
          scoreFormat={scoreFormat}
          customListNames={modalCustomListNames}
          onCustomListNamesChange={(names) => {
            const uniqueNames = Array.from(new Set(names));
            if (editEntryMediaType === "ANIME") {
              setAnimeCustomLists(uniqueNames);
              LIBRARY_META_CACHE = {
                ...(LIBRARY_META_CACHE ?? {
                  snapshot,
                  scoreFormat,
                  animeCustomLists: [],
                  mangaCustomLists,
                }),
                animeCustomLists: uniqueNames,
              };
            } else {
              setMangaCustomLists(uniqueNames);
              LIBRARY_META_CACHE = {
                ...(LIBRARY_META_CACHE ?? {
                  snapshot,
                  scoreFormat,
                  animeCustomLists,
                  mangaCustomLists: [],
                }),
                mangaCustomLists: uniqueNames,
              };
            }
          }}
          onClose={() => setEditEntry(null)}
          onSaved={() => {
            loadData(mediaKind, activeStatus, true);
            onEntryEdited?.();
          }}
        />
      )}


      {detailsId != null && (
        <MediaDetailsPanel
          mediaId={detailsId}
          onClose={() => setDetailsId(null)}
        />
      )}

      {/* ── Conflict resolution dialog ─────────────────────────────── */}
      {showConflictDialog && (
        <ConflictResolutionDialog
          onClose={(anyResolved) => {
            setShowConflictDialog(false);
            if (anyResolved) loadData(mediaKind, activeStatus, true);
          }}
        />
      )}
    </div>
  );
}
