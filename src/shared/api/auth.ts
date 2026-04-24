import { invoke } from "@tauri-apps/api/core";
import type {
  AniListConfigStatus,
  AniListViewer,
  AuthRequestPlan,
  AuthSessionStatus,
} from "../types/app";
import {
  getOnlineStatus,
  initializeOnlineStatus,
} from "../network/onlineStatus";

export function prepareAuthRequest() {
  return invoke<AuthRequestPlan>("prepare_auth_request");
}

export function getAniListConfigStatus() {
  return invoke<AniListConfigStatus>("get_anilist_config_status");
}

export function getViewer() {
  initializeOnlineStatus();
  if (!getOnlineStatus()) {
    return Promise.reject(new Error("[OFFLINE] No network connection"));
  }
  return invoke<AniListViewer>("get_viewer");
}

export function getAuthSessionStatus() {
  return invoke<AuthSessionStatus>("get_auth_session_status");
}

export function storeAccessToken(accessToken: string) {
  return invoke<AuthSessionStatus>("store_access_token", { accessToken });
}

export function clearAccessToken() {
  return invoke<AuthSessionStatus>("clear_access_token");
}