import type { DetailPoint, NavigationItem } from "../shared/types/app";

export const NAVIGATION: NavigationItem[] = [
  {
    id: "overview",
    label: "Home",
    eyebrow: "Start here",
    summary: "Library overview, account status, and the next useful action.",
  },
  {
    id: "auth",
    label: "Account",
    eyebrow: "AniList",
    summary: "Sign in, reconnect, or inspect the local AniList session.",
  },
  {
    id: "library",
    label: "Library",
    eyebrow: "Local first",
    summary: "Collection overview and local list state backed by SQLite.",
  },
  {
    id: "activity",
    label: "Activity",
    eyebrow: "Social feed",
    summary: "Following activity feed from AniList in a dedicated screen.",
  },
  {
    id: "notifications",
    label: "Notifications",
    eyebrow: "AniList inbox",
    summary: "Airing, activity, forum, follows, media, and submissions updates with direct links.",
  },
  {
    id: "search",
    label: "Discover",
    eyebrow: "AniList direct",
    summary: "Find media, add it quickly, and grow the local library.",
  },
  {
    id: "schedule",
    label: "Airing",
    eyebrow: "Airing UX",
    summary: "Upcoming episodes and quick progress actions in one place.",
  },
  {
    id: "settings",
    label: "Settings",
    eyebrow: "Local app",
    summary: "Control local storage, sync expectations, and account behavior.",
  },
  {
    id: "statistics",
    label: "Stats",
    eyebrow: "Derived later",
    summary: "Usage insights, progress trends, and activity-derived views.",
  },
];

export const FOUNDATION_DECISIONS: DetailPoint[] = [
  {
    title: "Responsive by default",
    description:
      "The shell is built around stacked layouts and compact navigation so the same web codebase can scale down for mobile targets later.",
  },
  {
    title: "Rust owns the boundary",
    description:
      "Auth, database, AniList transport, notifications, and cache orchestration stay in Tauri commands instead of leaking into the Preact tree.",
  },
  {
    title: "Local-only runtime",
    description:
      "There is no app-owned cloud layer in the scaffold. The only remote system planned here is AniList itself.",
  },
];

export const NEXT_IMPLEMENTATION_STEPS: DetailPoint[] = [
  {
    title: "Database layer",
    description:
      "Introduce SQLite migrations and normalized local models before porting any Flutter screens 1:1.",
  },
  {
    title: "Auth flow",
    description:
      "Implement Windows-first OAuth callback handling with explicit timeout, retry, and manual fallback pathways.",
  },
  {
    title: "Feature routing",
    description:
      "Swap the current section switcher for real routing once the first domain pages need deep links and nested states.",
  },
];