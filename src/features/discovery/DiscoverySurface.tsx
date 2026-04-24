import { useCallback, useEffect, useState } from "preact/hooks";
import { addToLibrary, getTrendingMedia, searchMedia } from "../../shared/api/database";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";
import type { MediaSearchResult } from "../../shared/types/app";
import { useSideSheet } from "../../app/sideSheet";

function scoreClass(score: number | null) {
  if (score == null) return "text-[#7a766e]";
  if (score >= 75) return "text-[#8ecf8e]";
  if (score >= 55) return "text-[#d4b86a]";
  return "text-[#e08a8a]";
}

function formatLabel(format: string | null) {
  return format ? format.replace(/_/g, " ") : null;
}

function SectionRail({
  title,
  items,
  onOpen,
  onAdd,
  addingIds,
}: {
  title: string;
  items: MediaSearchResult[];
  onOpen: (mediaId: number) => void;
  onAdd: (item: MediaSearchResult) => void;
  addingIds: Set<number>;
}) {
  if (items.length === 0) return null;

  return (
    <section>
      <h2 class="mb-3 text-[0.75rem] font-bold uppercase tracking-[0.12em] text-[#7ca4be]">{title}</h2>
      <div class="-mx-6 overflow-x-auto overflow-y-hidden px-6 pb-2 [scrollbar-width:thin] [scrollbar-color:#2e2c29_transparent]">
        <div class="flex w-max gap-3 pr-6" style="touch-action: pan-x;">
          {items.map((item) => (
            <article
              key={item.mediaId}
              class="group relative flex w-42 shrink-0 cursor-pointer flex-col rounded-2xl border border-white/7 bg-white/3 p-2.5 transition hover:bg-white/5"
              onClick={() => onOpen(item.mediaId)}
            >
            {item.coverImage ? (
              <img
                src={item.coverImage}
                alt=""
                class="h-56 w-full rounded-xl object-cover"
                loading="lazy"
              />
            ) : (
              <div class="flex h-56 w-full items-center justify-center rounded-xl bg-white/8 text-xs text-[#7a766e]">
                No cover
              </div>
            )}

            <div class="mt-2 min-w-0">
              <p class="line-clamp-2 text-[0.85rem] font-semibold leading-snug text-[#f1efe7]">{item.title}</p>
              <div class="mt-1 flex items-center gap-1.5 text-[0.7rem] text-[#7a766e]">
                {formatLabel(item.format) && <span>{formatLabel(item.format)}</span>}
                {item.averageScore != null && (
                  <span class={scoreClass(item.averageScore)}>· ★ {item.averageScore / 10}</span>
                )}
              </div>
            </div>

            <div class="mt-2">
              {item.inLibrary ? (
                <span class="inline-flex rounded-full border border-[rgba(100,180,100,0.3)] bg-[rgba(100,180,100,0.12)] px-2.5 py-1 text-[0.7rem] font-medium text-[#8ecf8e]">
                  In library
                </span>
              ) : (
                <button
                  class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-2.5 py-1 text-[0.72rem] font-bold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.26)]"
                  onClick={(e) => {
                    e.stopPropagation();
                    onAdd(item);
                  }}
                  disabled={addingIds.has(item.mediaId)}
                >
                  {addingIds.has(item.mediaId) ? "Adding…" : "+ Add"}
                </button>
              )}
            </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

export function DiscoverySurface() {
  const sideSheet = useSideSheet();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [trendingAnime, setTrendingAnime] = useState<MediaSearchResult[]>([]);
  const [trendingManga, setTrendingManga] = useState<MediaSearchResult[]>([]);
  const [newAnime, setNewAnime] = useState<MediaSearchResult[]>([]);
  const [airingNow, setAiringNow] = useState<MediaSearchResult[]>([]);

  const [addingIds, setAddingIds] = useState<Set<number>>(new Set());
  const [openMediaId, setOpenMediaId] = useState<number | null>(null);

  const markInLibrary = useCallback((mediaId: number) => {
    const mark = (list: MediaSearchResult[]) =>
      list.map((item) => (item.mediaId === mediaId ? { ...item, inLibrary: true } : item));

    setTrendingAnime((prev) => mark(prev));
    setTrendingManga((prev) => mark(prev));
    setNewAnime((prev) => mark(prev));
    setAiringNow((prev) => mark(prev));
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [animeTrending, mangaTrending, animeNew, animeAiring] = await Promise.all([
        getTrendingMedia(1),
        searchMedia("", "MANGA", { sort: "TRENDING_DESC" }),
        searchMedia("", "ANIME", { sort: "START_DATE_DESC" }),
        searchMedia("", "ANIME", { statusFilter: "RELEASING", sort: "POPULARITY_DESC" }),
      ]);

      setTrendingAnime(animeTrending.slice(0, 10));
      setTrendingManga(mangaTrending.slice(0, 10));
      setNewAnime(animeNew.slice(0, 10));
      setAiringNow(animeAiring.slice(0, 10));
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    const onCloseOverlays = () => {
      if (openMediaId != null) {
        setOpenMediaId(null);
      }
    };

    window.addEventListener("miyolist:close-overlays", onCloseOverlays);
    return () => window.removeEventListener("miyolist:close-overlays", onCloseOverlays);
  }, [openMediaId]);

  const handleAdd = useCallback(async (item: MediaSearchResult) => {
    setAddingIds((prev) => new Set(prev).add(item.mediaId));
    try {
      await addToLibrary(
        item.mediaId,
        item.mediaType.toUpperCase(),
        "planning",
        item.title ?? null,
        item.coverImage ?? null,
      );
      markInLibrary(item.mediaId);
    } catch (e) {
      console.error("[discovery] add failed:", e);
    } finally {
      setAddingIds((prev) => {
        const next = new Set(prev);
        next.delete(item.mediaId);
        return next;
      });
    }
  }, [markInLibrary]);

  return (
    <div class="flex h-full flex-col">
      <header class="shrink-0 px-6 pt-7 pb-4">
        <p class="mb-0.5 text-[0.74rem] font-bold uppercase tracking-[0.16em] text-[#7ca4be]">Discovery</p>
        <h1 class="text-[2rem] font-bold leading-[1.05] tracking-[-0.03em] text-[#f1efe7]">Find your next watch</h1>
      </header>

      <div class="flex-1 overflow-y-auto px-6 pb-6">
        {error && (
          <div class="mb-4 rounded-xl border border-[rgba(210,80,80,0.28)] bg-[rgba(210,80,80,0.1)] px-4 py-3 text-sm text-[#e08a8a]">
            {error}
          </div>
        )}

        {loading ? (
          <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {Array.from({ length: 8 }).map((_, idx) => (
              <div key={idx} class="h-72 animate-pulse rounded-2xl border border-white/7 bg-white/3" />
            ))}
          </div>
        ) : (
          <div class="flex flex-col gap-7">
            <SectionRail
              title="Trending Anime"
              items={trendingAnime}
              onOpen={(id) => {
                if (sideSheet.isMultiPanel) sideSheet.openMedia(id);
                else setOpenMediaId(id);
              }}
              onAdd={handleAdd}
              addingIds={addingIds}
            />
            <SectionRail
              title="Trending Manga"
              items={trendingManga}
              onOpen={(id) => {
                if (sideSheet.isMultiPanel) sideSheet.openMedia(id);
                else setOpenMediaId(id);
              }}
              onAdd={handleAdd}
              addingIds={addingIds}
            />
            <SectionRail
              title="Newly Added Anime"
              items={newAnime}
              onOpen={(id) => {
                if (sideSheet.isMultiPanel) sideSheet.openMedia(id);
                else setOpenMediaId(id);
              }}
              onAdd={handleAdd}
              addingIds={addingIds}
            />
            <SectionRail
              title="Currently Airing"
              items={airingNow}
              onOpen={(id) => {
                if (sideSheet.isMultiPanel) sideSheet.openMedia(id);
                else setOpenMediaId(id);
              }}
              onAdd={handleAdd}
              addingIds={addingIds}
            />
          </div>
        )}
      </div>

      {!sideSheet.isMultiPanel && openMediaId != null && (
        <MediaDetailsPanel
          mediaId={openMediaId}
          onClose={() => setOpenMediaId(null)}
          onAdded={() => {
            markInLibrary(openMediaId);
          }}
        />
      )}
    </div>
  );
}
