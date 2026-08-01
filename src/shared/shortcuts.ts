// ─── Configurable keyboard shortcuts ────────────────────────────────────────
//
// Shortcuts live in `app_settings.keyboardShortcuts` as a JSON map of
//   action → combo string
// where a combo is a `+`-joined string of modifiers and the key, e.g.
// `"Ctrl+Shift+S"`, `"Alt+1"`, `"F5"`, `"Escape"`, `"Alt+ArrowLeft"`.
//
// The stored map is a *delta* over SHORTCUT_DEFAULTS — `mergeShortcuts`
// overlays persisted overrides on top of the built-in defaults, and
// `stripDefaults` removes entries that match a default so a reset is just
// saving `"{}"`.

export type ShortcutCategory = "Navigation" | "App" | "Panels";

export interface ShortcutActionDef {
  /** Action id dispatched via the `miyolist:shortcut` CustomEvent. */
  action: string;
  label: string;
  category: ShortcutCategory;
}

export const SHORTCUT_DEFAULTS: Record<string, string> = {
  "go-screen:library": "Alt+1",
  "go-screen:discovery": "Alt+2",
  "go-screen:activity": "Alt+3",
  "go-screen:notifications": "Alt+4",
  "go-screen:search": "Alt+5",
  "go-screen:schedule": "Alt+6",
  "focus-search": "Ctrl+F",
  "sync-now": "Ctrl+Shift+S",
  "refresh-surface": "F5",
  "close-overlays": "Escape",
  "cycle-panel-left": "Alt+ArrowLeft",
  "cycle-panel-right": "Alt+ArrowRight",
};

export const SHORTCUT_ACTIONS: ShortcutActionDef[] = [
  { action: "go-screen:library", label: "Open Library", category: "Navigation" },
  { action: "go-screen:discovery", label: "Open Discover", category: "Navigation" },
  { action: "go-screen:activity", label: "Open Activity", category: "Navigation" },
  { action: "go-screen:notifications", label: "Open Inbox", category: "Navigation" },
  { action: "go-screen:search", label: "Open Search", category: "Navigation" },
  { action: "go-screen:schedule", label: "Open Airing", category: "Navigation" },
  { action: "focus-search", label: "Focus search", category: "App" },
  { action: "sync-now", label: "Sync now", category: "App" },
  { action: "refresh-surface", label: "Refresh current screen", category: "App" },
  { action: "close-overlays", label: "Close overlays / panels", category: "App" },
  { action: "cycle-panel-left", label: "Focus previous panel", category: "Panels" },
  { action: "cycle-panel-right", label: "Focus next panel", category: "Panels" },
];

export const SHORTCUT_CATEGORIES: ShortcutCategory[] = ["Navigation", "App", "Panels"];

const MODIFIER_KEYS = new Set(["Control", "Shift", "Alt", "Meta", "CapsLock", "NumLock", "ScrollLock"]);

/** Normalize a single key to a stable, case-insensitive token used in combos. */
function normalizeKey(key: string): string {
  if (key === " ") return "Space";
  if (key.length === 1) return key.toUpperCase();
  // F1-F12, Escape, ArrowLeft, Enter, Tab, etc. are already stable tokens.
  return key;
}

/** Parse a stored combo string into its modifier flags + normalized key. */
function parseCombo(combo: string): { ctrl: boolean; alt: boolean; shift: boolean; meta: boolean; key: string } {
  const parts = combo.split("+");
  const key = normalizeKey(parts[parts.length - 1]);
  const mods = parts.slice(0, -1);
  return {
    ctrl: mods.includes("Ctrl"),
    alt: mods.includes("Alt"),
    shift: mods.includes("Shift"),
    meta: mods.includes("Meta"),
    key,
  };
}

/** Does this keydown event match the given combo string? */
export function shortcutMatches(event: KeyboardEvent, combo: string): boolean {
  const { ctrl, alt, shift, meta, key } = parseCombo(combo);
  return (
    event.ctrlKey === ctrl &&
    event.altKey === alt &&
    event.shiftKey === shift &&
    event.metaKey === meta &&
    normalizeKey(event.key) === key
  );
}

/**
 * Build a combo string from a keydown event (used by the Settings recorder).
 * Returns `null` for bare modifier presses so they can't be bound alone.
 */
export function comboFromEvent(event: KeyboardEvent): string | null {
  if (MODIFIER_KEYS.has(event.key)) return null;
  const mods: string[] = [];
  if (event.ctrlKey) mods.push("Ctrl");
  if (event.altKey) mods.push("Alt");
  if (event.shiftKey) mods.push("Shift");
  if (event.metaKey) mods.push("Meta");
  return [...mods, normalizeKey(event.key)].join("+");
}

/** Overlay persisted overrides on top of built-in defaults. */
export function mergeShortcuts(raw: string | undefined | null): Record<string, string> {
  let overrides: Record<string, string> = {};
  if (raw) {
    try {
      const parsed = JSON.parse(raw) as unknown;
      if (parsed && typeof parsed === "object") {
        overrides = parsed as Record<string, string>;
      }
    } catch {
      // Ignore malformed JSON; fall back to defaults.
    }
  }
  return { ...SHORTCUT_DEFAULTS, ...overrides };
}

/** Keep only entries that differ from defaults — a reset is saving `"{}"`. */
export function stripDefaults(merged: Record<string, string>): Record<string, string> {
  const overrides: Record<string, string> = {};
  for (const [action, combo] of Object.entries(merged)) {
    if (SHORTCUT_DEFAULTS[action] !== combo) {
      overrides[action] = combo;
    }
  }
  return overrides;
}

/** Human-friendly label for a combo, e.g. `Ctrl+Shift+S` stays as-is. */
export function formatCombo(combo: string): string {
  return combo.replace(/\+/g, " + ");
}
