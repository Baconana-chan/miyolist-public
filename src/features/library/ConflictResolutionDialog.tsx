import { useState, useEffect } from "preact/hooks";
import { getPendingConflicts, resolveConflict } from "../../shared/api/database";
import type { PendingConflict } from "../../shared/types/app";

// ─── Helpers ──────────────────────────────────────────────────────────────────

function statusLabel(s: string | null): string {
  if (!s) return "—";
  return { current: "Watching/Reading", completed: "Completed", planning: "Planning", paused: "On hold", dropped: "Dropped", repeating: "Repeating" }[s.toLowerCase()] ?? s;
}

function scoreLabel(n: number | null): string {
  return n != null && n > 0 ? String(n) : "—";
}

// ─── DiffRow ─────────────────────────────────────────────────────────────────

function DiffRow({ label, local, remote }: { label: string; local: string; remote: string }) {
  const differs = local !== remote;
  return (
    <tr class={differs ? "text-[#f1efe7]" : "text-[#5a5650] opacity-50"}>
      <td class="pr-3 pb-1.5 text-xs whitespace-nowrap">{label}</td>
      <td class="pr-3 pb-1.5 text-xs font-medium">{local}</td>
      <td class="pb-1.5 text-xs font-medium">{remote}</td>
    </tr>
  );
}

// ─── ConflictCard ─────────────────────────────────────────────────────────────

function ConflictCard({
  conflict,
  resolution,
  onChoose,
}: {
  conflict: PendingConflict;
  resolution: "local" | "remote" | null;
  onChoose: (choice: "local" | "remote") => void;
}) {
  const title = conflict.mediaTitle ?? `Media #${conflict.mediaId}`;
  const typeLabel = conflict.mediaType === "ANIME" ? "Anime" : conflict.mediaType === "MANGA" ? "Manga" : "Novel";

  return (
    <div
      class={[
        "rounded-xl border p-4 transition-colors",
        resolution === "local"
          ? "border-[#6a9fd4]/50 bg-[rgba(90,140,210,0.08)]"
          : resolution === "remote"
          ? "border-[#88c57a]/50 bg-[rgba(100,180,90,0.08)]"
          : "border-white/8 bg-white/3",
      ].join(" ")}
    >
      {/* Header */}
      <div class="mb-3 flex items-start justify-between gap-2">
        <div>
          <p class="text-sm font-semibold text-[#f1efe7] leading-snug">{title}</p>
          <p class="text-xs text-[#7a746e] mt-0.5">{typeLabel}</p>
        </div>
        {resolution && (
          <span class={[
            "shrink-0 rounded-full px-2 py-0.5 text-[0.7rem] font-medium",
            resolution === "local"
              ? "bg-[rgba(90,140,210,0.2)] text-[#8ab4f0]"
              : "bg-[rgba(100,180,90,0.2)] text-[#8ecf8e]",
          ].join(" ")}>
            {resolution === "local" ? "Keep local" : "Use AniList"}
          </span>
        )}
      </div>

      {/* Diff table */}
      <div class="mb-3 overflow-x-auto">
        <table class="w-full min-w-[280px]">
          <thead>
            <tr class="text-[0.68rem] text-[#5a5650] uppercase tracking-wide">
              <th class="pr-3 pb-2 text-left font-medium">Field</th>
              <th class="pr-3 pb-2 text-left font-medium">Local</th>
              <th class="pb-2 text-left font-medium">AniList</th>
            </tr>
          </thead>
          <tbody>
            <DiffRow label="Status"   local={statusLabel(conflict.localStatus)}            remote={statusLabel(conflict.remoteStatus)} />
            <DiffRow label="Score"    local={scoreLabel(conflict.localScore)}               remote={scoreLabel(conflict.remoteScore)} />
            <DiffRow label="Progress" local={String(conflict.localProgress)}                remote={String(conflict.remoteProgress)} />
            {(conflict.localNotes || conflict.remoteNotes) && (
              <DiffRow label="Notes" local={conflict.localNotes ?? "—"} remote={conflict.remoteNotes ?? "—"} />
            )}
          </tbody>
        </table>
      </div>

      {/* Choice buttons */}
      <div class="flex gap-2">
        <button
          class={[
            "flex-1 rounded-lg border py-1.5 text-xs font-medium transition-colors",
            resolution === "local"
              ? "border-[#6a9fd4]/60 bg-[rgba(90,140,210,0.15)] text-[#8ab4f0]"
              : "border-white/10 bg-white/4 text-[#b5b0a5] hover:border-[#6a9fd4]/40 hover:text-[#8ab4f0]",
          ].join(" ")}
          onClick={() => onChoose("local")}
        >
          Keep local
        </button>
        <button
          class={[
            "flex-1 rounded-lg border py-1.5 text-xs font-medium transition-colors",
            resolution === "remote"
              ? "border-[#6a9fd4]/60 bg-[rgba(100,180,90,0.15)] text-[#8ecf8e]"
              : "border-white/10 bg-white/4 text-[#b5b0a5] hover:border-[#88c57a]/40 hover:text-[#8ecf8e]",
          ].join(" ")}
          onClick={() => onChoose("remote")}
        >
          Use AniList
        </button>
      </div>
    </div>
  );
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

interface Props {
  onClose: (anyResolved: boolean) => void;
}

export function ConflictResolutionDialog({ onClose }: Props) {
  const [conflicts,    setConflicts]    = useState<PendingConflict[]>([]);
  const [resolutions,  setResolutions]  = useState<Record<number, "local" | "remote">>({});
  const [loading,      setLoading]      = useState(true);
  const [applying,     setApplying]     = useState(false);

  useEffect(() => {
    getPendingConflicts()
      .then(setConflicts)
      .finally(() => setLoading(false));
  }, []);

  function choose(mediaId: number, choice: "local" | "remote") {
    setResolutions((prev) => ({ ...prev, [mediaId]: choice }));
  }

  function resolveAll(choice: "local" | "remote") {
    const next: Record<number, "local" | "remote"> = {};
    for (const c of conflicts) next[c.mediaId] = choice;
    setResolutions(next);
  }

  async function applyResolutions() {
    const entries = Object.entries(resolutions);
    if (entries.length === 0) { onClose(false); return; }

    setApplying(true);
    try {
      await Promise.all(
        entries.map(([id, choice]) =>
          resolveConflict(Number(id), choice === "remote")
        )
      );
      onClose(true);
    } finally {
      setApplying(false);
    }
  }

  const resolvedCount = Object.keys(resolutions).length;
  const totalCount    = conflicts.length;
  const allResolved   = resolvedCount === totalCount && totalCount > 0;

  return (
    /* Backdrop */
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(false); }}
    >
      {/* Panel */}
      <div class="relative flex h-full max-h-[600px] w-full max-w-[520px] flex-col rounded-2xl border border-white/10 bg-[#1a1916] shadow-2xl">

        {/* Header */}
        <div class="flex items-center justify-between border-b border-white/8 px-5 py-4">
          <div>
            <h2 class="text-base font-semibold text-[#f1efe7]">Sync conflicts</h2>
            <p class="mt-0.5 text-xs text-[#7a746e]">
              {loading
                ? "Loading…"
                : `${totalCount} entr${totalCount === 1 ? "y" : "ies"} changed on both sides`}
            </p>
          </div>
          <button
            class="rounded-lg p-1.5 text-[#7a746e] transition hover:bg-white/6 hover:text-[#f1efe7]"
            onClick={() => onClose(false)}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        {/* Explanation */}
        <div class="px-5 pt-3 pb-2 text-xs text-[#7a746e] leading-relaxed">
          Both your local edits and AniList changes happened since the last sync.
          For each entry below, choose which version to keep.
          <span class="text-[#b5b0a5]"> "Keep local"</span> keeps your device copy and will push it to AniList.
          <span class="text-[#8ecf8e]"> "Use AniList"</span> overwrites your local copy with the AniList version.
        </div>

        {/* Bulk actions */}
        {!loading && totalCount > 1 && (
          <div class="flex gap-2 px-5 pb-2">
            <button
              class="flex-1 rounded-lg border border-white/8 bg-white/4 py-1 text-xs text-[#b5b0a5] transition hover:text-[#8ab4f0] hover:border-[#6a9fd4]/30"
              onClick={() => resolveAll("local")}
            >
              Keep all local
            </button>
            <button
              class="flex-1 rounded-lg border border-white/8 bg-white/4 py-1 text-xs text-[#b5b0a5] transition hover:text-[#8ecf8e] hover:border-[#88c57a]/30"
              onClick={() => resolveAll("remote")}
            >
              Use all from AniList
            </button>
          </div>
        )}

        {/* Conflict list */}
        <div class="flex-1 overflow-y-auto px-5 pb-2 flex flex-col gap-3">
          {loading && (
            <p class="py-6 text-center text-sm text-[#7a746e]">Loading conflicts…</p>
          )}
          {!loading && totalCount === 0 && (
            <p class="py-6 text-center text-sm text-[#7a746e]">No pending conflicts.</p>
          )}
          {conflicts.map((c) => (
            <ConflictCard
              key={c.mediaId}
              conflict={c}
              resolution={resolutions[c.mediaId] ?? null}
              onChoose={(choice) => choose(c.mediaId, choice)}
            />
          ))}
        </div>

        {/* Footer */}
        <div class="flex items-center justify-between border-t border-white/8 px-5 py-3">
          <span class="text-xs text-[#5a5650]">
            {resolvedCount}/{totalCount} resolved
          </span>
          <div class="flex gap-2">
            <button
              class="rounded-lg border border-white/10 bg-white/4 px-4 py-1.5 text-xs text-[#b5b0a5] transition hover:text-[#f1efe7]"
              onClick={() => onClose(false)}
              disabled={applying}
            >
              Cancel
            </button>
            <button
              class={[
                "rounded-lg px-4 py-1.5 text-xs font-medium transition",
                allResolved && !applying
                  ? "bg-[#5a7fa8] text-white hover:bg-[#6a8fb8]"
                  : "bg-white/8 text-[#5a5650] cursor-not-allowed",
              ].join(" ")}
              disabled={!allResolved || applying}
              onClick={applyResolutions}
            >
              {applying ? "Applying…" : "Apply resolutions"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
