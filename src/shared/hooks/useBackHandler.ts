import { useEffect, useRef } from "preact/hooks";

/**
 * Tracks how many overlays are currently open globally so we can decide when
 * to enter / exit Fullscreen mode (used to hide the Android status bar while
 * any panel is on screen).
 */
let openOverlayCount = 0;

const MOBILE_BREAKPOINT_PX = 900;

function isMobileViewport(): boolean {
  return typeof window !== "undefined" && window.innerWidth <= MOBILE_BREAKPOINT_PX;
}

async function enterFullscreenIfMobile(): Promise<void> {
  if (!isMobileViewport()) return;
  if (typeof document === "undefined") return;
  // Already fullscreen → nothing to do.
  if (document.fullscreenElement) return;
  try {
    await document.documentElement.requestFullscreen?.({ navigationUI: "hide" });
  } catch {
    // requestFullscreen requires a user gesture and can throw on some
    // platforms (notably iOS Safari WebView).  Silently ignore — the panel
    // still works, just without the status bar being hidden.
  }
}

async function exitFullscreenIfMobile(): Promise<void> {
  if (!isMobileViewport()) return;
  if (typeof document === "undefined") return;
  if (!document.fullscreenElement) return;
  try {
    await document.exitFullscreen?.();
  } catch {
    // Ignore — the user might have already exited fullscreen via the system UI.
  }
}

/**
 * Wires an overlay (modal panel, sheet, dialog, ...) into the browser's
 * History API so that the system back gesture / hardware back button on
 * Android closes the overlay instead of exiting the app.
 *
 * The hook also requests Fullscreen on mobile while at least one overlay is
 * open, which on Android causes the status bar to retract and stop competing
 * with the panel's own header buttons.
 *
 * @param isOpen   Whether the overlay is currently visible.  Pass `false`
 *                 (or simply skip mounting the component) to opt out — for
 *                 example when the panel is rendered embedded inside a
 *                 desktop side sheet.
 * @param onClose  Called when the back gesture is detected.  Receives no
 *                 arguments; the parent is expected to flip its own "is
 *                 open" state to `false`.
 */
export function useBackHandler(isOpen: boolean, onClose: () => void): void {
  // Keep a ref to the latest onClose so the effect doesn't re-bind on every
  // render — otherwise we would push a fresh history entry every time the
  // parent re-renders with a new inline arrow function.
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;

  useEffect(() => {
    if (!isOpen) return;
    if (typeof window === "undefined") return;

    // Push a sentinel state so the next system-back triggers `popstate`
    // instead of navigating away from the WebView.
    const marker = { miyolistOverlay: true, ts: Date.now() };
    window.history.pushState(marker, "");

    openOverlayCount += 1;
    if (openOverlayCount === 1) {
      void enterFullscreenIfMobile();
    }

    let triggeredByBack = false;
    const handlePopState = () => {
      // The browser already popped our entry — record that so cleanup does
      // not try to pop a *second* time.
      triggeredByBack = true;
      onCloseRef.current();
    };

    window.addEventListener("popstate", handlePopState);

    return () => {
      window.removeEventListener("popstate", handlePopState);

      openOverlayCount = Math.max(0, openOverlayCount - 1);
      if (openOverlayCount === 0) {
        void exitFullscreenIfMobile();
      }

      // The overlay is closing because the parent flipped its own state
      // (e.g. user tapped the ✕ button) — pop the sentinel we pushed so the
      // history stack stays balanced and a later back gesture doesn't land
      // on a "phantom" entry.
      if (!triggeredByBack && (window.history.state as { miyolistOverlay?: boolean } | null)?.miyolistOverlay) {
        window.history.back();
      }
    };
  }, [isOpen]);
}
