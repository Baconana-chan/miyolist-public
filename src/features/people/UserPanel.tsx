import { useState, useEffect, useMemo } from "preact/hooks";
import { useBackHandler } from "../../shared/hooks/useBackHandler";
import { openUrl } from "@tauri-apps/plugin-opener";
import {
  getAuthSessionStatus,
  getCharacterDetails,
  getFollowers,
  getFollowing,
  getMediaDetails,
  getStaffDetails,
  getUserMediaList,
  getUserProfile,
  toggleFollow,
} from "../../shared/api/database";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";
import { CharacterPanel } from "./CharacterPanel";
import { StaffPanel } from "./StaffPanel";
import { StudioPanel } from "./StudioPanel";
import { AnilistMarkdown, anilistPlainText } from "../../shared/components/AnilistMarkdown";
import { KaomojiLoadingText, PanelSkeleton } from "../../shared/components/Skeleton";
import type {
  CharacterDetails,
  MediaDetails,
  SocialUser,
  StaffDetails,
  UserMediaListItem,
  UserProfile,
} from "../../shared/types/app";

const USER_PROFILE_TTL_MS = 5 * 60 * 1000;
const USER_SOCIAL_TTL_MS = 3 * 60 * 1000;
const USER_LIST_TTL_MS = 2 * 60 * 1000;
const LINK_CARD_TTL_MS = 15 * 60 * 1000;

type Cached<T> = {
  data: T;
  fetchedAt: number;
};

const USER_PROFILE_CACHE = new Map<string, Cached<UserProfile>>();
const USER_FOLLOWING_CACHE = new Map<number, Cached<SocialUser[]>>();
const USER_FOLLOWERS_CACHE = new Map<number, Cached<SocialUser[]>>();
const USER_LIST_CACHE = new Map<string, Cached<UserMediaListItem[]>>();
const LINK_MEDIA_CACHE = new Map<number, Cached<MediaDetails>>();
const LINK_CHARACTER_CACHE = new Map<number, Cached<CharacterDetails>>();
const LINK_STAFF_CACHE = new Map<number, Cached<StaffDetails>>();

function isFresh(fetchedAt: number, ttlMs: number): boolean {
  return Date.now() - fetchedAt < ttlMs;
}

function prettyEnum(v: string | null | undefined): string | null {
  if (!v) return null;
  return v
    .toLowerCase()
    .replace(/_/g, " ")
    .replace(/^\w/, (c) => c.toUpperCase());
}

function parseAniListMediaUrl(url: string): { mediaId: number } | null {
  try {
    const u = new URL(url);
    if (!(u.hostname === "anilist.co" || u.hostname.endsWith(".anilist.co"))) return null;
    const parts = u.pathname.split("/").filter(Boolean);
    if (parts.length < 2) return null;
    if (parts[0] !== "anime" && parts[0] !== "manga") return null;
    const mediaId = Number(parts[1]);
    return Number.isFinite(mediaId) ? { mediaId } : null;
  } catch {
    return null;
  }
}

function parseAniListCharacterOrStaffUrl(url: string): { kind: "character" | "staff"; id: number } | null {
  try {
    const u = new URL(url);
    if (!(u.hostname === "anilist.co" || u.hostname.endsWith(".anilist.co"))) return null;
    const parts = u.pathname.split("/").filter(Boolean);
    if (parts.length < 2) return null;
    const kind = parts[0];
    const id = Number(parts[1]);
    if (!Number.isFinite(id)) return null;
    if (kind !== "character" && kind !== "staff") return null;
    return { kind, id };
  } catch {
    return null;
  }
}

function parseAniListSearchUrl(url: string): { label: string } | null {
  try {
    const u = new URL(url);
    if (!(u.hostname === "anilist.co" || u.hostname.endsWith(".anilist.co"))) return null;
    const parts = u.pathname.split("/").filter(Boolean);
    if (parts.length < 2 || parts[0] !== "search") return null;

    const genres = u.searchParams.get("genres");
    const tags = u.searchParams.get("tags");
    const q = u.searchParams.get("search");

    if (genres) return { label: `Genre: ${genres}` };
    if (tags) return { label: `Tag: ${tags}` };
    if (q) return { label: `Search: ${q}` };
    return { label: "Open AniList search" };
  } catch {
    return null;
  }
}

function AniListMediaLinkCard({
  url,
  label,
  onOpenMedia,
}: {
  url: string;
  label: string;
  onOpenMedia: (mediaId: number) => void;
}) {
  const parsed = parseAniListMediaUrl(url);
  const [details, setDetails] = useState<MediaDetails | null>(null);

  useEffect(() => {
    if (!parsed) return;
    const cached = LINK_MEDIA_CACHE.get(parsed.mediaId);
    if (cached && isFresh(cached.fetchedAt, LINK_CARD_TTL_MS)) {
      setDetails(cached.data);
      return;
    }
    getMediaDetails(parsed.mediaId)
      .then((value) => {
        setDetails(value);
        LINK_MEDIA_CACHE.set(parsed.mediaId, { data: value, fetchedAt: Date.now() });
      })
      .catch(() => setDetails(null));
  }, [parsed?.mediaId]);

  if (!parsed) return null;

  const title = details?.titleEnglish ?? details?.titleRomaji ?? label;
  const meta = [
    prettyEnum(details?.format),
    prettyEnum(details?.status),
    details?.seasonYear ? String(details.seasonYear) : null,
    details?.averageScore != null ? `${details.averageScore}%` : null,
  ]
    .filter(Boolean)
    .join(" · ");

  return (
    <button
      class="my-1 flex w-full max-w-[20rem] items-center gap-2.5 rounded-md border border-[#2a4060] bg-[#091a2c] p-2 text-left transition hover:border-[#3f5f86] hover:bg-[#0d2238]"
      onClick={() => onOpenMedia(parsed.mediaId)}
      title="Open in app"
    >
      {details?.coverImage ? (
        <img src={details.coverImage} alt="" class="h-14 w-10 shrink-0 rounded object-cover" />
      ) : (
        <div class="h-14 w-10 shrink-0 rounded bg-[#15314e]" />
      )}
      <div class="min-w-0">
        <p class="truncate text-[0.86rem] font-semibold text-[#ff7ac3]">{title}</p>
        {meta && <p class="truncate text-[0.76rem] text-[#8db0cf]">{meta}</p>}
      </div>
    </button>
  );
}

function AniListPersonLinkCard({
  url,
  label,
  onOpenCharacter,
  onOpenStaff,
}: {
  url: string;
  label: string;
  onOpenCharacter: (id: number) => void;
  onOpenStaff: (id: number) => void;
}) {
  const parsed = parseAniListCharacterOrStaffUrl(url);
  const [details, setDetails] = useState<CharacterDetails | StaffDetails | null>(null);

  useEffect(() => {
    if (!parsed) return;
    if (parsed.kind === "character") {
      const cachedCharacter = LINK_CHARACTER_CACHE.get(parsed.id);
      if (cachedCharacter && isFresh(cachedCharacter.fetchedAt, LINK_CARD_TTL_MS)) {
        setDetails(cachedCharacter.data);
        return;
      }
      getCharacterDetails(parsed.id)
        .then((value) => {
          setDetails(value);
          LINK_CHARACTER_CACHE.set(parsed.id, { data: value, fetchedAt: Date.now() });
        })
        .catch(() => setDetails(null));
      return;
    }

    const cachedStaff = LINK_STAFF_CACHE.get(parsed.id);
    if (cachedStaff && isFresh(cachedStaff.fetchedAt, LINK_CARD_TTL_MS)) {
      setDetails(cachedStaff.data);
      return;
    }

    getStaffDetails(parsed.id)
      .then((value) => {
        setDetails(value);
        LINK_STAFF_CACHE.set(parsed.id, { data: value, fetchedAt: Date.now() });
      })
      .catch(() => setDetails(null));
  }, [parsed?.id, parsed?.kind]);

  if (!parsed) return null;

  const isCharacter = parsed.kind === "character";
  const image = isCharacter
    ? (details as CharacterDetails | null)?.image ?? null
    : (details as StaffDetails | null)?.image ?? null;
  const title = isCharacter
    ? (details as CharacterDetails | null)?.nameFull ?? label
    : (details as StaffDetails | null)?.nameFull ?? label;
  const meta = isCharacter ? "Character" : "Staff";

  return (
    <button
      class="my-1 flex w-full max-w-[20rem] items-center gap-2.5 rounded-md border border-[#3e2d56] bg-[#1a0f2a] p-2 text-left transition hover:border-[#604083] hover:bg-[#221338]"
      onClick={() => (isCharacter ? onOpenCharacter(parsed.id) : onOpenStaff(parsed.id))}
      title="Open in app"
    >
      {image ? (
        <img src={image} alt="" class="h-14 w-10 shrink-0 rounded object-cover" />
      ) : (
        <div class="h-14 w-10 shrink-0 rounded bg-[#33214a]" />
      )}
      <div class="min-w-0">
        <p class="truncate text-[0.86rem] font-semibold text-[#c9a8ff]">{title}</p>
        <p class="truncate text-[0.76rem] text-[#b8a5d8]">{meta}</p>
      </div>
    </button>
  );
}

function AniListSearchChip({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      class="my-0.5 inline-flex items-center rounded-full border border-[#305070]/50 bg-[#12273d] px-2.5 py-0.5 text-[0.76rem] text-[#9ec0de] transition hover:border-[#4d7297]/70 hover:text-[#c3dbef]"
      onClick={onClick}
      title="Open link"
    >
      {label}
    </button>
  );
}

function CloseBtn({ onClose }: { onClose: () => void }) {
  return (
    <button
      class="absolute right-4 top-4 z-20 rounded-full border border-white/10 bg-[#111214]/90 p-2 text-[#7a766e] backdrop-blur-sm transition hover:border-white/20 hover:text-[#f1efe7]"
      onClick={onClose}
      title="Close"
    >
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
      </svg>
    </button>
  );
}

function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div class="flex flex-col rounded-2xl border border-white/7 bg-white/3 px-3 py-3">
      <span class="text-[0.7rem] uppercase tracking-wider text-[#5a5650]">{label}</span>
      <span class="mt-0.5 text-[1rem] font-bold text-[#f1efe7]">{value}</span>
    </div>
  );
}

type SocialTab = "about" | "following" | "followers" | "list";

function UserContent({
  profile,
  socialTab,
  onTab,
  following,
  followers,
  followingLoading,
  followersLoading,
  listType,
  onListType,
  otherUserList,
  listLoading,
  onOpenMedia,
  onOpenCharacter,
  onOpenStaff,
  onOpenStudio,
  onOpenUser,
  followBusy,
  canFollow,
  onToggleFollow,
  embedded,
  onRequestSpan,
}: {
  profile: UserProfile;
  socialTab: SocialTab;
  onTab: (tab: SocialTab) => void;
  following: SocialUser[];
  followers: SocialUser[];
  followingLoading: boolean;
  followersLoading: boolean;
  listType: "ANIME" | "MANGA";
  onListType: (value: "ANIME" | "MANGA") => void;
  otherUserList: UserMediaListItem[];
  listLoading: boolean;
  onOpenMedia: (mediaId: number) => void;
  onOpenCharacter: (id: number) => void;
  onOpenStaff: (id: number) => void;
  onOpenStudio: (id: number) => void;
  onOpenUser: (username: string) => void;
  followBusy: boolean;
  canFollow: boolean;
  onToggleFollow: () => void;
  embedded?: boolean;
  onRequestSpan?: (span: 1 | 2 | 3) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const aboutRaw = profile.about?.trim() ?? null;
  const aboutPlain = aboutRaw ? anilistPlainText(aboutRaw) : null;
  const isLongAbout = (aboutPlain?.length ?? 0) > 250;

  const handleAboutLink = (url: string): boolean => {
    try {
      const u = new URL(url);
      if (!(u.hostname === "anilist.co" || u.hostname.endsWith(".anilist.co"))) return false;

      const parts = u.pathname.split("/").filter(Boolean);
      if (parts.length >= 2) {
        const kind = parts[0];
        const id = Number(parts[1]);
        if ((kind === "anime" || kind === "manga") && Number.isFinite(id)) {
          onOpenMedia(id);
          return true;
        }
        if (kind === "character" && Number.isFinite(id)) {
          onOpenCharacter(id);
          return true;
        }
        if (kind === "staff" && Number.isFinite(id)) {
          onOpenStaff(id);
          return true;
        }
        if (kind === "studio" && Number.isFinite(id)) {
          onOpenStudio(id);
          return true;
        }
        if (kind === "user") {
          const userName = decodeURIComponent(parts[1] || "").trim();
          if (userName) {
            onOpenUser(userName);
            return true;
          }
        }
      }
    } catch {
      return false;
    }
    return false;
  };

  const renderAboutLink = ({ text, url, isAniList }: { text: string; url: string; isAniList: boolean }) => {
    if (!isAniList) return null;

    const media = parseAniListMediaUrl(url);
    if (media) return <AniListMediaLinkCard url={url} label={text} onOpenMedia={onOpenMedia} />;

    const person = parseAniListCharacterOrStaffUrl(url);
    if (person) {
      return (
        <AniListPersonLinkCard
          url={url}
          label={text}
          onOpenCharacter={onOpenCharacter}
          onOpenStaff={onOpenStaff}
        />
      );
    }

    const search = parseAniListSearchUrl(url);
    if (search) {
      return (
        <AniListSearchChip
          label={search.label}
          onClick={() => {
            if (!handleAboutLink(url)) {
              void openUrl(url);
            }
          }}
        />
      );
    }

    return null;
  };

  const peopleList = socialTab === "following" ? following : followers;
  const peopleLoading = socialTab === "following" ? followingLoading : followersLoading;
  const peopleTitle = socialTab === "following" ? "Following" : "Followers";

  const tabClass = (id: SocialTab) =>
    `rounded-full border px-2.5 py-1 text-[0.72rem] transition ${
      socialTab === id
        ? "border-[#d97452]/60 bg-[#d97452]/20 text-[#f1efe7]"
        : "border-white/10 text-[#9a9690] hover:text-[#f1efe7]"
    }`;

  const followLabel = profile.isFollowing ? "Unfollow" : "Follow";

  return (
    <div class="flex flex-col">
      {/* Banner */}
      <div class="relative h-24 shrink-0 overflow-hidden bg-linear-to-br from-[#d97452]/30 to-[#7ca4be]/30">
        {profile.bannerUrl && (
          <img src={profile.bannerUrl} alt="" class="h-full w-full object-cover" />
        )}
        {/* Avatar */}
        <div class="absolute -bottom-8 left-5 z-20">
          {profile.avatarUrl ? (
            <img
              src={profile.avatarUrl}
              alt={profile.name}
              class="h-16 w-16 rounded-2xl border-2 border-[#111214] object-cover"
            />
          ) : (
            <div class="flex h-16 w-16 items-center justify-center rounded-2xl border-2 border-[#111214] bg-[#1e2024] text-2xl font-bold text-[#d97452]">
              {profile.name[0].toUpperCase()}
            </div>
          )}
        </div>
      </div>

      {/* Name */}
      <div class="mt-10 px-5">
        <h1 class="text-[1.3rem] font-bold text-[#f1efe7]">{profile.name}</h1>
        <p class="text-[0.72rem] text-[#5a5650]">AniList user</p>
        <div class="mt-2 flex items-center gap-2 text-[0.74rem] text-[#9a9690]">
          <span>{profile.followingCount} following</span>
          <span class="text-[#4a4844]">•</span>
          <span>{profile.followersCount} followers</span>
        </div>
        {canFollow && (
          <button
            class={`mt-3 rounded-full border px-3 py-1.5 text-[0.76rem] font-semibold transition ${
              profile.isFollowing
                ? "border-[#6f7f92]/45 bg-[#6f7f92]/16 text-[#d5e1ea] hover:bg-[#6f7f92]/26"
                : "border-[#d97452]/45 bg-[#d97452]/18 text-[#f1efe7] hover:bg-[#d97452]/28"
            }`}
            onClick={onToggleFollow}
            disabled={followBusy}
          >
            {followBusy ? "Saving…" : followLabel}
          </button>
        )}
      </div>

      <div class="mt-4 px-5">
        <div class="flex flex-wrap gap-2">
          <button class={tabClass("about")} onClick={() => onTab("about")}>About</button>
          <button class={tabClass("following")} onClick={() => onTab("following")}>Following</button>
          <button class={tabClass("followers")} onClick={() => onTab("followers")}>Followers</button>
          <button class={tabClass("list")} onClick={() => onTab("list")}>View their list</button>
        </div>
      </div>

      {/* About */}
      {socialTab === "about" && aboutRaw && (
        <div class="mt-4 px-5">
          <p class="mb-1 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">About</p>
          <div class="text-[0.85rem] leading-relaxed text-[#b5b0a5]">
            <div class={`relative ${!expanded && isLongAbout ? "max-h-30 overflow-hidden" : ""}`}>
              <AnilistMarkdown text={aboutRaw} onLinkClick={handleAboutLink} renderLink={renderAboutLink} />
              {!expanded && isLongAbout && (
                <div class="pointer-events-none absolute bottom-0 left-0 right-0 h-10 bg-linear-to-t from-[#111214] to-transparent" />
              )}
            </div>
          </div>
          {isLongAbout && (
            <button
              class="mt-1.5 text-[0.78rem] text-[#7ca4be] underline-offset-2 hover:underline"
              onClick={() => setExpanded((v) => !v)}
            >
              {expanded ? "Show less" : "Show more"}
            </button>
          )}
        </div>
      )}
      {socialTab === "about" && !aboutRaw && (
        <div class="mt-4 px-5">
          <p class="text-[0.82rem] text-[#7a766e]">This user has not added an About section.</p>
        </div>
      )}

      {/* Anime stats */}
      {socialTab === "about" && profile.stats && (
        <>
          <div class="mt-5 px-5">
            <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Anime</p>
            <div class="grid grid-cols-3 gap-2">
              <StatCard label="Titles" value={profile.stats.animeCount.toLocaleString()} />
              <StatCard label="Episodes" value={profile.stats.episodesWatched.toLocaleString()} />
              <StatCard label="Mean score" value={profile.stats.animeMeanScore != null ? profile.stats.animeMeanScore.toFixed(1) : "—"} />
            </div>
          </div>
          <div class="mt-4 px-5">
            <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Manga</p>
            <div class="grid grid-cols-3 gap-2">
              <StatCard label="Titles" value={profile.stats.mangaCount.toLocaleString()} />
              <StatCard label="Chapters" value={profile.stats.chaptersRead.toLocaleString()} />
              <StatCard label="Mean score" value={profile.stats.mangaMeanScore != null ? profile.stats.mangaMeanScore.toFixed(1) : "—"} />
            </div>
          </div>
        </>
      )}

      {(socialTab === "following" || socialTab === "followers") && (
        <div class="mt-4 px-5">
          <p class="mb-2 text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">{peopleTitle}</p>
          {peopleLoading ? (
            <KaomojiLoadingText label="Loading users" index={3} />
          ) : peopleList.length === 0 ? (
            <p class="text-[0.82rem] text-[#7a766e]">No users to show.</p>
          ) : (
            <div class="flex flex-col gap-2">
              {peopleList.slice(0, 30).map((u) => (
                <button
                  key={u.id}
                  class="flex items-center gap-2.5 rounded-xl border border-white/8 bg-white/3 px-2.5 py-2 text-left transition hover:bg-white/6"
                  onClick={() => onOpenUser(u.name)}
                >
                  {u.avatarUrl ? (
                    <img src={u.avatarUrl} alt={u.name} class="h-8 w-8 rounded-lg object-cover" />
                  ) : (
                    <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-[#1e2024] text-xs font-bold text-[#d97452]">
                      {u.name[0]?.toUpperCase() ?? "?"}
                    </div>
                  )}
                  <div class="min-w-0 flex-1">
                    <p class="truncate text-[0.82rem] font-medium text-[#e8e4da]">{u.name}</p>
                    <p class="text-[0.68rem] text-[#7a766e]">
                      {u.isFollowing ? "Following" : ""}{u.isFollowing && u.isFollower ? " · " : ""}{u.isFollower ? "Follows you" : ""}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      )}

      {socialTab === "list" && (
        <div class="mt-4 px-5">
          <div class="mb-2 flex items-center justify-between">
            <p class="text-[0.72rem] font-semibold uppercase tracking-wider text-[#5a5650]">Read-only list</p>
            <div class="flex items-center gap-2">
              <div class="rounded-full border border-white/10 bg-white/4 p-0.5">
                <button
                  class={`rounded-full px-2 py-1 text-[0.7rem] ${listType === "ANIME" ? "bg-[#d97452] text-white" : "text-[#9a9690]"}`}
                  onClick={() => onListType("ANIME")}
                >
                  Anime
                </button>
                <button
                  class={`rounded-full px-2 py-1 text-[0.7rem] ${listType === "MANGA" ? "bg-[#d97452] text-white" : "text-[#9a9690]"}`}
                  onClick={() => onListType("MANGA")}
                >
                  Manga
                </button>
              </div>
              {embedded && onRequestSpan && (
                <div class="rounded-full border border-white/10 bg-white/4 p-0.5">
                  <button
                    class="rounded-full px-2 py-1 text-[0.7rem] text-[#9a9690] hover:text-[#f1efe7]"
                    onClick={() => onRequestSpan(2)}
                    title="Expand panel"
                  >
                    2x
                  </button>
                  <button
                    class="rounded-full px-2 py-1 text-[0.7rem] text-[#9a9690] hover:text-[#f1efe7]"
                    onClick={() => onRequestSpan(3)}
                    title="Extra-wide panel"
                  >
                    3x
                  </button>
                </div>
              )}
            </div>
          </div>

          {listLoading ? (
            <KaomojiLoadingText label="Loading list" index={4} />
          ) : otherUserList.length === 0 ? (
            <p class="text-[0.82rem] text-[#7a766e]">No entries found for this list.</p>
          ) : (
            <div>
              <div class="mb-2 text-[0.7rem] text-[#7a766e]">
                {otherUserList.length.toLocaleString()} entries
              </div>
              <div class="flex flex-col gap-2">
                {otherUserList.map((entry, idx) => (
                  <button
                    key={`${entry.mediaId}-${entry.updatedAt}-${entry.status}-${idx}`}
                    class="flex items-center gap-2 rounded-xl border border-white/8 bg-white/3 px-2.5 py-2 text-left transition hover:bg-white/6"
                    onClick={() => onOpenMedia(entry.mediaId)}
                  >
                    {entry.coverImage ? (
                      <img src={entry.coverImage} alt="" class="h-11 w-8 rounded object-cover" />
                    ) : (
                      <div class="h-11 w-8 rounded bg-white/10" />
                    )}
                    <div class="min-w-0 flex-1">
                      <p class="truncate text-[0.82rem] font-medium text-[#e8e4da]">{entry.title}</p>
                      <p class="text-[0.68rem] text-[#7a766e]">
                        {entry.status.replace(/_/g, " ")} · {entry.progress}
                        {entry.mediaType === "MANGA" ? ` ch` : ` ep`}
                      </p>
                      <p class="text-[0.66rem] text-[#5f5a53]">
                        {entry.score != null ? `Score ${entry.score}` : "No score"}
                        {entry.progressVolumes > 0 ? ` · Vol ${entry.progressVolumes}` : ""}
                        {` · Updated ${new Date(entry.updatedAt * 1000).toLocaleDateString()}`}
                      </p>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      <div class="h-8 shrink-0" />
    </div>
  );
}

export interface UserPanelProps {
  /** AniList username. */
  username: string;
  onClose: () => void;
  embedded?: boolean;
  onOpenMedia?: (mediaId: number) => void;
  onOpenCharacter?: (id: number) => void;
  onOpenStaff?: (id: number) => void;
  onOpenStudio?: (id: number) => void;
  onOpenUser?: (username: string) => void;
  onRequestSpan?: (span: 1 | 2 | 3) => void;
}

export function UserPanel({
  username,
  onClose,
  embedded = false,
  onOpenMedia,
  onOpenCharacter,
  onOpenStaff,
  onOpenStudio,
  onOpenUser,
  onRequestSpan,
}: UserPanelProps) {
  useBackHandler(!embedded, onClose);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [socialTab, setSocialTab] = useState<SocialTab>("about");
  const [currentViewerId, setCurrentViewerId] = useState<number | null>(null);
  const [followBusy, setFollowBusy] = useState(false);

  const [following, setFollowing] = useState<SocialUser[]>([]);
  const [followers, setFollowers] = useState<SocialUser[]>([]);
  const [followingLoading, setFollowingLoading] = useState(false);
  const [followersLoading, setFollowersLoading] = useState(false);

  const [listType, setListType] = useState<"ANIME" | "MANGA">("ANIME");
  const [otherUserList, setOtherUserList] = useState<UserMediaListItem[]>([]);
  const [listLoading, setListLoading] = useState(false);
  const [openMediaId, setOpenMediaId] = useState<number | null>(null);
  const [openCharacterId, setOpenCharacterId] = useState<number | null>(null);
  const [openStaffId, setOpenStaffId] = useState<number | null>(null);
  const [openStudioId, setOpenStudioId] = useState<number | null>(null);
  const [openUserName, setOpenUserName] = useState<string | null>(null);

  const canFollow = useMemo(() => {
    if (!profile) return false;
    if (currentViewerId == null) return false;
    return profile.id !== currentViewerId;
  }, [profile, currentViewerId]);

  useEffect(() => {
    setLoading(true); setError(null); setProfile(null);
    setFollowing([]);
    setFollowers([]);
    setOtherUserList([]);

    const cacheKey = username.trim().toLowerCase();
    const cachedProfile = USER_PROFILE_CACHE.get(cacheKey);

    if (cachedProfile && isFresh(cachedProfile.fetchedAt, USER_PROFILE_TTL_MS)) {
      setProfile(cachedProfile.data);
      setLoading(false);
    }

    getAuthSessionStatus().then((s) => setCurrentViewerId(s.viewerId)).catch(() => setCurrentViewerId(null));
    getUserProfile(username)
      .then((value) => {
        setProfile(value);
        USER_PROFILE_CACHE.set(cacheKey, { data: value, fetchedAt: Date.now() });
      })
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }, [username]);

  useEffect(() => {
    if (!profile) return;
    if (socialTab === "following") {
      const cachedFollowing = USER_FOLLOWING_CACHE.get(profile.id);
      if (cachedFollowing && isFresh(cachedFollowing.fetchedAt, USER_SOCIAL_TTL_MS)) {
        setFollowing(cachedFollowing.data);
        return;
      }

      setFollowingLoading(true);
      getFollowing(profile.id)
        .then((value) => {
          setFollowing(value);
          USER_FOLLOWING_CACHE.set(profile.id, { data: value, fetchedAt: Date.now() });
        })
        .catch((e) => setError(String(e)))
        .finally(() => setFollowingLoading(false));
      return;
    }

    if (socialTab === "followers") {
      const cachedFollowers = USER_FOLLOWERS_CACHE.get(profile.id);
      if (cachedFollowers && isFresh(cachedFollowers.fetchedAt, USER_SOCIAL_TTL_MS)) {
        setFollowers(cachedFollowers.data);
        return;
      }

      setFollowersLoading(true);
      getFollowers(profile.id)
        .then((value) => {
          setFollowers(value);
          USER_FOLLOWERS_CACHE.set(profile.id, { data: value, fetchedAt: Date.now() });
        })
        .catch((e) => setError(String(e)))
        .finally(() => setFollowersLoading(false));
      return;
    }

    if (socialTab === "list") {
      const listCacheKey = `${profile.id}:${listType}`;
      const cachedList = USER_LIST_CACHE.get(listCacheKey);
      if (cachedList && isFresh(cachedList.fetchedAt, USER_LIST_TTL_MS)) {
        setOtherUserList(cachedList.data);
        return;
      }

      setListLoading(true);
      getUserMediaList(profile.id, listType)
        .then((value) => {
          setOtherUserList(value);
          USER_LIST_CACHE.set(listCacheKey, { data: value, fetchedAt: Date.now() });
        })
        .catch((e) => setError(String(e)))
        .finally(() => setListLoading(false));
    }
  }, [profile, socialTab, listType]);

  const handleToggleFollow = async () => {
    if (!profile || !canFollow) return;
    setFollowBusy(true);
    try {
      const next = await toggleFollow(profile.id, !profile.isFollowing);
      const fresh = await getUserProfile(profile.name);
      USER_PROFILE_CACHE.set(profile.name.trim().toLowerCase(), { data: fresh, fetchedAt: Date.now() });
      USER_FOLLOWING_CACHE.delete(profile.id);
      USER_FOLLOWERS_CACHE.delete(profile.id);
      setProfile({ ...fresh, isFollowing: next });
    } catch (e) {
      setError(String(e));
    } finally {
      setFollowBusy(false);
    }
  };

  const openMediaTarget = (id: number) => {
    if (onOpenMedia) {
      onOpenMedia(id);
      return;
    }
    setOpenMediaId(id);
  };

  const openCharacterTarget = (id: number) => {
    if (onOpenCharacter) {
      onOpenCharacter(id);
      return;
    }
    setOpenCharacterId(id);
  };

  const openStaffTarget = (id: number) => {
    if (onOpenStaff) {
      onOpenStaff(id);
      return;
    }
    setOpenStaffId(id);
  };

  const openStudioTarget = (id: number) => {
    if (onOpenStudio) {
      onOpenStudio(id);
      return;
    }
    setOpenStudioId(id);
  };

  const openUserTarget = (name: string) => {
    if (onOpenUser) {
      onOpenUser(name);
      return;
    }
    setOpenUserName(name);
  };

  const panelBody = (
    <>
      <CloseBtn onClose={onClose} />
      {loading && (
        <PanelSkeleton label="Loading user profile" kaomojiIndex={3} />
      )}
      {error && !loading && (
        <div class="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
          <p class="text-[0.85rem] text-[#7a766e]">{error}</p>
          <button class="rounded-full border border-white/10 px-4 py-2 text-[0.82rem] text-[#9a9690] hover:text-[#f1efe7]" onClick={onClose}>Close</button>
        </div>
      )}
      {profile && !loading && (
        <UserContent
          profile={profile}
          socialTab={socialTab}
          onTab={setSocialTab}
          following={following}
          followers={followers}
          followingLoading={followingLoading}
          followersLoading={followersLoading}
          listType={listType}
          onListType={setListType}
          otherUserList={otherUserList}
          listLoading={listLoading}
          onOpenMedia={openMediaTarget}
          onOpenCharacter={openCharacterTarget}
          onOpenStaff={openStaffTarget}
          onOpenStudio={openStudioTarget}
          onOpenUser={openUserTarget}
          followBusy={followBusy}
          canFollow={canFollow}
          onToggleFollow={handleToggleFollow}
          embedded={embedded}
          onRequestSpan={onRequestSpan}
        />
      )}
    </>
  );

  if (embedded) {
    return (
      <div class="relative flex h-full w-full flex-col overflow-y-auto bg-[#111214]">
        {panelBody}
      </div>
    );
  }

  return (
    <div class="fixed inset-0 z-50 flex" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      <div class="relative z-10 ml-auto flex h-full w-full max-w-[24rem] flex-col overflow-y-auto bg-[#111214] shadow-[-4px_0_40px_rgba(0,0,0,0.6)]">
        {panelBody}
      </div>
      {!embedded && openMediaId != null && (
        <MediaDetailsPanel mediaId={openMediaId} onClose={() => setOpenMediaId(null)} />
      )}
      {!embedded && openCharacterId != null && (
        <CharacterPanel characterId={openCharacterId} onClose={() => setOpenCharacterId(null)} />
      )}
      {!embedded && openStaffId != null && (
        <StaffPanel staffId={openStaffId} onClose={() => setOpenStaffId(null)} />
      )}
      {!embedded && openStudioId != null && (
        <StudioPanel studioId={openStudioId} onClose={() => setOpenStudioId(null)} />
      )}
      {!embedded && openUserName != null && (
        <UserPanel username={openUserName} onClose={() => setOpenUserName(null)} />
      )}
    </div>
  );
}
