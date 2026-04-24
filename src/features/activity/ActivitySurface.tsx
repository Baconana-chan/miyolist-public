import { useCallback, useEffect, useMemo, useRef, useState } from "preact/hooks";
import { openUrl } from "@tauri-apps/plugin-opener";
import { getFollowingActivity, getGlobalActivity, postActivity, saveActivityReply, toggleActivityLike } from "../../shared/api/database";
import { getViewer } from "../../shared/api/auth";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";
import { UserPanel } from "../people/UserPanel";
import { useSideSheet } from "../../app/sideSheet";
import { AnilistMarkdown } from "../../shared/components/AnilistMarkdown";
import type { FollowingActivityItem } from "../../shared/types/app";

type ActivityTab = "following" | "global";
type ActivityFilter = "all" | "status" | "messages" | "list";
const MAX_REPLY_LENGTH = 2200;
const MAX_STATUS_LENGTH = 2000;

const ACTIVITY_FILTERS: Array<{ id: ActivityFilter; label: string }> = [
  { id: "all", label: "All" },
  { id: "status", label: "Status" },
  { id: "messages", label: "Messages" },
  { id: "list", label: "List" },
];

const ACTIVITY_PAGE_SIZE = 25;
const ACTIVITY_CACHE_TTL_MS = 2 * 60 * 1000;

type ActivityFeedCache = {
  items: FollowingActivityItem[];
  page: number;
  hasMore: boolean;
  fetchedAt: number;
};

let FOLLOWING_FEED_CACHE: ActivityFeedCache | null = null;
let GLOBAL_FEED_CACHE: ActivityFeedCache | null = null;

function isFeedCacheFresh(fetchedAt: number): boolean {
  return Date.now() - fetchedAt < ACTIVITY_CACHE_TTL_MS;
}

function matchesActivityFilter(item: FollowingActivityItem, filter: ActivityFilter, tab: ActivityTab, viewerId: number | null): boolean {
  if (filter === "all") return true;
  if (filter === "list") {
    return item.activityType === "ANIME_LIST" || item.activityType === "MANGA_LIST";
  }
  if (filter === "status") {
    if (tab === "following") {
      return item.activityType === "TEXT" && !item.isMessage && viewerId != null && item.userId === viewerId;
    }
    return item.activityType === "TEXT" && !item.isMessage;
  }

  if (tab === "following") {
    return item.activityType === "TEXT" && (item.isMessage || viewerId == null || item.userId !== viewerId);
  }
  return item.activityType === "TEXT" && item.isMessage;
}

function titleCase(value: string | null): string | null {
  if (!value) return null;
  return value.replace(/_/g, " ").replace(/^\w/, (char) => char.toUpperCase());
}

function formatActivitySummary(item: FollowingActivityItem): string | null {
  if (item.activityType === "TEXT") return null;
  const status = titleCase(item.status) ?? (item.activityType === "MANGA_LIST" ? "Updated manga list" : "Updated anime list");
  const progress = item.progress ? ` ${item.progress}` : "";
  const title = item.mediaTitle ? ` of ${item.mediaTitle}` : "";
  return `${status}${progress}${title}`;
}

function ActionButton({
  label,
  title,
  onClick,
}: {
  label: string;
  title: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      class="inline-flex h-8 min-w-8 items-center justify-center rounded-lg border border-white/8 bg-white/4 px-2 text-[0.72rem] font-semibold text-[#b5b0a5] transition hover:border-white/14 hover:text-[#f1efe7]"
    >
      {label}
    </button>
  );
}

function ReplyComposer({
  busy,
  onCancel,
  onSubmit,
}: {
  busy: boolean;
  onCancel: () => void;
  onSubmit: (text: string) => Promise<void>;
}) {
  const [draft, setDraft] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const applyTransform = useCallback((transform: (selected: string) => string) => {
    const textarea = textareaRef.current;
    if (!textarea) return;
    const start = textarea.selectionStart ?? draft.length;
    const end = textarea.selectionEnd ?? draft.length;
    const selected = draft.slice(start, end);
    const inserted = transform(selected);
    const nextValue = `${draft.slice(0, start)}${inserted}${draft.slice(end)}`;
    setDraft(nextValue);
    queueMicrotask(() => {
      textarea.focus();
      const caret = start + inserted.length;
      textarea.setSelectionRange(caret, caret);
    });
  }, [draft]);

  const submit = async () => {
    const text = draft.trim();
    if (!text || text.length > MAX_REPLY_LENGTH || busy) return;
    await onSubmit(text);
    setDraft("");
  };

  return (
    <div class="mt-3 rounded-xl border border-white/10 bg-white/3 p-3">
      <div class="mb-2 flex flex-wrap items-center gap-1.5">
        <ActionButton label="B" title="Bold" onClick={() => applyTransform((s) => `__${s || "bold text"}__`)} />
        <ActionButton label="I" title="Italic" onClick={() => applyTransform((s) => `_${s || "italic text"}_`)} />
        <ActionButton label="S" title="Strikethrough" onClick={() => applyTransform((s) => `~~${s || "strikethrough"}~~`)} />
        <ActionButton label="Spoil" title="Spoiler" onClick={() => applyTransform((s) => `~!${s || "spoiler"}!~`)} />
        <ActionButton label="Link" title="Link" onClick={() => applyTransform((s) => `[${s || "text"}](https://)`)} />
        <ActionButton label="Img" title="Image" onClick={() => applyTransform(() => "img(https://example.com/image.jpg)")} />
        <ActionButton label="YT" title="YouTube" onClick={() => applyTransform(() => "youtube(dQw4w9WgXcQ)")} />
        <ActionButton label="•" title="Bullet list" onClick={() => applyTransform(() => "- item 1\n- item 2")} />
        <ActionButton label="1." title="Numbered list" onClick={() => applyTransform(() => "1. item 1\n2. item 2")} />
        <ActionButton label="H" title="Heading" onClick={() => applyTransform((s) => `# ${s || "Heading"}`)} />
        <ActionButton label="C" title="Centered text" onClick={() => applyTransform((s) => `~~~${s || "centered text"}~~~`)} />
        <ActionButton label='"' title="Quote" onClick={() => applyTransform((s) => `> ${s || "quote"}`)} />
        <ActionButton label="</>" title="Code block" onClick={() => applyTransform(() => "```\ncode\n```")} />
      </div>

      <textarea
        ref={textareaRef}
        rows={5}
        maxLength={MAX_REPLY_LENGTH}
        value={draft}
        placeholder="Write a reply..."
        class="w-full resize-none rounded-xl border border-white/10 bg-[#171512] px-3 py-2.5 text-[0.88rem] text-[#f1efe7] placeholder-[#7a766e] outline-none transition focus:border-[rgba(217,116,82,0.45)]"
        onInput={(e) => setDraft((e.currentTarget as HTMLTextAreaElement).value)}
      />

      <div class="mt-3 flex items-center justify-between gap-3">
        <button
          type="button"
          class="text-[0.76rem] text-[#b7aea1] underline underline-offset-2 hover:text-[#e7e1d6]"
          onClick={() => void openUrl("https://anilist.co/forum/thread/14")}
        >
          Please read the site guidelines before posting
        </button>

        <div class="flex items-center gap-2">
          <span class={`text-[0.72rem] ${draft.length > MAX_REPLY_LENGTH ? "text-[#e08a8a]" : "text-[#7a766e]"}`}>
            {draft.length}/{MAX_REPLY_LENGTH}
          </span>
          <button
            type="button"
            class="rounded-full border border-white/10 bg-white/4 px-3 py-1.5 text-[0.78rem] font-semibold text-[#b5b0a5] transition hover:text-[#f1efe7]"
            onClick={onCancel}
            disabled={busy}
          >
            Cancel
          </button>
          <button
            type="button"
            class="rounded-full border border-[rgba(217,116,82,0.4)] bg-[rgba(217,116,82,0.2)] px-3 py-1.5 text-[0.78rem] font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.3)] disabled:opacity-50"
            onClick={() => void submit()}
            disabled={busy || draft.trim().length === 0 || draft.length > MAX_REPLY_LENGTH}
          >
            {busy ? "Publishing…" : "Publish"}
          </button>
        </div>
      </div>
    </div>
  );
}

function StatusComposer({
  busy,
  onCancel,
  onSubmit,
}: {
  busy: boolean;
  onCancel: () => void;
  onSubmit: (text: string) => Promise<void>;
}) {
  const [draft, setDraft] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const applyTransform = useCallback((transform: (selected: string) => string) => {
    const textarea = textareaRef.current;
    if (!textarea) return;
    const start = textarea.selectionStart ?? draft.length;
    const end = textarea.selectionEnd ?? draft.length;
    const selected = draft.slice(start, end);
    const inserted = transform(selected);
    const nextValue = `${draft.slice(0, start)}${inserted}${draft.slice(end)}`;
    setDraft(nextValue);
    queueMicrotask(() => {
      textarea.focus();
      const caret = start + inserted.length;
      textarea.setSelectionRange(caret, caret);
    });
  }, [draft]);

  const submit = async () => {
    const text = draft.trim();
    if (!text || text.length > MAX_STATUS_LENGTH || busy) return;
    await onSubmit(text);
    setDraft("");
  };

  return (
    <div class="mb-4 rounded-xl border border-white/10 bg-white/3 p-3">
      <div class="mb-2 flex flex-wrap items-center gap-1.5">
        <ActionButton label="B" title="Bold" onClick={() => applyTransform((s) => `__${s || "bold text"}__`)} />
        <ActionButton label="I" title="Italic" onClick={() => applyTransform((s) => `_${s || "italic text"}_`)} />
        <ActionButton label="S" title="Strikethrough" onClick={() => applyTransform((s) => `~~${s || "strikethrough"}~~`)} />
        <ActionButton label="Spoil" title="Spoiler" onClick={() => applyTransform((s) => `~!${s || "spoiler"}!~`)} />
        <ActionButton label="Link" title="Link" onClick={() => applyTransform((s) => `[${s || "text"}](https://)`)} />
        <ActionButton label="Img" title="Image" onClick={() => applyTransform(() => "img(https://example.com/image.jpg)")} />
        <ActionButton label="YT" title="YouTube" onClick={() => applyTransform(() => "youtube(dQw4w9WgXcQ)")} />
        <ActionButton label="•" title="Bullet list" onClick={() => applyTransform(() => "- item 1\n- item 2")} />
        <ActionButton label="1." title="Numbered list" onClick={() => applyTransform(() => "1. item 1\n2. item 2")} />
        <ActionButton label="H" title="Heading" onClick={() => applyTransform((s) => `# ${s || "Heading"}`)} />
        <ActionButton label="C" title="Centered text" onClick={() => applyTransform((s) => `~~~${s || "centered text"}~~~`)} />
        <ActionButton label='"' title="Quote" onClick={() => applyTransform((s) => `> ${s || "quote"}`)} />
        <ActionButton label="</>" title="Code block" onClick={() => applyTransform(() => "```\ncode\n```")} />
      </div>

      <textarea
        ref={textareaRef}
        rows={5}
        maxLength={MAX_STATUS_LENGTH}
        value={draft}
        placeholder="Write a status..."
        class="w-full resize-none rounded-xl border border-white/10 bg-[#171512] px-3 py-2.5 text-[0.88rem] text-[#f1efe7] placeholder-[#7a766e] outline-none transition focus:border-[rgba(217,116,82,0.45)]"
        onInput={(e) => setDraft((e.currentTarget as HTMLTextAreaElement).value)}
      />

      <div class="mt-3 flex items-center justify-between gap-3">
        <button
          type="button"
          class="text-[0.76rem] text-[#b7aea1] underline underline-offset-2 hover:text-[#e7e1d6]"
          onClick={() => void openUrl("https://anilist.co/forum/thread/14")}
        >
          Please read the site guidelines before posting
        </button>

        <div class="flex items-center gap-2">
          <span class={`text-[0.72rem] ${draft.length > MAX_STATUS_LENGTH ? "text-[#e08a8a]" : "text-[#7a766e]"}`}>
            {draft.length}/{MAX_STATUS_LENGTH}
          </span>
          <button
            type="button"
            class="rounded-full border border-white/10 bg-white/4 px-3 py-1.5 text-[0.78rem] font-semibold text-[#b5b0a5] transition hover:text-[#f1efe7]"
            onClick={onCancel}
            disabled={busy}
          >
            Cancel
          </button>
          <button
            type="button"
            class="rounded-full border border-[rgba(217,116,82,0.4)] bg-[rgba(217,116,82,0.2)] px-3 py-1.5 text-[0.78rem] font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.3)] disabled:opacity-50"
            onClick={() => void submit()}
            disabled={busy || draft.trim().length === 0 || draft.length > MAX_STATUS_LENGTH}
          >
            {busy ? "Posting…" : "Post"}
          </button>
        </div>
      </div>
    </div>
  );
}

export function ActivitySurface() {
  const sideSheet = useSideSheet();
  const [tab, setTab] = useState<ActivityTab>("following");
  const [followingItems, setFollowingItems] = useState<FollowingActivityItem[]>([]);
  const [globalItems, setGlobalItems] = useState<FollowingActivityItem[]>([]);
  const [followingPage, setFollowingPage] = useState(1);
  const [globalPage, setGlobalPage] = useState(1);
  const [followingHasMore, setFollowingHasMore] = useState(true);
  const [globalHasMore, setGlobalHasMore] = useState(true);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [openMediaId, setOpenMediaId] = useState<number | null>(null);
  const [openUserName, setOpenUserName] = useState<string | null>(null);
  const [likeBusyIds, setLikeBusyIds] = useState<number[]>([]);
  const [replyBusyIds, setReplyBusyIds] = useState<number[]>([]);
  const [replyingToId, setReplyingToId] = useState<number | null>(null);
  const [showStatusComposer, setShowStatusComposer] = useState(false);
  const [postingStatus, setPostingStatus] = useState(false);
  const [viewerId, setViewerId] = useState<number | null>(null);
  const [activityFilter, setActivityFilter] = useState<ActivityFilter>("all");

  const activeItems = tab === "following" ? followingItems : globalItems;
  const activePage = tab === "following" ? followingPage : globalPage;
  const activeHasMore = tab === "following" ? followingHasMore : globalHasMore;

  const applyItemUpdate = useCallback((updater: (item: FollowingActivityItem) => FollowingActivityItem) => {
    setFollowingItems((prev) => prev.map(updater));
    setGlobalItems((prev) => prev.map(updater));
  }, []);

  const loadActivityFeed = useCallback(async (
    targetTab: ActivityTab,
    options: { refresh?: boolean; loadMore?: boolean } = {},
  ) => {
    const { refresh = false, loadMore = false } = options;
    const cache = targetTab === "following" ? FOLLOWING_FEED_CACHE : GLOBAL_FEED_CACHE;

    if (!refresh && !loadMore && cache && isFeedCacheFresh(cache.fetchedAt)) {
      if (targetTab === "following") {
        setFollowingItems(cache.items);
        setFollowingPage(cache.page);
        setFollowingHasMore(cache.hasMore);
      } else {
        setGlobalItems(cache.items);
        setGlobalPage(cache.page);
        setGlobalHasMore(cache.hasMore);
      }
      setError(null);
      setLoading(false);
      return;
    }

    const currentItems = targetTab === "following" ? followingItems : globalItems;
    const currentPage = targetTab === "following" ? followingPage : globalPage;
    const pageToLoad = loadMore ? currentPage + 1 : 1;

    if (loadMore) {
      setLoadingMore(true);
    } else {
      setLoading(true);
    }
    setError(null);

    try {
      const fetched = targetTab === "following"
        ? await getFollowingActivity(pageToLoad, ACTIVITY_PAGE_SIZE)
        : await getGlobalActivity(pageToLoad, ACTIVITY_PAGE_SIZE);
      const hasMore = fetched.length >= ACTIVITY_PAGE_SIZE;
      const nextItems = loadMore ? [...currentItems, ...fetched] : fetched;

      if (targetTab === "following") {
        setFollowingItems(nextItems);
        setFollowingPage(pageToLoad);
        setFollowingHasMore(hasMore);
        FOLLOWING_FEED_CACHE = {
          items: nextItems,
          page: pageToLoad,
          hasMore,
          fetchedAt: Date.now(),
        };
      } else {
        setGlobalItems(nextItems);
        setGlobalPage(pageToLoad);
        setGlobalHasMore(hasMore);
        GLOBAL_FEED_CACHE = {
          items: nextItems,
          page: pageToLoad,
          hasMore,
          fetchedAt: Date.now(),
        };
      }
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [followingItems, globalItems, followingPage, globalPage]);

  useEffect(() => {
    void getViewer()
      .then((viewer) => setViewerId(viewer.id))
      .catch(() => setViewerId(null));
  }, []);

  useEffect(() => {
    setError(null);
    setReplyingToId(null);
    if (tab === "following" && followingItems.length > 0) {
      setLoading(false);
      return;
    }
    if (tab === "global" && globalItems.length > 0) {
      setLoading(false);
      return;
    }
    void loadActivityFeed(tab);
  }, [tab, followingItems.length, globalItems.length, loadActivityFeed]);

  const handleToggleLike = useCallback(async (activityId: number) => {
    setLikeBusyIds((prev) => (prev.includes(activityId) ? prev : [...prev, activityId]));
    try {
      const isLiked = await toggleActivityLike(activityId);
      applyItemUpdate((item) => {
        if (item.id !== activityId) return item;
        const currentLikes = item.likeCount;
        return {
          ...item,
          isLiked,
          likeCount: isLiked
            ? currentLikes + (item.isLiked ? 0 : 1)
            : Math.max(0, currentLikes - (item.isLiked ? 1 : 0)),
        };
      });
    } catch (e) {
      setError(String(e));
    } finally {
      setLikeBusyIds((prev) => prev.filter((id) => id !== activityId));
    }
  }, [applyItemUpdate]);

  const handleReplySubmit = useCallback(async (activityId: number, text: string) => {
    setReplyBusyIds((prev) => (prev.includes(activityId) ? prev : [...prev, activityId]));
    try {
      await saveActivityReply(activityId, text);
      applyItemUpdate((item) => item.id === activityId ? { ...item, replyCount: item.replyCount + 1 } : item);
      setReplyingToId(null);
    } catch (e) {
      setError(String(e));
    } finally {
      setReplyBusyIds((prev) => prev.filter((id) => id !== activityId));
    }
  }, [applyItemUpdate]);

  const handleStatusSubmit = useCallback(async (text: string) => {
    setPostingStatus(true);
    try {
      await postActivity(text);
      setShowStatusComposer(false);
      FOLLOWING_FEED_CACHE = null;
      await loadActivityFeed("following", { refresh: true });
      if (tab !== "following") setTab("following");
    } catch (e) {
      setError(String(e));
    } finally {
      setPostingStatus(false);
    }
  }, [loadActivityFeed, tab]);

  const visibleItems = useMemo(() => {
    return activeItems.filter((item) => matchesActivityFilter(item, activityFilter, tab, viewerId));
  }, [activeItems, activityFilter, tab, viewerId]);

  const openUserPanel = (name: string) => {
    if (sideSheet.isMultiPanel) {
      sideSheet.openUser(name, 2);
      return;
    }
    setOpenUserName(name);
  };

  return (
    <div class="flex h-full flex-col">
      <header class="shrink-0 px-6 pt-7 pb-4">
        <p class="mb-0.5 text-[0.74rem] font-bold uppercase tracking-[0.16em] text-[#7ca4be]">Activity</p>
        <h1 class="text-[2rem] font-bold leading-[1.05] tracking-[-0.03em] text-[#f1efe7]">AniList feed</h1>

        <div class="mt-3 flex flex-wrap items-center gap-2">
          <div class="inline-flex rounded-full border border-white/10 bg-white/4 p-0.5">
            <button
              class={`rounded-full px-3 py-1 text-[0.75rem] font-semibold ${tab === "following" ? "bg-[#d97452] text-white" : "text-[#9a9690]"}`}
              onClick={() => setTab("following")}
            >
              Following
            </button>
            <button
              class={`rounded-full px-3 py-1 text-[0.75rem] font-semibold ${tab === "global" ? "bg-[#d97452] text-white" : "text-[#9a9690]"}`}
              onClick={() => setTab("global")}
            >
              Global
            </button>
          </div>

          <div class="inline-flex rounded-full border border-white/10 bg-white/4 p-0.5">
            {ACTIVITY_FILTERS.map((filter) => (
              <button
                key={filter.id}
                class={`rounded-full px-2.5 py-1 text-[0.72rem] font-semibold ${activityFilter === filter.id ? "bg-[#4e95c3] text-white" : "text-[#9a9690]"}`}
                onClick={() => setActivityFilter(filter.id)}
              >
                {filter.label}
              </button>
            ))}
          </div>

          {tab === "following" && (
            <button
              class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.14)] px-3 py-1 text-[0.72rem] font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)]"
              onClick={() => setShowStatusComposer((prev) => !prev)}
            >
              {showStatusComposer ? "Close" : "Write a status"}
            </button>
          )}

          <button
            class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-3 py-1 text-[0.72rem] font-semibold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.24)]"
            onClick={() => void loadActivityFeed(tab, { refresh: true })}
            disabled={loading || loadingMore}
          >
            Refresh
          </button>
        </div>
      </header>

      <div class="flex-1 overflow-y-auto px-6 pb-6">
        {error && (
          <div class="mb-4 rounded-xl border border-[rgba(210,80,80,0.28)] bg-[rgba(210,80,80,0.1)] px-4 py-3 text-sm text-[#e08a8a]">
            {error}
          </div>
        )}

        {tab === "following" && showStatusComposer && (
          <StatusComposer
            busy={postingStatus}
            onCancel={() => setShowStatusComposer(false)}
            onSubmit={handleStatusSubmit}
          />
        )}

        {loading ? (
          <div class="flex h-40 items-center justify-center text-sm text-[#7a766e]">
            {tab === "following" ? "Loading following activity…" : "Loading global activity…"}
          </div>
        ) : visibleItems.length === 0 ? (
          <div class="rounded-xl border border-white/10 bg-white/3 px-4 py-4 text-sm text-[#9a9690]">
            No activity for this filter yet.
          </div>
        ) : (
          <>
            <div class="flex flex-col gap-2.5">
              {visibleItems.map((item) => (
                <article key={`${tab}-${item.id}`} class="rounded-xl border border-white/8 bg-white/3 p-3">
                  <div class="flex items-center gap-2.5">
                    <button
                      type="button"
                      class="flex min-w-0 flex-1 items-center gap-2.5 text-left"
                      onClick={() => openUserPanel(item.userName)}
                    >
                      {item.userAvatar ? (
                        <img src={item.userAvatar} alt={item.userName} class="h-8 w-8 rounded-lg object-cover" />
                      ) : (
                        <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-white/8 text-xs font-bold text-[#d97452]">
                          {item.userName[0]?.toUpperCase() ?? "?"}
                        </div>
                      )}
                      <div class="min-w-0 flex-1">
                        <p class="truncate text-[0.82rem] font-semibold text-[#ece7dc] transition hover:text-[#9ec0de]">{item.userName}</p>
                        <p class="text-[0.68rem] text-[#7a766e]">{new Date(item.createdAt * 1000).toLocaleString()}</p>
                      </div>
                    </button>
                  </div>

                  {formatActivitySummary(item) && (
                    <p class="mt-2 text-[0.82rem] font-medium text-[#e7e1d6]">{formatActivitySummary(item)}</p>
                  )}

                  {item.text && (
                    <div class="mt-2 text-[0.82rem] leading-relaxed text-[#c4beb1]">
                      <AnilistMarkdown text={item.text} />
                    </div>
                  )}

                  {item.mediaId != null && (
                    <button
                      class="mt-2 flex items-center gap-2 rounded-lg border border-white/10 bg-white/4 px-2 py-1.5 text-left transition hover:bg-white/8"
                      onClick={() => setOpenMediaId(item.mediaId!)}
                    >
                      {item.mediaCoverImage ? (
                        <img src={item.mediaCoverImage} alt="" class="h-10 w-7 rounded object-cover" />
                      ) : (
                        <div class="h-10 w-7 rounded bg-white/10" />
                      )}
                      <div class="min-w-0 flex-1">
                        <p class="truncate text-[0.8rem] text-[#e7e1d6]">{item.mediaTitle ?? `Media #${item.mediaId}`}</p>
                        <p class="text-[0.68rem] text-[#7a766e]">{item.status ?? item.activityType.replace(/_/g, " ")}</p>
                      </div>
                    </button>
                  )}

                  <div class="mt-3 flex items-center gap-3">
                    <button
                      type="button"
                      class={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[0.74rem] font-semibold transition ${item.isLiked ? "bg-[rgba(220,80,110,0.18)] text-[#f49ab1]" : "bg-white/4 text-[#9a9690] hover:text-[#f1efe7]"}`}
                      onClick={() => void handleToggleLike(item.id)}
                      disabled={likeBusyIds.includes(item.id)}
                    >
                      <span>{item.isLiked ? "♥" : "♡"}</span>
                      <span>{item.likeCount}</span>
                    </button>

                    <button
                      type="button"
                      class="inline-flex items-center gap-1.5 rounded-full bg-white/4 px-2.5 py-1 text-[0.74rem] font-semibold text-[#9a9690] transition hover:text-[#f1efe7]"
                      onClick={() => setReplyingToId((current) => current === item.id ? null : item.id)}
                    >
                      <span>💬</span>
                      <span>{item.replyCount}</span>
                    </button>
                  </div>

                  {replyingToId === item.id && (
                    <ReplyComposer
                      busy={replyBusyIds.includes(item.id)}
                      onCancel={() => setReplyingToId(null)}
                      onSubmit={(text) => handleReplySubmit(item.id, text)}
                    />
                  )}

                  {item.replies.length > 0 && (
                    <div class="mt-3 space-y-2 rounded-xl border border-white/8 bg-white/3 p-2.5">
                      <p class="text-[0.7rem] font-semibold uppercase tracking-[0.12em] text-[#7ca4be]">Replies</p>
                      {item.replies.map((reply) => (
                        <div key={reply.id} class="rounded-lg border border-white/8 bg-[#171512] p-2">
                          <button
                            type="button"
                            class="mb-1 flex min-w-0 items-center gap-2 text-left"
                            onClick={() => openUserPanel(reply.userName)}
                          >
                            {reply.userAvatar ? (
                              <img src={reply.userAvatar} alt={reply.userName} class="h-6 w-6 rounded-md object-cover" />
                            ) : (
                              <div class="flex h-6 w-6 items-center justify-center rounded-md bg-white/8 text-[0.62rem] font-bold text-[#d97452]">
                                {reply.userName[0]?.toUpperCase() ?? "?"}
                              </div>
                            )}
                            <div class="min-w-0">
                              <p class="truncate text-[0.75rem] font-semibold text-[#ece7dc]">{reply.userName}</p>
                              <p class="text-[0.66rem] text-[#7a766e]">{new Date(reply.createdAt * 1000).toLocaleString()}</p>
                            </div>
                          </button>
                          {reply.text && (
                            <div class="text-[0.8rem] leading-relaxed text-[#c4beb1]">
                              <AnilistMarkdown text={reply.text} />
                            </div>
                          )}
                        </div>
                      ))}
                      {item.replyCount > item.replies.length && (
                        <p class="text-[0.68rem] text-[#7a766e]">
                          Showing {item.replies.length} of {item.replyCount} replies.
                        </p>
                      )}
                    </div>
                  )}
                </article>
              ))}
            </div>

            {activeHasMore && (
              <div class="mt-4 flex justify-center">
                <button
                  type="button"
                  class="rounded-full border border-white/10 bg-white/4 px-4 py-1.5 text-[0.78rem] font-semibold text-[#c8c4bc] transition hover:text-[#f1efe7] disabled:opacity-60"
                  disabled={loadingMore}
                  onClick={() => void loadActivityFeed(tab, { loadMore: true })}
                >
                  {loadingMore ? "Loading more…" : `Load more (${activePage})`}
                </button>
              </div>
            )}
          </>
        )}
      </div>

      {openMediaId != null && (
        <MediaDetailsPanel mediaId={openMediaId} onClose={() => setOpenMediaId(null)} />
      )}
      {!sideSheet.isMultiPanel && openUserName != null && (
        <UserPanel username={openUserName} onClose={() => setOpenUserName(null)} />
      )}
    </div>
  );
}
