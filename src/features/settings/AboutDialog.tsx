import { useEffect, useState } from "preact/hooks";
import { openUrl } from "@tauri-apps/plugin-opener";
import { getBootstrapPayload } from "../../shared/api/bootstrap";
import type { BootstrapPayload } from "../../shared/types/app";

interface AboutDialogProps {
  onClose: () => void;
}

const EXTERNAL_LINKS = [
  {
    label: "GitHub Repository",
    url: "https://github.com/Baconana-chan/miyolist-public",
    icon: "🔗",
  },
  {
    label: "AniList Profile",
    url: "https://anilist.co/user/Baconana/",
    icon: "👤",
  },
  {
    label: "Website",
    url: "https://miyo.my/",
    icon: "🌐",
  },
];

const DEPENDENCY_ACKS = [
  { name: "preact", license: "MIT", url: "https://preactjs.com/" },
  { name: "@tauri-apps/api", license: "MIT OR Apache-2.0", url: "https://tauri.app/" },
  { name: "@tauri-apps/plugin-opener", license: "MIT OR Apache-2.0", url: "https://tauri.app/" },
  { name: "@preact/preset-vite", license: "MIT", url: "https://preactjs.com/" },
  { name: "vite", license: "MIT", url: "https://vite.dev/" },
  { name: "typescript", license: "Apache-2.0", url: "https://www.typescriptlang.org/" },
  { name: "tailwindcss", license: "MIT", url: "https://tailwindcss.com/" },
  { name: "@tailwindcss/vite", license: "MIT", url: "https://tailwindcss.com/" },
  { name: "tauri", license: "MIT OR Apache-2.0", url: "https://tauri.app/" },
  { name: "tauri-build", license: "MIT OR Apache-2.0", url: "https://tauri.app/" },
  { name: "tauri-plugin-opener", license: "MIT OR Apache-2.0", url: "https://tauri.app/" },
  { name: "tauri-plugin-notification", license: "MIT OR Apache-2.0", url: "https://tauri.app/" },
  { name: "rusqlite", license: "MIT", url: "https://github.com/rusqlite/rusqlite" },
  { name: "reqwest", license: "MIT OR Apache-2.0", url: "https://github.com/seanmonstar/reqwest" },
  { name: "serde", license: "MIT OR Apache-2.0", url: "https://serde.rs/" },
  { name: "serde_json", license: "MIT OR Apache-2.0", url: "https://serde.rs/" },
  { name: "uuid", license: "MIT OR Apache-2.0", url: "https://github.com/uuid-rs/uuid" },
  { name: "url", license: "MIT OR Apache-2.0", url: "https://github.com/servo/rust-url" },
  { name: "dotenvy", license: "MIT OR Apache-2.0", url: "https://github.com/allan2/dotenvy" },
  { name: "keyring", license: "MIT OR Apache-2.0", url: "https://github.com/hwchen/keyring-rs" },
] as const;

const THIRD_PARTY_SERVICES = [
  { name: "AniList GraphQL", status: "In use", url: "https://anilist.co/" },
  { name: "AnimeThemes.moe", status: "Planned", url: "https://animethemes.moe/" },
  { name: "JustWatch", status: "Planned", url: "https://www.justwatch.com/" },
  { name: "MangaUpdates", status: "Planned", url: "https://www.mangaupdates.com/" },
  { name: "Kitsu", status: "Planned", url: "https://kitsu.app/" },
] as const;

export function AboutDialog({ onClose }: AboutDialogProps) {
  const [bootstrap, setBootstrap] = useState<BootstrapPayload | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getBootstrapPayload()
      .then(setBootstrap)
      .catch((e) => console.error("Failed to load bootstrap:", e))
      .finally(() => setLoading(false));
  }, []);

  const handleOpenLink = async (url: string) => {
    try {
      openUrl(url);
    } catch (e) {
      console.error("Failed to open URL:", e);
    }
  };

  return (
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4 backdrop-blur-sm"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div class="w-full max-w-2xl rounded-3xl border border-white/10 bg-[#1a1815] p-6 shadow-2xl max-h-[90dvh] overflow-y-auto">
        {/* Header */}
        <div class="flex items-start justify-between gap-3 mb-4">
          <div class="flex-1">
            <h2 class="text-lg font-bold text-[#f1efe7]">About MiyoList</h2>
          </div>
          <button
            class="rounded-full p-1.5 text-[#7a766e] transition hover:text-[#f1efe7]"
            onClick={onClose}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div class="space-y-5">
          {/* Version info */}
          <div class="space-y-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-3">
            <div class="flex items-center justify-between">
              <span class="text-[0.8rem] font-medium text-[#9a9690] uppercase tracking-wider">Product</span>
              <span class="text-sm font-semibold text-[#f1efe7]">
                {loading ? "Loading…" : bootstrap?.productName || "MiyoList"}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-[0.8rem] font-medium text-[#9a9690] uppercase tracking-wider">Version</span>
              <span class="text-sm font-semibold text-[#d97452]">
                {loading ? "Loading…" : bootstrap?.appVersion || "—"}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-[0.8rem] font-medium text-[#9a9690] uppercase tracking-wider">Platform</span>
              <span class="text-sm font-mono text-[#b5b0a5]">
                {loading ? "Loading…" : bootstrap?.primaryPlatform || "—"}
              </span>
            </div>
          </div>

          {/* Description */}
          <div class="space-y-2">
            <p class="text-[0.9rem] text-[#b5b0a5] leading-relaxed">
              A local-first AniList desktop client built with{" "}
              <span class="text-[#d97452] font-semibold">Tauri</span>, <span class="text-[#d97452] font-semibold">Preact</span>, and{" "}
              <span class="text-[#d97452] font-semibold">Rust</span>.
            </p>
            <p class="text-[0.9rem] text-[#b5b0a5] leading-relaxed">
              Your library and activity stay on this device. All data is stored locally in SQLite — nothing is uploaded to a backend.
            </p>
          </div>

          {/* External links */}
          <div class="space-y-2">
            <h3 class="text-[0.8rem] font-semibold text-[#9a9690] uppercase tracking-wider">Links</h3>
            <div class="space-y-2">
              {EXTERNAL_LINKS.map((link) => (
                <button
                  key={link.url}
                  onClick={() => handleOpenLink(link.url)}
                  class="w-full flex items-center justify-between rounded-lg border border-[#3a3836] bg-[#252321] px-4 py-3 text-left transition hover:border-[#d97452]/40 hover:bg-[#2d2a27]"
                >
                  <span class="text-sm font-medium text-[#b5b0a5] group-hover:text-[#f1efe7]">
                    {link.icon} {link.label}
                  </span>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-[#7a766e]">
                    <path d="M7 17L17 7M17 7H7M17 7V17" />
                  </svg>
                </button>
              ))}
            </div>
          </div>

          {/* Dependencies and licenses */}
          <div class="space-y-2">
            <h3 class="text-[0.8rem] font-semibold text-[#9a9690] uppercase tracking-wider">Dependencies and Licenses</h3>
            <p class="text-[0.78rem] text-[#7a766e] leading-relaxed">
              MiyoList is licensed under MIT. The project also relies on open-source packages listed below with their original licenses.
            </p>
            <div class="rounded-xl border border-[#2e2c2a] bg-[#1e1c1a] divide-y divide-[#2e2c2a]">
              {DEPENDENCY_ACKS.map((dep) => (
                <button
                  key={dep.name}
                  class="w-full flex items-center justify-between gap-3 px-3 py-2.5 text-left transition hover:bg-[#252321]"
                  onClick={() => handleOpenLink(dep.url)}
                  title={`Open ${dep.name}`}
                >
                  <span class="text-[0.82rem] text-[#d8d3cb]">{dep.name}</span>
                  <span class="rounded-full border border-[#3a3836] px-2 py-0.5 text-[0.68rem] text-[#9a9690]">{dep.license}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Third-party services */}
          <div class="space-y-2">
            <h3 class="text-[0.8rem] font-semibold text-[#9a9690] uppercase tracking-wider">Third-party services</h3>
            <p class="text-[0.78rem] text-[#7a766e] leading-relaxed">
              Current and planned integrations. For planned metadata providers (AnimeThemes.moe, JustWatch, MangaUpdates, Kitsu),
              MiyoList performs title-based lookup requests only. User library/activity data is not uploaded to these services.
            </p>
            <div class="rounded-xl border border-[#2e2c2a] bg-[#1e1c1a] divide-y divide-[#2e2c2a]">
              {THIRD_PARTY_SERVICES.map((service) => (
                <button
                  key={service.name}
                  class="w-full flex items-center justify-between gap-3 px-3 py-2.5 text-left transition hover:bg-[#252321]"
                  onClick={() => handleOpenLink(service.url)}
                  title={`Open ${service.name}`}
                >
                  <span class="text-[0.82rem] text-[#d8d3cb]">{service.name}</span>
                  <span class={`rounded-full border px-2 py-0.5 text-[0.68rem] ${service.status === "In use" ? "border-[rgba(100,180,100,0.35)] text-[#9cd89c]" : "border-[#3a3836] text-[#9a9690]"}`}>
                    {service.status}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Credits */}
          <div class="rounded-xl bg-[#252321] px-4 py-3 space-y-1">
            <p class="text-[0.75rem] text-[#7a766e]">
              Made by <span class="text-[#d97452] font-semibold">Baconana</span>
            </p>
            <p class="text-[0.75rem] text-[#7a766e]">
              Powered by <span class="text-[#b5b0a5] font-medium">AniList GraphQL</span>
            </p>
            <p class="text-[0.75rem] text-[#7a766e]">
              Open-source acknowledgments are listed above with their respective licenses.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
