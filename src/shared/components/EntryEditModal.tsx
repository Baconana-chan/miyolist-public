import { useEffect, useState } from "preact/hooks";
import { useBackHandler } from "../hooks/useBackHandler";
import {
  deleteListEntry,
  getFavorites,
  getNotificationOverrides,
  setDiscordHidden as setDiscordHiddenRpc,
  setNotificationOverride,
  toggleMediaFavorite,
  updateListEntry,
} from "../api/database";
import type { ListEntry } from "../types/app";
import { DropdownSelect } from "./DropdownSelect";
import { inputScoreToRaw, rawScoreToInput, scoreInputConfig } from "../scoreFormat";

const STATUS_OPTIONS = [
  { value: "current",   label: "Watching / Reading" },
  { value: "completed", label: "Completed"           },
  { value: "planning",  label: "Plan to watch/read"  },
  { value: "paused",    label: "On hold"             },
  { value: "dropped",   label: "Dropped"             },
  { value: "repeating", label: "Rewatching"          },
];

const inputCls = "w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-[0.9rem] text-[#f1efe7] placeholder-[#5a5650] focus:border-[#d97452]/60 focus:outline-none";

interface EntryEditModalProps {
  entry: ListEntry;
  scoreFormat?: string;
  customListNames?: string[];
  onCustomListNamesChange?: (names: string[]) => void;
  onClose: () => void;
  onSaved: () => void;
  /** Called after a successful delete. If omitted the modal just closes. */
  onDeleted?: () => void;
  isFavorite?: boolean;
  favoritePending?: boolean;
  onToggleFavorite?: () => void;
}

export function EntryEditModal({
  entry,
  scoreFormat = "POINT_10_DECIMAL",
  customListNames = [],
  onCustomListNamesChange,
  onClose,
  onSaved,
  onDeleted,
  isFavorite,
  favoritePending = false,
  onToggleFavorite,
}: EntryEditModalProps) {
  // System back-gesture / hardware back closes the modal instead of the app.
  useBackHandler(true, onClose);
  const isManga = entry.mediaType.toUpperCase() === "MANGA";
  const scoreCfg = scoreInputConfig(scoreFormat);

  const [status,          setStatus]          = useState(entry.status);
  const [score,           setScore]           = useState<string>(rawScoreToInput(entry.score, scoreFormat));
  const [progress,        setProgress]        = useState<string>(String(entry.progress));
  const [progressVolumes, setProgressVolumes] = useState<string>(String(entry.progressVolumes));
  const [repeatCount,     setRepeatCount]     = useState<string>(String(entry.repeatCount));
  const [startDate,       setStartDate]       = useState<string>(entry.startedAt ?? "");
  const [completedDate,   setCompletedDate]   = useState<string>(entry.completedAt ?? "");
  const [notes,           setNotes]           = useState<string>(entry.notes ?? "");
  const [selectedCustomLists, setSelectedCustomLists] = useState<string[]>(entry.customLists ?? []);
  const [localCustomListNames, setLocalCustomListNames] = useState<string[]>(
    Array.from(new Set([...(customListNames ?? []), ...((entry.customLists ?? []).filter(Boolean))])),
  );
  const [newCustomListName, setNewCustomListName] = useState("");
  const [saving,          setSaving]          = useState(false);
  const [deleting,        setDeleting]        = useState(false);
  const [error,           setError]           = useState<string | null>(null);
  const [localIsFavorite, setLocalIsFavorite] = useState<boolean>(isFavorite ?? false);
  const [localFavoritePending, setLocalFavoritePending] = useState(false);
  const [mangaMuted, setMangaMuted] = useState(false);
  const [discordHidden, setDiscordHidden] = useState(false);
  const [notifPending, setNotifPending] = useState(false);

  // Load the per-media notification override (manga release mute) and the
  // Discord privacy flag for this entry so the toggles start in the right state.
  useEffect(() => {
    let cancelled = false;
    getNotificationOverrides([entry.mediaId])
      .then((rows) => {
        if (cancelled) return;
        const row = rows.find((r) => r.mediaId === entry.mediaId);
        setMangaMuted(row ? !row.enabled : false);
        setDiscordHidden(row?.discordHidden ?? false);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [entry.mediaId]);

  async function handleToggleMangaMute() {
    if (notifPending) return;
    setNotifPending(true);
    setError(null);
    try {
      // Intentional flip: `enabled = 0` means muted (see is_manga_release_muted),
      // so passing the *current muted* state as `enabled` toggles it — do NOT
      // "simplify" this to `!mangaMuted`, that would keep the current state.
      await setNotificationOverride(entry.mediaId, mangaMuted);
      setMangaMuted((prev) => !prev);
    } catch (e) {
      setError(String(e));
    } finally {
      setNotifPending(false);
    }
  }

  async function handleToggleDiscordHidden() {
    if (notifPending) return;
    setNotifPending(true);
    setError(null);
    try {
      await setDiscordHiddenRpc(entry.mediaId, !discordHidden);
      setDiscordHidden((prev) => !prev);
    } catch (e) {
      setError(String(e));
    } finally {
      setNotifPending(false);
    }
  }

  useEffect(() => {
    setLocalCustomListNames((prev) =>
      Array.from(new Set([...prev, ...customListNames, ...((entry.customLists ?? []).filter(Boolean))])),
    );
  }, [customListNames, entry.customLists]);

  useEffect(() => {
    if (isFavorite != null) {
      setLocalIsFavorite(isFavorite);
      return;
    }

    let cancelled = false;
    getFavorites()
      .then((favorites) => {
        if (cancelled) return;
        const ids = isManga ? favorites.manga.map((item) => item.id) : favorites.anime.map((item) => item.id);
        setLocalIsFavorite(ids.includes(entry.mediaId));
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, [entry.mediaId, isFavorite, isManga]);

  async function handleToggleFavorite() {
    if (onToggleFavorite) {
      onToggleFavorite();
      return;
    }

    if (localFavoritePending) return;
    setLocalFavoritePending(true);
    setError(null);
    try {
      const nextFavorite = await toggleMediaFavorite(entry.mediaId, isManga ? "MANGA" : "ANIME");
      setLocalIsFavorite(nextFavorite);
    } catch (e) {
      setError(String(e));
    } finally {
      setLocalFavoritePending(false);
    }
  }

  async function handleSave() {
    setSaving(true);
    setError(null);
    try {
      await updateListEntry(
        entry.localId,
        entry.mediaId,
        status,
        inputScoreToRaw(score, scoreFormat),
        parseInt(progress, 10) || 0,
        isManga ? (parseInt(progressVolumes, 10) || 0) : 0,
        parseInt(repeatCount, 10) || 0,
        startDate.trim() !== "" ? startDate.trim() : null,
        completedDate.trim() !== "" ? completedDate.trim() : null,
        notes.trim() !== "" ? notes.trim() : null,
        selectedCustomLists,
      );
      onCustomListNamesChange?.(localCustomListNames);
      onSaved();
      onClose();
    } catch (e) {
      setError(String(e));
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!window.confirm(`Remove "${entry.title}" from your library? This cannot be undone.`)) return;
    setDeleting(true);
    setError(null);
    try {
      await deleteListEntry(entry.localId, entry.anilistEntryId);
      (onDeleted ?? onSaved)();
      onClose();
    } catch (e) {
      setError(String(e));
      setDeleting(false);
    }
  }

  const maxProgress = entry.episodesOrChapters;
  const progressLabel = isManga ? "Chapter" : "Episode";

  function toggleCustomList(name: string) {
    setSelectedCustomLists((prev) =>
      prev.includes(name)
        ? prev.filter((item) => item !== name)
        : [...prev, name],
    );
  }

  function handleAddCustomList() {
    const name = newCustomListName.trim();
    if (!name) return;
    const exists = localCustomListNames.some((n) => n.toLowerCase() === name.toLowerCase());
    if (exists) {
      setNewCustomListName("");
      return;
    }
    setLocalCustomListNames((prev) => [...prev, name]);
    setSelectedCustomLists((prev) => [...prev, name]);
    setNewCustomListName("");
  }

  return (
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div class="w-full max-w-md rounded-3xl border border-white/10 bg-[#1a1815] p-6 shadow-2xl max-h-[90dvh] overflow-y-auto">
        {/* Header */}
        <div class="flex items-start justify-between gap-3">
          <div class="flex min-w-0 items-center gap-3">
            {entry.coverImage && (
              <img
                src={entry.coverImage}
                alt=""
                class="h-14 w-10 shrink-0 rounded-lg object-cover"
              />
            )}
            <div class="min-w-0">
              <h2 class="truncate text-[1.05rem] font-bold text-[#f1efe7]">{entry.title}</h2>
              <p class="text-[0.78rem] text-[#7a766e]">{isManga ? "Manga" : "Anime"}</p>
            </div>
          </div>
          <div class="flex shrink-0 items-center gap-2">
            <button
              type="button"
              class={`rounded-full border px-3 py-1.5 text-[0.76rem] font-medium transition ${(isFavorite ?? localIsFavorite) ? "border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] text-[#f1efe7] hover:bg-[rgba(217,116,82,0.24)]" : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"}`}
              onClick={handleToggleFavorite}
              disabled={favoritePending || localFavoritePending}
            >
              {(favoritePending || localFavoritePending) ? "Updating…" : (isFavorite ?? localIsFavorite) ? "Remove favourite" : "Add favourite"}
            </button>
            <button
              class="rounded-full p-1.5 text-[#7a766e] transition hover:text-[#f1efe7]"
              onClick={onClose}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>
        </div>

        <div class="mt-5 space-y-4">
          {/* Status */}
          <div>
            <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">Status</label>
            <DropdownSelect
              options={STATUS_OPTIONS}
              value={status}
              onChange={setStatus}
              buttonClass={`${inputCls} flex items-center justify-between`}
              menuClass="w-full overflow-hidden rounded-xl border border-white/10 bg-[#161714] shadow-[-2px_8px_28px_rgba(0,0,0,0.45)]"
            />
          </div>

          {/* Progress + Score row */}
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">
                {progressLabel}{maxProgress ? ` / ${maxProgress}` : ""}
              </label>
              <input
                type="number" min="0" max={maxProgress ?? undefined}
                class={inputCls} value={progress}
                onInput={(e) => setProgress((e.target as HTMLInputElement).value)}
              />
            </div>
            <div>
              <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">
                {scoreCfg.label}
                {scoreCfg.hint ? ` · ${scoreCfg.hint}` : ""}
              </label>
              <input
                type="number" min={scoreCfg.min} max={scoreCfg.max} step={scoreCfg.step} placeholder="—"
                class={inputCls} value={score}
                onInput={(e) => setScore((e.target as HTMLInputElement).value)}
              />
            </div>
          </div>

          {/* Volume progress (manga/LN only) + Repeat count */}
          {isManga && (
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">
                  Volumes read
                </label>
                <input
                  type="number" min="0"
                  class={inputCls} value={progressVolumes}
                  onInput={(e) => setProgressVolumes((e.target as HTMLInputElement).value)}
                />
              </div>
              <div>
                <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">
                  {isManga ? "Times reread" : "Times rewatched"}
                </label>
                <input
                  type="number" min="0"
                  class={inputCls} value={repeatCount}
                  onInput={(e) => setRepeatCount((e.target as HTMLInputElement).value)}
                />
              </div>
            </div>
          )}
          {!isManga && (
            <div>
              <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">Times rewatched</label>
              <input
                type="number" min="0"
                class={inputCls} value={repeatCount}
                onInput={(e) => setRepeatCount((e.target as HTMLInputElement).value)}
              />
            </div>
          )}

          {/* Start date + Finish date */}
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">Start date</label>
              <input
                type="date"
                class={inputCls} value={startDate}
                onInput={(e) => setStartDate((e.target as HTMLInputElement).value)}
              />
            </div>
            <div>
              <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">Finish date</label>
              <input
                type="date"
                class={inputCls} value={completedDate}
                onInput={(e) => setCompletedDate((e.target as HTMLInputElement).value)}
              />
            </div>
          </div>

          {/* Notes */}
          <div>
            <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">Notes</label>
            <textarea
              rows={3}
              placeholder="Personal notes…"
              class="w-full resize-none rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-[0.9rem] text-[#f1efe7] placeholder-[#5a5650] focus:border-[#d97452]/60 focus:outline-none"
              value={notes}
              onInput={(e) => setNotes((e.target as HTMLTextAreaElement).value)}
            />
          </div>

          {/* Notifications & privacy */}
          {isManga && (
            <div>
              <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">
                Notifications
              </label>
              <button
                type="button"
                class={`flex w-full items-center justify-between gap-3 rounded-xl border px-3 py-2.5 text-left transition ${mangaMuted ? "border-white/8 bg-white/3" : "border-[rgba(217,116,82,0.3)] bg-[rgba(217,116,82,0.08)]"}`}
                onClick={handleToggleMangaMute}
                disabled={notifPending}
              >
                <span class="min-w-0">
                  <span class="block text-[0.85rem] font-medium text-[#e8e3dc]">
                    {mangaMuted ? "Muted" : "Notify about new chapters"}
                  </span>
                  <span class="block text-[0.7rem] text-[#7a746e]">
                    {mangaMuted
                      ? "Chapter-release alerts are turned off for this title."
                      : "Alerts for new chapters via the MangaUpdates release indexer."}
                  </span>
                </span>
                <span
                  class={`relative h-5 w-9 shrink-0 rounded-full transition ${mangaMuted ? "bg-white/15" : "bg-[#d97452]"}`}
                  aria-hidden="true"
                >
                  <span
                    class={`absolute top-0.5 h-4 w-4 rounded-full bg-[#f1efe7] transition-all ${mangaMuted ? "left-0.5" : "left-[1.05rem]"}`}
                  />
                </span>
              </button>
            </div>
          )}

          {/* Discord privacy (desktop) */}
          <div>
            <button
              type="button"
              class={`flex w-full items-center justify-between gap-3 rounded-xl border px-3 py-2.5 text-left transition ${discordHidden ? "border-[rgba(217,116,82,0.3)] bg-[rgba(217,116,82,0.08)]" : "border-white/8 bg-white/3"}`}
              onClick={handleToggleDiscordHidden}
              disabled={notifPending}
            >
              <span class="min-w-0">
                <span class="block text-[0.85rem] font-medium text-[#e8e3dc]">
                  {discordHidden ? "Hidden from Discord" : "Show in Discord presence"}
                </span>
                <span class="block text-[0.7rem] text-[#7a746e]">
                  {discordHidden
                    ? "This title stays out of your Discord Rich Presence."
                    : "Keep this title out of your Discord status (Rich Presence)."}
                </span>
              </span>
              <span
                class={`relative h-5 w-9 shrink-0 rounded-full transition ${discordHidden ? "bg-[#d97452]" : "bg-white/15"}`}
                aria-hidden="true"
              >
                <span
                  class={`absolute top-0.5 h-4 w-4 rounded-full bg-[#f1efe7] transition-all ${discordHidden ? "left-[1.05rem]" : "left-0.5"}`}
                />
              </span>
            </button>
          </div>

          {/* Custom lists */}
          <div>
            <label class="mb-2 block text-[0.8rem] font-medium text-[#9a9690]">Custom lists</label>
            <div class="mb-2 flex items-center gap-2">
              <input
                type="text"
                placeholder="Create new list"
                class={inputCls}
                value={newCustomListName}
                onInput={(e) => setNewCustomListName((e.target as HTMLInputElement).value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    handleAddCustomList();
                  }
                }}
              />
              <button
                class="shrink-0 rounded-xl border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-3 py-2.5 text-[0.78rem] font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)]"
                onClick={handleAddCustomList}
                type="button"
              >
                Add
              </button>
            </div>

            {localCustomListNames.length > 0 ? (
              <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
                {localCustomListNames.map((name) => (
                  <label key={name} class="flex items-center gap-2 rounded-lg border border-white/8 bg-white/3 px-2.5 py-2 text-[0.82rem] text-[#d0cbc2]">
                    <input
                      type="checkbox"
                      checked={selectedCustomLists.includes(name)}
                      onChange={() => toggleCustomList(name)}
                      class="h-3.5 w-3.5 rounded border-white/20 bg-transparent text-[#d97452] focus:ring-[#d97452]/40"
                    />
                    <span class="truncate" title={name}>{name}</span>
                  </label>
                ))}
              </div>
            ) : (
              <p class="text-[0.78rem] text-[#7a766e]">No custom lists yet. Create your first one above.</p>
            )}
          </div>

          {error && (
            <p class="rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2 text-[0.82rem] text-red-400">
              {error}
            </p>
          )}
        </div>

        {/* Delete */}
        <div class="mt-5 border-t border-white/5 pt-4">
          <button
            class="w-full rounded-full border border-red-500/30 px-4 py-2 text-[0.82rem] font-medium text-red-400 transition hover:bg-red-500/10 disabled:opacity-40"
            onClick={handleDelete}
            disabled={saving || deleting}
          >
            {deleting ? "Removing…" : "Remove from library"}
          </button>
        </div>

        {/* Save / Cancel */}
        <div class="mt-3 flex gap-2">
          <button
            class="flex-1 rounded-full border border-white/10 px-4 py-2.5 text-[0.88rem] font-medium text-[#7a766e] transition hover:border-white/20 hover:text-[#f1efe7]"
            onClick={onClose}
            disabled={saving || deleting}
          >
            Cancel
          </button>
          <button
            class="flex-1 rounded-full bg-[#d97452] px-4 py-2.5 text-[0.88rem] font-bold text-white transition hover:bg-[#e0875f] disabled:opacity-50"
            onClick={handleSave}
            disabled={saving || deleting}
          >
            {saving ? "Saving…" : "Save"}
          </button>
        </div>
      </div>
    </div>
  );
}

