import { useCallback, useEffect, useMemo, useRef, useState } from "preact/hooks";
import {
  checkMangaReleases,
  clearAiringCache,
  clearImageCache,
  clearMangaReleaseMapping,
  clearOrphanMediaCache,
  clearSearchHistory,
  exportDatabaseBackup,
  exportLibraryJson,
  getAppSettings,
  getCacheStats,
  getMangaReleaseMappings,
  importLibraryJson,
  getNotificationSettings,
  saveNotificationSettings,
  prefetchCovers,
  saveAppSettings,
  searchMangaupdatesSeries,
  setAlwaysOnTop,
  setDiscordRpc,
  setMangaReleaseMapping,
} from "../../shared/api/database";
import type {
  AppSettings,
  CacheStats,
  ExportResult,
  ImportResult,
  MangaReleaseMapping,
  MangaUpdatesSeries,
  NotificationSettings,
} from "../../shared/types/app";
import { DropdownSelect } from "../../shared/components/DropdownSelect";
import { AboutDialog } from "./AboutDialog";
import {
  comboFromEvent,
  formatCombo,
  mergeShortcuts,
  SHORTCUT_ACTIONS,
  SHORTCUT_CATEGORIES,
  stripDefaults,
} from "../../shared/shortcuts";

// ─── helpers ─────────────────────────────────────────────────────────────────

function fmtBytes(n: number) {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / 1024 / 1024).toFixed(1)} MB`;
}

const SCORE_FORMAT_OPTIONS = [
  { value: "POINT_100", label: "100-point (0-100)" },
  { value: "POINT_10_DECIMAL", label: "10-point decimal (0.0-10.0)" },
  { value: "POINT_10", label: "10-point integer (0-10)" },
  { value: "POINT_5", label: "5-star" },
  { value: "POINT_3", label: "3-point" },
  { value: "SMILEY", label: "Smiley / mood" },
] as const;

// ─── sub-components ───────────────────────────────────────────────────────────

function SectionBlock({
  title,
  children,
}: {
  title: string;
  children: preact.ComponentChildren;
}) {
  return (
    <section class="flex flex-col gap-4 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-5 py-4">
      <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">{title}</h2>
      {children}
    </section>
  );
}

function Toggle({
  label,
  description,
  checked,
  onChange,
}: {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label class="flex items-center justify-between gap-4 cursor-pointer group">
      <div class="flex-1">
        <span class="text-sm text-[#e8e3dc]">{label}</span>
        {description && (
          <p class="text-xs text-[#7a746e] mt-0.5">{description}</p>
        )}
      </div>
      <button
        role="switch"
        aria-checked={checked}
        class={`relative w-10 h-6 rounded-full transition-colors shrink-0 ${
          checked ? "bg-[#d97452]" : "bg-[#3a3836]"
        }`}
        onClick={() => onChange(!checked)}
      >
        <span
          class={`absolute left-0 top-1 w-4 h-4 rounded-full bg-white shadow transition-transform ${
            checked ? "translate-x-[18px]" : "translate-x-[2px]"
          }`}
        />
      </button>
    </label>
  );
}

function SelectField({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: { value: string; label: string }[];
  onChange: (v: string) => void;
}) {
  return (
    <div class="flex items-center justify-between gap-4">
      <span class="text-sm text-[#e8e3dc]">{label}</span>
      <DropdownSelect
        align="right"
        options={options}
        value={value}
        onChange={onChange}
        buttonClass="bg-[#2e2c2a] border border-[#3a3836] text-[#e8e3dc] text-sm rounded-lg px-3 py-1.5"
        menuClass="min-w-44 overflow-hidden rounded-xl border border-[#3a3836] bg-[#242220] shadow-[-2px_8px_28px_rgba(0,0,0,0.45)]"
        optionClass="w-full px-3 py-2 text-left text-[0.82rem] text-[#bfb9ae] transition hover:bg-white/6 hover:text-[#f1efe7]"
        selectedOptionClass="bg-[rgba(217,116,82,0.2)] text-[#f1efe7]"
      />
    </div>
  );
}

function ActionButton({
  label,
  sub,
  onClick,
  variant = "default",
  disabled,
}: {
  label: string;
  sub?: string;
  onClick: () => void;
  variant?: "default" | "danger" | "accent";
  disabled?: boolean;
}) {
  const color =
    variant === "danger"
      ? "border-[#ef4444]/40 text-[#ef4444] hover:bg-[#ef4444]/10"
      : variant === "accent"
      ? "border-[#d97452]/40 text-[#d97452] hover:bg-[#d97452]/10"
      : "border-[#3a3836] text-[#b5b0a5] hover:border-[#d97452] hover:text-[#d97452]";

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      class={`flex flex-col items-start px-4 py-3 rounded-xl border transition-colors text-left disabled:opacity-40 disabled:cursor-not-allowed ${color}`}
    >
      <span class="text-sm font-medium">{label}</span>
      {sub && <span class="text-xs text-[#7a746e] mt-0.5">{sub}</span>}
    </button>
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

export function SettingsSurface() {
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [notificationSettings, setNotificationSettings] = useState<NotificationSettings | null>(null);
  const [cacheStats, setCacheStats] = useState<CacheStats | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ text: string; kind: "ok" | "err" } | null>(null);
  const [importPath, setImportPath] = useState("");
  const [showAbout, setShowAbout] = useState(false);
  const importRef = useRef<HTMLInputElement>(null);

  // ── Manga release tracking ──────────────────────────────────────────────
  const [mangaMappings, setMangaMappings] = useState<MangaReleaseMapping[] | null>(null);
  const [mangaBusy, setMangaBusy] = useState(false);
  // Media id currently being re-linked (inline MangaUpdates search).
  const [replacingFor, setReplacingFor] = useState<number | null>(null);
  const [muQuery, setMuQuery] = useState("");
  const [muResults, setMuResults] = useState<MangaUpdatesSeries[] | null>(null);
  const [muSearching, setMuSearching] = useState(false);

  const notice = (text: string, kind: "ok" | "err" = "ok") => {
    setMessage({ text, kind });
    setTimeout(() => setMessage(null), 4000);
  };

  const loadMangaMappings = useCallback(async () => {
    try {
      const mappings = await getMangaReleaseMappings();
      setMangaMappings(mappings);
    } catch (e) {
      notice(String(e), "err");
    }
  }, []);

  const load = useCallback(async () => {
    try {
      const [s, c] = await Promise.all([getAppSettings(), getCacheStats()]);
      setSettings(s);
      setCacheStats(c);
      const ns = await getNotificationSettings();
      setNotificationSettings(ns);
      loadMangaMappings();
    } catch (e) {
      notice(String(e), "err");
    }
  }, [loadMangaMappings]);

  const patchNotifications = async (partial: Partial<NotificationSettings>) => {
    if (!notificationSettings) return;
    const next = { ...notificationSettings, ...partial };
    setNotificationSettings(next);
    try {
      await saveNotificationSettings(next);
    } catch (e) {
      notice(String(e), "err");
    }
  };

  // ── Manga release tracking handlers ─────────────────────────────────────
  const checkMangaNow = async () => {
    if (mangaBusy) return;
    setMangaBusy(true);
    try {
      const sent = await checkMangaReleases();
      notice(sent > 0 ? `Checked — ${sent} new chapter notification(s)` : "Checked — no new chapters");
      await loadMangaMappings();
    } catch (e) {
      notice(String(e), "err");
    } finally {
      setMangaBusy(false);
    }
  };

  const beginReplace = (mapping: MangaReleaseMapping) => {
    setReplacingFor(mapping.mediaId);
    setMuQuery(mapping.title);
    setMuResults(null);
  };

  const runMuSearch = async () => {
    if (!muQuery.trim() || muSearching) return;
    setMuSearching(true);
    try {
      const results = await searchMangaupdatesSeries(muQuery.trim());
      setMuResults(results);
    } catch (e) {
      notice(String(e), "err");
    } finally {
      setMuSearching(false);
    }
  };

  const applyMapping = async (mediaId: number, series: MangaUpdatesSeries) => {
    try {
      await setMangaReleaseMapping(mediaId, series.seriesId, series.title);
      notice(`Linked to "${series.title}"`);
      setReplacingFor(null);
      setMuResults(null);
      await loadMangaMappings();
    } catch (e) {
      notice(String(e), "err");
    }
  };

  const removeMapping = async (mediaId: number) => {
    try {
      await clearMangaReleaseMapping(mediaId);
      notice("Tracking removed");
      await loadMangaMappings();
    } catch (e) {
      notice(String(e), "err");
    }
  };

  useEffect(() => {
    load();
  }, []);

  // Memoized so the shortcut recorder effect below doesn't re-subscribe on
  // every SettingsSurface re-render while a combo is being recorded.
  const patch = useCallback(
    async (partial: Partial<AppSettings>) => {
      if (!settings) return;
      const next = { ...settings, ...partial };
      setSettings(next);
      try {
        await saveAppSettings(next);
      } catch (e) {
        notice(String(e), "err");
      }
    },
    [settings],
  );

  // ── Keyboard shortcut rebinding ─────────────────────────────────────────
  const [recordingAction, setRecordingAction] = useState<string | null>(null);
  const shortcuts = useMemo(
    () => mergeShortcuts(settings?.keyboardShortcuts),
    [settings?.keyboardShortcuts],
  );

  useEffect(() => {
    if (!recordingAction) return;
    const onKeyDown = (event: KeyboardEvent) => {
      event.preventDefault();
      event.stopImmediatePropagation();
      if (event.key === "Escape") {
        setRecordingAction(null);
        return;
      }
      const combo = comboFromEvent(event);
      if (!combo) return; // bare modifier press — keep recording

      // Reject combos already bound to a different action.
      const conflict = Object.entries(shortcuts).find(
        ([action, existing]) => action !== recordingAction && existing === combo,
      );
      if (conflict) {
        const label =
          SHORTCUT_ACTIONS.find((a) => a.action === conflict[0])?.label ?? conflict[0];
        notice(`"${formatCombo(combo)}" is already used by "${label}".`, "err");
        setRecordingAction(null);
        return;
      }

      const next = { ...shortcuts, [recordingAction]: combo };
      patch({ keyboardShortcuts: JSON.stringify(stripDefaults(next)) });
      setRecordingAction(null);
    };
    window.addEventListener("keydown", onKeyDown, true);
    return () => window.removeEventListener("keydown", onKeyDown, true);
  }, [recordingAction, shortcuts, patch]);

  const run = async (fn: () => Promise<unknown>, successMsg: string) => {
    setBusy(true);
    try {
      const result = await fn();
      if (result && typeof result === "object" && "path" in (result as object)) {
        const r = result as ExportResult;
        notice(`${successMsg} → ${r.path}`);
      } else if (result && typeof result === "object" && "importedCount" in (result as object)) {
        const r = result as ImportResult;
        notice(
          `Imported ${r.importedCount} entries, skipped ${r.skippedCount}${r.errors.length ? ` (${r.errors.length} errors)` : ""}`,
          r.errors.length > 0 ? "err" : "ok",
        );
      } else {
        notice(successMsg);
      }
      await getCacheStats().then(setCacheStats);
    } catch (e) {
      notice(String(e), "err");
    } finally {
      setBusy(false);
    }
  };

  if (!settings) {
    return (
      <div class="flex items-center justify-center h-48 text-[#7a746e] text-sm">
        Loading settings…
      </div>
    );
  }

  return (
    <div class="flex flex-col gap-5 p-4 max-w-2xl mx-auto">
      {/* header */}
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-bold text-[#e8e3dc]">Settings</h1>
        {message && (
          <span
            class={`text-xs px-3 py-1.5 rounded-full ${
              message.kind === "ok"
                ? "bg-[#22c55e]/15 text-[#22c55e]"
                : "bg-[#ef4444]/15 text-[#ef4444]"
            }`}
          >
            {message.text}
          </span>
        )}
      </div>

      {/* Data & privacy notice */}
      <div class="flex gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-5 py-4">
        <span class="text-lg shrink-0 mt-0.5">🔒</span>
        <div class="flex flex-col gap-1">
          <p class="text-sm font-semibold text-[#e8e3dc]">Your data stays on this device</p>
          <p class="text-xs text-[#7a746e] leading-relaxed">
            MiyoList stores everything — your library, progress, and settings — in a local SQLite
            database. Nothing is uploaded automatically. AniList sync is always an explicit
            user-triggered action. There is no app-owned cloud backend.
          </p>
        </div>
      </div>

      {/* Content */}
      <SectionBlock title="Content">
        <Toggle
          label="Show adult content"
          description="Unlocks 18+ titles in search results and browse. Does not affect your existing library."
          checked={settings.showAdultContent}
          onChange={(v) => patch({ showAdultContent: v })}
        />
      </SectionBlock>

      {/* Desktop behavior */}
      <SectionBlock title="Desktop behavior">
        <Toggle
          label="Close button minimizes to tray"
          description="When enabled, pressing X keeps MiyoList running in the system tray instead of exiting."
          checked={settings.minimizeToTrayOnClose}
          onChange={(v) => patch({ minimizeToTrayOnClose: v })}
        />
        <Toggle
          label="Keep window on top"
          description="Pins the MiyoList window above other windows while you browse."
          checked={settings.alwaysOnTop}
          onChange={(v) => {
            // The command floats the window AND persists the flag, so no
            // separate patch is needed — just mirror the value into local
            // state for an instant toggle.
            setSettings((prev) => (prev ? { ...prev, alwaysOnTop: v } : prev));
            setAlwaysOnTop(v).catch((e) => notice(String(e), "err"));
          }}
        />
      </SectionBlock>

      {/* Discord Rich Presence */}
      <SectionBlock title="Discord Rich Presence">
        <Toggle
          label="Show activity on Discord"
          description="Displays what you're watching or reading as your Discord status. Requires a Discord Application ID set in the build (MIYOLIST_DISCORD_APP_ID)."
          checked={settings.discordRpcEnabled}
          onChange={(v) => {
            // The command connects/disconnects the RPC client AND persists the
            // flag, so just mirror the value into local state for an instant toggle.
            setSettings((prev) => (prev ? { ...prev, discordRpcEnabled: v } : prev));
            setDiscordRpc(v).catch((e) => notice(String(e), "err"));
          }}
        />
      </SectionBlock>

      {/* Keyboard shortcuts */}
      <SectionBlock title="Keyboard shortcuts">
        <p class="text-xs text-[#7a746e] leading-relaxed">
          Click a shortcut and press the new key combination to rebind it. Press
          Esc while recording to cancel.
        </p>
        {SHORTCUT_CATEGORIES.map((category) => (
          <div key={category} class="flex flex-col gap-2">
            <p class="text-[10px] uppercase tracking-wider text-[#7a746e]">{category}</p>
            {SHORTCUT_ACTIONS.filter((a) => a.category === category).map((def) => {
              const combo = shortcuts[def.action] ?? "";
              const recording = recordingAction === def.action;
              return (
                <div key={def.action} class="flex items-center justify-between gap-3">
                  <span class="text-sm text-[#e8e3dc]">{def.label}</span>
                  <button
                    onClick={() => setRecordingAction(recording ? null : def.action)}
                    title={`Rebind "${def.label}"`}
                    class={`min-w-32 rounded-lg border px-3 py-1.5 text-sm font-mono transition ${
                      recording
                        ? "animate-pulse border-[#d97452] bg-[#d97452]/15 text-[#f29a7c]"
                        : "border-[#3a3836] bg-[#252321] text-[#b5b0a5] hover:border-[#d97452] hover:text-[#f29a7c]"
                    }`}
                  >
                    {recording ? "Press keys…" : formatCombo(combo)}
                  </button>
                </div>
              );
            })}
          </div>
        ))}
        <button
          onClick={() => patch({ keyboardShortcuts: "{}" })}
          class="self-start rounded-lg border border-[#3a3836] px-4 py-2 text-sm text-[#b5b0a5] transition hover:border-[#d97452] hover:text-[#d97452]"
        >
          Reset to defaults
        </button>
      </SectionBlock>

      {/* Library defaults */}
      <SectionBlock title="Library defaults">
        <SelectField
          label="Default tab"
          value={settings.defaultListTab}
          options={[
            { value: "ANIME", label: "Anime" },
            { value: "MANGA", label: "Manga" },
            { value: "NOVEL", label: "Light novels" },
          ]}
          onChange={(v) => patch({ defaultListTab: v })}
        />
        <SelectField
          label="Default sort"
          value={settings.defaultSort}
          options={[
            { value: "updated_desc", label: "Last updated" },
            { value: "title_asc", label: "Title A→Z" },
            { value: "score_desc", label: "Score (high first)" },
            { value: "progress_desc", label: "Progress (high first)" },
          ]}
          onChange={(v) => patch({ defaultSort: v })}
        />
        <SelectField
          label="Default view"
          value={settings.libraryView}
          options={[
            { value: "list", label: "List" },
            { value: "compact", label: "Compact" },
            { value: "grid", label: "Grid" },
          ]}
          onChange={(v) => patch({ libraryView: v })}
        />
        <div class="flex flex-col gap-2 rounded-lg bg-[#252321] px-3 py-3">
          <SelectField
            label="Score format"
            value={settings.scoreFormat}
            options={[...SCORE_FORMAT_OPTIONS]}
            onChange={(v) => patch({ scoreFormat: v })}
          />
          <p class="text-xs text-[#7a746e] leading-relaxed">
            Controls how scores are shown in your library, edit modal, and statistics. On first login
            this is imported from AniList, but you can override it here at any time.
          </p>
        </div>
      </SectionBlock>

      {/* Library visibility */}
      <SectionBlock title="Library visibility">
        <p class="text-xs text-[#7a746e]">
          Choose which status categories are hidden by default. You can always reveal them with the
          filter panel inside the library.
        </p>
        {(
          [
            { status: "DROPPED", label: "Dropped" },
            { status: "PAUSED", label: "Paused" },
            { status: "PLANNING", label: "Planning" },
            { status: "REPEATING", label: "Repeating" },
          ] as { status: string; label: string }[]
        ).map(({ status, label }) => {
          const hidden = settings.hiddenStatuses
            .split(",")
            .filter(Boolean)
            .includes(status);
          return (
            <Toggle
              key={status}
              label={`Hide "${label}" by default`}
              checked={hidden}
              onChange={(v) => {
                const cur = settings.hiddenStatuses
                  .split(",")
                  .filter(Boolean);
                const next = v
                  ? [...cur.filter((s) => s !== status), status]
                  : cur.filter((s) => s !== status);
                patch({ hiddenStatuses: next.join(",") });
              }}
            />
          );
        })}
      </SectionBlock>

      {/* Cache */}
      <SectionBlock title="Cache">
        {cacheStats && (
          <div class="grid grid-cols-2 gap-2 sm:grid-cols-3 mb-1">
            {[
              { label: "Media metadata", value: String(cacheStats.mediaCacheCount) },
              { label: "Search history", value: String(cacheStats.searchHistoryCount) },
              { label: "Airing cache", value: String(cacheStats.airingCacheCount) },
              { label: "Activity log", value: String(cacheStats.activityLogCount) },
              {
                label: "Cover images",
                value: `${cacheStats.imageCacheCount} (${fmtBytes(cacheStats.imageCacheBytes)})`,
              },
            ].map((item) => (
              <div
                key={item.label}
                class="flex flex-col gap-0.5 rounded-lg bg-[#252321] px-3 py-2"
              >
                <span class="text-[10px] text-[#7a746e] uppercase tracking-wider">
                  {item.label}
                </span>
                <span class="text-sm font-medium text-[#e8e3dc]">{item.value}</span>
              </div>
            ))}
          </div>
        )}
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
          <ActionButton
            label="Pre-fetch covers"
            sub="Downloads all library covers for offline use"
            variant="accent"
            disabled={busy}
            onClick={() => run(prefetchCovers, "Cover pre-fetch started")}
          />
          <ActionButton
            label="Clear search history"
            disabled={busy}
            onClick={() => run(clearSearchHistory, "Search history cleared")}
          />
          <ActionButton
            label="Clear orphan metadata"
            sub="Media not in your library"
            disabled={busy}
            onClick={() => run(clearOrphanMediaCache, "Orphan cache cleared")}
          />
          <ActionButton
            label="Clear airing cache"
            sub="Will re-fetch on next schedule refresh"
            disabled={busy}
            onClick={() => run(clearAiringCache, "Airing cache cleared")}
          />
          <ActionButton
            label="Clear cover images"
            variant="danger"
            disabled={busy}
            onClick={() => run(clearImageCache, "Image cache cleared")}
          />
        </div>
      </SectionBlock>

      {/* Backup & export */}
      <SectionBlock title="Backup & export">
        <p class="text-xs text-[#7a746e]">
          Exports are written to your app data folder. Use the "Open exports folder" button after
          exporting to find your files.
        </p>
        <div class="grid grid-cols-2 gap-2">
          <ActionButton
            label="Export library as JSON"
            sub="Human-readable, can be re-imported"
            variant="accent"
            disabled={busy}
            onClick={() => run(exportLibraryJson, "Exported")}
          />
          <ActionButton
            label="Export SQLite backup"
            sub="Full database snapshot"
            variant="accent"
            disabled={busy}
            onClick={() => run(exportDatabaseBackup, "Backup saved")}
          />
        </div>
      </SectionBlock>

      {/* Import */}
      <SectionBlock title="Import">
        <p class="text-xs text-[#7a746e]">
          Import a JSON file previously exported from MiyoList. Existing entries are kept — only
          new ones are added. Paste the full file path below.
        </p>
        <div class="flex gap-2 items-stretch">
          <input
            ref={importRef}
            id="settings-import-path"
            name="settingsImportPath"
            type="text"
            placeholder="C:\Users\...\library_1234567890.json"
            value={importPath}
            onInput={(e) => setImportPath((e.target as HTMLInputElement).value)}
            class="flex-1 bg-[#2e2c2a] border border-[#3a3836] text-[#e8e3dc] text-sm rounded-lg px-3 py-2 focus:outline-none focus:border-[#d97452] placeholder:text-[#5a5650]"
          />
          <button
            onClick={() => {
              if (!importPath.trim()) {
                notice("Please enter a file path", "err");
                return;
              }
              run(() => importLibraryJson(importPath.trim()), "Import complete");
            }}
            disabled={busy || !importPath.trim()}
            class="px-4 py-2 rounded-lg bg-[#d97452] text-white text-sm font-medium disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#c8663f] transition-colors"
          >
            Import
          </button>
        </div>
      </SectionBlock>

      {/* AniList sync transparency */}
      <SectionBlock title="AniList sync">
        {settings.lastSyncedAt && (
          <div class="text-xs text-[#7a746e]">
            Last synced: <span class="text-[#b5b0a5]">{new Date(settings.lastSyncedAt).toLocaleString()}</span>
          </div>
        )}
        <SelectField
          label="Background auto-sync"
          value={String(settings.autoSyncInterval)}
          options={[
            { value: "0",  label: "Disabled" },
            { value: "5",  label: "Every 5 minutes" },
            { value: "15", label: "Every 15 minutes (default)" },
            { value: "30", label: "Every 30 minutes" },
            { value: "60", label: "Every hour" },
          ]}
          onChange={(v) => patch({ autoSyncInterval: Number(v) })}
        />
        <div class="flex flex-col gap-2 text-sm text-[#b5b0a5] leading-relaxed">
          <p>
            <span class="text-[#e8e3dc] font-medium">What is synced:</span> Your list entries
            (status, score, progress, notes) are synced to AniList when you press "Sync" or edit an
            entry. The sync is always opt-in.
          </p>
          <p>
            <span class="text-[#e8e3dc] font-medium">What is never sent:</span> App settings,
            activity log, search history, and cached images. These live only on this device.
          </p>
          <p>
            <span class="text-[#e8e3dc] font-medium">Delta sync:</span> After the first full sync,
            subsequent syncs only pull entries changed since the last run — no more transferring
            your entire list on every refresh.
          </p>
          <p>
            <span class="text-[#e8e3dc] font-medium">Offline mode:</span> The app is fully usable
            without an internet connection. Edits are flagged as pending and synced the next time
            you trigger a sync.
          </p>
        </div>
      </SectionBlock>

      {/* Notifications */}
      <SectionBlock title="Notifications">
        <p class="text-xs text-[#7a746e] leading-relaxed">
          These toggles control notification categories fetched from AniList and local airing alerts.
          Category UI is available in the Notifications screen.
        </p>
        <Toggle
          label="Airing"
          description="Episode aired alerts for anime in your schedule."
          checked={notificationSettings?.airingEnabled ?? true}
          onChange={(v) => patchNotifications({ airingEnabled: v })}
        />
        <Toggle
          label="Activity"
          description="Mentions, replies, likes, and other activity updates."
          checked={notificationSettings?.activityEnabled ?? true}
          onChange={(v) => patchNotifications({ activityEnabled: v })}
        />
        <Toggle
          label="Forum"
          description="Forum thread mentions, replies, and subscriptions."
          checked={notificationSettings?.forumEnabled ?? true}
          onChange={(v) => patchNotifications({ forumEnabled: v })}
        />
        <Toggle
          label="Follows"
          description="User follow notifications."
          checked={notificationSettings?.followsEnabled ?? true}
          onChange={(v) => patchNotifications({ followsEnabled: v })}
        />
        <Toggle
          label="Media"
          description="Media updates (related additions, merges, deletions)."
          checked={notificationSettings?.mediaEnabled ?? true}
          onChange={(v) => patchNotifications({ mediaEnabled: v })}
        />
        <Toggle
          label="Submissions"
          description="Submission-related updates grouped under media changes."
          checked={notificationSettings?.submissionsEnabled ?? true}
          onChange={(v) => patchNotifications({ submissionsEnabled: v })}
        />
        <Toggle
          label="Manga new chapters"
          description="Alerts for new chapters of your CURRENT/REPEATING manga, tracked via the MangaUpdates release indexer."
          checked={notificationSettings?.mangaReleasesEnabled ?? false}
          onChange={(v) => patchNotifications({ mangaReleasesEnabled: v })}
        />
      </SectionBlock>

      {/* Manga release tracking */}
      <SectionBlock title="Manga release tracking">
        <p class="text-xs text-[#7a746e] leading-relaxed">
          MiyoList links your manga to series on MangaUpdates (an independent release
          indexer) to learn when new chapters drop. Links are found automatically; if one
          is wrong, pick the right series manually below.
        </p>
        <button
          onClick={checkMangaNow}
          disabled={mangaBusy}
          class="self-start rounded-lg border border-[#3a3836] px-4 py-2 text-sm text-[#b5b0a5] transition hover:border-[#d97452] hover:text-[#d97452] disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {mangaBusy ? "Checking…" : "Check for new chapters now"}
        </button>

        {mangaMappings === null ? (
          <p class="text-xs text-[#7a746e]">Loading tracked titles…</p>
        ) : mangaMappings.length === 0 ? (
          <p class="text-xs text-[#7a746e]">
            Nothing tracked yet — links are created automatically the next time
            chapters are checked (manga with CURRENT / REPEATING status).
          </p>
        ) : (
          <div class="flex flex-col gap-2">
            {mangaMappings.map((mapping) => (
              <div
                key={mapping.mediaId}
                class="flex items-center justify-between gap-3 rounded-lg bg-[#252321] border border-[#3a3836] px-3 py-2"
              >
                <div class="min-w-0 flex-1">
                  <p class="truncate text-sm font-medium text-[#e8e3dc]">{mapping.title}</p>
                  <p class="truncate text-xs text-[#7a746e]">
                    {mapping.muTitle ? (
                      <>
                        ↳ {mapping.muTitle}{" "}
                        <span class={mapping.manual ? "text-[#d97452]" : "text-[#5e7a90]"}>
                          · {mapping.manual ? "manual" : "auto"}
                        </span>
                      </>
                    ) : (
                      "Not linked"
                    )}
                  </p>
                </div>
                <div class="flex shrink-0 gap-1.5">
                  <button
                    onClick={() => beginReplace(mapping)}
                    class="rounded-lg border border-[#3a3836] px-2.5 py-1 text-xs text-[#b5b0a5] transition hover:border-[#d97452] hover:text-[#d97452]"
                  >
                    {mapping.muTitle ? "Change" : "Link"}
                  </button>
                  {mapping.muTitle && (
                    <button
                      onClick={() => removeMapping(mapping.mediaId)}
                      class="rounded-lg border border-[#ef4444]/30 px-2.5 py-1 text-xs text-[#ef4444] transition hover:bg-[#ef4444]/10"
                    >
                      Remove
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {replacingFor !== null && (
          <div class="flex flex-col gap-2 rounded-lg bg-[#1f1d1b] border border-[#d97452]/30 p-3">
            <p class="text-xs text-[#b5b0a5]">
              Search MangaUpdates to replace the link for{" "}
              <span class="text-[#e8e3dc]">
                {mangaMappings?.find((m) => m.mediaId === replacingFor)?.title ?? "this title"}
              </span>:
            </p>
            <div class="flex gap-2">
              <input
                type="text"
                value={muQuery}
                onInput={(e) => setMuQuery((e.target as HTMLInputElement).value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") runMuSearch();
                  if (e.key === "Escape") setReplacingFor(null);
                }}
                placeholder="Search MangaUpdates…"
                class="flex-1 bg-[#2e2c2a] border border-[#3a3836] text-[#e8e3dc] text-sm rounded-lg px-3 py-1.5 focus:outline-none focus:border-[#d97452] placeholder:text-[#5a5650]"
              />
              <button
                onClick={runMuSearch}
                disabled={muSearching || !muQuery.trim()}
                class="px-3 py-1.5 rounded-lg bg-[#d97452] text-white text-sm font-medium disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#c8663f] transition-colors"
              >
                {muSearching ? "…" : "Search"}
              </button>
            </div>
            {muResults && (
              <div class="flex max-h-48 flex-col gap-1 overflow-y-auto pr-1">
                {muResults.length === 0 ? (
                  <p class="text-xs text-[#7a746e]">No matches found.</p>
                ) : (
                  muResults.map((series) => (
                    <button
                      key={series.seriesId}
                      onClick={() => applyMapping(replacingFor, series)}
                      class="flex items-center justify-between gap-2 rounded-lg px-2.5 py-1.5 text-left transition hover:bg-white/6"
                    >
                      <span class="min-w-0 truncate text-sm text-[#e8e3dc]">{series.title}</span>
                      <span class="shrink-0 text-xs text-[#7a746e]">
                        {series.seriesType ?? "?"}
                        {series.year ? ` · ${series.year}` : ""}
                      </span>
                    </button>
                  ))
                )}
              </div>
            )}
            <button
              onClick={() => setReplacingFor(null)}
              class="self-end text-xs text-[#7a746e] transition hover:text-[#b5b0a5]"
            >
              Cancel
            </button>
          </div>
        )}
      </SectionBlock>

      {/* About */}
      <SectionBlock title="About">
        <button
          onClick={() => setShowAbout(true)}
          class="w-full px-4 py-3 rounded-xl border border-[#3a3836] bg-[#252321] text-[#b5b0a5] text-sm font-medium transition hover:border-[#d97452] hover:text-[#d97452]"
        >
          View app info & links
        </button>
      </SectionBlock>

      {showAbout && <AboutDialog onClose={() => setShowAbout(false)} />}
    </div>
  );
}
