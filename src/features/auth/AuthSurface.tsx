import { useState, useEffect, useRef } from "preact/hooks";
import type { JSX } from "preact/jsx-runtime";
import { openUrl } from "@tauri-apps/plugin-opener";
import {
  prepareAuthRequest,
  getAuthSessionStatus,
  clearAccessToken,
} from "../../shared/api/auth";
import { getFavorites, getFollowers, getFollowing, getUserProfile } from "../../shared/api/database";
import type { AuthSessionStatus, SocialUser, UserFavorites, UserProfile } from "../../shared/types/app";
import { CharacterPanel } from "../people/CharacterPanel";
import { StaffPanel } from "../people/StaffPanel";
import { StudioPanel } from "../people/StudioPanel";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";
import { UserPanel } from "../people/UserPanel";

type AuthPhase = "idle" | "preparing" | "waiting" | "error";

interface AuthSurfaceProps {
  session: AuthSessionStatus | null;
  onAuthenticated: (session: AuthSessionStatus) => void;
  onLogout?: () => void;
}

type AccountViewCacheEntry = {
  favs: UserFavorites | null;
  socialProfile: UserProfile | null;
  following: SocialUser[];
  followers: SocialUser[];
  fetchedAt: number;
};

const ACCOUNT_VIEW_CACHE = new Map<number, AccountViewCacheEntry>();
const ACCOUNT_VIEW_CACHE_TTL_MS = 5 * 60 * 1000;

// ─── Signed-in account view ───────────────────────────────────────────────────

function CoverTile({ title, img, onClick }: { title: string; img: string | null; onClick?: () => void }) {
  const inner = (
    <div class="aspect-[2/3] w-full overflow-hidden rounded-lg bg-white/5">
      {img ? (
        <img src={img} alt={title} class="h-full w-full object-cover transition group-hover:scale-105" />
      ) : (
        <div class="flex h-full w-full items-center justify-center text-[0.6rem] text-[#5e7a90] px-1 text-center leading-tight">
          {title}
        </div>
      )}
    </div>
  );
  return onClick ? (
    <button class="group relative flex-shrink-0 w-[72px]" title={title} onClick={onClick}>{inner}</button>
  ) : (
    <div class="group relative flex-shrink-0 w-[72px]" title={title}>{inner}</div>
  );
}

function PersonTile({ name, img, onClick }: { name: string; img: string | null; onClick?: () => void }) {
  const inner = (
    <>
      <div class="aspect-square w-full overflow-hidden rounded-full bg-white/5">
        {img ? (
          <img src={img} alt={name} class="h-full w-full object-cover transition group-hover:scale-105" />
        ) : (
          <div class="flex h-full w-full items-center justify-center text-[0.75rem] font-bold text-[#d97452]">
            {name[0]?.toUpperCase() ?? "?"}
          </div>
        )}
      </div>
      <p class="mt-1 truncate text-center text-[0.65rem] leading-tight text-[#848076]">{name}</p>
    </>
  );
  return onClick ? (
    <button class="group relative flex-shrink-0 w-[72px]" title={name} onClick={onClick}>{inner}</button>
  ) : (
    <div class="group relative flex-shrink-0 w-[72px]" title={name}>{inner}</div>
  );
}

function StudioTile({ name, onClick }: { name: string; onClick?: () => void }) {
  const inner = (
    <span class="block truncate rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-[0.75rem] text-[#c8c4bc] transition group-hover:border-[rgba(217,116,82,0.3)] group-hover:text-[#f1efe7]">
      {name}
    </span>
  );
  return onClick ? (
    <button class="group" title={name} onClick={onClick}>{inner}</button>
  ) : (
    <div class="group" title={name}>{inner}</div>
  );
}
function FavSection<T>({
  label,
  items,
  renderItem,
}: {
  label: string;
  items: T[];
  renderItem: (item: T) => JSX.Element;
}) {
  if (items.length === 0) return null;
  return (
    <div class="mb-6">
      <h3 class="mb-2.5 text-[0.74rem] font-bold uppercase tracking-[0.14em] text-[#7ca4be]">
        {label}
      </h3>
      <div class="flex flex-wrap gap-2.5">
        {items.map(renderItem)}
      </div>
    </div>
  );
}

function AccountView({
  session,
  onLogout,
}: Pick<AuthSurfaceProps, "session" | "onLogout"> & { onLogout: () => void }) {
  const [signingOut, setSigningOut] = useState(false);
  const [favs, setFavs] = useState<UserFavorites | null>(null);
  const [favsLoading, setFavsLoading] = useState(true);
  const [favsError, setFavsError] = useState<string | null>(null);
  const [socialLoading, setSocialLoading] = useState(true);
  const [socialError, setSocialError] = useState<string | null>(null);
  const [socialProfile, setSocialProfile] = useState<UserProfile | null>(null);
  const [socialTab, setSocialTab] = useState<"following" | "followers">("following");
  const [following, setFollowing] = useState<SocialUser[]>([]);
  const [followers, setFollowers] = useState<SocialUser[]>([]);
  const [openUser, setOpenUser] = useState<string | null>(null);

  // Panel state
  const [openCharacter, setOpenCharacter] = useState<number | null>(null);
  const [openStaff,     setOpenStaff]     = useState<number | null>(null);
  const [openStudio,    setOpenStudio]    = useState<number | null>(null);
  const [openMedia,     setOpenMedia]     = useState<number | null>(null);

  useEffect(() => {
    const viewerId = session?.viewerId;
    if (!viewerId) {
      setFavsLoading(false);
      return;
    }

    const cached = ACCOUNT_VIEW_CACHE.get(viewerId);
    if (cached && Date.now() - cached.fetchedAt < ACCOUNT_VIEW_CACHE_TTL_MS) {
      setFavs(cached.favs);
      setFavsError(null);
      setFavsLoading(false);
      return;
    }

    setFavsLoading(true);
    setFavsError(null);
    getFavorites()
      .then((data) => {
        setFavs(data);
        ACCOUNT_VIEW_CACHE.set(viewerId, {
          ...(cached ?? {
            favs: null,
            socialProfile: null,
            following: [],
            followers: [],
            fetchedAt: 0,
          }),
          favs: data,
          fetchedAt: Date.now(),
        });
      })
      .catch((e) => setFavsError(String(e)))
      .finally(() => setFavsLoading(false));
  }, [session?.viewerId]);

  useEffect(() => {
    async function loadSocial() {
      if (!session?.viewerId || !session?.viewerName) {
        setSocialLoading(false);
        return;
      }

      const viewerId = session.viewerId;
      const cached = ACCOUNT_VIEW_CACHE.get(viewerId);
      if (cached && Date.now() - cached.fetchedAt < ACCOUNT_VIEW_CACHE_TTL_MS) {
        setSocialProfile(cached.socialProfile);
        setFollowing(cached.following);
        setFollowers(cached.followers);
        setSocialError(null);
        setSocialLoading(false);
        return;
      }

      setSocialLoading(true);
      setSocialError(null);
      try {
        const [profile, followingUsers, followerUsers] = await Promise.all([
          getUserProfile(session.viewerName),
          getFollowing(session.viewerId, 1),
          getFollowers(session.viewerId, 1),
        ]);
        setSocialProfile(profile);
        setFollowing(followingUsers);
        setFollowers(followerUsers);

        ACCOUNT_VIEW_CACHE.set(viewerId, {
          ...(cached ?? {
            favs: null,
            socialProfile: null,
            following: [],
            followers: [],
            fetchedAt: 0,
          }),
          socialProfile: profile,
          following: followingUsers,
          followers: followerUsers,
          fetchedAt: Date.now(),
        });
      } catch (e) {
        setSocialError(String(e));
      } finally {
        setSocialLoading(false);
      }
    }

    loadSocial();
  }, [session?.viewerId, session?.viewerName]);

  async function handleSignOut() {
    setSigningOut(true);
    try {
      await clearAccessToken();
      onLogout();
    } catch {
      setSigningOut(false);
    }
  }

  const hasFavs =
    favs &&
    (favs.anime.length + favs.manga.length + favs.characters.length + favs.staff.length + favs.studios.length) > 0;
  const activeUsers = socialTab === "following" ? following : followers;

  return (
    <div class="p-8 max-w-180">
      {/* Header */}
      <div class="mb-8">
        <p class="mb-1 text-[0.74rem] font-bold uppercase tracking-[0.16em] text-[#7ca4be]">
          Account
        </p>
        <h1 class="text-[2rem] font-bold leading-[1.05] tracking-[-0.03em] text-[#f1efe7]">
          AniList profile
        </h1>
      </div>

      {/* Profile card */}
      <div class="mb-5 flex items-center gap-4 rounded-[1.4rem] border border-white/10 bg-[rgba(24,27,30,0.86)] p-5 backdrop-blur-xl">
        {session?.viewerAvatarUrl ? (
          <img
            src={session.viewerAvatarUrl}
            alt=""
            class="h-16 w-16 rounded-full object-cover ring-2 ring-white/10"
          />
        ) : (
          <div class="flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-[rgba(217,116,82,0.2)] text-[1.5rem] font-bold text-[#d97452]">
            {session?.viewerName?.[0]?.toUpperCase() ?? "?"}
          </div>
        )}
        <div>
          <div class="text-[1.2rem] font-bold text-[#f1efe7]">
            {session?.viewerName}
          </div>
          <div class="mt-0.5 text-[0.82rem] text-[#7ca4be]">
            AniList · ID {session?.viewerId}
          </div>
        </div>
      </div>

      {/* Session info */}
      <div class="mb-8 rounded-2xl border border-white/7 bg-white/3 px-4 py-3">
        <p class="text-[0.82rem] text-[#b5b0a5]">
          Session active. All app data is stored locally — no cloud backend is used.
        </p>
      </div>

      <div class="mb-8 rounded-[1.2rem] border border-white/7 bg-[rgba(20,23,26,0.7)] p-5">
        <div class="mb-4 flex items-center justify-between">
          <h2 class="text-[1.1rem] font-bold tracking-[-0.02em] text-[#f1efe7]">Social</h2>
          {session?.viewerName && (
            <button
              class="rounded-full border border-white/10 bg-white/4 px-3 py-1 text-[0.75rem] text-[#c8c4bc] transition hover:border-[rgba(217,116,82,0.3)] hover:text-[#f1efe7]"
              onClick={() => setOpenUser(session.viewerName!)}
            >
              Open public panel
            </button>
          )}
        </div>

        {socialLoading ? (
          <p class="text-[0.82rem] text-[#7a766e]">Loading social stats…</p>
        ) : socialError ? (
          <p class="text-[0.82rem] text-red-300/80">{socialError}</p>
        ) : (
          <>
            <div class="mb-3 grid grid-cols-2 gap-2.5">
              <button
                class={`rounded-xl border px-3 py-2 text-left transition ${socialTab === "following" ? "border-[rgba(217,116,82,0.45)] bg-[rgba(217,116,82,0.15)]" : "border-white/10 bg-white/3"}`}
                onClick={() => setSocialTab("following")}
              >
                <p class="text-[0.68rem] uppercase tracking-wider text-[#7a766e]">Following</p>
                <p class="mt-0.5 text-[1rem] font-bold text-[#f1efe7]">{socialProfile?.followingCount ?? following.length}</p>
              </button>
              <button
                class={`rounded-xl border px-3 py-2 text-left transition ${socialTab === "followers" ? "border-[rgba(217,116,82,0.45)] bg-[rgba(217,116,82,0.15)]" : "border-white/10 bg-white/3"}`}
                onClick={() => setSocialTab("followers")}
              >
                <p class="text-[0.68rem] uppercase tracking-wider text-[#7a766e]">Followers</p>
                <p class="mt-0.5 text-[1rem] font-bold text-[#f1efe7]">{socialProfile?.followersCount ?? followers.length}</p>
              </button>
            </div>

            {activeUsers.length === 0 ? (
              <p class="text-[0.8rem] text-[#7a766e]">No users to show.</p>
            ) : (
              <div class="flex max-h-[17.5rem] flex-col gap-2 overflow-y-auto pr-1">
                {activeUsers.map((u) => (
                  <button
                    key={u.id}
                    class="flex items-center gap-2.5 rounded-xl border border-white/8 bg-white/3 px-2.5 py-2 text-left transition hover:bg-white/6"
                    onClick={() => setOpenUser(u.name)}
                  >
                    {u.avatarUrl ? (
                      <img src={u.avatarUrl} alt={u.name} class="h-8 w-8 rounded-lg object-cover" />
                    ) : (
                      <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-[rgba(217,116,82,0.2)] text-[0.75rem] font-bold text-[#d97452]">
                        {u.name[0]?.toUpperCase() ?? "?"}
                      </div>
                    )}
                    <div class="min-w-0 flex-1">
                      <p class="truncate text-[0.82rem] font-medium text-[#e8e4da]">{u.name}</p>
                      <p class="text-[0.68rem] text-[#7a766e]">
                        {u.isFollowing ? "Following" : ""}
                        {u.isFollowing && u.isFollower ? " · " : ""}
                        {u.isFollower ? "Follows you" : ""}
                      </p>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {/* ── Favourites ──────────────────────────────────────────────────── */}
      <div class="mb-8">
        <div class="mb-4 flex items-center justify-between">
          <h2 class="text-[1.1rem] font-bold tracking-[-0.02em] text-[#f1efe7]">Favourites</h2>
          {favsLoading && (
            <span class="text-[0.78rem] text-[#5e7a90]">Loading…</span>
          )}
        </div>

        {favsError && (
          <div class="mb-4 rounded-xl border border-red-500/15 bg-red-500/6 px-4 py-3">
            <p class="text-[0.82rem] text-red-300/80">
              Could not load favourites — {favsError}
            </p>
          </div>
        )}

        {!favsLoading && !favsError && !hasFavs && (
          <p class="text-[0.85rem] text-[#5e7a90]">No favourites yet.</p>
        )}

        {hasFavs && (
          <div class="rounded-[1.2rem] border border-white/7 bg-[rgba(20,23,26,0.7)] p-5">
            <FavSection
              label="Anime"
              items={favs!.anime}
              renderItem={(m) => <CoverTile key={m.id} title={m.title} img={m.coverImage} onClick={() => setOpenMedia(m.id)} />}
            />
            <FavSection
              label="Manga"
              items={favs!.manga}
              renderItem={(m) => <CoverTile key={m.id} title={m.title} img={m.coverImage} onClick={() => setOpenMedia(m.id)} />}
            />
            <FavSection
              label="Characters"
              items={favs!.characters}
              renderItem={(p) => <PersonTile key={p.id} name={p.name} img={p.image} onClick={() => setOpenCharacter(p.id)} />}
            />
            <FavSection
              label="Staff"
              items={favs!.staff}
              renderItem={(p) => <PersonTile key={p.id} name={p.name} img={p.image} onClick={() => setOpenStaff(p.id)} />}
            />
            <FavSection
              label="Studios"
              items={favs!.studios}
              renderItem={(s) => <StudioTile key={s.id} name={s.name} onClick={() => setOpenStudio(s.id)} />}
            />
          </div>
        )}
      </div>

      {/* Sign out */}
      <button
        class="rounded-full border border-white/10 bg-white/5 px-5 py-2.5 text-[0.88rem] font-semibold text-[#b5b0a5] transition hover:border-red-500/30 hover:bg-red-500/8 hover:text-red-300 disabled:cursor-not-allowed disabled:opacity-50"
        onClick={handleSignOut}
        disabled={signingOut}
      >
        {signingOut ? "Signing out…" : "Sign out"}
      </button>

      {/* ── Panels ───────────────────────────────────────────────────────── */}
      {openCharacter != null && (
        <CharacterPanel
          characterId={openCharacter}
          onClose={() => setOpenCharacter(null)}
          onMediaClick={(id) => { setOpenCharacter(null); setOpenMedia(id); }}
        />
      )}
      {openStaff != null && (
        <StaffPanel
          staffId={openStaff}
          onClose={() => setOpenStaff(null)}
          onCharacterClick={(id) => { setOpenStaff(null); setOpenCharacter(id); }}
        />
      )}
      {openStudio != null && (
        <StudioPanel
          studioId={openStudio}
          onClose={() => setOpenStudio(null)}
          onMediaClick={(id) => { setOpenStudio(null); setOpenMedia(id); }}
        />
      )}
      {openMedia != null && (
        <MediaDetailsPanel mediaId={openMedia} onClose={() => setOpenMedia(null)} />
      )}
      {openUser != null && (
        <UserPanel username={openUser} onClose={() => setOpenUser(null)} />
      )}
    </div>
  );
}

// ─── Login screen ─────────────────────────────────────────────────────────────

function LoginView({ onAuthenticated }: { onAuthenticated: (s: AuthSessionStatus) => void }) {
  const [phase, setPhase] = useState<AuthPhase>("idle");
  const [error, setError] = useState<string | null>(null);

  const pollRef    = useRef<ReturnType<typeof setInterval> | null>(null);
  const timeoutRef = useRef<ReturnType<typeof setTimeout>  | null>(null);

  function stopPolling() {
    if (pollRef.current)    { clearInterval(pollRef.current);  pollRef.current    = null; }
    if (timeoutRef.current) { clearTimeout(timeoutRef.current); timeoutRef.current = null; }
  }

  useEffect(() => () => stopPolling(), []);

  async function startSignIn() {
    setPhase("preparing");
    setError(null);

    try {
      const plan = await prepareAuthRequest();
      await openUrl(plan.authUrl);
      setPhase("waiting");

      // Poll every 2 s until the Rust callback listener stores the token
      pollRef.current = setInterval(async () => {
        try {
          const status = await getAuthSessionStatus();
          if (status.hasAccessToken) {
            stopPolling();
            setPhase("idle");
            onAuthenticated(status);
          }
        } catch {
          // ignore transient poll errors
        }
      }, 2000);

      // 3-minute hard timeout
      timeoutRef.current = setTimeout(() => {
        stopPolling();
        setPhase("error");
        setError("Sign-in timed out. Please try again.");
      }, 180_000);
    } catch (e) {
      setPhase("error");
      setError(e instanceof Error ? e.message : String(e));
    }
  }

  function cancelWaiting() {
    stopPolling();
    setPhase("idle");
    setError(null);
  }

  if (phase === "waiting") {
    return (
      <div class="w-full max-w-100">
        <div class="rounded-3xl border border-[rgba(124,164,190,0.25)] bg-[rgba(124,164,190,0.07)] p-6 text-left">
          <div class="mb-3 flex items-center gap-3">
            <Spinner />
            <span class="font-semibold text-[#f1efe7]">Waiting for sign-in…</span>
          </div>
          <p class="text-[0.88rem] leading-relaxed text-[#b5b0a5]">
            A browser window has opened. Sign in on AniList and the app will
            update automatically when the callback arrives.
          </p>
          <button
            class="mt-5 text-[0.82rem] text-[#7ca4be] underline-offset-2 hover:underline"
            onClick={cancelWaiting}
          >
            Cancel
          </button>
        </div>
      </div>
    );
  }

  return (
    <div class="w-full max-w-100">
      <button
        class="w-full rounded-2xl border border-[rgba(217,116,82,0.4)] bg-[rgba(217,116,82,0.18)] px-6 py-3.5 text-[1rem] font-bold text-[#f1efe7] transition hover:-translate-y-px hover:border-[rgba(217,116,82,0.64)] hover:bg-[rgba(217,116,82,0.28)] disabled:pointer-events-none disabled:opacity-60"
        onClick={startSignIn}
        disabled={phase === "preparing"}
      >
        {phase === "preparing" ? "Preparing…" : "Sign in with AniList"}
      </button>

      {error && (
        <div class="mt-4 rounded-2xl border border-red-500/20 bg-red-500/6 p-4">
          <p class="text-[0.87rem] text-red-300">{error}</p>
        </div>
      )}

      <p class="mt-5 text-[0.79rem] leading-relaxed text-[#7a766e]">
        MiyoList uses AniList for your list data. Everything is stored locally —
        no cloud backend is used.
      </p>
    </div>
  );
}

// ─── Root export ─────────────────────────────────────────────────────────────

export function AuthSurface({ session, onAuthenticated, onLogout }: AuthSurfaceProps) {
  // When accessed from the sidebar while logged in
  if (session?.hasAccessToken) {
    return (
      <AccountView
        session={session}
        onLogout={onLogout ?? (() => {})}
      />
    );
  }

  // Full-screen login view (used by AppShell when not authenticated)
  return (
    <div class="flex h-screen flex-col items-center justify-center px-8">
      <div class="flex w-full max-w-100 flex-col items-center text-center">
        {/* Logo mark */}
        <div class="mb-6 flex h-16 w-16 items-center justify-center rounded-[1.25rem] bg-[rgba(217,116,82,0.2)] ring-1 ring-[rgba(217,116,82,0.3)]">
          <svg
            width="30"
            height="30"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#d97452"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
          </svg>
        </div>

        <h1 class="mb-1.5 text-[2.8rem] font-bold leading-none tracking-[-0.04em] text-[#f1efe7]">
          MiyoList
        </h1>
        <p class="mb-10 max-w-[30ch] text-[1rem] leading-relaxed text-[#848076]">
          Your anime &amp; manga library, local first.
        </p>

        <LoginView onAuthenticated={onAuthenticated} />
      </div>
    </div>
  );
}

function Spinner() {
  return (
    <svg
      class="animate-spin shrink-0"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    >
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
  );
}
