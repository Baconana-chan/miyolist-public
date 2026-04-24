import { useState, useEffect, useCallback } from "preact/hooks";
import {
  addToLibrary,
  getAiringSchedule,
  getAppSettings,
  getGlobalAiringSchedule,
  getListEntries,
  getNotificationOverrides,
  incrementEpisodeProgress,
  refreshAiringSchedule,
  setNotificationOverride,
  saveAppSettings,
} from "../../shared/api/database";
import type { AiringEntry, AppSettings, GlobalAiringEntry } from "../../shared/types/app";
import { KaomojiLoadingText, MediaCardSkeleton } from "../../shared/components/Skeleton";
import { actionButtonClass, tileClass } from "../../shared/tw";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const GLOBAL_SCHEDULE_TTL_MS = 3 * 60 * 1000;
const GLOBAL_SCHEDULE_CACHE = new Map<number, Cached<GlobalAiringEntry[]>>();

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function now() {
  return Math.floor(Date.now() / 1000);
}

function currentWeekday(): number {
  const day = new Date().getDay();
  return day === 0 ? 7 : day;
}

const WEEKDAY_OPTIONS = [
  { value: 1, short: "Mon", label: "Monday" },
  { value: 2, short: "Tue", label: "Tuesday" },
  { value: 3, short: "Wed", label: "Wednesday" },
  { value: 4, short: "Thu", label: "Thursday" },
  { value: 5, short: "Fri", label: "Friday" },
  { value: 6, short: "Sat", label: "Saturday" },
  { value: 7, short: "Sun", label: "Sunday" },
] as const;

const POPULARITY_THRESHOLDS = [
  { value: 0, label: "All" },
  { value: 5000, label: "5k+" },
  { value: 10000, label: "10k+" },
  { value: 25000, label: "25k+" },
  { value: 50000, label: "50k+" },
] as const;

/** Returns a human-readable relative-time string (e.g. "in 2 h 14 m"). */
function formatCountdown(airingAt: number): string {
  const diff = airingAt - now();
  if (diff <= 0) return "Aired";
  const days = Math.floor(diff / 86400);
  const hours = Math.floor((diff % 86400) / 3600);
  const mins = Math.floor((diff % 3600) / 60);
  if (days > 0) return `in ${days}d ${hours}h`;
  if (hours > 0) return `in ${hours}h ${mins}m`;
  return `in ${mins}m`;
}

/** Short day label — "Today", "Tomorrow", or weekday name. */
function dayLabel(airingAt: number): string {
  const d = new Date(airingAt * 1000);
  const today = new Date();
  const diff = Math.floor((d.setHours(0, 0, 0, 0) - today.setHours(0, 0, 0, 0)) / 86400000);
  if (diff === 0) return "Today";
  if (diff === 1) return "Tomorrow";
  if (diff < 0) return "Past";
  return d.toLocaleDateString(undefined, { weekday: "long" });
}

/**
 * Full date label for entries beyond this week — includes the date so that
 * multiple future Sundays don't collapse into one group.
 */
function fullDayLabel(airingAt: number): string {
  return new Date(airingAt * 1000).toLocaleDateString(undefined, {
    weekday: "long",
    month: "short",
    day: "numeric",
  });
}

function formatClock(airingAt: number): string {
  return new Date(airingAt * 1000).toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatPopularity(popularity: number | null): string {
  if (popularity == null) return "Popularity n/a";
  return `${new Intl.NumberFormat().format(popularity)} users`;
}

function formatMediaFormat(format: string | null): string {
  if (!format) return "Format n/a";
  return format.replace(/_/g, " ").toLowerCase().replace(/\b\w/g, (char: string) => char.toUpperCase());
}

/** Group entries by airing day. */
function groupByDay(entries: AiringEntry[]): Map<string, AiringEntry[]> {
  const map = new Map<string, AiringEntry[]>();
  for (const entry of entries) {
    const label = dayLabel(entry.airingAt);
    if (!map.has(label)) map.set(label, []);
    map.get(label)!.push(entry);
  }
  return map;
}

// ─── Sub-components ───────────────────────────────────────────────────────────

interface EntryCardProps {
  entry: AiringEntry;
  muted: boolean;
  onToggleMute: (mediaId: number, muted: boolean) => void;
  onProgressChange: (mediaId: number, delta: number) => void;
}

function EntryCard({ entry, muted, onToggleMute, onProgressChange }: EntryCardProps) {
  const aired = entry.airingAt <= now();
  const behindBy = entry.episode - entry.userProgress;
  const pct = entry.totalEpisodes
    ? Math.min(100, Math.round((entry.userProgress / entry.totalEpisodes) * 100))
    : null;

  return (
    <article class="flex gap-3 rounded-[1.1rem] border border-white/7 bg-white/3 p-3 transition hover:bg-white/5">
      <div class="relative shrink-0">
        {entry.coverImage ? (
          <img
            src={entry.coverImage}
            alt={entry.title}
            class="h-22 w-[3.8rem] rounded-[0.6rem] object-cover"
            loading="lazy"
          />
        ) : (
          <div class="flex h-22 w-[3.8rem] items-center justify-center rounded-[0.6rem] bg-white/5 text-[0.7rem] text-[#b5b0a5]">
            No cover
          </div>
        )}
        {entry.score != null && entry.score > 0 && (
          <span class="absolute -bottom-1 -right-1 rounded-full bg-[rgba(217,116,82,0.88)] px-1.5 py-0.5 text-[0.65rem] font-bold text-white">
            {entry.score % 1 === 0 ? entry.score : entry.score.toFixed(1)}
          </span>
        )}
      </div>

      <div class="flex min-w-0 flex-1 flex-col gap-1">
        <p class="truncate text-sm font-semibold leading-tight text-[#f1efe7]" title={entry.title}>
          {entry.title}
        </p>

        <p class="text-xs text-[#7ca4be]">
          Ep {entry.episode}
          {entry.totalEpisodes ? ` / ${entry.totalEpisodes}` : ""}
          {" · "}
          <span class={aired ? "text-[#8ecf8e]" : "text-[#d4b86a]"}>{formatCountdown(entry.airingAt)}</span>
        </p>

        {pct != null && (
          <div class="h-1 w-full overflow-hidden rounded-full bg-white/10">
            <div
              class="h-full rounded-full bg-[rgba(217,116,82,0.7)] transition-all"
              style={{ width: `${pct}%` }}
            />
          </div>
        )}

        <p class="text-xs text-[#b5b0a5]">
          Your progress: ep {entry.userProgress}
          {behindBy > 0 && <span class="ml-1 text-[#e08a8a]">({behindBy} behind)</span>}
        </p>
      </div>

      <div class="flex shrink-0 flex-col items-center justify-center gap-1">
        <button
          title={muted ? "Enable airing notifications" : "Mute airing notifications"}
          onClick={() => onToggleMute(entry.mediaId, !muted)}
          class={`flex h-7 w-7 items-center justify-center rounded-full transition ${
            muted
              ? "bg-[rgba(210,80,80,0.16)] text-[#e08a8a] hover:bg-[rgba(210,80,80,0.26)]"
              : "bg-white/8 text-[#7ca4be] hover:bg-white/14"
          }`}
        >
          {muted ? "🔕" : "🔔"}
        </button>
        <button
          title="Mark +1 episode watched"
          onClick={() => onProgressChange(entry.mediaId, 1)}
          class="flex h-7 w-7 items-center justify-center rounded-full bg-white/8 text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.28)] active:scale-95"
        >
          +
        </button>
        <span class="text-xs tabular-nums text-[#7ca4be]">{entry.userProgress}</span>
        <button
          title="Mark -1 episode"
          onClick={() => onProgressChange(entry.mediaId, -1)}
          disabled={entry.userProgress <= 0}
          class="flex h-7 w-7 items-center justify-center rounded-full bg-white/8 text-[#b5b0a5] transition hover:bg-white/12 active:scale-95 disabled:opacity-30"
        >
          −
        </button>
      </div>
    </article>
  );
}

interface EntryRowProps {
  entry: AiringEntry;
  muted: boolean;
  onToggleMute: (mediaId: number, muted: boolean) => void;
  onProgressChange: (mediaId: number, delta: number) => void;
}

function EntryRow({ entry, muted, onToggleMute, onProgressChange }: EntryRowProps) {
  const aired = entry.airingAt <= now();
  const behindBy = entry.episode - entry.userProgress;

  return (
    <div class="flex items-center gap-3 border-b border-white/5 py-2.5 last:border-0">
      {entry.coverImage && (
          <img src={entry.coverImage} alt="" class="h-8 w-5.5 shrink-0 rounded object-cover" loading="lazy" />
      )}
      <p class="min-w-0 flex-1 truncate text-sm text-[#f1efe7]" title={entry.title}>
        {entry.title}
      </p>
      <span class="shrink-0 text-xs tabular-nums text-[#7ca4be]">Ep {entry.episode}</span>
      <span class={`shrink-0 text-xs tabular-nums ${aired ? "text-[#8ecf8e]" : "text-[#d4b86a]"}`}>
        {formatCountdown(entry.airingAt)}
      </span>
      <button
        title={muted ? "Enable airing notifications" : "Mute airing notifications"}
        onClick={() => onToggleMute(entry.mediaId, !muted)}
        class={`shrink-0 rounded px-1.5 py-0.5 text-xs transition ${
          muted
            ? "bg-[rgba(210,80,80,0.16)] text-[#e08a8a] hover:bg-[rgba(210,80,80,0.26)]"
            : "bg-white/8 text-[#7ca4be] hover:bg-white/14"
        }`}
      >
        {muted ? "🔕" : "🔔"}
      </button>
      {behindBy > 0 && <span class="shrink-0 text-xs text-[#e08a8a]">-{behindBy}</span>}
      <div class="flex shrink-0 items-center gap-1">
        <button
          onClick={() => onProgressChange(entry.mediaId, -1)}
          disabled={entry.userProgress <= 0}
          class="flex h-6 w-6 items-center justify-center rounded bg-white/8 text-xs text-[#b5b0a5] transition hover:bg-white/12 disabled:opacity-30"
        >
          −
        </button>
        <span class="w-6 text-center text-xs tabular-nums text-[#f1efe7]">{entry.userProgress}</span>
        <button
          onClick={() => onProgressChange(entry.mediaId, 1)}
          class="flex h-6 w-6 items-center justify-center rounded bg-white/8 text-xs text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.28)]"
        >
          +
        </button>
      </div>
    </div>
  );
}

interface GlobalEntryCardProps {
  entry: GlobalAiringEntry;
  inLibrary: boolean;
  adding: boolean;
  onAdd: (entry: GlobalAiringEntry) => void;
  onOpen: (mediaId: number) => void;
}

function GlobalEntryCard({ entry, inLibrary, adding, onAdd, onOpen }: GlobalEntryCardProps) {
  const aired = entry.airingAt <= now();

  return (
    <article class="flex flex-col rounded-[1.1rem] border border-white/7 bg-white/3 p-3 transition hover:bg-white/5">
      <div class="flex gap-3">
        <button
          type="button"
          onClick={() => onOpen(entry.mediaId)}
          class="relative shrink-0 overflow-hidden rounded-[0.7rem] focus:outline-none focus-visible:ring-2 focus-visible:ring-[rgba(217,116,82,0.5)]"
        >
          {entry.coverImage ? (
            <img
              src={entry.coverImage}
              alt={entry.title}
              class="h-[6.1rem] w-[4.2rem] object-cover"
              loading="lazy"
            />
          ) : (
            <div class="flex h-[6.1rem] w-[4.2rem] items-center justify-center bg-white/5 text-[0.7rem] text-[#b5b0a5]">
              No cover
            </div>
          )}
        </button>

        <div class="min-w-0 flex-1">
          <button
            type="button"
            onClick={() => onOpen(entry.mediaId)}
            class="w-full truncate text-left text-sm font-semibold leading-tight text-[#f1efe7] transition hover:text-white"
            title={entry.title}
          >
            {entry.title}
          </button>
          <p class="mt-1 text-xs text-[#7ca4be]">
            Ep {entry.episode}
            {" · "}
            <span class={aired ? "text-[#8ecf8e]" : "text-[#d4b86a]"}>{formatCountdown(entry.airingAt)}</span>
          </p>
          <p class="mt-1 text-xs text-[#b5b0a5]">
            {formatClock(entry.airingAt)}
            {" · "}
            {formatMediaFormat(entry.format)}
          </p>
          <p class="mt-1 text-xs text-[#b5b0a5]">{formatPopularity(entry.popularity)}</p>
        </div>
      </div>

      <div class="mt-3 flex items-center justify-between gap-2">
        {inLibrary ? (
          <span class="rounded-full border border-[rgba(124,164,190,0.28)] bg-[rgba(124,164,190,0.12)] px-3 py-1.5 text-[0.72rem] font-semibold uppercase tracking-[0.12em] text-[#a9d2eb]">
            In library
          </span>
        ) : (
          <button
            type="button"
            onClick={() => onAdd(entry)}
            disabled={adding}
            class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-3 py-1.5 text-xs font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)] disabled:cursor-wait disabled:opacity-60"
          >
            {adding ? "Adding…" : "Add to Planning"}
          </button>
        )}

        <button
          type="button"
          onClick={() => onOpen(entry.mediaId)}
          class="text-xs font-semibold text-[#b5b0a5] transition hover:text-[#f1efe7]"
        >
          Details
        </button>
      </div>
    </article>
  );
}

interface GlobalEntryRowProps {
  entry: GlobalAiringEntry;
  inLibrary: boolean;
  adding: boolean;
  onAdd: (entry: GlobalAiringEntry) => void;
  onOpen: (mediaId: number) => void;
}

function GlobalEntryRow({ entry, inLibrary, adding, onAdd, onOpen }: GlobalEntryRowProps) {
  const aired = entry.airingAt <= now();

  return (
    <div class="flex items-center gap-3 border-b border-white/5 py-2.5 last:border-0">
      <button type="button" onClick={() => onOpen(entry.mediaId)} class="shrink-0 rounded focus:outline-none focus-visible:ring-2 focus-visible:ring-[rgba(217,116,82,0.5)]">
        {entry.coverImage ? (
          <img src={entry.coverImage} alt="" class="h-8 w-5.5 rounded object-cover" loading="lazy" />
        ) : (
          <div class="h-8 w-5.5 rounded bg-white/5" />
        )}
      </button>

      <div class="min-w-0 flex-1">
        <button
          type="button"
          onClick={() => onOpen(entry.mediaId)}
          class="w-full truncate text-left text-sm text-[#f1efe7] transition hover:text-white"
          title={entry.title}
        >
          {entry.title}
        </button>
        <p class="mt-0.5 text-xs text-[#b5b0a5]">
          {formatMediaFormat(entry.format)}
          {" · "}
          {formatPopularity(entry.popularity)}
        </p>
      </div>

      <span class="shrink-0 text-xs tabular-nums text-[#7ca4be]">Ep {entry.episode}</span>
      <span class="shrink-0 text-xs tabular-nums text-[#b5b0a5]">{formatClock(entry.airingAt)}</span>
      <span class={`shrink-0 text-xs tabular-nums ${aired ? "text-[#8ecf8e]" : "text-[#d4b86a]"}`}>
        {formatCountdown(entry.airingAt)}
      </span>

      {inLibrary ? (
        <span class="shrink-0 rounded-full border border-[rgba(124,164,190,0.28)] bg-[rgba(124,164,190,0.12)] px-2.5 py-1 text-[0.7rem] font-semibold uppercase tracking-[0.12em] text-[#a9d2eb]">
          Added
        </span>
      ) : (
        <button
          type="button"
          onClick={() => onAdd(entry)}
          disabled={adding}
          class="shrink-0 rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-3 py-1.5 text-xs font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)] disabled:cursor-wait disabled:opacity-60"
        >
          {adding ? "Adding…" : "Planning"}
        </button>
      )}
    </div>
  );
}

// ─── Surface ──────────────────────────────────────────────────────────────────

type ViewMode = "list" | "card";
type ScheduleMode = "personal" | "global";

const WEEK_SECONDS = 7 * 24 * 3600;

export function ScheduleSurface() {
  const [entries, setEntries] = useState<AiringEntry[]>([]);
  const [globalEntries, setGlobalEntries] = useState<GlobalAiringEntry[]>([]);
  const [mutedMediaIds, setMutedMediaIds] = useState<number[]>([]);
  const [libraryMediaIds, setLibraryMediaIds] = useState<number[]>([]);
  const [addingMediaIds, setAddingMediaIds] = useState<number[]>([]);
  const [viewMode, setViewMode] = useState<ViewMode>("list");
  const [scheduleMode, setScheduleMode] = useState<ScheduleMode>("personal");
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [globalLoading, setGlobalLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [personalUpdatedAt, setPersonalUpdatedAt] = useState<Date | null>(null);
  const [globalUpdatedAt, setGlobalUpdatedAt] = useState<Date | null>(null);
  const [showLater, setShowLater] = useState(false);
  const [selectedWeekday, setSelectedWeekday] = useState<number>(currentWeekday());
  const [popularityThreshold, setPopularityThreshold] = useState<number>(10000);
  const [openMediaId, setOpenMediaId] = useState<number | null>(null);

  const loadLibraryMediaIds = useCallback(async () => {
    const animeEntries = await getListEntries("ANIME");
    setLibraryMediaIds(animeEntries.map((entry) => entry.mediaId));
  }, []);

  const load = useCallback(async () => {
    try {
      const [data, animeEntries] = await Promise.all([getAiringSchedule(), getListEntries("ANIME")]);
      data.sort((a, b) => a.airingAt - b.airingAt);
      setEntries(data);
      setLibraryMediaIds(animeEntries.map((entry) => entry.mediaId));
      setError(null);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  const loadGlobal = useCallback(async (weekday: number, force = false) => {
    const cached = GLOBAL_SCHEDULE_CACHE.get(weekday);
    if (!force && cached && isFresh(cached.fetchedAt, GLOBAL_SCHEDULE_TTL_MS)) {
      setGlobalEntries(cached.data);
      setGlobalLoading(false);
      setError(null);
      return;
    }

    setGlobalLoading(true);
    try {
      const data = await getGlobalAiringSchedule(weekday);
      data.sort((a, b) => a.airingAt - b.airingAt);
      setGlobalEntries(data);
      GLOBAL_SCHEDULE_CACHE.set(weekday, { data, fetchedAt: Date.now() });
      setError(null);
    } catch (e) {
      setError(String(e));
    } finally {
      setGlobalLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    getAppSettings()
      .then((nextSettings) => {
        setSettings(nextSettings);
        if (nextSettings.scheduleView === "card" || nextSettings.scheduleView === "list") {
          setViewMode(nextSettings.scheduleView);
        }
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (scheduleMode !== "global") return;
    void loadGlobal(selectedWeekday);
  }, [loadGlobal, scheduleMode, selectedWeekday]);

  useEffect(() => {
    if (entries.length === 0) {
      setMutedMediaIds([]);
      return;
    }
    const ids = Array.from(new Set(entries.map((entry) => entry.mediaId)));
    getNotificationOverrides(ids)
      .then((rows) => {
        const muted = rows.filter((row) => !row.enabled).map((row) => row.mediaId);
        setMutedMediaIds(muted);
      })
      .catch(() => {});
  }, [entries]);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      if (scheduleMode === "personal") {
        await refreshAiringSchedule();
        await load();
        setPersonalUpdatedAt(new Date());
      } else {
        await Promise.all([loadGlobal(selectedWeekday, true), loadLibraryMediaIds()]);
        setGlobalUpdatedAt(new Date());
      }
    } catch (e) {
      setError(String(e));
    } finally {
      setRefreshing(false);
    }
  }, [load, loadGlobal, loadLibraryMediaIds, scheduleMode, selectedWeekday]);

  const handleProgressChange = useCallback(async (mediaId: number, delta: number) => {
    try {
      const newProgress = await incrementEpisodeProgress(mediaId, delta);
      setEntries((prev) => prev.map((entry) => (entry.mediaId === mediaId ? { ...entry, userProgress: newProgress } : entry)));
    } catch (e) {
      console.error("[schedule] progress update failed:", e);
    }
  }, []);

  const handleViewModeChange = useCallback((mode: ViewMode) => {
    setViewMode(mode);
    if (!settings || settings.scheduleView === mode) return;
    const nextSettings = { ...settings, scheduleView: mode };
    setSettings(nextSettings);
    saveAppSettings(nextSettings).catch((e) => {
      console.error("[schedule] failed to save schedule view mode:", e);
    });
  }, [settings]);

  const handleAddToPlanning = useCallback(async (entry: GlobalAiringEntry) => {
    setAddingMediaIds((prev) => (prev.includes(entry.mediaId) ? prev : [...prev, entry.mediaId]));
    try {
      await addToLibrary(entry.mediaId, "ANIME", "planning", entry.title, entry.coverImage ?? null);
      setLibraryMediaIds((prev) => (prev.includes(entry.mediaId) ? prev : [...prev, entry.mediaId]));
    } catch (e) {
      setError(String(e));
    } finally {
      setAddingMediaIds((prev) => prev.filter((mediaId) => mediaId !== entry.mediaId));
    }
  }, []);

  const handleToggleMute = useCallback(async (mediaId: number, muted: boolean) => {
    setMutedMediaIds((prev) => {
      if (muted) {
        return prev.includes(mediaId) ? prev : [...prev, mediaId];
      }
      return prev.filter((id) => id !== mediaId);
    });
    try {
      await setNotificationOverride(mediaId, !muted);
    } catch (e) {
      setError(String(e));
    }
  }, []);

  const cutoff = now() + WEEK_SECONDS;
  const thisWeek = entries.filter((entry) => entry.airingAt <= cutoff);
  const later = entries.filter((entry) => entry.airingAt > cutoff);
  const weekGroups = groupByDay(thisWeek);
  const laterGroups = (() => {
    const map = new Map<string, AiringEntry[]>();
    for (const entry of later) {
      const label = fullDayLabel(entry.airingAt);
      if (!map.has(label)) map.set(label, []);
      map.get(label)!.push(entry);
    }
    return map;
  })();

  const filteredGlobalEntries = globalEntries.filter((entry) => (entry.popularity ?? 0) >= popularityThreshold);
  const selectedWeekdayLabel = WEEKDAY_OPTIONS.find((option) => option.value === selectedWeekday)?.label ?? "Selected day";
  const shownUpdatedAt = scheduleMode === "personal" ? personalUpdatedAt : globalUpdatedAt;

  return (
    <>
      <div class="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4 md:p-6">
        <div class="flex flex-wrap items-center gap-3">
          <div class="flex-1">
            <p class="mb-0.5 text-[0.74rem] font-bold uppercase tracking-[0.16em] text-[#7ca4be]">Schedule</p>
            <h1 class="m-0 text-2xl font-bold leading-tight tracking-tight text-[#f1efe7]">
              {scheduleMode === "personal" ? "Airing this week" : "All Airing"}
            </h1>
            <p class="mt-0.5 text-xs text-[#b5b0a5]">
              {scheduleMode === "personal"
                ? "Upcoming episodes from your current and repeating anime."
                : `AniChart-like feed for ${selectedWeekdayLabel}, filtered by popularity.`}
            </p>
            {shownUpdatedAt && (
              <p class="mt-1 text-xs text-[#b5b0a5]">Updated {shownUpdatedAt.toLocaleTimeString()}</p>
            )}
          </div>

          <div class="flex items-center gap-1 rounded-full border border-white/10 bg-white/4 p-1">
            {([
              ["personal", "My schedule"],
              ["global", "All airing"],
            ] as const).map(([mode, label]) => (
              <button
                key={mode}
                type="button"
                onClick={() => setScheduleMode(mode)}
                class={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                  scheduleMode === mode
                    ? "bg-[rgba(217,116,82,0.28)] text-[#f1efe7]"
                    : "text-[#b5b0a5] hover:text-[#f1efe7]"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          <div class="flex items-center gap-1 rounded-full border border-white/10 bg-white/4 p-1">
            {(["list", "card"] as ViewMode[]).map((mode) => (
              <button
                key={mode}
                type="button"
                onClick={() => handleViewModeChange(mode)}
                class={`rounded-full px-3 py-1 text-xs font-semibold capitalize transition ${
                  viewMode === mode
                    ? "bg-[rgba(217,116,82,0.28)] text-[#f1efe7]"
                    : "text-[#b5b0a5] hover:text-[#f1efe7]"
                }`}
              >
                {mode}
              </button>
            ))}
          </div>

          <button onClick={handleRefresh} disabled={refreshing} class={`${actionButtonClass} flex items-center gap-1.5 text-xs`}>
            <span class={refreshing ? "animate-spin" : ""}>↻</span>
            {refreshing ? "Refreshing…" : scheduleMode === "personal" ? "Refresh" : "Reload"}
          </button>
        </div>

        {scheduleMode === "global" && (
          <section class={tileClass}>
            <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <p class="text-sm font-semibold text-[#f1efe7]">Browse by weekday</p>
                <p class="mt-1 text-xs text-[#b5b0a5]">Each tab shows the next upcoming occurrence for that weekday.</p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <span class="text-[0.72rem] font-semibold uppercase tracking-[0.12em] text-[#7ca4be]">Popularity</span>
                {POPULARITY_THRESHOLDS.map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setPopularityThreshold(option.value)}
                    class={`rounded-full px-3 py-1.5 text-xs font-semibold transition ${
                      popularityThreshold === option.value
                        ? "bg-[rgba(217,116,82,0.28)] text-[#f1efe7]"
                        : "border border-white/10 bg-white/4 text-[#b5b0a5] hover:text-[#f1efe7]"
                    }`}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            </div>

            <div class="mt-4 flex flex-wrap gap-2">
              {WEEKDAY_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setSelectedWeekday(option.value)}
                  class={`rounded-full px-3 py-2 text-xs font-semibold transition ${
                    selectedWeekday === option.value
                      ? "bg-[rgba(217,116,82,0.28)] text-[#f1efe7]"
                      : "border border-white/10 bg-white/4 text-[#b5b0a5] hover:text-[#f1efe7]"
                  }`}
                >
                  {option.short}
                </button>
              ))}
            </div>

            {!globalLoading && (
              <p class="mt-4 text-xs text-[#b5b0a5]">
                Showing {filteredGlobalEntries.length} of {globalEntries.length} airing titles for {selectedWeekdayLabel}.
              </p>
            )}
          </section>
        )}

        {error && (
          <div class="rounded-xl border border-[rgba(210,80,80,0.28)] bg-[rgba(210,80,80,0.1)] px-4 py-3 text-sm text-[#e08a8a]">
            {error}
          </div>
        )}

        {loading && scheduleMode === "personal" && (
          <div class="space-y-3">
            <KaomojiLoadingText label="Preparing your schedule" index={3} className="text-sm text-[#b5b0a5]" />
            <div class="flex flex-col gap-3">
              {Array.from({ length: 4 }).map((_, index) => (
                <MediaCardSkeleton key={index} />
              ))}
            </div>
          </div>
        )}

        {globalLoading && scheduleMode === "global" && (
          <div class="space-y-3">
            <KaomojiLoadingText label="Pulling global airing feed" index={4} className="text-sm text-[#b5b0a5]" />
            <div class="flex flex-col gap-3">
              {Array.from({ length: 4 }).map((_, index) => (
                <MediaCardSkeleton key={index} />
              ))}
            </div>
          </div>
        )}

        {!loading && scheduleMode === "personal" && entries.length === 0 && !error && (
          <div class="flex flex-1 flex-col items-center justify-center gap-3 text-center">
            <p class="text-4xl">📅</p>
            <p class="text-sm text-[#b5b0a5]">
              No upcoming episodes found.
              <br />
              Make sure you have anime set to <em>Watching</em>, then press <strong>Refresh</strong>.
            </p>
          </div>
        )}

        {!globalLoading && scheduleMode === "global" && filteredGlobalEntries.length === 0 && !error && (
          <div class="flex flex-1 flex-col items-center justify-center gap-3 text-center">
            <p class="text-4xl">🌍</p>
            <p class="text-sm text-[#b5b0a5]">
              Nothing matched the current popularity filter for {selectedWeekdayLabel}.
              <br />
              Lower the threshold to include more upcoming shows.
            </p>
          </div>
        )}

        {!loading && scheduleMode === "personal" && entries.length > 0 && (
          viewMode === "list" ? (
            <div class="flex flex-col gap-5">
              {thisWeek.length === 0 && <p class="text-sm text-[#b5b0a5]">No episodes airing in the next 7 days.</p>}
              {Array.from(weekGroups.entries()).map(([day, dayEntries]) => (
                <section key={day}>
                  <h2 class="mb-2 text-[0.74rem] font-bold uppercase tracking-[0.12em] text-[#7ca4be]">{day}</h2>
                  <div class="rounded-[1.1rem] border border-white/7 bg-white/3 px-3">
                    {dayEntries.map((entry) => (
                      <EntryRow
                        key={`${entry.mediaId}-${entry.episode}`}
                        entry={entry}
                        muted={mutedMediaIds.includes(entry.mediaId)}
                        onToggleMute={handleToggleMute}
                        onProgressChange={handleProgressChange}
                      />
                    ))}
                  </div>
                </section>
              ))}

              {later.length > 0 && (
                <section>
                  <button
                    type="button"
                    onClick={() => setShowLater((value) => !value)}
                    class="flex w-full items-center gap-2 rounded-[1.1rem] border border-white/7 bg-white/3 px-4 py-3 text-left transition hover:bg-white/5"
                  >
                    <span class={`text-[0.7rem] transition-transform ${showLater ? "rotate-90" : ""}`}>▶</span>
                    <span class="text-xs font-semibold text-[#b5b0a5]">
                      Later — {later.length} episode{later.length !== 1 ? "s" : ""} further ahead
                    </span>
                  </button>
                  {showLater && (
                    <div class="mt-3 flex flex-col gap-4">
                      {Array.from(laterGroups.entries()).map(([day, dayEntries]) => (
                        <section key={day}>
                          <h2 class="mb-2 text-[0.74rem] font-bold uppercase tracking-[0.12em] text-[#7ca4be]">{day}</h2>
                          <div class="rounded-[1.1rem] border border-white/7 bg-white/3 px-3">
                            {dayEntries.map((entry) => (
                              <EntryRow
                                key={`${entry.mediaId}-${entry.episode}`}
                                entry={entry}
                                muted={mutedMediaIds.includes(entry.mediaId)}
                                onToggleMute={handleToggleMute}
                                onProgressChange={handleProgressChange}
                              />
                            ))}
                          </div>
                        </section>
                      ))}
                    </div>
                  )}
                </section>
              )}
            </div>
          ) : (
            <div class="flex flex-col gap-5">
              {thisWeek.length === 0 && <p class="text-sm text-[#b5b0a5]">No episodes airing in the next 7 days.</p>}
              {Array.from(weekGroups.entries()).map(([day, dayEntries]) => (
                <section key={day}>
                  <h2 class="mb-3 text-[0.74rem] font-bold uppercase tracking-[0.12em] text-[#7ca4be]">{day}</h2>
                  <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
                    {dayEntries.map((entry) => (
                      <EntryCard
                        key={`${entry.mediaId}-${entry.episode}`}
                        entry={entry}
                        muted={mutedMediaIds.includes(entry.mediaId)}
                        onToggleMute={handleToggleMute}
                        onProgressChange={handleProgressChange}
                      />
                    ))}
                  </div>
                </section>
              ))}

              {later.length > 0 && (
                <section>
                  <button
                    type="button"
                    onClick={() => setShowLater((value) => !value)}
                    class="flex w-full items-center gap-2 rounded-[1.1rem] border border-white/7 bg-white/3 px-4 py-3 text-left transition hover:bg-white/5"
                  >
                    <span class={`text-[0.7rem] transition-transform ${showLater ? "rotate-90" : ""}`}>▶</span>
                    <span class="text-xs font-semibold text-[#b5b0a5]">
                      Later — {later.length} episode{later.length !== 1 ? "s" : ""} further ahead
                    </span>
                  </button>
                  {showLater && (
                    <div class="mt-3 flex flex-col gap-4">
                      {Array.from(laterGroups.entries()).map(([day, dayEntries]) => (
                        <section key={day}>
                          <h2 class="mb-3 text-[0.74rem] font-bold uppercase tracking-[0.12em] text-[#7ca4be]">{day}</h2>
                          <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
                            {dayEntries.map((entry) => (
                              <EntryCard
                                key={`${entry.mediaId}-${entry.episode}`}
                                entry={entry}
                                muted={mutedMediaIds.includes(entry.mediaId)}
                                onToggleMute={handleToggleMute}
                                onProgressChange={handleProgressChange}
                              />
                            ))}
                          </div>
                        </section>
                      ))}
                    </div>
                  )}
                </section>
              )}
            </div>
          )
        )}

        {!globalLoading && scheduleMode === "global" && filteredGlobalEntries.length > 0 && (
          viewMode === "list" ? (
            <section>
              <div class="rounded-[1.1rem] border border-white/7 bg-white/3 px-3">
                {filteredGlobalEntries.map((entry) => (
                  <GlobalEntryRow
                    key={`${entry.mediaId}-${entry.episode}`}
                    entry={entry}
                    inLibrary={libraryMediaIds.includes(entry.mediaId)}
                    adding={addingMediaIds.includes(entry.mediaId)}
                    onAdd={handleAddToPlanning}
                    onOpen={setOpenMediaId}
                  />
                ))}
              </div>
            </section>
          ) : (
            <section>
              <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
                {filteredGlobalEntries.map((entry) => (
                  <GlobalEntryCard
                    key={`${entry.mediaId}-${entry.episode}`}
                    entry={entry}
                    inLibrary={libraryMediaIds.includes(entry.mediaId)}
                    adding={addingMediaIds.includes(entry.mediaId)}
                    onAdd={handleAddToPlanning}
                    onOpen={setOpenMediaId}
                  />
                ))}
              </div>
            </section>
          )
        )}
      </div>

      {openMediaId != null && (
        <MediaDetailsPanel
          mediaId={openMediaId}
          onClose={() => setOpenMediaId(null)}
          onAdded={() => {
            void loadLibraryMediaIds();
            void load();
          }}
        />
      )}
    </>
  );
}