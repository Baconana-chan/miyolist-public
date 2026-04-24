import { useCallback, useEffect, useMemo, useState } from "preact/hooks";
import { openUrl } from "@tauri-apps/plugin-opener";
import {
  getAniListNotifications,
  getNotificationSettings,
  incrementEpisodeProgress,
} from "../../shared/api/database";
import type { AniListNotificationItem, NotificationSettings } from "../../shared/types/app";

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const NOTIFICATION_SETTINGS_TTL_MS = 10 * 60 * 1000;
let NOTIFICATION_SETTINGS_CACHE: Cached<NotificationSettings> | null = null;

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

const TABS = [
  { id: "ALL", label: "All" },
  { id: "AIRING", label: "Airing" },
  { id: "ACTIVITY", label: "Activity" },
  { id: "FORUM", label: "Forum" },
  { id: "FOLLOWS", label: "Follows" },
  { id: "MEDIA", label: "Media" },
  { id: "SUBMISSIONS", label: "Submissions" },
] as const;

type TabId = (typeof TABS)[number]["id"];

function fmtWhen(unixTs: number): string {
  if (!unixTs) return "just now";
  const dt = new Date(unixTs * 1000);
  return dt.toLocaleString();
}

function categoryEnabled(settings: NotificationSettings | null, tab: TabId): boolean {
  if (!settings || tab === "ALL") return true;
  if (tab === "AIRING") return settings.airingEnabled;
  if (tab === "ACTIVITY") return settings.activityEnabled;
  if (tab === "FORUM") return settings.forumEnabled;
  if (tab === "FOLLOWS") return settings.followsEnabled;
  if (tab === "MEDIA") return settings.mediaEnabled;
  if (tab === "SUBMISSIONS") return settings.submissionsEnabled;
  return true;
}

export function NotificationsSurface() {
  const [settings, setSettings] = useState<NotificationSettings | null>(null);
  const [tab, setTab] = useState<TabId>("ALL");
  const [query, setQuery] = useState("");
  const [items, setItems] = useState<AniListNotificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyIds, setBusyIds] = useState<number[]>([]);

  const load = useCallback(async (nextTab: TabId, forceSettingsRefresh = false) => {
    setLoading(true);
    setError(null);
    try {
      const notificationsPromise = getAniListNotifications(nextTab === "ALL" ? null : nextTab, 1, 50, false);
      const settingsPromise =
        !forceSettingsRefresh && NOTIFICATION_SETTINGS_CACHE && isFresh(NOTIFICATION_SETTINGS_CACHE.fetchedAt, NOTIFICATION_SETTINGS_TTL_MS)
          ? Promise.resolve(NOTIFICATION_SETTINGS_CACHE.data)
          : getNotificationSettings().then((value) => {
              NOTIFICATION_SETTINGS_CACHE = { data: value, fetchedAt: Date.now() };
              return value;
            });

      const [ns, notifications] = await Promise.all([settingsPromise, notificationsPromise]);
      setSettings(ns);
      setItems(notifications);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load(tab);
  }, [load, tab]);

  const filtered = useMemo(() => {
    if (!settings) return items;
    const q = query.trim().toLowerCase();
    return items.filter((item) => {
      const t = item.notificationType;
      const categoryAllowed =
        t === "AIRING"
          ? settings.airingEnabled
          : t.startsWith("ACTIVITY_")
            ? settings.activityEnabled
            : t.startsWith("THREAD_")
              ? settings.forumEnabled
              : t === "FOLLOWING"
                ? settings.followsEnabled
                : t.startsWith("MEDIA_") || t.startsWith("RELATED_MEDIA_")
                  ? settings.mediaEnabled
                  : settings.submissionsEnabled;
      if (!categoryAllowed) return false;
      if (!q) return true;

      const haystack = [
        item.notificationType,
        item.title,
        item.body,
        item.userName,
      ]
        .filter(Boolean)
        .join("\n")
        .toLowerCase();
      return haystack.includes(q);
    });
  }, [items, settings, query]);

  async function handleOpen(link: string | null) {
    if (!link) return;
    try {
      await openUrl(link);
    } catch {
      // ignore open errors
    }
  }

  async function handleMarkWatched(item: AniListNotificationItem) {
    if (item.mediaId == null) return;
    setBusyIds((prev) => [...prev, item.id]);
    try {
      await incrementEpisodeProgress(item.mediaId, 1);
    } catch {
      // ignore action errors; list remains visible
    } finally {
      setBusyIds((prev) => prev.filter((id) => id !== item.id));
    }
  }

  const activeCategoryEnabled = categoryEnabled(settings, tab);

  return (
    <div class="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4 md:p-6">
      <div class="flex flex-wrap items-center gap-3">
        <div class="flex-1">
          <p class="mb-0.5 text-[0.74rem] font-bold uppercase tracking-[0.16em] text-[#7ca4be]">Notifications</p>
          <h1 class="m-0 text-2xl font-bold leading-tight tracking-tight text-[#f1efe7]">AniList inbox</h1>
          <p class="mt-1 text-xs text-[#b5b0a5]">
            Airing, Activity, Forum, Follows, Media, and Submissions notifications.
            Types without dedicated in-app UI open as direct AniList links.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load(tab, true)}
          class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-4 py-2 text-xs font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)]"
        >
          Refresh
        </button>
      </div>

      <div class="flex flex-wrap items-center gap-2 rounded-[1.1rem] border border-white/7 bg-white/3 p-2">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            class={`rounded-full px-3 py-1.5 text-xs font-semibold transition ${
              tab === t.id
                ? "bg-[rgba(217,116,82,0.28)] text-[#f1efe7]"
                : "text-[#b5b0a5] hover:text-[#f1efe7]"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div class="rounded-[1.1rem] border border-white/7 bg-white/3 p-3">
        <label class="mb-1 block text-[0.72rem] font-semibold uppercase tracking-[0.12em] text-[#7ca4be]">
          Search in notifications
        </label>
        <input
          type="text"
          value={query}
          onInput={(e) => setQuery((e.target as HTMLInputElement).value)}
          placeholder="Search by title, content, type, or user..."
          class="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-[#f1efe7] placeholder-[#7a746e] outline-none transition focus:border-[rgba(217,116,82,0.45)]"
        />
      </div>

      {!activeCategoryEnabled && (
        <div class="rounded-xl border border-[rgba(210,150,80,0.28)] bg-[rgba(210,150,80,0.1)] px-4 py-3 text-sm text-[#d4b86a]">
          This category is disabled in Settings → Notifications.
        </div>
      )}

      {error && (
        <div class="rounded-xl border border-[rgba(210,80,80,0.28)] bg-[rgba(210,80,80,0.1)] px-4 py-3 text-sm text-[#e08a8a]">
          {error}
        </div>
      )}

      {loading ? (
        <div class="flex flex-col gap-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} class="h-20 animate-pulse rounded-[1.1rem] border border-white/7 bg-white/3" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div class="flex flex-1 items-center justify-center rounded-[1.1rem] border border-white/7 bg-white/3 p-8 text-center text-sm text-[#b5b0a5]">
          {query.trim() ? "No notifications match your search." : "No notifications in this category."}
        </div>
      ) : (
        <div class="flex flex-col gap-3">
          {filtered.map((item) => {
            const isAiring = item.notificationType === "AIRING";
            const busy = busyIds.includes(item.id);
            return (
              <article key={item.id} class="rounded-[1.1rem] border border-white/7 bg-white/3 p-3">
                <div class="flex gap-3">
                  {item.coverImage ? (
                    <img src={item.coverImage} alt="" class="h-15 w-11 rounded object-cover" loading="lazy" />
                  ) : item.userAvatar ? (
                    <img src={item.userAvatar} alt="" class="h-11 w-11 rounded-full object-cover" loading="lazy" />
                  ) : (
                    <div class="flex h-11 w-11 items-center justify-center rounded bg-white/5 text-xs text-[#7ca4be]">
                      {item.notificationType.slice(0, 2)}
                    </div>
                  )}

                  <div class="min-w-0 flex-1">
                    <div class="flex flex-wrap items-center gap-2">
                      <span class="rounded-full border border-[rgba(124,164,190,0.28)] bg-[rgba(124,164,190,0.12)] px-2.5 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.12em] text-[#a9d2eb]">
                        {item.notificationType.replace(/_/g, " ")}
                      </span>
                      <span class="text-xs text-[#7a746e]">{fmtWhen(item.createdAt)}</span>
                    </div>
                    <p class="mt-1 text-sm font-semibold text-[#f1efe7]">{item.title}</p>
                    <p class="mt-1 text-xs text-[#b5b0a5] leading-relaxed">{item.body}</p>
                  </div>
                </div>

                <div class="mt-3 flex flex-wrap items-center gap-2">
                  {item.link && (
                    <button
                      type="button"
                      onClick={() => void handleOpen(item.link)}
                      class="rounded-full border border-white/15 bg-white/4 px-3 py-1.5 text-xs font-semibold text-[#d2cdc2] transition hover:text-[#f1efe7]"
                    >
                      Open in AniList
                    </button>
                  )}
                  {isAiring && item.mediaId != null && (
                    <button
                      type="button"
                      onClick={() => void handleMarkWatched(item)}
                      disabled={busy}
                      class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-3 py-1.5 text-xs font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)] disabled:opacity-50"
                    >
                      {busy ? "Marking…" : "Mark watched"}
                    </button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      )}
    </div>
  );
}
