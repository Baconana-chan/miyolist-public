import { invoke } from "@tauri-apps/api/core";
import type { BootstrapPayload } from "../types/app";

export function getBootstrapPayload() {
  return invoke<BootstrapPayload>("get_bootstrap");
}