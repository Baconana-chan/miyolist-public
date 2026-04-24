import { createContext } from "preact";
import { useCallback, useContext, useEffect, useMemo, useRef, useState } from "preact/hooks";
import type { ComponentChildren } from "preact";

export type SideSheetEntry =
  | { key: string; type: "media"; mediaId: number; span: 1 | 2 | 3 }
  | { key: string; type: "character"; characterId: number; span: 1 | 2 | 3 }
  | { key: string; type: "staff"; staffId: number; span: 1 | 2 | 3 }
  | { key: string; type: "studio"; studioId: number; span: 1 | 2 | 3 }
  | { key: string; type: "user"; username: string; span: 1 | 2 | 3 };

type SideSheetContextValue = {
  isMultiPanel: boolean;
  stack: SideSheetEntry[];
  activeIndex: number;
  setActiveIndex: (index: number) => void;
  closeByKey: (key: string) => void;
  closeRightmost: () => boolean;
  clear: () => void;
  cycleFocus: (dir: "left" | "right") => boolean;
  bringToFront: (key: string) => void;
  setSpan: (key: string, span: 1 | 2 | 3) => void;
  openMedia: (mediaId: number) => void;
  openCharacter: (characterId: number) => void;
  openStaff: (staffId: number) => void;
  openStudio: (studioId: number) => void;
  openUser: (username: string, span?: 1 | 2 | 3) => void;
};

const SideSheetContext = createContext<SideSheetContextValue | null>(null);

function entryKey(prefix: string, id: number) {
  return `${prefix}:${id}:${Date.now()}:${Math.random().toString(36).slice(2, 7)}`;
}

const MULTI_PANEL_BREAKPOINT = 1400;
const MAX_PANELS = 4;

export function SideSheetProvider({ children }: { children: ComponentChildren }) {
  const [isMultiPanel, setIsMultiPanel] = useState(() => window.innerWidth >= MULTI_PANEL_BREAKPOINT);
  const [stack, setStack] = useState<SideSheetEntry[]>([]);
  const [activeIndex, setActiveIndex] = useState(0);
  const stackRef = useRef(stack);
  stackRef.current = stack;

  useEffect(() => {
    const onResize = () => setIsMultiPanel(window.innerWidth >= MULTI_PANEL_BREAKPOINT);
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  useEffect(() => {
    if (!isMultiPanel && stack.length > 1) {
      setStack((prev) => prev.slice(-1));
      setActiveIndex(0);
    }
  }, [isMultiPanel, stack.length]);

  useEffect(() => {
    if (stack.length === 0) {
      setActiveIndex(0);
      return;
    }
    if (activeIndex >= stack.length) {
      setActiveIndex(stack.length - 1);
    }
  }, [activeIndex, stack.length]);

  const append = useCallback((entry: SideSheetEntry) => {
    const next = isMultiPanel
      ? [...stackRef.current, entry].slice(-MAX_PANELS)
      : [entry];
    setStack(next);
    setActiveIndex(next.length - 1);
  }, [isMultiPanel]);

  const closeByKey = useCallback((key: string) => {
    setStack((prev) => prev.filter((entry) => entry.key !== key));
  }, []);

  const closeRightmost = useCallback(() => {
    let closed = false;
    setStack((prev) => {
      if (prev.length === 0) return prev;
      closed = true;
      return prev.slice(0, -1);
    });
    return closed;
  }, []);

  const clear = useCallback(() => {
    setStack([]);
    setActiveIndex(0);
  }, []);

  const cycleFocus = useCallback((dir: "left" | "right") => {
    const len = stackRef.current.length;
    if (len === 0) return false;
    setActiveIndex((prev) => {
      if (dir === "left") return (prev - 1 + len) % len;
      return (prev + 1) % len;
    });
    return true;
  }, []);

  const bringToFront = useCallback((key: string) => {
    const prev = stackRef.current;
    const idx = prev.findIndex((entry) => entry.key === key);
    if (idx < 0) return;
    if (idx === prev.length - 1) {
      setActiveIndex(idx);
      return;
    }
    const entry = prev[idx];
    const next = [...prev.slice(0, idx), ...prev.slice(idx + 1), entry];
    setStack(next);
    setActiveIndex(next.length - 1);
  }, []);

  const setSpan = useCallback((key: string, span: 1 | 2 | 3) => {
    setStack((prev) => prev.map((entry) => (entry.key === key ? { ...entry, span } : entry)));
  }, []);

  const openMedia = useCallback((mediaId: number) => {
    append({ key: entryKey("media", mediaId), type: "media", mediaId, span: 1 });
  }, [append]);

  const openCharacter = useCallback((characterId: number) => {
    append({ key: entryKey("character", characterId), type: "character", characterId, span: 1 });
  }, [append]);

  const openStaff = useCallback((staffId: number) => {
    append({ key: entryKey("staff", staffId), type: "staff", staffId, span: 1 });
  }, [append]);

  const openStudio = useCallback((studioId: number) => {
    append({ key: entryKey("studio", studioId), type: "studio", studioId, span: 1 });
  }, [append]);

  const openUser = useCallback((username: string, span: 1 | 2 | 3 = 2) => {
    append({ key: entryKey("user", Date.now()), type: "user", username, span });
  }, [append]);

  const value = useMemo<SideSheetContextValue>(() => ({
    isMultiPanel,
    stack,
    activeIndex,
    setActiveIndex,
    closeByKey,
    closeRightmost,
    clear,
    cycleFocus,
    bringToFront,
    setSpan,
    openMedia,
    openCharacter,
    openStaff,
    openStudio,
    openUser,
  }), [isMultiPanel, stack, activeIndex, openMedia, openCharacter, openStaff, openStudio, openUser, closeByKey, closeRightmost, clear, cycleFocus, bringToFront, setSpan, setActiveIndex]);

  return <SideSheetContext.Provider value={value}>{children}</SideSheetContext.Provider>;
}

export function useSideSheet() {
  const ctx = useContext(SideSheetContext);
  if (!ctx) {
    throw new Error("useSideSheet must be used within SideSheetProvider");
  }
  return ctx;
}
