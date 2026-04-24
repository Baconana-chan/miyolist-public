import { invoke } from "@tauri-apps/api/core";

const PROBE_INTERVAL_MS = 30_000;

type Listener = (online: boolean) => void;

let online = typeof navigator !== "undefined" ? navigator.onLine : true;
let initialized = false;
let inFlightProbe: Promise<boolean> | null = null;
const listeners = new Set<Listener>();

function emit(nextOnline: boolean) {
  if (online === nextOnline) return;
  online = nextOnline;
  for (const listener of listeners) listener(online);
}

async function pingAniList(): Promise<boolean> {
  try {
    // Probe via backend to avoid browser/webview CORS/CORB restrictions.
    return await invoke<boolean>("get_online_status");
  } catch {
    return false;
  }
}

async function probe() {
  if (inFlightProbe) {
    emit(await inFlightProbe);
    return;
  }
  inFlightProbe = pingAniList();
  const next = await inFlightProbe;
  inFlightProbe = null;
  emit(next);
}

export function initializeOnlineStatus() {
  if (initialized || typeof window === "undefined") return;
  initialized = true;

  const handleOnline = () => {
    // Browser believes connection is up. Confirm AniList reachability.
    void probe();
  };
  const handleOffline = () => {
    emit(false);
  };

  window.addEventListener("online", handleOnline);
  window.addEventListener("offline", handleOffline);

  setInterval(() => {
    void probe();
  }, PROBE_INTERVAL_MS);

  // Initial reachability probe on app startup.
  void probe();
}

export function getOnlineStatus() {
  return online;
}

export function probeOnlineStatusNow() {
  return probe();
}

export function subscribeOnlineStatus(listener: Listener) {
  listeners.add(listener);
  listener(online);
  return () => {
    listeners.delete(listener);
  };
}
