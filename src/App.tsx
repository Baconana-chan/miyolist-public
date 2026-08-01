import { useEffect, useRef } from "preact/hooks";
import { AppShell } from "./app/AppShell";
import { getAppSettings } from "./shared/api/database";
import { mergeShortcuts, shortcutMatches } from "./shared/shortcuts";
import type { ScreenId } from "./shared/types/app";

// Screen navigation actions dispatch `go-screen` with a target screen id.
const SCREEN_ACTIONS: Partial<Record<string, ScreenId>> = {
  "go-screen:library": "library",
  "go-screen:discovery": "discovery",
  "go-screen:activity": "activity",
  "go-screen:notifications": "notifications",
  "go-screen:search": "search",
  "go-screen:schedule": "schedule",
  "go-screen:statistics": "statistics",
  "go-screen:settings": "settings",
};

export default function App() {
  // Hold the active shortcut map in a ref so the keydown listener can read
  // the latest value without being re-registered on every settings change.
  const shortcutsRef = useRef<Record<string, string>>(mergeShortcuts(undefined));

  useEffect(() => {
    const applySettings = async () => {
      try {
        const settings = await getAppSettings();
        shortcutsRef.current = mergeShortcuts(settings.keyboardShortcuts);
      } catch {
        // Keep defaults if settings can't be read.
      }
    };
    applySettings();

    const onSettingsChanged = () => {
      applySettings();
    };
    window.addEventListener("miyolist:settings-changed", onSettingsChanged);

    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      const isTypingContext =
        !!target &&
        (target.tagName === "INPUT" ||
          target.tagName === "TEXTAREA" ||
          target.tagName === "SELECT" ||
          target.isContentEditable);

      const map = shortcutsRef.current;

      for (const [action, combo] of Object.entries(map)) {
        if (!shortcutMatches(event, combo)) continue;

        // Escape should always dismiss overlays, even mid-typing; other
        // single-key bindings must not hijack typing in inputs.
        if (isTypingContext && action !== "close-overlays" && combo.split("+").length === 1) {
          continue;
        }

        event.preventDefault();

        const screen = SCREEN_ACTIONS[action];
        if (screen) {
          window.dispatchEvent(
            new CustomEvent("miyolist:shortcut", {
              detail: { action: "go-screen", screen },
            }),
          );
          return;
        }

        window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action } }));
        return;
      }

      // Safety net: Escape always dismisses overlays, even if it was
      // rebound to something else in settings.
      if (event.key === "Escape") {
        window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "close-overlays" } }));
        return;
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("miyolist:settings-changed", onSettingsChanged);
    };
  }, []);

  return <AppShell />;
}
