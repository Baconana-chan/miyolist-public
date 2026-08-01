import { useEffect, useRef, useState } from "preact/hooks";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";
import {
  checkForUpdates,
  installUpdate,
  skipUpdateVersion,
} from "../../shared/api/database";
import type { UpdateInfo } from "../../shared/types/app";

interface UpdateDialogProps {
  onClose: () => void;
  /** Pre-fetched update (from the startup auto-check); when omitted the dialog runs its own forced check. */
  initialUpdate?: UpdateInfo | null;
}

type Status =
  | "checking"
  | "available"
  | "up-to-date"
  | "installing"
  | "error";

const PROGRESS_EVENT = "updater://progress";

/**
 * On Windows the updater's NSIS path tears the process down mid-install, so
 * the frontend never sees the install promise resolve — the app just closes.
 * Adjust the hint text so that looks intentional instead of like a crash.
 */
const IS_WINDOWS =
  typeof navigator !== "undefined" && /Windows/i.test(navigator.userAgent ?? "");

/**
 * Modal that offers an available app update with the three classic choices:
 * Download & Install, Remind me later, Skip this version.  While an update
 * downloads, the Rust side streams progress on `updater://progress`, which is
 * rendered as a progress bar.
 */
export function UpdateDialog({ onClose, initialUpdate }: UpdateDialogProps) {
  const [status, setStatus] = useState<Status>(
    initialUpdate ? "available" : "checking",
  );
  const [update, setUpdate] = useState<UpdateInfo | null>(initialUpdate ?? null);
  const [error, setError] = useState<string | null>(null);
  const [downloaded, setDownloaded] = useState(0);
  const [total, setTotal] = useState<number | null>(null);
  const unlistenRef = useRef<UnlistenFn | null>(null);

  // When no pre-fetched update was passed, run a forced check on mount.
  useEffect(() => {
    if (initialUpdate) return;
    let cancelled = false;
    checkForUpdates(true)
      .then((result) => {
        if (cancelled) return;
        if (result) {
          setUpdate(result);
          setStatus("available");
        } else {
          setStatus("up-to-date");
        }
      })
      .catch((e) => {
        if (cancelled) return;
        setError(String(e));
        setStatus("error");
      });
    return () => {
      cancelled = true;
    };
  }, [initialUpdate]);

  // Subscribe to download progress while the dialog is open.
  useEffect(() => {
    let unlisten: UnlistenFn | null = null;
    listen<{ downloaded: number; total?: number | null }>(PROGRESS_EVENT, (e) => {
      setDownloaded(e.payload.downloaded ?? 0);
      setTotal(e.payload.total ?? null);
    }).then((fn) => {
      unlisten = fn;
      unlistenRef.current = fn;
    });
    return () => {
      unlisten?.();
      unlistenRef.current = null;
    };
  }, []);

  async function handleInstall() {
    setStatus("installing");
    setError(null);
    try {
      await installUpdate();
      // On success the Rust side restarts the app into the new version.
    } catch (e) {
      setError(String(e));
      setStatus("available");
    }
  }

  async function handleSkip() {
    if (update) {
      try {
        await skipUpdateVersion(update.version);
      } catch {
        // Best-effort: even if persisting fails, close the dialog.
      }
    }
    onClose();
  }

  const percent =
    total && total > 0 ? Math.min(100, Math.round((downloaded / total) * 100)) : null;

  const title =
    status === "up-to-date"
      ? "You're up to date"
      : status === "checking"
        ? "Checking for updates…"
        : status === "installing"
          ? `Installing ${update?.version ?? "update"}…`
          : `MiyoList ${update?.version ?? ""} is available`;

  return (
    <div
      class="fixed inset-0 z-[80] flex items-center justify-center bg-black/60 px-4 backdrop-blur-sm"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div class="w-full max-w-md rounded-3xl border border-white/10 bg-[#1a1815] p-6 shadow-2xl">
        <div class="mb-4 flex items-start justify-between gap-3">
          <div>
            <p class="text-[0.68rem] font-semibold uppercase tracking-[0.14em] text-[#7ca4be]">
              Updater
            </p>
            <h2 class="mt-0.5 text-lg font-bold text-[#f1efe7]">{title}</h2>
          </div>
          <button
            class="rounded-full p-1.5 text-[#7a766e] transition hover:text-[#f1efe7]"
            onClick={onClose}
            aria-label="Close"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        <div class="space-y-4">
          {status === "checking" && (
            <p class="text-[0.9rem] text-[#b5b0a5]">Contacting GitHub Releases…</p>
          )}

          {status === "up-to-date" && (
            <p class="text-[0.9rem] text-[#b5b0a5] leading-relaxed">
              MiyoList {update?.currentVersion ?? ""} is the latest version.
            </p>
          )}

          {status === "available" && update && (
            <>
              <div class="flex items-center gap-2 text-[0.82rem]">
                <span class="rounded-full border border-[rgba(100,180,100,0.35)] px-2 py-0.5 text-[0.68rem] text-[#9cd89c]">
                  {update.currentVersion} → {update.version}
                </span>
                {update.date && (
                  <span class="text-[#7a766e]">
                    {new Date(update.date).toLocaleDateString()}
                  </span>
                )}
              </div>
              {update.body && (
                <div class="max-h-40 overflow-y-auto whitespace-pre-wrap rounded-xl border border-[#2e2c2a] bg-[#1e1c1a] px-3 py-2.5 text-[0.82rem] text-[#d8d3cb] leading-relaxed">
                  {update.body}
                </div>
              )}
              <div class="flex flex-col gap-2">
                <button
                  class="w-full rounded-xl bg-[#d97452] px-4 py-2.5 text-sm font-semibold text-[#17130f] transition hover:bg-[#e0835f]"
                  onClick={handleInstall}
                >
                  Download &amp; Install
                </button>
                <div class="flex gap-2">
                  <button
                    class="flex-1 rounded-xl border border-white/10 px-3 py-2 text-[0.82rem] font-medium text-[#b5b0a5] transition hover:bg-white/5"
                    onClick={onClose}
                  >
                    Remind me later
                  </button>
                  <button
                    class="flex-1 rounded-xl border border-white/10 px-3 py-2 text-[0.82rem] font-medium text-[#b5b0a5] transition hover:bg-white/5"
                    onClick={handleSkip}
                  >
                    Skip this version
                  </button>
                </div>
              </div>
            </>
          )}

          {status === "installing" && (
            <div class="space-y-3">
              <div class="h-2 overflow-hidden rounded-full bg-[#2e2c2a]">
                <div
                  class="h-full rounded-full bg-[#d97452] transition-[width] duration-200"
                  style={{ width: `${percent ?? 0}%` }}
                />
              </div>
              <p class="text-[0.8rem] text-[#9a9690]">
                {percent !== null
                  ? `Downloading… ${percent}%`
                  : "Downloading…"}
              </p>
              <p class="text-[0.72rem] text-[#7a766e]">
                {IS_WINDOWS
                  ? "The app will close while the update installs — relaunch it after the installer finishes."
                  : "The app will restart automatically when the update is ready."}
              </p>
            </div>
          )}

          {status === "error" && (
            <>
              <p class="text-[0.82rem] text-[#e06b5a] leading-relaxed">
                {error || "Something went wrong while checking for updates."}
              </p>
              <div class="flex gap-2">
                <button
                  class="flex-1 rounded-xl bg-[#d97452] px-3 py-2 text-[0.82rem] font-semibold text-[#17130f] transition hover:bg-[#e0835f]"
                  onClick={() => {
                    setStatus("checking");
                    setError(null);
                    checkForUpdates(true)
                      .then((result) => {
                        if (result) {
                          setUpdate(result);
                          setStatus("available");
                        } else {
                          setStatus("up-to-date");
                        }
                      })
                      .catch((e) => {
                        setError(String(e));
                        setStatus("error");
                      });
                  }}
                >
                  Try again
                </button>
                <button
                  class="flex-1 rounded-xl border border-white/10 px-3 py-2 text-[0.82rem] font-medium text-[#b5b0a5] transition hover:bg-white/5"
                  onClick={onClose}
                >
                  Close
                </button>
              </div>
            </>
          )}

        </div>
      </div>
    </div>
  );
}
