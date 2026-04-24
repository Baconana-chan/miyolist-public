import { useState, useRef, useMemo, useEffect } from "preact/hooks";
import { searchMedia, addToLibrary, searchCharacters, searchStaff, searchStudios, searchUsers } from "../../shared/api/database";
import { MediaDetailsPanel } from "../media/MediaDetailsPanel";
import { CharacterPanel } from "../people/CharacterPanel";
import { StaffPanel } from "../people/StaffPanel";
import { StudioPanel } from "../people/StudioPanel";
import { UserPanel } from "../people/UserPanel";
import { KaomojiLoadingText, MediaCardSkeleton } from "../../shared/components/Skeleton";
import type { MediaSearchResult, PersonSearchResult, StudioSearchResult, UserSearchResult, ScreenId } from "../../shared/types/app";
import { useSideSheet } from "../../app/sideSheet";

// ─── Types ────────────────────────────────────────────────────────────────────

type MediaType    = "ANIME" | "MANGA";
type PeopleType   = "CHARACTER" | "STAFF" | "STUDIO" | "USER";
type SearchTab    = "media" | "people";
type AddStatus    = "current" | "planning" | "completed";
type FilterToggle = "include" | "exclude";

// ─── Static data ──────────────────────────────────────────────────────────────

const GENRES = [
  "Action", "Adventure", "Comedy", "Drama", "Ecchi", "Fantasy",
  "Horror", "Mahou Shoujo", "Mecha", "Music", "Mystery", "Psychological",
  "Romance", "Sci-Fi", "Slice of Life", "Sports", "Supernatural", "Thriller", "Hentai",
];

const TAG_CATEGORIES: { label: string; tags: string[] }[] = [
  { label: "Cast / Main Cast", tags: [
    "Anti-Hero", "Elderly Protagonist", "Ensemble Cast", "Estranged Family",
    "Female Protagonist", "Male Protagonist", "Primarily Adult Cast", "Primarily Animal Cast",
    "Primarily Child Cast", "Primarily Female Cast", "Primarily Male Cast", "Primarily Teen Cast",
  ]},
  { label: "Cast / Traits", tags: [
    "Age Regression", "Agender", "Aliens", "Amnesia", "Angels", "Anthropomorphism",
    "Aromantic", "Arranged Marriage", "Artificial Intelligence", "Asexual", "Bisexual",
    "Butler", "Centaur", "Chimera", "Chuunibyou", "Clone", "Cosplay", "Cowboys",
    "Crossdressing", "Cyborg", "Delinquents", "Demons", "Detective", "Dinosaurs",
    "Disability", "Dissociative Identities", "Dragons", "Dullahan", "Elf", "Fairy",
    "Femboy", "Ghost", "Goblin", "Gods", "Gyaru", "Hikikomori", "Homeless", "Idol",
    "Kemonomimi", "Kuudere", "Maids", "Mermaid", "Monster Boy", "Monster Girl",
    "Nekomimi", "Ninja", "Nudity", "Nun", "Office Lady", "Oiran", "Ojou-sama",
    "Orphan", "Pirates", "Robots", "Samurai", "Shrine Maiden", "Skeleton", "Succubus",
    "Tanned Skin", "Teacher", "Tomboy", "Transgender", "Tsundere", "Twins", "Vampire",
    "Veterinarian", "Vikings", "Villainess", "VTuber", "Werewolf", "Witch", "Yandere", "Zombie",
  ]},
  { label: "Demographic", tags: ["Josei", "Kids", "Seinen", "Shoujo", "Shounen"] },
  { label: "Setting", tags: ["Matriarchy"] },
  { label: "Setting / Scene", tags: [
    "Bar", "Boarding School", "Camping", "Circus", "Coastal", "College", "Desert",
    "Dungeon", "Foreign", "Inn", "Konbini", "Natural Disaster", "Office",
    "Outdoor Activities", "Prison", "Restaurant", "Rural", "School", "School Club",
    "Snowscape", "Urban", "Wilderness", "Work",
  ]},
  { label: "Setting / Time", tags: [
    "Achronological Order", "Anachronism", "Ancient China", "Dystopian",
    "Historical", "Medieval", "Time Skip",
  ]},
  { label: "Setting / Universe", tags: [
    "Afterlife", "Alternate Universe", "Augmented Reality", "Omegaverse",
    "Post-Apocalyptic", "Space", "Urban Fantasy", "Virtual World",
  ]},
  { label: "Technical", tags: [
    "4-koma", "Achromatic", "Advertisement", "Anthology", "CGI", "Episodic",
    "Flash", "Full CGI", "Full Color", "Gekiga", "Graduation Project", "Long Strip",
    "Mixed Media", "No Dialogue", "Non-fiction", "POV", "Puppetry", "Rotoscoping",
    "Single-Page Chapter", "Stop Motion", "Vertical Video",
  ]},
  { label: "Theme / Action", tags: [
    "Archery", "Battle Royale", "Espionage", "Fugitive", "Guns", "Martial Arts",
    "Spearplay", "Swordplay",
  ]},
  { label: "Theme / Arts", tags: [
    "Acting", "Ballet", "Calligraphy", "Classic Literature", "Drawing", "Fashion",
    "Food", "Kabuki", "Makeup", "Manzai", "Modeling", "Photography", "Rakugo", "Writing",
  ]},
  { label: "Theme / Arts \u2013 Music", tags: [
    "Band", "Classical Music", "Dancing", "Hip-hop Music", "Jazz Music",
    "Metal Music", "Musical Theater", "Rock Music",
  ]},
  { label: "Theme / Comedy", tags: ["Parody", "Satire", "Slapstick", "Surreal Comedy"] },
  { label: "Theme / Drama", tags: [
    "Bullying", "Class Struggle", "Coming of Age", "Conspiracy", "Eco-Horror",
    "Fake Relationship", "Kingdom Management", "Rehabilitation", "Revenge", "Suicide", "Tragedy",
  ]},
  { label: "Theme / Fantasy", tags: [
    "Alchemy", "Body Swapping", "Cultivation", "Curses", "Exorcism", "Fairy Tale",
    "Henshin", "Isekai", "Kaiju", "Magic", "Mythology", "Necromancy", "Reverse Isekai",
    "Shapeshifting", "Steampunk", "Super Power", "Superhero", "Wuxia", "Youkai",
  ]},
  { label: "Theme / Game", tags: ["Board Game", "E-Sports", "Video Games"] },
  { label: "Theme / Game \u2013 Card & Board", tags: [
    "Card Battle", "Go", "Karuta", "Mahjong", "Poker", "Shogi",
  ]},
  { label: "Theme / Game \u2013 Sport", tags: [
    "Acrobatics", "Airsoft", "American Football", "Athletics", "Badminton",
    "Baseball", "Basketball", "Bowling", "Boxing", "Cheerleading", "Cycling",
    "Fencing", "Fishing", "Fitness", "Football", "Golf", "Handball", "Ice Skating",
    "Judo", "Lacrosse", "Parkour", "Rugby", "Scuba Diving", "Skateboarding",
    "Sumo", "Surfing", "Swimming", "Table Tennis", "Tennis", "Volleyball", "Wrestling",
  ]},
  { label: "Theme / Other", tags: [
    "Adoption", "Animals", "Astronomy", "Autobiographical", "Biographical",
    "Blackmail", "Body Horror", "Body Image", "Brainwashing", "Cannibalism",
    "Chibi", "Cosmic Horror", "Creature Taming", "Crime", "Crossover", "Death Game",
    "Denpa", "Drugs", "Economics", "Educational", "Environmental", "Ero Guro",
    "Filmmaking", "Found Family", "Gambling", "Gender Bending", "Gore",
    "Human Experimentation", "Indigenous Cultures", "Language Barrier", "LGBTQ+ Themes",
    "Lost Civilization", "Marriage", "Medicine", "Memory Manipulation", "Meta",
    "Mountaineering", "Noir", "Otaku Culture", "Pandemic", "Philosophy", "Politics",
    "Pregnancy", "Proxy Battle", "Psychosexual", "Reincarnation", "Religion",
    "Rescue", "Royal Affairs", "Slavery", "Software Development", "Survival",
    "Terrorism", "Torture", "Travel", "Vocal Synth", "War",
  ]},
  { label: "Theme / Other \u2013 Organisations", tags: [
    "Assassins", "Criminal Organization", "Cult", "Firefighters", "Gangs",
    "Mafia", "Military", "Police", "Triads", "Yakuza",
  ]},
  { label: "Theme / Other \u2013 Vehicle", tags: [
    "Aviation", "Cars", "Mopeds", "Motorcycles", "Ships", "Tanks", "Trains",
  ]},
  { label: "Theme / Romance", tags: [
    "Age Gap", "Boys' Love", "Cohabitation", "Female Harem", "Heterosexual",
    "Interspecies", "Love Triangle", "Male Harem", "Matchmaking",
    "Mixed Gender Harem", "Polyamorous", "Teens' Love", "Unrequited Love", "Yuri",
  ]},
  { label: "Theme / Sci-Fi", tags: [
    "Cyberpunk", "Space Opera", "Time Loop", "Time Manipulation", "Tokusatsu",
  ]},
  { label: "Theme / Sci-Fi \u2013 Mecha", tags: ["Real Robot", "Super Robot"] },
  { label: "Theme / Slice of Life", tags: [
    "Agriculture", "Cute Boys Doing Cute Things", "Cute Girls Doing Cute Things",
    "Family Life", "Horticulture", "Iyashikei", "Parenthood",
  ]},
  { label: "Sexual Content", tags: [
    "Ahegao", "Amputation", "Anal Sex", "Armpits", "Ashikoki", "Asphyxiation",
    "Bondage", "Boobjob", "Cervix Penetration", "Cheating", "Cumflation",
    "Cunnilingus", "Deepthroat", "Defloration", "DILF", "Double Penetration",
    "Erotic Piercings", "Exhibitionism", "Facial", "Feet", "Fellatio", "Femdom",
    "Fingering", "Fisting", "Flat Chest", "Futanari", "Group Sex", "Hair Pulling",
    "Handjob", "Human Pet", "Hypersexuality", "Incest", "Inseki", "Irrumatio",
    "Lactation", "Large Breasts", "Male Pregnancy", "Masochism", "Masturbation",
    "Mating Press", "MILF", "Nakadashi", "Netorare", "Netorase", "Netori",
    "Oyakodon", "Pet Play", "Prostitution", "Public Sex", "Rape", "Rimjob",
    "Sadism", "Scat", "Scissoring", "Sex Toys", "Shimaidon", "Squirting",
    "Sumata", "Swapping", "Sweat", "Tentacles", "Threesome", "Virginity",
    "Vore", "Voyeur", "Watersports", "Zoophilia",
  ]},
];

const ANIME_FORMATS = [
  { value: "TV",       label: "TV"       },
  { value: "TV_SHORT", label: "TV Short" },
  { value: "MOVIE",    label: "Movie"    },
  { value: "SPECIAL",  label: "Special"  },
  { value: "OVA",      label: "OVA"      },
  { value: "ONA",      label: "ONA"      },
  { value: "MUSIC",    label: "Music"    },
];

const MANGA_FORMATS = [
  { value: "MANGA",    label: "Manga"    },
  { value: "ONE_SHOT", label: "One Shot" },
  { value: "NOVEL",    label: "Novel"    },
];

const STATUS_OPTIONS = [
  { value: "",                 label: "Any status"        },
  { value: "FINISHED",         label: "Finished"          },
  { value: "RELEASING",        label: "Releasing"         },
  { value: "NOT_YET_RELEASED", label: "Not Yet Released"  },
  { value: "CANCELLED",        label: "Cancelled"         },
  { value: "HIATUS",           label: "Hiatus"            },
];

const SORT_OPTIONS = [
  { value: "SEARCH_MATCH",    label: "Search Match"    },
  { value: "SCORE_DESC",      label: "Score \u2193"    },
  { value: "SCORE",           label: "Score \u2191"    },
  { value: "TRENDING_DESC",   label: "Trending"        },
  { value: "POPULARITY_DESC", label: "Popularity"      },
  { value: "START_DATE_DESC", label: "Newest first"    },
  { value: "START_DATE",      label: "Oldest first"    },
  { value: "TITLE_ROMAJI",    label: "Title A \u2192 Z"},
  { value: "EPISODES_DESC",   label: "Most episodes"   },
  { value: "FAVOURITES_DESC", label: "Most favourited" },
];

// ─── Helpers + static ───────────────────────────────────────────────────────

const ADD_STATUS_OPTIONS: { value: AddStatus; label: string }[] = [
  { value: "current",   label: "Watching / Reading" },
  { value: "planning",  label: "Plan to watch/read"  },
  { value: "completed", label: "Completed"           },
];

function toggleFilterMap(
  map: Map<string, FilterToggle>,
  key: string,
): Map<string, FilterToggle> {
  const next = new Map(map);
  const cur = next.get(key);
  if (!cur)                  next.set(key, "include");
  else if (cur === "include") next.set(key, "exclude");
  else                       next.delete(key);
  return next;
}

interface SearchSurfaceProps {
  onNavigate: (screen: ScreenId) => void;
}

// ─── Filter pill ─────────────────────────────────────────────────────────────

function FilterPill({
  label, state, onToggle,
}: {
  label: string;
  state: FilterToggle | undefined;
  onToggle: () => void;
}) {
  const base = "rounded-full border px-2.5 py-0.5 text-[0.76rem] cursor-pointer select-none transition";
  const cls =
    state === "include" ? `${base} border-[rgba(217,116,82,0.45)] bg-[rgba(217,116,82,0.18)] text-[#d97452]` :
    state === "exclude" ? `${base} border-[rgba(200,70,70,0.4)]  bg-[rgba(200,70,70,0.14)]  text-[#e08080]` :
                          `${base} border-white/8 bg-white/4 text-[#7a766e] hover:text-[#c0bdb5]`;
  return <span class={cls} onClick={onToggle}>{label}</span>;
}

// ─── Result card ─────────────────────────────────────────────────────────────

function ResultCard({
  item,
  onAdd,
  onDetails,
}: {
  item: MediaSearchResult;
  onAdd: (item: MediaSearchResult) => void;
  onDetails: (id: number) => void;
}) {
  const scoreColor =
    item.averageScore == null ? "text-[#7a766e]" :
    item.averageScore >= 75   ? "text-[#8ecf8e]" :
    item.averageScore >= 55   ? "text-[#d4b86a]" :
                                "text-[#e08a8a]";

  return (
    <div
      class="group flex gap-3 rounded-2xl border border-white/7 bg-white/3 p-3 transition hover:bg-white/5 cursor-pointer"
      onClick={() => onDetails(item.mediaId)}
    >
      {item.coverImage ? (
        <img
          src={item.coverImage}
          alt=""
          class="h-24 w-16 shrink-0 rounded-xl object-cover"
          loading="lazy"
        />
      ) : (
        <div class="h-24 w-16 shrink-0 rounded-xl bg-white/8" />
      )}

      <div class="min-w-0 flex-1">
        <p class="line-clamp-2 text-[0.9rem] font-semibold leading-snug text-[#f1efe7]">
          {item.title}
        </p>
        <div class="mt-1 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-[0.75rem] text-[#7a766e]">
          {item.format && <span>{item.format.replace(/_/g, " ")}</span>}
          {item.episodes != null && <span>· {item.episodes} ep</span>}
          {item.chapters != null && <span>· {item.chapters} ch</span>}
          {item.averageScore != null && (
            <span class={scoreColor}>· ★ {item.averageScore / 10}</span>
          )}
        </div>
        {item.genres.length > 0 && (
          <div class="mt-1.5 flex flex-wrap gap-1">
            {item.genres.slice(0, 4).map((g) => (
              <span key={g} class="rounded-full bg-white/6 px-2 py-0.5 text-[0.68rem] text-[#9a9690]">
                {g}
              </span>
            ))}
          </div>
        )}
      </div>

      <div class="flex shrink-0 flex-col items-end justify-between">
        {item.inLibrary ? (
          <span class="rounded-full border border-[rgba(100,180,100,0.3)] bg-[rgba(100,180,100,0.12)] px-2.5 py-1 text-[0.72rem] font-medium text-[#8ecf8e]">
            In library
          </span>
        ) : (
          <button
            class="rounded-full border border-[rgba(217,116,82,0.34)] bg-[rgba(217,116,82,0.16)] px-3 py-1.5 text-[0.78rem] font-bold text-[#f1efe7] transition hover:bg-[rgba(217,116,82,0.26)]"
            onClick={(e) => { e.stopPropagation(); onAdd(item); }}
          >
            + Add
          </button>
        )}
      </div>
    </div>
  );
}

// ─── People result cards ──────────────────────────────────────────────────────

function PersonCard({ item, onClick }: { item: PersonSearchResult; onClick: () => void }) {
  return (
    <button
      class="group flex items-center gap-3 rounded-2xl border border-white/7 bg-white/3 p-3 text-left transition hover:bg-white/5"
      onClick={onClick}
    >
      {item.image ? (
        <img src={item.image} alt="" class="h-14 w-14 shrink-0 rounded-full object-cover" />
      ) : (
        <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-white/8 text-xl font-bold text-[#d97452]">
          {item.name[0]?.toUpperCase() ?? "?"}
        </div>
      )}
      <div class="min-w-0 flex-1">
        <p class="truncate text-[0.9rem] font-semibold text-[#f1efe7] group-hover:text-white">{item.name}</p>
        {item.sub && <p class="mt-0.5 truncate text-[0.75rem] text-[#7a766e]">{item.sub}</p>}
        <p class="mt-0.5 text-[0.68rem] font-semibold uppercase tracking-wide text-[#5a5650]">
          {item.kind === "CHARACTER" ? "Character" : "Staff"}
        </p>
      </div>
      <svg class="shrink-0 text-[#5a5650] group-hover:text-[#d97452]" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="9 18 15 12 9 6" />
      </svg>
    </button>
  );
}

function StudioCard({ item, onClick }: { item: StudioSearchResult; onClick: () => void }) {
  return (
    <button
      class="group flex items-center gap-3 rounded-2xl border border-white/7 bg-white/3 p-3 text-left transition hover:bg-white/5"
      onClick={onClick}
    >
      <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/8 text-xl font-bold text-[#7ca4be]">
        {item.name[0]?.toUpperCase() ?? "S"}
      </div>
      <div class="min-w-0 flex-1">
        <p class="truncate text-[0.9rem] font-semibold text-[#f1efe7] group-hover:text-white">{item.name}</p>
        {item.recentTitle && <p class="mt-0.5 truncate text-[0.75rem] text-[#7a766e]">{item.recentTitle}</p>}
        {item.isAnimationStudio && (
          <p class="mt-0.5 text-[0.68rem] font-semibold uppercase tracking-wide text-[#d97452]">Animation Studio</p>
        )}
      </div>
      <svg class="shrink-0 text-[#5a5650] group-hover:text-[#d97452]" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="9 18 15 12 9 6" />
      </svg>
    </button>
  );
}

function UserCard({ item, onClick }: { item: UserSearchResult; onClick: () => void }) {
  return (
    <button
      class="group flex items-center gap-3 rounded-2xl border border-white/7 bg-white/3 p-3 text-left transition hover:bg-white/5"
      onClick={onClick}
    >
      {item.avatarUrl ? (
        <img src={item.avatarUrl} alt="" class="h-14 w-14 shrink-0 rounded-xl object-cover" />
      ) : (
        <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-white/8 text-xl font-bold text-[#d97452]">
          {item.name[0]?.toUpperCase() ?? "U"}
        </div>
      )}
      <div class="min-w-0 flex-1">
        <p class="truncate text-[0.9rem] font-semibold text-[#f1efe7] group-hover:text-white">{item.name}</p>
        <p class="mt-0.5 text-[0.68rem] font-semibold uppercase tracking-wide text-[#5a5650]">User</p>
      </div>
      <svg class="shrink-0 text-[#5a5650] group-hover:text-[#d97452]" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="9 18 15 12 9 6" />
      </svg>
    </button>
  );
}

// ─── Add-to-library modal ─────────────────────────────────────────────────────

function AddModal({
  item,
  onClose,
  onAdded,
}: {
  item: MediaSearchResult;
  onClose: () => void;
  onAdded: () => void;
}) {
  const [status,  setStatus]  = useState<AddStatus>("planning");
  const [saving,  setSaving]  = useState(false);
  const [error,   setError]   = useState<string | null>(null);

  async function handleAdd() {
    setSaving(true);
    setError(null);
    try {
      await addToLibrary(item.mediaId, item.mediaType, status, item.title, item.coverImage);
      onAdded();
      onClose();
    } catch (e) {
      setError(String(e));
      setSaving(false);
    }
  }

  return (
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div class="w-full max-w-sm rounded-3xl border border-white/10 bg-[#1a1815] p-6 shadow-2xl">
        <div class="flex items-start gap-3">
          {item.coverImage && (
            <img src={item.coverImage} alt="" class="h-14 w-10 shrink-0 rounded-lg object-cover" />
          )}
          <div class="min-w-0">
            <h2 class="truncate text-[1rem] font-bold text-[#f1efe7]">{item.title}</h2>
            <p class="text-[0.78rem] text-[#7a766e]">{item.mediaType.toUpperCase() === "MANGA" ? "Manga" : "Anime"}</p>
          </div>
        </div>

        <div class="mt-4">
          <label class="mb-1.5 block text-[0.8rem] font-medium text-[#9a9690]">Add as</label>
          <select
            class="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-[0.9rem] text-[#f1efe7] focus:border-[#d97452]/60 focus:outline-none"
            value={status}
            onChange={(e) => setStatus((e.target as HTMLSelectElement).value as AddStatus)}
          >
            {ADD_STATUS_OPTIONS.map(({ value, label }) => (
              <option key={value} value={value}>{label}</option>
            ))}
          </select>
        </div>

        {error && (
          <p class="mt-3 rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2 text-[0.82rem] text-red-400">
            {error}
          </p>
        )}

        <div class="mt-5 flex gap-2">
          <button
            class="flex-1 rounded-full border border-white/10 px-4 py-2.5 text-[0.88rem] font-medium text-[#7a766e] transition hover:border-white/20 hover:text-[#f1efe7]"
            onClick={onClose}
            disabled={saving}
          >
            Cancel
          </button>
          <button
            class="flex-1 rounded-full bg-[#d97452] px-4 py-2.5 text-[0.88rem] font-bold text-white transition hover:bg-[#e0875f] disabled:opacity-50"
            onClick={handleAdd}
            disabled={saving}
          >
            {saving ? "Adding…" : "Add to library"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Search surface ───────────────────────────────────────────────────────────

export function SearchSurface({ onNavigate: _onNavigate }: SearchSurfaceProps) {
  const sideSheet = useSideSheet();
  // Core state
  const [query,      setQuery]      = useState("");
  const [searchTab,  setSearchTab]  = useState<SearchTab>("media");
  const [mediaType,  setMediaType]  = useState<MediaType>("ANIME");
  const [peopleType, setPeopleType] = useState<PeopleType>("CHARACTER");
  const [results,    setResults]    = useState<MediaSearchResult[]>([]);
  const [searching,  setSearching]  = useState(false);
  const [searched,   setSearched]   = useState(false);
  const [error,      setError]      = useState<string | null>(null);
  const [addTarget,  setAddTarget]  = useState<MediaSearchResult | null>(null);
  const [detailsId,  setDetailsId]  = useState<number | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const queryInputRef = useRef<HTMLInputElement>(null);

  // People search state
  const [personResults,  setPersonResults]  = useState<PersonSearchResult[]>([]);
  const [studioResults,  setStudioResults]  = useState<StudioSearchResult[]>([]);
  const [userResults,    setUserResults]    = useState<UserSearchResult[]>([]);
  const [peopleSearched, setPeopleSearched] = useState(false);
  const [openCharacter,  setOpenCharacter]  = useState<number | null>(null);
  const [openStaff,      setOpenStaff]      = useState<number | null>(null);
  const [openStudio,     setOpenStudio]     = useState<number | null>(null);
  const [openUser,       setOpenUser]       = useState<string | null>(null);
  const debounceRef2 = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Filter state
  const [showFilters,  setShowFilters]  = useState(false);
  const [genreFilter,  setGenreFilter]  = useState<Map<string, FilterToggle>>(() => new Map());
  const [tagFilter,    setTagFilter]    = useState<Map<string, FilterToggle>>(() => new Map());
  const [tagSearch,    setTagSearch]    = useState("");
  const [formatFilter, setFormatFilter] = useState<string[]>([]);
  const [statusFilter, setStatusFilter] = useState("");
  const [sortFilter,   setSortFilter]   = useState("SEARCH_MATCH");
  const [yearFrom,     setYearFrom]     = useState("");
  const [yearTo,       setYearTo]       = useState("");
  const [minTagRank,   setMinTagRank]   = useState(0);
  const [expandedCats, setExpandedCats] = useState<Set<string>>(() => new Set());

  // ── Derived ──────────────────────────────────────────────────────────────

  const activeFilterCount = useMemo(() => {
    let n = 0;
    if (genreFilter.size > 0)          n++;
    if (tagFilter.size > 0)            n++;
    if (formatFilter.length > 0)       n++;
    if (statusFilter)                  n++;
    if (sortFilter !== "SEARCH_MATCH") n++;
    if (yearFrom || yearTo)            n++;
    if (minTagRank > 0)                n++;
    return n;
  }, [genreFilter, tagFilter, formatFilter, statusFilter, sortFilter, yearFrom, yearTo, minTagRank]);

  const filteredCategories = useMemo(() => {
    if (!tagSearch.trim()) return TAG_CATEGORIES;
    const q = tagSearch.toLowerCase();
    return TAG_CATEGORIES
      .map((cat) => ({ label: cat.label, tags: cat.tags.filter((t) => t.toLowerCase().includes(q)) }))
      .filter((cat) => cat.tags.length > 0);
  }, [tagSearch]);

  // ── People search ────────────────────────────────────────────────────────

  function doSearchPeople(q: string, pt: PeopleType) {
    if (q.trim().length < 2) {
      setPersonResults([]); setStudioResults([]); setUserResults([]);
      setPeopleSearched(false); return;
    }
    if (debounceRef2.current) clearTimeout(debounceRef2.current);
    debounceRef2.current = setTimeout(async () => {
      setSearching(true); setError(null);
      try {
        if (pt === "CHARACTER") {
          const r = await searchCharacters(q.trim()); setPersonResults(r);
        } else if (pt === "STAFF") {
          const r = await searchStaff(q.trim()); setPersonResults(r);
        } else if (pt === "STUDIO") {
          const r = await searchStudios(q.trim()); setStudioResults(r);
        } else {
          const r = await searchUsers(q.trim()); setUserResults(r);
        }
        setPeopleSearched(true);
      } catch (e) {
        setError(String(e));
      } finally {
        setSearching(false);
      }
    }, 350);
  }

  // ── Search dispatcher ────────────────────────────────────────────────────

  function doSearch(
    q: string,
    mt: MediaType,
    ov: {
      genreFilter?:  Map<string, FilterToggle>;
      tagFilter?:    Map<string, FilterToggle>;
      formatFilter?: string[];
      statusFilter?: string;
      sortFilter?:   string;
      yearFrom?:     string;
      yearTo?:       string;
      minTagRank?:   number;
    } = {},
  ) {
    const gf  = ov.genreFilter  ?? genreFilter;
    const tf  = ov.tagFilter    ?? tagFilter;
    const ff  = ov.formatFilter ?? formatFilter;
    const sf  = ov.statusFilter ?? statusFilter;
    const srt = ov.sortFilter   ?? sortFilter;
    const yf  = ov.yearFrom     ?? yearFrom;
    const yt  = ov.yearTo       ?? yearTo;
    const mtr = ov.minTagRank   ?? minTagRank;

    const genresIn    = [...gf].filter(([, v]) => v === "include").map(([k]) => k);
    const genresNotIn = [...gf].filter(([, v]) => v === "exclude").map(([k]) => k);
    const tagsIn      = [...tf].filter(([, v]) => v === "include").map(([k]) => k);
    const tagsNotIn   = [...tf].filter(([, v]) => v === "exclude").map(([k]) => k);

    const hasFilters =
      genresIn.length > 0 || genresNotIn.length > 0 ||
      tagsIn.length > 0   || tagsNotIn.length > 0   ||
      ff.length > 0 || !!sf || !!yf || !!yt || mtr > 0;

    if (q.trim().length < 2 && !hasFilters) { setResults([]); setSearched(false); return; }

    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(async () => {
      setSearching(true); setError(null);
      try {
        const res = await searchMedia(q.trim(), mt, {
          genresIn:       genresIn.length    ? genresIn    : null,
          genresNotIn:    genresNotIn.length ? genresNotIn : null,
          tagsIn:         tagsIn.length      ? tagsIn      : null,
          tagsNotIn:      tagsNotIn.length   ? tagsNotIn   : null,
          formatIn:       ff.length          ? ff          : null,
          statusFilter:   sf                 || null,
          sort:           srt,
          yearGreater:    yf  ? parseInt(yf)  : null,
          yearLesser:     yt  ? parseInt(yt)  : null,
          minimumTagRank: mtr > 0             ? mtr        : null,
          isAdult:        null,
        });
        setResults(res); setSearched(true);
      } catch (e) {
        setError(String(e));
      } finally {
        setSearching(false);
      }
    }, 350);
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  function handleQueryChange(e: Event) {
    const val = (e.target as HTMLInputElement).value;
    setQuery(val);
    if (searchTab === "media") doSearch(val, mediaType);
    else doSearchPeople(val, peopleType);
  }

  function handleTypeChange(mt: MediaType) {
    setMediaType(mt); setFormatFilter([]);
    doSearch(query, mt, { formatFilter: [] });
  }

  function handlePeopleTypeChange(pt: PeopleType) {
    setPeopleType(pt);
    doSearchPeople(query, pt);
  }

  function handleSearchTabChange(tab: SearchTab) {
    setSearchTab(tab);
    if (tab === "media") doSearch(query, mediaType);
    else doSearchPeople(query, peopleType);
  }

  function handleGenreToggle(genre: string) {
    const next = toggleFilterMap(genreFilter, genre);
    setGenreFilter(next); doSearch(query, mediaType, { genreFilter: next });
  }

  function handleTagToggle(tag: string) {
    const next = toggleFilterMap(tagFilter, tag);
    setTagFilter(next); doSearch(query, mediaType, { tagFilter: next });
  }

  function handleFormatToggle(fmt: string) {
    const next = formatFilter.includes(fmt)
      ? formatFilter.filter((f) => f !== fmt)
      : [...formatFilter, fmt];
    setFormatFilter(next); doSearch(query, mediaType, { formatFilter: next });
  }

  function handleStatusChange(s: string) {
    setStatusFilter(s); doSearch(query, mediaType, { statusFilter: s });
  }

  function handleSortChange(s: string) {
    setSortFilter(s); doSearch(query, mediaType, { sortFilter: s });
  }

  function handleYearFromChange(v: string) {
    setYearFrom(v); doSearch(query, mediaType, { yearFrom: v });
  }

  function handleYearToChange(v: string) {
    setYearTo(v); doSearch(query, mediaType, { yearTo: v });
  }

  function handleMinTagRankChange(v: number) {
    setMinTagRank(v); doSearch(query, mediaType, { minTagRank: v });
  }

  function handleAdded() { doSearch(query, mediaType); }

  function resetFilters() {
    const em = new Map<string, FilterToggle>();
    setGenreFilter(em); setTagFilter(em); setFormatFilter([]);
    setStatusFilter(""); setSortFilter("SEARCH_MATCH");
    setYearFrom(""); setYearTo(""); setMinTagRank(0);
    doSearch(query, mediaType, {
      genreFilter: em, tagFilter: em, formatFilter: [],
      statusFilter: "", sortFilter: "SEARCH_MATCH",
      yearFrom: "", yearTo: "", minTagRank: 0,
    });
  }

  function toggleCategory(label: string) {
    setExpandedCats((prev) => {
      const next = new Set(prev);
      if (next.has(label)) next.delete(label); else next.add(label);
      return next;
    });
  }

  const formats = mediaType === "ANIME" ? ANIME_FORMATS : MANGA_FORMATS;

  const openMediaPanel = (id: number) => {
    if (sideSheet.isMultiPanel) {
      sideSheet.openMedia(id);
      return;
    }
    setDetailsId(id);
  };

  const openCharacterPanel = (id: number) => {
    if (sideSheet.isMultiPanel) {
      sideSheet.openCharacter(id);
      return;
    }
    setOpenCharacter(id);
  };

  const openStaffPanel = (id: number) => {
    if (sideSheet.isMultiPanel) {
      sideSheet.openStaff(id);
      return;
    }
    setOpenStaff(id);
  };

  const openStudioPanel = (id: number) => {
    if (sideSheet.isMultiPanel) {
      sideSheet.openStudio(id);
      return;
    }
    setOpenStudio(id);
  };

  const openUserPanel = (name: string) => {
    if (sideSheet.isMultiPanel) {
      sideSheet.openUser(name, 2);
      return;
    }
    setOpenUser(name);
  };

  useEffect(() => {
    const onFocusSearchInput = () => {
      queryInputRef.current?.focus();
      queryInputRef.current?.select();
    };

    const onCloseOverlays = () => {
      if (openUser != null) {
        setOpenUser(null);
      } else if (openStudio != null) {
        setOpenStudio(null);
      } else if (openStaff != null) {
        setOpenStaff(null);
      } else if (openCharacter != null) {
        setOpenCharacter(null);
      } else if (detailsId != null) {
        setDetailsId(null);
      } else if (addTarget != null) {
        setAddTarget(null);
      } else if (showFilters) {
        setShowFilters(false);
      }
    };

    window.addEventListener("miyolist:focus-search-input", onFocusSearchInput);
    window.addEventListener("miyolist:close-overlays", onCloseOverlays);

    return () => {
      window.removeEventListener("miyolist:focus-search-input", onFocusSearchInput);
      window.removeEventListener("miyolist:close-overlays", onCloseOverlays);
    };
  }, [addTarget, detailsId, openCharacter, openStaff, openStudio, openUser, showFilters]);

  // ── Render ───────────────────────────────────────────────────────────────

  return (
    <div class="flex h-full flex-col">
      {/* ── Header ────────────────────────────────────────────────────── */}
      <header class="shrink-0 px-8 pt-8 pb-5">
        <h1 class="text-[2rem] font-bold leading-[1.05] tracking-[-0.03em] text-[#f1efe7]">Discover</h1>

        {/* Search row */}
        <div class="mt-4 flex gap-2">
          <div class="relative flex-1">
            <svg class="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[#5a5650]"
              width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              ref={queryInputRef}
              type="text"
              placeholder="Search anime, manga, or browse by filters\u2026"
              class="w-full rounded-2xl border border-white/10 bg-white/5 py-3 pl-10 pr-4 text-[0.95rem] text-[#f1efe7] placeholder-[#5a5650] focus:border-[#d97452]/50 focus:outline-none"
              value={query}
              onInput={handleQueryChange}
              autofocus
            />
            {searching && (
              <span class="absolute right-3.5 top-1/2 -translate-y-1/2 text-[0.75rem] text-[#7a766e]">Searching\u2026 (・`ω´・)</span>
            )}
          </div>

          {/* Filter toggle */}
          <button
            class={`relative flex shrink-0 items-center gap-1.5 rounded-2xl border px-4 text-[0.85rem] font-medium transition ${
              showFilters || activeFilterCount > 0
                ? "border-[rgba(217,116,82,0.4)] bg-[rgba(217,116,82,0.12)] text-[#d97452]"
                : "border-white/10 bg-white/5 text-[#7a766e] hover:text-[#d4d0c8]"
            }`}
            onClick={() => setShowFilters((v) => !v)}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="4" y1="6" x2="20" y2="6" /><line x1="8" y1="12" x2="16" y2="12" /><line x1="11" y1="18" x2="13" y2="18" />
            </svg>
            Filters
            {activeFilterCount > 0 && (
              <span class="flex h-4 min-w-4 items-center justify-center rounded-full bg-[#d97452] px-1 text-[0.6rem] font-bold text-white">
                {activeFilterCount}
              </span>
            )}
          </button>
        </div>

        {/* Type + sort row */}
        <div class="mt-3 flex items-center gap-1.5">
          {(["ANIME", "MANGA"] as MediaType[]).map((mt) => (
            <button
              key={mt}
              class={`rounded-full px-4 py-1.5 text-[0.82rem] font-semibold transition ${
                searchTab === "media" && mediaType === mt
                  ? "bg-[rgba(217,116,82,0.22)] text-[#f1efe7]"
                  : "text-[#7a766e] hover:text-[#d4d0c8]"
              }`}
              onClick={() => { setSearchTab("media"); handleTypeChange(mt); }}
            >
              {mt === "ANIME" ? "Anime" : "Manga"}
            </button>
          ))}
          <button
            class={`rounded-full px-4 py-1.5 text-[0.82rem] font-semibold transition ${
              searchTab === "people"
                ? "bg-[rgba(124,164,190,0.22)] text-[#f1efe7]"
                : "text-[#7a766e] hover:text-[#d4d0c8]"
            }`}
            onClick={() => handleSearchTabChange("people")}
          >
            People
          </button>
        </div>

        {/* People sub-type row */}
        {searchTab === "people" && (
          <div class="mt-2 flex items-center gap-1">
            {(["CHARACTER", "STAFF", "STUDIO", "USER"] as PeopleType[]).map((pt) => (
              <button
                key={pt}
                class={`rounded-full px-3 py-1 text-[0.75rem] font-medium transition ${
                  peopleType === pt
                    ? "bg-[rgba(124,164,190,0.18)] text-[#7ca4be]"
                    : "text-[#5a5650] hover:text-[#9a9690]"
                }`}
                onClick={() => handlePeopleTypeChange(pt)}
              >
                {pt === "CHARACTER" ? "Characters" : pt === "STAFF" ? "Staff" : pt === "STUDIO" ? "Studios" : "Users"}
              </button>
            ))}
          </div>
        )}
      </header>

      {/* ── Filter panel ──────────────────────────────────────────────── */}
      {showFilters && searchTab === "media" && (
        <div
          class="shrink-0 overflow-y-auto border-t border-white/7 bg-[rgba(16,14,12,0.7)] px-8 py-5"
          style="max-height: 56vh"
        >
          {/* Genres */}
          <section class="mb-5">
            <p class="mb-2 text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Genres</p>
            <div class="flex flex-wrap gap-1.5">
              {GENRES.map((g) => (
                <FilterPill key={g} label={g} state={genreFilter.get(g)} onToggle={() => handleGenreToggle(g)} />
              ))}
            </div>
          </section>

          {/* Format */}
          <section class="mb-5">
            <p class="mb-2 text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Format</p>
            <div class="flex flex-wrap gap-1.5">
              {formats.map((f) => (
                <span
                  key={f.value}
                  class={`cursor-pointer select-none rounded-full border px-2.5 py-0.5 text-[0.76rem] transition ${
                    formatFilter.includes(f.value)
                      ? "border-[rgba(217,116,82,0.45)] bg-[rgba(217,116,82,0.18)] text-[#d97452]"
                      : "border-white/8 bg-white/4 text-[#7a766e] hover:text-[#c0bdb5]"
                  }`}
                  onClick={() => handleFormatToggle(f.value)}
                >
                  {f.label}
                </span>
              ))}
            </div>
          </section>

          {/* Status / Sort / Year */}
          <section class="mb-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div>
              <p class="mb-1 text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Status</p>
              <select
                class="w-full rounded-xl border border-white/8 bg-white/4 px-2.5 py-1.5 text-[0.82rem] text-[#c0bdb5] focus:outline-none"
                value={statusFilter}
                onChange={(e) => handleStatusChange((e.target as HTMLSelectElement).value)}
              >
                {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div>
              <p class="mb-1 text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Sort</p>
              <select
                class="w-full rounded-xl border border-white/8 bg-white/4 px-2.5 py-1.5 text-[0.82rem] text-[#c0bdb5] focus:outline-none"
                value={sortFilter}
                onChange={(e) => handleSortChange((e.target as HTMLSelectElement).value)}
              >
                {SORT_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div>
              <p class="mb-1 text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Year from</p>
              <input
                type="number" min="1960" max="2030" placeholder="e.g. 2020"
                class="w-full rounded-xl border border-white/8 bg-white/4 px-2.5 py-1.5 text-[0.82rem] text-[#c0bdb5] placeholder-[#3a3830] focus:outline-none"
                value={yearFrom}
                onInput={(e) => handleYearFromChange((e.target as HTMLInputElement).value)}
              />
            </div>
            <div>
              <p class="mb-1 text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Year to</p>
              <input
                type="number" min="1960" max="2030" placeholder="e.g. 2025"
                class="w-full rounded-xl border border-white/8 bg-white/4 px-2.5 py-1.5 text-[0.82rem] text-[#c0bdb5] placeholder-[#3a3830] focus:outline-none"
                value={yearTo}
                onInput={(e) => handleYearToChange((e.target as HTMLInputElement).value)}
              />
            </div>
          </section>

          {/* Tags */}
          <section>
            <div class="mb-2 flex flex-wrap items-center justify-between gap-2">
              <p class="text-[0.7rem] font-semibold uppercase tracking-wider text-[#5a5650]">Tags</p>
              <div class="flex items-center gap-3">
                {/* Min tag rank */}
                <div class="flex items-center gap-2">
                  <span class="text-[0.72rem] text-[#5a5650]">Min %</span>
                  <input
                    type="range" min="0" max="100" step="5"
                    class="w-20 accent-[#d97452]"
                    value={minTagRank}
                    onInput={(e) => handleMinTagRankChange(parseInt((e.target as HTMLInputElement).value))}
                  />
                  <span class="w-7 text-right text-[0.72rem] text-[#7a766e]">{minTagRank > 0 ? `${minTagRank}%` : "\u2013"}</span>
                </div>
                {/* Tag search */}
                <div class="relative">
                  <svg class="pointer-events-none absolute left-2 top-1/2 -translate-y-1/2 text-[#5a5650]"
                    width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
                  </svg>
                  <input
                    type="text" placeholder="Filter tags\u2026"
                    class="w-32 rounded-xl border border-white/8 bg-white/4 py-1 pl-6 pr-3 text-[0.78rem] text-[#c0bdb5] placeholder-[#3a3830] focus:outline-none"
                    value={tagSearch}
                    onInput={(e) => setTagSearch((e.target as HTMLInputElement).value)}
                  />
                </div>
              </div>
            </div>

            {/* Active tags strip */}
            {tagFilter.size > 0 && (
              <div class="mb-2 flex flex-wrap gap-1.5">
                {[...tagFilter.entries()].map(([tag, state]) => (
                  <FilterPill key={tag} label={tag} state={state} onToggle={() => handleTagToggle(tag)} />
                ))}
              </div>
            )}

            {/* Tag category accordion */}
            <div class="space-y-1">
              {filteredCategories.map((cat) => {
                const isOpen = tagSearch.trim() !== "" || expandedCats.has(cat.label);
                const selectedInCat = cat.tags.filter((t) => tagFilter.has(t)).length;
                return (
                  <div key={cat.label} class="rounded-xl border border-white/6 bg-white/2">
                    <button
                      class="flex w-full items-center justify-between px-3 py-1.5 text-left"
                      onClick={() => toggleCategory(cat.label)}
                    >
                      <span class="text-[0.78rem] font-medium text-[#9a9690]">{cat.label}</span>
                      <span class="flex items-center gap-2 text-[0.7rem] text-[#5a5650]">
                        {selectedInCat > 0 && (
                          <span class="text-[#d97452]">{selectedInCat} selected</span>
                        )}
                        {isOpen ? "\u25b2" : "\u25bc"}
                      </span>
                    </button>
                    {isOpen && (
                      <div class="flex flex-wrap gap-1.5 border-t border-white/6 px-3 pb-2.5 pt-2">
                        {cat.tags.map((t) => (
                          <FilterPill key={t} label={t} state={tagFilter.get(t)} onToggle={() => handleTagToggle(t)} />
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </section>

          {activeFilterCount > 0 && (
            <div class="mt-4 text-center">
              <button
                class="text-[0.82rem] text-[#5a5650] transition hover:text-[#d97452]"
                onClick={resetFilters}
              >
                Reset all filters
              </button>
            </div>
          )}
        </div>
      )}

      {/* ── Results ───────────────────────────────────────────────────── */}
      <div class="flex-1 overflow-y-auto px-8 pb-8 pt-4">
        {error && (
          <p class="mb-4 rounded-2xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-[0.85rem] text-red-400">{error}</p>
        )}

        {/* ─ Media results ─ */}
        {searchTab === "media" && (
          <>
            {searching && (
              <div class="space-y-3 pb-2">
                <KaomojiLoadingText label="Hunting titles" index={1} />
                <div class="grid gap-2">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <MediaCardSkeleton key={i} />
                  ))}
                </div>
              </div>
            )}
            {!searched && !searching && activeFilterCount === 0 && (
              <p class="py-20 text-center text-[0.9rem] text-[#5a5650]">
                Type at least 2 characters or apply genre/tag filters
              </p>
            )}
            {searched && results.length === 0 && !searching && (
              <p class="py-20 text-center text-[0.9rem] text-[#5a5650]">No results found</p>
            )}
            {results.length > 0 && (
              <div class="grid gap-2">
                {results.map((item) => (
                  <ResultCard key={item.mediaId} item={item} onAdd={setAddTarget} onDetails={openMediaPanel} />
                ))}
                <p class="pt-1 text-center text-[0.75rem] text-[#3a3830]">{results.length} results (max 50)</p>
              </div>
            )}
          </>
        )}

        {/* ─ People results ─ */}
        {searchTab === "people" && (
          <>
            {searching && (
              <div class="space-y-3 pb-2">
                <KaomojiLoadingText label="Searching people" index={2} />
                <div class="grid gap-2">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <MediaCardSkeleton key={i} compact />
                  ))}
                </div>
              </div>
            )}
            {!peopleSearched && !searching && (
              <p class="py-20 text-center text-[0.9rem] text-[#5a5650]">
                Type at least 2 characters to search
              </p>
            )}

            {/* Characters / Staff */}
            {(peopleType === "CHARACTER" || peopleType === "STAFF") && peopleSearched && (
              <>
                {personResults.length === 0 && !searching && (
                  <p class="py-20 text-center text-[0.9rem] text-[#5a5650]">No results found</p>
                )}
                {personResults.length > 0 && (
                  <div class="grid gap-2">
                    {personResults.map((item) => (
                      <PersonCard
                        key={item.id}
                        item={item}
                        onClick={() => {
                          if (item.kind === "CHARACTER") openCharacterPanel(item.id);
                          else openStaffPanel(item.id);
                        }}
                      />
                    ))}
                  </div>
                )}
              </>
            )}

            {/* Studios */}
            {peopleType === "STUDIO" && peopleSearched && (
              <>
                {studioResults.length === 0 && !searching && (
                  <p class="py-20 text-center text-[0.9rem] text-[#5a5650]">No results found</p>
                )}
                {studioResults.length > 0 && (
                  <div class="grid gap-2">
                    {studioResults.map((item) => (
                      <StudioCard key={item.id} item={item} onClick={() => openStudioPanel(item.id)} />
                    ))}
                  </div>
                )}
              </>
            )}

            {/* Users */}
            {peopleType === "USER" && peopleSearched && (
              <>
                {userResults.length === 0 && !searching && (
                  <p class="py-20 text-center text-[0.9rem] text-[#5a5650]">No results found</p>
                )}
                {userResults.length > 0 && (
                  <div class="grid gap-2">
                    {userResults.map((item) => (
                      <UserCard key={item.id} item={item} onClick={() => openUserPanel(item.name)} />
                    ))}
                  </div>
                )}
              </>
            )}
          </>
        )}
      </div>

      {/* ── Modals ────────────────────────────────────────────────────── */}
      {addTarget && (
        <AddModal item={addTarget} onClose={() => setAddTarget(null)} onAdded={handleAdded} />
      )}

      {!sideSheet.isMultiPanel && detailsId != null && (
        <MediaDetailsPanel mediaId={detailsId} onClose={() => setDetailsId(null)} onAdded={handleAdded} />
      )}

      {!sideSheet.isMultiPanel && openCharacter != null && (
        <CharacterPanel
          characterId={openCharacter}
          onClose={() => setOpenCharacter(null)}
          onMediaClick={(id) => { setOpenCharacter(null); setDetailsId(id); }}
        />
      )}

      {!sideSheet.isMultiPanel && openStaff != null && (
        <StaffPanel
          staffId={openStaff}
          onClose={() => setOpenStaff(null)}
          onCharacterClick={(id) => { setOpenStaff(null); setOpenCharacter(id); }}
        />
      )}

      {!sideSheet.isMultiPanel && openStudio != null && (
        <StudioPanel
          studioId={openStudio}
          onClose={() => setOpenStudio(null)}
          onMediaClick={(id) => { setOpenStudio(null); setDetailsId(id); }}
        />
      )}

      {!sideSheet.isMultiPanel && openUser != null && (
        <UserPanel username={openUser} onClose={() => setOpenUser(null)} />
      )}
    </div>
  );
}

