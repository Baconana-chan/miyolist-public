import { useState, useEffect, useRef, useCallback } from "preact/hooks";

import type { JSX } from "preact/jsx-runtime";
import { getAuthSessionStatus } from "../shared/api/auth";
import { checkForUpdates, checkMangaReleases, checkNotifications, getAppSettings, getSyncProgress, prefetchCovers, pushDirtyEntries, refreshAiringSchedule, syncUserLists } from "../shared/api/database";
import { useOnlineStatus } from "../shared/hooks/useOnlineStatus";
import type { AuthSessionStatus, ScreenId, SyncSummary, UpdateInfo } from "../shared/types/app";
import { UpdateDialog } from "../features/settings/UpdateDialog";
import { AuthSurface } from "../features/auth/AuthSurface";
import { LibrarySurface, invalidateLibraryCache } from "../features/library/LibrarySurface";
import { DiscoverySurface } from "../features/discovery/DiscoverySurface";
import { ActivitySurface } from "../features/activity/ActivitySurface";
import { NotificationsSurface } from "../features/notifications/NotificationsSurface";
import { SearchSurface } from "../features/search/SearchSurface";
import { ScheduleSurface } from "../features/schedule/ScheduleSurface";
import { StatisticsSurface } from "../features/statistics/StatisticsSurface";
import { SettingsSurface } from "../features/settings/SettingsSurface";
import { MediaDetailsPanel } from "../features/media/MediaDetailsPanel";
import { CharacterPanel } from "../features/people/CharacterPanel";
import { StaffPanel } from "../features/people/StaffPanel";
import { StudioPanel } from "../features/people/StudioPanel";
import { UserPanel } from "../features/people/UserPanel";
import { SideSheetProvider, useSideSheet } from "./sideSheet";

// ─── Icons ────────────────────────────────────────────────────────────────────

function IconBook() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </svg>
  );
}

function IconSearch() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="11" cy="11" r="8" />
      <line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  );
}

function IconCompass() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="10" />
      <polygon points="16 8 14 14 8 16 10 10 16 8" />
    </svg>
  );
}

function IconCalendar() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}

function IconBell() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function IconActivity() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
    </svg>
  );
}

function IconChart() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  );
}

function IconGear() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}

// ─── Nav config ───────────────────────────────────────────────────────────────

type NavItem = {
  id: ScreenId;
  label: string;
  Icon: () => JSX.Element;
};

const MOBILE_BREAKPOINT_PX = 900;

const NAV: NavItem[] = [
  { id: "library",    label: "Library",  Icon: IconBook     },
  { id: "discovery",  label: "Discover", Icon: IconCompass  },
  { id: "activity", label: "Activity", Icon: IconActivity },
  { id: "notifications", label: "Inbox", Icon: IconBell },
  { id: "search",     label: "Search",   Icon: IconSearch   },
  { id: "schedule",   label: "Airing",   Icon: IconCalendar },
  { id: "statistics", label: "Stats",    Icon: IconChart    },
  { id: "settings",   label: "Settings", Icon: IconGear     },
];

const MOBILE_NAV_ORDER: ScreenId[] = [
  "library",
  "discovery",
  "search",
  "schedule",
  "activity",
  "notifications",
  "statistics",
  "settings",
];

function useMobileShell() {
  const [mobile, setMobile] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const query = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT_PX}px)`);
    const apply = () => setMobile(query.matches);
    apply();

    query.addEventListener("change", apply);
    return () => query.removeEventListener("change", apply);
  }, []);

  return mobile;
}

function SideSheetHost() {
  const sideSheet = useSideSheet();
  const panelRefs = useRef<Array<HTMLDivElement | null>>([]);

  useEffect(() => {
    const node = panelRefs.current[sideSheet.activeIndex];
    node?.focus();
  }, [sideSheet.activeIndex, sideSheet.stack.length]);

  if (!sideSheet.isMultiPanel || sideSheet.stack.length === 0) {
    return null;
  }

  return (
    <section class="pointer-events-none absolute inset-0 z-40 flex justify-end">
      <button
        class="pointer-events-auto absolute inset-0 bg-black/45 backdrop-blur-sm"
        aria-label="Close right panel"
        onClick={() => {
          sideSheet.closeRightmost();
        }}
      />
      <div class="pointer-events-auto relative flex h-full max-w-full items-stretch overflow-visible pl-3">
        <div class="flex h-full flex-row-reverse items-stretch gap-3 overflow-x-auto p-3 [scrollbar-width:thin] [scrollbar-color:#2e2c29_transparent]">
        {sideSheet.stack.map((entry, index) => {
          const isActive = index === sideSheet.activeIndex;
          const panelWidth = entry.span === 3
            ? "w-[min(72rem,calc(100vw-1rem))]"
            : entry.span === 2
              ? "w-[min(48rem,calc(100vw-1rem))]"
              : "w-[min(24rem,calc(100vw-1rem))]";
          const panelLabel = entry.type === "user" ? `user · ${entry.username}` : entry.type;
          const canResize = entry.type === "user";
          return (
            <div
              key={entry.key}
              class={`relative h-full ${panelWidth} shrink-0 overflow-hidden rounded-2xl border bg-[#111214] shadow-[-8px_0_30px_rgba(0,0,0,0.45)] ${isActive ? "border-[rgba(217,116,82,0.42)]" : "border-white/8"}`}
              tabIndex={0}
              ref={(el) => {
                panelRefs.current[index] = el;
              }}
              onFocus={() => sideSheet.setActiveIndex(index)}
            >
              <div class="flex items-center justify-between border-b border-white/7 bg-[#161719] px-3 py-2">
                <span class="text-[0.72rem] font-semibold uppercase tracking-[0.12em] text-[#7ca4be]">
                  {panelLabel}
                </span>
                <div class="flex items-center gap-1.5">
                  {canResize && (
                    <div class="flex items-center gap-1">
                      {[1, 2, 3].map((span) => (
                        <button
                          key={span}
                          class={`rounded-md border px-2 py-0.5 text-[0.68rem] transition ${entry.span === span ? "border-[rgba(217,116,82,0.42)] text-[#f1efe7]" : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"}`}
                          title={`Resize to ${span}x`}
                          onClick={(e) => {
                            e.stopPropagation();
                            sideSheet.setSpan(entry.key, span as 1 | 2 | 3);
                          }}
                        >
                          {span}x
                        </button>
                      ))}
                    </div>
                  )}
                  <button
                    class="rounded-md border border-white/10 px-2 py-0.5 text-[0.68rem] text-[#9a9690] transition hover:text-[#f1efe7]"
                    title="Bring to front"
                    onClick={(e) => {
                      e.stopPropagation();
                      sideSheet.bringToFront(entry.key);
                    }}
                  >
                    ↗
                  </button>
                  <button
                    class="rounded-md border border-white/10 px-2 py-0.5 text-[0.68rem] text-[#9a9690] transition hover:text-[#f1efe7]"
                    title="Close panel"
                    onClick={(e) => {
                      e.stopPropagation();
                      sideSheet.closeByKey(entry.key);
                    }}
                  >
                    ×
                  </button>
                </div>
              </div>

              <div class="h-[calc(100%-2.2rem)]">
                {entry.type === "media" && (
                  <MediaDetailsPanel
                    mediaId={entry.mediaId}
                    embedded
                    onClose={() => sideSheet.closeByKey(entry.key)}
                    onOpenMedia={sideSheet.openMedia}
                    onOpenCharacter={sideSheet.openCharacter}
                    onOpenStaff={sideSheet.openStaff}
                    onOpenStudio={sideSheet.openStudio}
                  />
                )}
                {entry.type === "character" && (
                  <CharacterPanel
                    characterId={entry.characterId}
                    embedded
                    onClose={() => sideSheet.closeByKey(entry.key)}
                    onMediaClick={sideSheet.openMedia}
                  />
                )}
                {entry.type === "staff" && (
                  <StaffPanel
                    staffId={entry.staffId}
                    embedded
                    onClose={() => sideSheet.closeByKey(entry.key)}
                    onCharacterClick={sideSheet.openCharacter}
                  />
                )}
                {entry.type === "studio" && (
                  <StudioPanel
                    studioId={entry.studioId}
                    embedded
                    onClose={() => sideSheet.closeByKey(entry.key)}
                    onMediaClick={sideSheet.openMedia}
                  />
                )}
                {entry.type === "user" && (
                  <UserPanel
                    username={entry.username}
                    embedded
                    onClose={() => sideSheet.closeByKey(entry.key)}
                    onOpenMedia={sideSheet.openMedia}
                    onOpenCharacter={sideSheet.openCharacter}
                    onOpenStaff={sideSheet.openStaff}
                    onOpenStudio={sideSheet.openStudio}
                    onOpenUser={(name) => sideSheet.openUser(name, 2)}
                    onRequestSpan={(span) => sideSheet.setSpan(entry.key, span)}
                  />
                )}
              </div>
            </div>
          );
        })}
        </div>
      </div>
    </section>
  );
}

// ─── Shell ────────────────────────────────────────────────────────────────────

/**
 * Null-rendering component that handles keyboard shortcuts involving the side
 * sheet. Isolated here so that side-sheet context changes do NOT cause
 * AppShellContent (and all its surface children) to re-render.
 */
function SideSheetShortcuts({
  setScreen,
  setSurfaceRefreshKey,
}: {
  setScreen: (id: ScreenId) => void;
  setSurfaceRefreshKey: (fn: (n: number) => number) => void;
}) {
  const sideSheet = useSideSheet();
  const sideSheetRef = useRef(sideSheet);
  sideSheetRef.current = sideSheet;

  useEffect(() => {
    const onShortcut = (event: Event) => {
      const detail = (event as CustomEvent<{ action?: string; screen?: ScreenId }>).detail;
      if (!detail?.action) return;

      switch (detail.action) {
        case "focus-search": {
          setScreen("search");
          requestAnimationFrame(() => {
            window.dispatchEvent(new CustomEvent("miyolist:focus-search-input"));
          });
          return;
        }
        case "sync-now": {
          syncUserLists()
            .then((summary) => {
              if (
                summary &&
                (summary.synced > 0 || summary.pushed > 0 || summary.conflicts > 0)
              ) {
                invalidateLibraryCache();
                setSurfaceRefreshKey((n) => n + 1);
              }
            })
            .catch(() => {/* silent manual sync */});
          return;
        }
        case "go-screen": {
          if (detail.screen) setScreen(detail.screen);
          return;
        }
        case "close-overlays": {
          if (sideSheetRef.current.closeRightmost()) {
            return;
          }
          window.dispatchEvent(new CustomEvent("miyolist:close-overlays"));
          return;
        }
        case "cycle-panel-left": {
          sideSheetRef.current.cycleFocus("left");
          return;
        }
        case "cycle-panel-right": {
          sideSheetRef.current.cycleFocus("right");
          return;
        }
        case "refresh-surface": {
          setSurfaceRefreshKey((n) => n + 1);
          return;
        }
        default:
          return;
      }
    };

    window.addEventListener("miyolist:shortcut", onShortcut as EventListener);
    return () => window.removeEventListener("miyolist:shortcut", onShortcut as EventListener);
  }, [setScreen, setSurfaceRefreshKey]);

  return null;
}

/**
 * The header "Sync" button.  Owns its own polling of the Rust-side sync
 * progress mutex so the 1s poll tick re-renders ONLY this small button —
 * previously the poll lived in AppShellContent and re-rendered the entire
 * shell (including the active surface, e.g. a 2.5k-entry library grid)
 * every second for the whole sync.
 */
function SyncButton({ onSyncComplete }: { onSyncComplete: (s: SyncSummary | null) => void }) {
  const [manualSyncing, setManualSyncing] = useState(false);
  const [syncProgressText, setSyncProgressText] = useState<string>("");

  async function handleManualSync() {
    if (manualSyncing) return;
    setManualSyncing(true);
    setSyncProgressText("");

    // Poll the Rust-side progress mutex every second so the button renders
    // real feedback ("Pulling anime · 250") on long syncs instead of a
    // frozen "Syncing..." for ~2 minutes on a 2.5k-entry library.
    const pollId = setInterval(async () => {
      try {
        const p = await getSyncProgress();
        if (p.active) {
          const count = p.entries > 0 ? ` · ${p.entries}` : "";
          setSyncProgressText(`${p.phase || "syncing"}${count}`);
        }
      } catch {
        // ignore transient poll errors
      }
    }, 1000);

    try {
      const summary = await syncUserLists();
      onSyncComplete(summary);
    } catch {
      onSyncComplete(null);
    } finally {
      clearInterval(pollId);
      setManualSyncing(false);
      setSyncProgressText("");
    }
  }

  return (
    <button
      class="rounded-full border border-[rgba(255,255,255,0.12)] bg-white/5 px-3 py-1.5 text-[0.76rem] font-semibold text-[#d9d5cc] transition hover:bg-white/10 disabled:opacity-50"
      onClick={handleManualSync}
      disabled={manualSyncing}
    >
      {manualSyncing
        ? syncProgressText
          ? `↻ ${syncProgressText}`
          : "Syncing…"
        : "Sync"}
    </button>
  );
}

function AppShellContent() {
  const [session, setSession]   = useState<AuthSessionStatus | null>(null);
  const [screen,  setScreen]    = useState<ScreenId>("library");
  const [booting, setBooting]   = useState(true);
  const [surfaceRefreshKey, setSurfaceRefreshKey] = useState(0);
  const online = useOnlineStatus();
  const mobileShell = useMobileShell();
  const wasOnlineRef = useRef<boolean>(online);

  // Refresh the active surface only when a sync actually changed data.
  // Bumping surfaceRefreshKey remounts every surface, which on a
  // 2.5k-entry library means re-serialising + re-parsing the whole list
  // over IPC — so skip it entirely when a sync pulled/pushed nothing.
  const refreshLibraryIfChanged = useCallback((summary: SyncSummary | null) => {
    if (!summary) return;
    const changed =
      summary.synced > 0 || summary.pushed > 0 || summary.conflicts > 0;
    if (!changed) return;
    invalidateLibraryCache();
    setSurfaceRefreshKey((n) => n + 1);
  }, []);

  // ── Dirty-entry flush: push any pending local edits to AniList 60 s after
  // the last edit, regardless of which screen the user is on.
  const autoSyncTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const scheduleAutoSync = useCallback(() => {
    if (autoSyncTimer.current) clearTimeout(autoSyncTimer.current);
    autoSyncTimer.current = setTimeout(() => {
      pushDirtyEntries().catch(() => {/* silent — user can manual-sync */});
    }, 60_000);
  }, []);

  // ── Background interval sync: call sync_user_lists every N minutes based
  // on the user's autoSyncInterval setting.  A value of 0 disables it.
  // Re-created whenever settings change (SettingsSurface dispatches
  // "miyolist:settings-changed"), so interval changes apply immediately
  // without an app restart.
  const bgSyncIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const setupBgSyncInterval = useCallback(() => {
    getAppSettings()
      .then((s) => {
        const minutes = s.autoSyncInterval ?? 15;
        if (bgSyncIntervalRef.current) clearInterval(bgSyncIntervalRef.current);
        bgSyncIntervalRef.current = null;
        if (minutes > 0) {
          bgSyncIntervalRef.current = setInterval(() => {
            syncUserLists()
              .then((summary) => refreshLibraryIfChanged(summary))
              .catch(() => {/* silent background sync */});
            // Also check for new manga chapters (fire-and-forget; the Rust
            // side respects the master toggle + per-media mutes).
            checkMangaReleases().catch(() => {});
          }, minutes * 60_000);
        }
      })
      .catch(() => {/* settings unavailable — skip */});
  }, []);

  useEffect(() => {
    setupBgSyncInterval();
    window.addEventListener("miyolist:settings-changed", setupBgSyncInterval);
    return () => {
      window.removeEventListener("miyolist:settings-changed", setupBgSyncInterval);
      if (bgSyncIntervalRef.current) clearInterval(bgSyncIntervalRef.current);
    };
  }, [setupBgSyncInterval]);

  useEffect(() => {
    getAuthSessionStatus()
      .then((s) => {
        setSession(s);
        if (s?.hasAccessToken) {
          // Fire-and-forget: surface any OS notifications for episodes that
          // aired since the app was last open (no network request needed).
          checkNotifications().catch(() => {});
          // Same for new manga chapters — respects the master toggle.
          checkMangaReleases().catch(() => {});
        }
      })
      .catch(() => setSession(null))
      .finally(() => setBooting(false));
  }, []);

  // Re-check the stored session periodically so a token that expires while
  // the app is open falls back to the auth screen instead of showing raw API
  // errors.  Cheap local read; only updates state when something changed.
  useEffect(() => {
    const id = setInterval(() => {
      getAuthSessionStatus()
        .then((s) => {
          setSession((prev) => {
            if (!prev) return s;
            const changed =
              prev.hasAccessToken !== s.hasAccessToken ||
              prev.isTokenExpired !== s.isTokenExpired ||
              prev.viewerId !== s.viewerId;
            return changed ? s : prev;
          });
        })
        .catch(() => {/* transient — keep current session */});
    }, 60_000);
    return () => clearInterval(id);
  }, []);

  // Global toast host: the Rust command layer surfaces "saved locally, but
  // AniList push failed" warnings via the "miyolist:toast" CustomEvent.
  // Auto-update prompt: the Rust side throttles to once per day and respects
  // a user-skipped version, so this is a fire-and-forget check on boot.
  const [pendingUpdate, setPendingUpdate] = useState<UpdateInfo | null>(null);
  useEffect(() => {
    checkForUpdates(false)
      .then((update) => {
        if (update) setPendingUpdate(update);
      })
      .catch(() => {/* offline / no manifest — try again next launch */});
  }, []);

  const [toast, setToast] = useState<{ text: string; kind: "warn" | "ok" | "err" } | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => {
    const onToast = (e: Event) => {
      const detail = (e as CustomEvent<{ text?: string; kind?: "warn" | "ok" | "err" }>).detail;
      if (!detail?.text) return;
      setToast({ text: detail.text, kind: detail.kind ?? "warn" });
      if (toastTimer.current) clearTimeout(toastTimer.current);
      toastTimer.current = setTimeout(() => setToast(null), 5000);
    };
    window.addEventListener("miyolist:toast", onToast);
    return () => {
      window.removeEventListener("miyolist:toast", onToast);
      if (toastTimer.current) clearTimeout(toastTimer.current);
    };
  }, []);

  const toastBar = toast && (
    <div class="pointer-events-none fixed bottom-5 left-1/2 z-[90] w-max max-w-[min(90vw,28rem)] -translate-x-1/2 rounded-xl border border-[rgba(217,116,82,0.35)] bg-[rgba(20,22,26,0.96)] px-4 py-2.5 text-[0.8rem] text-[#e8e3dc] shadow-2xl backdrop-blur">
      <span
        class={`mr-2 inline-block h-2 w-2 rounded-full ${
          toast.kind === "err" ? "bg-[#e06b5a]" : toast.kind === "ok" ? "bg-[#7cbe8c]" : "bg-[#d9a06a]"
        }`}
      />
      {toast.text}
    </div>
  );

  // Disable the native right-click context menu on desktop — the app is a
  // packaged Tauri client, not a webpage, so the browser's "Inspect / Reload"
  // menu only confuses end users.  The handler is a no-op on touch devices
  // (mobile WebViews don't fire `contextmenu`) so we don't need to gate it.
  useEffect(() => {
    const onContextMenu = (event: MouseEvent) => {
      event.preventDefault();
    };
    window.addEventListener("contextmenu", onContextMenu);
    return () => window.removeEventListener("contextmenu", onContextMenu);
  }, []);

  useEffect(() => {
    const becameOnline = !wasOnlineRef.current && online;
    wasOnlineRef.current = online;
    if (!becameOnline || !session?.hasAccessToken) return;

    // Restore remote-dependent tasks on reconnect.
    pushDirtyEntries()
      .then(() => syncUserLists())
      .then((summary) => refreshLibraryIfChanged(summary))
      .then(() => refreshAiringSchedule())
      .then(() => prefetchCovers())
      .then(() => checkMangaReleases())
      .catch(() => {
        // Keep reconnect flow silent; periodic sync will retry.
      });
    // Re-try the (throttled) update check too — if the app launched offline,
    // the boot check failed and won't fire again until the next launch.
    checkForUpdates(false)
      .then((update) => {
        if (update) setPendingUpdate(update);
      })
      .catch(() => {/* offline again — try on the next reconnect */});
  }, [online, session?.hasAccessToken]);

  if (booting) {
    return (
      <div class="flex h-screen items-center justify-center">
        <span class="text-[#b5b0a5]">Loading…</span>
      </div>
    );
  }

  // Not authenticated OR the stored token has expired → full-screen auth.
  if (!session?.hasAccessToken || session.isTokenExpired) {
    return (
      <AuthSurface
        session={session}
        onAuthenticated={(s) => {
          setSession(s);
          setScreen("library");
        }}
      />
    );
  }

  function handleLogout() {
    setSession({ hasAccessToken: false, viewerId: null, viewerName: null, viewerAvatarUrl: null, tokenExpiresAt: null, isTokenExpired: false, updatedAt: null });
  }

  const renderActiveSurface = () => (
    <>
      {screen === "library"    && <LibrarySurface key={`library:${surfaceRefreshKey}`} session={session} onNavigate={setScreen} onEntryEdited={scheduleAutoSync} />}
      {screen === "discovery"  && <DiscoverySurface key={`discovery:${surfaceRefreshKey}`} />}
      {screen === "activity"   && <ActivitySurface key={`activity:${surfaceRefreshKey}`} />}
      {screen === "notifications" && <NotificationsSurface key={`notifications:${surfaceRefreshKey}`} />}
      {screen === "search"     && <SearchSurface key={`search:${surfaceRefreshKey}`} onNavigate={setScreen} />}
      {screen === "schedule"   && <ScheduleSurface key={`schedule:${surfaceRefreshKey}`} />}
      {screen === "statistics" && <StatisticsSurface key={`statistics:${surfaceRefreshKey}`} />}
      {screen === "settings"   && <SettingsSurface key={`settings:${surfaceRefreshKey}`} />}
      {screen === "auth"       && <AuthSurface key={`auth:${surfaceRefreshKey}`} session={session} onAuthenticated={setSession} onLogout={handleLogout} />}
    </>
  );

  const activeNav = NAV.find((item) => item.id === screen);


  if (mobileShell) {
    return (
      <div class="relative flex h-screen flex-col overflow-hidden bg-[radial-gradient(1100px_520px_at_22%_-12%,rgba(217,116,82,0.12),transparent_62%),radial-gradient(900px_440px_at_78%_0%,rgba(94,122,144,0.16),transparent_58%),#0d0f12]">
        <SideSheetShortcuts setScreen={setScreen} setSurfaceRefreshKey={setSurfaceRefreshKey} />

        {!online && (
          <div class="z-20 border-b border-[rgba(190,130,90,0.35)] bg-[rgba(44,36,28,0.92)] px-4 py-2 text-[0.78rem] text-[#d7c3a2] backdrop-blur">
            Offline mode: showing local data. Sync resumes automatically once online.
          </div>
        )}

        <header class="z-20 flex shrink-0 items-center justify-between border-b border-white/8 bg-[rgba(15,16,19,0.78)] px-4 pb-3 pt-[calc(0.7rem+env(safe-area-inset-top))] backdrop-blur-xl">
          <div class="min-w-0">
            <p class="text-[0.68rem] uppercase tracking-[0.14em] text-[#73889b]">MiyoList</p>
            <h1 class="truncate text-[1.35rem] font-bold tracking-[-0.02em] text-[#f1efe7]">{activeNav?.label ?? "Screen"}</h1>
          </div>
          <div class="flex items-center gap-2">
            <SyncButton onSyncComplete={refreshLibraryIfChanged} />
            <button
              class="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-full border border-white/12 bg-white/5"
              onClick={() => setScreen("auth")}
              title="Account"
            >
              {session.viewerAvatarUrl ? (
                <img
                  src={session.viewerAvatarUrl}
                  alt={session.viewerName ?? ""}
                  class="h-full w-full object-cover"
                />
              ) : (
                <span class="text-[0.8rem] font-bold text-[#f1efe7]">{session.viewerName?.[0]?.toUpperCase() ?? "?"}</span>
              )}
            </button>
          </div>
        </header>

        <main class="min-h-0 flex-1 overflow-y-auto">
          {renderActiveSurface()}
        </main>

        <nav class="z-30 shrink-0 border-t border-white/10 bg-[rgba(13,15,18,0.94)] px-2 pb-[calc(0.35rem+env(safe-area-inset-bottom))] pt-1.5 backdrop-blur-xl">
          <ul class="flex items-center gap-1 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {MOBILE_NAV_ORDER.map((id) => {
              const item = NAV.find((candidate) => candidate.id === id);
              if (!item) return null;
              const active = screen === id;
              const { Icon, label } = item;
              return (
                <li key={id}>
                  <button
                    class={`flex min-w-[4.65rem] flex-col items-center gap-0.5 rounded-xl px-2 py-1.5 text-[0.66rem] font-semibold tracking-[0.01em] transition ${
                      active
                        ? "bg-[rgba(217,116,82,0.2)] text-[#f1efe7]"
                        : "text-[#8b877f] hover:bg-white/6 hover:text-[#ded9d0]"
                    }`}
                    onClick={() => setScreen(id)}
                    title={label}
                  >
                    <span class={`${active ? "text-[#f29a7c]" : "text-[#6f8ca5]"}`}>
                      <Icon />
                    </span>
                    <span>{label}</span>
                  </button>
                </li>
              );
            })}
          </ul>
        </nav>

        <SideSheetHost />
        {toastBar}
        {pendingUpdate && (
          <UpdateDialog
            initialUpdate={pendingUpdate}
            onClose={() => setPendingUpdate(null)}
          />
        )}
      </div>
    );
  }

  return (
    <div class="relative flex h-screen overflow-hidden">
      <SideSheetShortcuts setScreen={setScreen} setSurfaceRefreshKey={setSurfaceRefreshKey} />
      {/* ── Sidebar ─────────────────────────────────────────────────────── */}
      <aside class="flex w-55 shrink-0 flex-col border-r border-white/7 bg-[rgba(14,15,17,0.95)] backdrop-blur-xl">

        {/* App wordmark */}
        <div class="flex items-center gap-2.5 px-5 pt-6 pb-5">
          <div class="flex h-7 w-7 items-center justify-center rounded-lg bg-[rgba(217,116,82,0.25)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97452" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
              <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
            </svg>
          </div>
          <span class="text-[1.05rem] font-bold tracking-[-0.03em] text-[#f1efe7]">MiyoList</span>
        </div>

        {/* Navigation */}
        <nav class="flex-1 px-2.5">
          <ul class="grid gap-0.5">
            {NAV.map(({ id, label, Icon }) => {
              const active = screen === id;
              const shortcutHint =
                id === "library" ? "Alt+1" :
                id === "discovery" ? "Alt+2" :
                id === "activity" ? "Alt+3" :
                id === "notifications" ? "Alt+4" :
                id === "search" ? "Alt+5 / Ctrl+F" :
                id === "schedule" ? "Alt+6" :
                "";
              return (
                <li key={id}>
                  <button
                    class={`flex w-full items-center gap-3 rounded-[0.85rem] px-3 py-2.5 text-[0.9rem] font-medium transition-all ${
                      active
                        ? "bg-[rgba(217,116,82,0.14)] text-[#f1efe7]"
                        : "text-[#848076] hover:bg-white/5 hover:text-[#d4d0c8]"
                    }`}
                    onClick={() => setScreen(id)}
                    title={shortcutHint ? `${label} (${shortcutHint})` : label}
                  >
                    <span class={`shrink-0 ${active ? "text-[#d97452]" : "text-[#5e7a90]"}`}>
                      <Icon />
                    </span>
                    {label}
                    {active && (
                      <span class="ml-auto h-1.5 w-1.5 rounded-full bg-[#d97452]" />
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </nav>

        {/* Account widget */}
        <div class="border-t border-white/7 p-2.5">
          <button
            class="flex w-full items-center gap-3 rounded-[0.85rem] px-2.5 py-2.5 text-left transition hover:bg-white/5"
            onClick={() => setScreen("auth")}
          >
            {session.viewerAvatarUrl ? (
              <img
                src={session.viewerAvatarUrl}
                alt={session.viewerName ?? ""}
                class="h-8 w-8 shrink-0 rounded-full object-cover ring-1 ring-white/10"
              />
            ) : (
              <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[rgba(217,116,82,0.2)] text-sm font-bold text-[#d97452]">
                {session.viewerName?.[0]?.toUpperCase() ?? "?"}
              </div>
            )}
            <div class="min-w-0 flex-1">
              <div class="truncate text-[0.85rem] font-semibold leading-tight text-[#f1efe7]">
                {session.viewerName ?? "Account"}
              </div>
              <div class="text-[0.72rem] text-[#5e7a90]">AniList</div>
            </div>
          </button>
        </div>
      </aside>

      {/* ── Main content ────────────────────────────────────────────────── */}
      <main class="min-w-0 flex-1 overflow-y-auto">
        {!online && (
          <div class="sticky top-0 z-20 border-b border-[rgba(190,130,90,0.35)] bg-[rgba(44,36,28,0.92)] px-4 py-2 text-[0.78rem] text-[#d7c3a2] backdrop-blur">
            Offline mode: showing local data. Sync and AniList updates will resume automatically when connection returns.
          </div>
        )}
        {renderActiveSurface()}
      </main>

      <SideSheetHost />
      {toastBar}
      {pendingUpdate && (
        <UpdateDialog
          initialUpdate={pendingUpdate}
          onClose={() => setPendingUpdate(null)}
        />
      )}
    </div>
  );
}

export function AppShell() {
  return (
    <SideSheetProvider>
      <AppShellContent />
    </SideSheetProvider>
  );
}
