/**
 * Renders AniList Markdown V2 as styled JSX.
 *
 * Supported syntax:
 *   [text](url)      → clickable link (opens in browser via Tauri opener)
 *   __text__         → bold
 *   _text_           → italic
 *   ~~text~~         → strikethrough
 *   ~!text!~         → spoiler (click to reveal)
 *   \n               → line break
 *
 * HTML tags are stripped before parsing.
 */

import { useState } from "preact/hooks";
import type { ComponentChild } from "preact";
import { openUrl } from "@tauri-apps/plugin-opener";

// ─── Token types ─────────────────────────────────────────────────────────────

type Seg =
  | { k: "text";    v: string }
  | { k: "bold";    v: string }
  | { k: "italic";  v: string }
  | { k: "strike";  v: string }
  | { k: "link";    text: string; url: string }
  | { k: "spoiler"; v: string };

type LinePart =
  | { k: "text"; v: string }
  | { k: "img"; url: string; size: number };

const URL_RE = /^https?:\/\/[^\s<>()]+/;
const IMG_TAG_RE = /img(\d{1,4})?\((https?:\/\/[^)\s]+)\)/gi;

// ─── Inline parser ────────────────────────────────────────────────────────────

function parseInline(src: string): Seg[] {
  const out: Seg[] = [];
  let i = 0;
  let buf = "";

  const flush = () => {
    if (buf) { out.push({ k: "text", v: buf }); buf = ""; }
  };

  while (i < src.length) {
    // Link: [text](url)
    if (src[i] === "[") {
      const cb = src.indexOf("]", i + 1);
      if (cb > i && src[cb + 1] === "(") {
        const cp = src.indexOf(")", cb + 2);
        if (cp > cb) {
          flush();
          out.push({ k: "link", text: src.slice(i + 1, cb), url: src.slice(cb + 2, cp) });
          i = cp + 1; continue;
        }
      }
    }

    // Bare URL: https://...
    if (src[i] === "h") {
      const rest = src.slice(i);
      const m = rest.match(URL_RE);
      if (m && m[0]) {
        flush();
        const url = m[0].replace(/[.,;:!?]+$/, "");
        out.push({ k: "link", text: url, url });
        i += m[0].length;
        continue;
      }
    }

    // Spoiler: ~!text!~  (must check before ~~ and ~)
    if (src[i] === "~" && src[i + 1] === "!") {
      const ce = src.indexOf("!~", i + 2);
      if (ce > i) {
        flush();
        out.push({ k: "spoiler", v: src.slice(i + 2, ce) });
        i = ce + 2; continue;
      }
    }

    // Bold: __text__  (must check before single _)
    if (src[i] === "_" && src[i + 1] === "_") {
      const ce = src.indexOf("__", i + 2);
      if (ce > i) {
        flush();
        out.push({ k: "bold", v: src.slice(i + 2, ce) });
        i = ce + 2; continue;
      }
    }

    // Italic: _text_
    if (src[i] === "_" && src[i + 1] !== "_") {
      const ce = src.indexOf("_", i + 1);
      if (ce > i) {
        flush();
        out.push({ k: "italic", v: src.slice(i + 1, ce) });
        i = ce + 1; continue;
      }
    }

    // Strikethrough: ~~text~~
    if (src[i] === "~" && src[i + 1] === "~") {
      const ce = src.indexOf("~~", i + 2);
      if (ce > i) {
        flush();
        out.push({ k: "strike", v: src.slice(i + 2, ce) });
        i = ce + 2; continue;
      }
    }

    buf += src[i]; i++;
  }

  flush();
  return out;
}

// ─── Spoiler span (needs local state) ────────────────────────────────────────

function SpoilerSpan({ text }: { text: string }) {
  const [revealed, setRevealed] = useState(false);
  return (
    <span
      class={`cursor-pointer rounded px-0.5 transition-colors ${
        revealed
          ? "bg-white/10"
          : "select-none bg-[#3a3830] text-transparent hover:bg-[#4a4840]"
      }`}
      onClick={() => setRevealed((v) => !v)}
      title={revealed ? "Click to hide" : "Spoiler — click to reveal"}
    >
      {text}
    </span>
  );
}

function isAniListUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return u.hostname === "anilist.co" || u.hostname.endsWith(".anilist.co");
  } catch {
    return false;
  }
}

function parseLineParts(line: string): LinePart[] {
  const out: LinePart[] = [];
  let cursor = 0;
  let match: RegExpExecArray | null;

  IMG_TAG_RE.lastIndex = 0;
  while ((match = IMG_TAG_RE.exec(line)) !== null) {
    const start = match.index;
    const end = start + match[0].length;
    if (start > cursor) {
      out.push({ k: "text", v: line.slice(cursor, start) });
    }
    const parsedSize = Number.parseInt(match[1] ?? "100", 10);
    const size = Number.isFinite(parsedSize) ? Math.max(32, Math.min(parsedSize, 1000)) : 100;
    out.push({ k: "img", url: match[2], size });
    cursor = end;
  }

  if (cursor < line.length) {
    out.push({ k: "text", v: line.slice(cursor) });
  }

  return out.length > 0 ? out : [{ k: "text", v: line }];
}

// ─── Line renderer ────────────────────────────────────────────────────────────

function renderSegs(
  segs: Seg[],
  keyPrefix: string,
  onLinkClick?: (url: string) => boolean | Promise<boolean> | void,
  renderLink?: (link: { text: string; url: string; isAniList: boolean }) => ComponentChild | null | undefined,
) {
  return segs.map((seg, i) => {
    const key = `${keyPrefix}-${i}`;
    switch (seg.k) {
      case "text":
        return <span key={key}>{seg.v}</span>;
      case "bold":
        return <strong key={key} class="font-semibold text-[#e8e4dc]">{seg.v}</strong>;
      case "italic":
        return <em key={key} class="italic">{seg.v}</em>;
      case "strike":
        return <s key={key} class="line-through opacity-50">{seg.v}</s>;
      case "link":
        const isAni = isAniListUrl(seg.url);
        const custom = renderLink?.({ text: seg.text, url: seg.url, isAniList: isAni });
        if (custom != null) return <span key={key}>{custom}</span>;
        return (
          <a
            key={key}
            class={`cursor-pointer transition-colors ${
              isAni
                ? "inline-flex items-center rounded-full border border-[#7ca4be]/35 bg-[#7ca4be]/12 px-2 py-0.5 text-[#b7d3e4] no-underline hover:border-[#9fc4db]/55 hover:text-[#cde4f0]"
                : "text-[#7ca4be] underline underline-offset-2 hover:text-[#9fc4db]"
            }`}
            onClick={async (e) => {
              e.preventDefault();
              try {
                const handled = await onLinkClick?.(seg.url);
                if (handled) return;
              } catch {
                // Fall through to opener.
              }
              openUrl(seg.url).catch(() => {});
            }}
          >
            {seg.text}
          </a>
        );
      case "spoiler":
        return <SpoilerSpan key={key} text={seg.v} />;
    }
  });
}

// ─── Public component ─────────────────────────────────────────────────────────

/** Strips HTML entities from text. */
function decodeEntities(s: string) {
  return s
    .replace(/&amp;/g,  "&")
    .replace(/&lt;/g,   "<")
    .replace(/&gt;/g,   ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g,  "'")
    .replace(/&nbsp;/g, " ");
}

export interface AnilistMarkdownProps {
  /** Raw AniList description text (may contain HTML tags + markdown). */
  text: string;
  class?: string;
  /** Optional internal link handler; return true if handled in-app. */
  onLinkClick?: (url: string) => boolean | Promise<boolean> | void;
  /** Optional custom renderer for links (e.g. rich preview cards). */
  renderLink?: (link: { text: string; url: string; isAniList: boolean }) => ComponentChild | null | undefined;
}

export function AnilistMarkdown({ text, class: cls, onLinkClick, renderLink }: AnilistMarkdownProps) {
  const clean = decodeEntities(
    text
      .replace(/<br\s*\/?>/gi, "\n")  // <br> → newline before stripping
      .replace(/<[^>]+>/g, "")        // strip remaining HTML tags
  ).trim();

  const lines = clean.split("\n");

  return (
    <span class={cls}>
      {lines.map((line, i) => (
        <span key={i}>
          {i > 0 && <br />}
          {parseLineParts(line).map((part, partIndex) => {
            if (part.k === "text") {
              return (
                <span key={`${i}-txt-${partIndex}`}>
                  {renderSegs(parseInline(part.v), `${i}-txt-${partIndex}`, onLinkClick, renderLink)}
                </span>
              );
            }

            return (
              <button
                key={`${i}-img-${partIndex}`}
                type="button"
                class="mx-1 inline-flex align-middle"
                title="Open image"
                onClick={() => void openUrl(part.url)}
              >
                <img
                  src={part.url}
                  alt="AniList embedded"
                  loading="lazy"
                  class="rounded-md border border-white/10 object-cover"
                  style={{ width: `${part.size}px`, maxWidth: "100%" }}
                />
              </button>
            );
          })}
        </span>
      ))}
    </span>
  );
}

// ─── Helper: plain text extraction (for length checks / truncation) ───────────

export function anilistPlainText(text: string): string {
  return text
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1") // [text](url) → text
    .replace(/__([^_]+)__/g, "$1")           // __bold__ → bold
    .replace(/_([^_]+)_/g, "$1")             // _italic_ → italic
    .replace(/~~([^~]+)~~/g, "$1")           // ~~strike~~ → strike
    .replace(/~!([^!]+)!~/g, "$1")           // ~!spoiler!~ → spoiler
    .replace(/img\d*\((https?:\/\/[^)\s]+)\)/gi, "$1") // img120(url) → url
    .replace(/&amp;/g,  "&")
    .replace(/&lt;/g,   "<")
    .replace(/&gt;/g,   ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g,  "'")
    .replace(/&nbsp;/g, " ")
    .trim();
}
