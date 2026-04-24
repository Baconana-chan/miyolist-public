import { useCallback, useEffect, useRef, useState } from "preact/hooks";
import {
  clearAiringCache,
  clearImageCache,
  clearOrphanMediaCache,
  clearSearchHistory,
  exportDatabaseBackup,
  exportLibraryJson,
  getAppSettings,
  getCacheStats,
  importLibraryJson,
  getNotificationSettings,
  saveNotificationSettings,
  prefetchCovers,
  saveAppSettings,
} from "../../shared/api/database";
import type { AppSettings, CacheStats, ExportResult, ImportResult, NotificationSettings } from "../../shared/types/app";
import { DropdownSelect } from "../../shared/components/DropdownSelect";
import { AboutDialog } from "./AboutDialog";

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

  const notice = (text: string, kind: "ok" | "err" = "ok") => {
    setMessage({ text, kind });
    setTimeout(() => setMessage(null), 4000);
  };

  const load = useCallback(async () => {
    try {
      const [s, c] = await Promise.all([getAppSettings(), getCacheStats()]);
      setSettings(s);
      setCacheStats(c);
      const ns = await getNotificationSettings();
      setNotificationSettings(ns);
    } catch (e) {
      notice(String(e), "err");
    }
  }, []);

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

  useEffect(() => {
    load();
  }, []);

  const patch = async (partial: Partial<AppSettings>) => {
    if (!settings) return;
    const next = { ...settings, ...partial };
    setSettings(next);
    try {
      await saveAppSettings(next);
    } catch (e) {
      notice(String(e), "err");
    }
  };

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
