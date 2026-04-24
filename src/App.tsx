import { useEffect } from "preact/hooks";
import { AppShell } from "./app/AppShell";

export default function App() {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      const isTypingContext =
        !!target &&
        (target.tagName === "INPUT" ||
          target.tagName === "TEXTAREA" ||
          target.tagName === "SELECT" ||
          target.isContentEditable);

      if (event.ctrlKey && event.key.toLowerCase() === "f") {
        event.preventDefault();
        window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "focus-search" } }));
        return;
      }

      if (event.ctrlKey && event.shiftKey && event.key.toLowerCase() === "s") {
        event.preventDefault();
        window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "sync-now" } }));
        return;
      }

      if (event.altKey) {
        if (event.key === "ArrowLeft") {
          event.preventDefault();
          window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "cycle-panel-left" } }));
          return;
        }
        if (event.key === "ArrowRight") {
          event.preventDefault();
          window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "cycle-panel-right" } }));
          return;
        }

        const screenByDigit: Record<string, string> = {
          "1": "library",
          "2": "discovery",
          "3": "activity",
          "4": "notifications",
          "5": "search",
          "6": "schedule",
        };
        const screen = screenByDigit[event.key];
        if (screen) {
          event.preventDefault();
          window.dispatchEvent(
            new CustomEvent("miyolist:shortcut", {
              detail: { action: "go-screen", screen },
            }),
          );
          return;
        }
      }

      if (event.key === "Escape") {
        window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "close-overlays" } }));
        return;
      }

      if (event.key === "F5") {
        event.preventDefault();
        window.dispatchEvent(new CustomEvent("miyolist:shortcut", { detail: { action: "refresh-surface" } }));
        return;
      }

      if (isTypingContext) {
        return;
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return <AppShell />;
}
