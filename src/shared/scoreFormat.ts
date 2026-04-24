export type AniListScoreFormat =
  | "POINT_100"
  | "POINT_10_DECIMAL"
  | "POINT_10"
  | "POINT_5"
  | "POINT_3"
  | "SMILEY";

const DEFAULT_FORMAT: AniListScoreFormat = "POINT_10_DECIMAL";

function clamp(n: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, n));
}

export function normalizeScoreFormat(format: string | null | undefined): AniListScoreFormat {
  const f = String(format ?? "").toUpperCase();
  if (f === "POINT_100" || f === "POINT_10_DECIMAL" || f === "POINT_10" || f === "POINT_5" || f === "POINT_3" || f === "SMILEY") {
    return f;
  }
  return DEFAULT_FORMAT;
}

export function formatScore(rawScore10: number | null | undefined, format: string | null | undefined): string {
  if (rawScore10 == null || !Number.isFinite(rawScore10) || rawScore10 <= 0) return "—";
  const f = normalizeScoreFormat(format);
  const s = clamp(rawScore10, 0, 10);

  if (f === "POINT_100") return String(Math.round(s * 10));
  if (f === "POINT_10_DECIMAL") return s.toFixed(1).replace(/\.0$/, "");
  if (f === "POINT_10") return String(Math.round(s));
  if (f === "POINT_5") {
    const stars = clamp(Math.round(s / 2), 1, 5);
    return "★".repeat(stars);
  }
  if (f === "POINT_3") {
    const v3 = clamp(Math.round((s / 10) * 3), 1, 3);
    return `${v3}/3`;
  }

  const mood = clamp(Math.round((s / 10) * 3), 1, 3);
  if (mood === 1) return ":(";
  if (mood === 2) return ":|";
  return ":)";
}

export function rawScoreToInput(rawScore10: number | null | undefined, format: string | null | undefined): string {
  if (rawScore10 == null || !Number.isFinite(rawScore10) || rawScore10 <= 0) return "";
  const f = normalizeScoreFormat(format);
  const s = clamp(rawScore10, 0, 10);

  if (f === "POINT_100") return String(Math.round(s * 10));
  if (f === "POINT_10_DECIMAL") return s.toFixed(1).replace(/\.0$/, "");
  if (f === "POINT_10") return String(Math.round(s));
  if (f === "POINT_5") return String(clamp(Math.round(s / 2), 0, 5));
  if (f === "POINT_3") return String(clamp(Math.round((s / 10) * 3), 0, 3));
  return String(clamp(Math.round((s / 10) * 3), 1, 3));
}

export function inputScoreToRaw(input: string, format: string | null | undefined): number | null {
  const trimmed = input.trim();
  if (trimmed === "") return null;
  const n = Number(trimmed);
  if (!Number.isFinite(n)) return null;

  const f = normalizeScoreFormat(format);
  let raw: number;

  if (f === "POINT_100") raw = clamp(n, 0, 100) / 10;
  else if (f === "POINT_10_DECIMAL") raw = clamp(n, 0, 10);
  else if (f === "POINT_10") raw = clamp(Math.round(n), 0, 10);
  else if (f === "POINT_5") raw = clamp(Math.round(n), 0, 5) * 2;
  else if (f === "POINT_3") raw = clamp(Math.round(n), 0, 3) * (10 / 3);
  else raw = clamp(Math.round(n), 1, 3) * (10 / 3);

  return Number(raw.toFixed(1));
}

export function scoreInputConfig(format: string | null | undefined): {
  label: string;
  min: number;
  max: number;
  step: number;
  hint?: string;
} {
  const f = normalizeScoreFormat(format);
  if (f === "POINT_100") return { label: "Score (0-100)", min: 0, max: 100, step: 1 };
  if (f === "POINT_10_DECIMAL") return { label: "Score (0-10)", min: 0, max: 10, step: 0.1 };
  if (f === "POINT_10") return { label: "Score (0-10)", min: 0, max: 10, step: 1 };
  if (f === "POINT_5") return { label: "Score (0-5)", min: 0, max: 5, step: 1, hint: "Stars" };
  if (f === "POINT_3") return { label: "Score (0-3)", min: 0, max: 3, step: 1 };
  return { label: "Mood score (1-3)", min: 1, max: 3, step: 1, hint: "1=:(  2=:|  3=:)" };
}
