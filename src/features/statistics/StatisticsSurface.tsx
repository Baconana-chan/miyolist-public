import { useCallback, useEffect, useMemo, useState } from "preact/hooks";
import {
  getAppSettings,
  getAnnualWrapUp,
  getActivityHeatmap,
  getActivityLogByDate,
  getActivityMonthlyTotals,
  getLibraryStats,
} from "../../shared/api/database";
import type {
  ActivityEntry,
  AnnualWrapUp,
  HeatmapDay,
  LibraryStats,
  MonthlyActivityCount,
} from "../../shared/types/app";
import { formatScore } from "../../shared/scoreFormat";

// ─── helpers ─────────────────────────────────────────────────────────────────

function fmt(n: number) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return String(n);
}

function minutesToHours(m: number) {
  const h = Math.round(m / 60);
  if (h < 24) return `${h}h`;
  const d = (h / 24).toFixed(1);
  return `${d}d`;
}

function activityLabel(e: ActivityEntry, scoreFormat: string): string {
  switch (e.activityType) {
    case "list_update":
      return e.note ?? "List entry updated";
    case "progress_update": {
      const diff =
        e.oldValue != null && e.newValue != null
          ? Number(e.newValue) - Number(e.oldValue)
          : null;
      const arrow = diff != null && diff >= 0 ? `+${diff}` : String(diff ?? "");
      return `Progress ${arrow} → ep ${e.newValue ?? "?"}`;
    }
    case "status_change":
      return `Status: ${e.oldValue ?? "?"} → ${e.newValue ?? "?"}`;
    case "score_change":
      return `Score: ${formatScore(e.oldValue != null ? Number(e.oldValue) : null, scoreFormat)} → ${formatScore(e.newValue != null ? Number(e.newValue) : null, scoreFormat)}`;
    case "added":
      return "Added to library";
    case "completed":
      return "Completed";
    default:
      return e.activityType;
  }
}

function relativeTime(iso: string): string {
  const d = Date.parse(iso);
  if (isNaN(d)) return iso;
  const diff = (Date.now() - d) / 1000;
  if (diff < 60) return "just now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  const days = Math.floor(diff / 86400);
  if (days < 30) return `${days}d ago`;
  return new Date(d).toLocaleDateString();
}

function downloadAnnualWrapUpImage(data: AnnualWrapUp, scoreFormat: string) {
  const canvas = document.createElement("canvas");
  canvas.width = 1600;
  canvas.height = 900;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;

  const grad = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
  grad.addColorStop(0, "#0f1730");
  grad.addColorStop(0.55, "#121e42");
  grad.addColorStop(1, "#0f1224");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.fillStyle = "rgba(255,255,255,0.06)";
  ctx.fillRect(48, 48, canvas.width - 96, canvas.height - 96);

  ctx.fillStyle = "#e8ecff";
  ctx.font = "700 56px 'Segoe UI', sans-serif";
  ctx.fillText(`MiyoList Wrapped ${data.year}`, 92, 140);

  ctx.fillStyle = "#9ec3ff";
  ctx.font = "600 28px 'Segoe UI', sans-serif";
  ctx.fillText("Annual summary generated automatically", 92, 185);

  const drawMetric = (label: string, value: string, x: number, y: number) => {
    ctx.fillStyle = "rgba(255,255,255,0.08)";
    ctx.fillRect(x, y, 320, 120);
    ctx.fillStyle = "#b6c8f2";
    ctx.font = "600 20px 'Segoe UI', sans-serif";
    ctx.fillText(label, x + 18, y + 38);
    ctx.fillStyle = "#f2f6ff";
    ctx.font = "700 44px 'Segoe UI', sans-serif";
    ctx.fillText(value, x + 18, y + 90);
  };

  drawMetric("Days active", String(data.daysActive), 92, 240);
  drawMetric("Completed anime", String(data.completedAnime), 428, 240);
  drawMetric("Episodes watched", String(data.episodesWatched), 764, 240);
  drawMetric("Chapters read", String(data.chaptersRead), 1100, 240);

  drawMetric("Mean score", formatScore(data.meanScore, scoreFormat), 92, 382);
  drawMetric("List updates", String(data.listUpdates), 428, 382);

  ctx.fillStyle = "rgba(255,255,255,0.08)";
  ctx.fillRect(764, 382, 656, 262);
  ctx.fillStyle = "#b6c8f2";
  ctx.font = "600 22px 'Segoe UI', sans-serif";
  ctx.fillText("Top genres", 788, 418);
  ctx.fillStyle = "#f2f6ff";
  ctx.font = "700 34px 'Segoe UI', sans-serif";
  data.topGenres.slice(0, 3).forEach((g, i) => {
    ctx.fillText(`${i + 1}. ${g.label}  (${g.count})`, 788, 468 + i * 56);
  });

  ctx.fillStyle = "rgba(255,255,255,0.08)";
  ctx.fillRect(92, 528, 640, 182);
  ctx.fillStyle = "#b6c8f2";
  ctx.font = "600 22px 'Segoe UI', sans-serif";
  ctx.fillText("Year highlights", 116, 566);
  ctx.fillStyle = "#e8ecff";
  ctx.font = "600 28px 'Segoe UI', sans-serif";
  ctx.fillText(`Top studio: ${data.topStudio ?? "N/A"}`, 116, 612);
  ctx.fillText(`Most active weekday: ${data.mostWatchedWeekday ?? "N/A"}`, 116, 654);

  ctx.fillStyle = "rgba(255,255,255,0.08)";
  ctx.fillRect(764, 660, 656, 174);
  ctx.fillStyle = "#b6c8f2";
  ctx.font = "600 22px 'Segoe UI', sans-serif";
  ctx.fillText("Completion timeline", 788, 698);
  ctx.fillStyle = "#f2f6ff";
  ctx.font = "600 26px 'Segoe UI', sans-serif";
  ctx.fillText(`First: ${data.firstCompletedTitle ?? "N/A"}`, 788, 744);
  ctx.fillText(`Last: ${data.lastCompletedTitle ?? "N/A"}`, 788, 790);

  ctx.fillStyle = "#9ca9cf";
  ctx.font = "500 20px 'Segoe UI', sans-serif";
  ctx.fillText("Generated by MiyoList", 92, 834);

  const fileName = `miyolist-wrapped-${data.year}.png`;
  canvas.toBlob((blob) => {
    if (!blob) return;
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = fileName;
    a.click();
    URL.revokeObjectURL(url);
  }, "image/png");
}

// ─── sub-components ───────────────────────────────────────────────────────────

function StatCard({
  label,
  value,
  sub,
}: {
  label: string;
  value: string;
  sub?: string;
}) {
  return (
    <div class="flex flex-col gap-0.5 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-3">
      <span class="text-xs text-[#7a746e] uppercase tracking-wider">{label}</span>
      <span class="text-2xl font-bold text-[#e8e3dc]">{value}</span>
      {sub && <span class="text-xs text-[#7a746e]">{sub}</span>}
    </div>
  );
}

function BarChart({
  items,
  maxCount,
  accent = "#d97452",
}: {
  items: { label: string; count: number }[];
  maxCount: number;
  accent?: string;
}) {
  if (!items.length) return <p class="text-sm text-[#7a746e]">No data yet.</p>;
  return (
    <div class="flex flex-col gap-1.5">
      {items.map((item) => {
        const pct = maxCount > 0 ? (item.count / maxCount) * 100 : 0;
        return (
          <div key={item.label} class="flex items-center gap-2 text-sm">
            <span class="w-28 shrink-0 truncate text-[#b5b0a5] text-right text-xs">
              {item.label}
            </span>
            <div class="flex-1 relative h-5 rounded-md bg-[#2e2c2a] overflow-hidden">
              <div
                class="h-full rounded-md transition-all"
                style={{ width: `${pct}%`, background: accent }}
              />
            </div>
            <span class="w-8 text-right text-[#7a746e] text-xs">{fmt(item.count)}</span>
          </div>
        );
      })}
    </div>
  );
}

function ScoreHistogram({ buckets, scoreFormat }: { buckets: { score: number; count: number }[]; scoreFormat: string }) {
  const max = Math.max(...buckets.map((b) => b.count), 1);
  return (
    <div class="flex flex-col gap-1">
      {/* Bars row — `h-24` provides the explicit height that each bar's
          `height: %` is computed against.  Putting bars directly under this
          container avoids the previous circular-height bug where the bar's
          percentage height resolved against an auto-height flex column. */}
      <div class="flex items-end gap-1.5 h-24">
        {buckets.map((b) => {
          const pct = (b.count / max) * 100;
          return (
            <div
              key={b.score}
              class="flex-1 rounded-t transition-all"
              style={{
                height: `${pct}%`,
                minHeight: b.count > 0 ? "4px" : "0",
                background: `rgba(217,116,82,${0.4 + (b.score / 10) * 0.6})`,
              }}
              title={`${b.count} entr${b.count === 1 ? "y" : "ies"}`}
            />
          );
        })}
      </div>
      {/* Labels row — kept as separate flex row so it has no influence on
          the bar height calculation above. */}
      <div class="flex gap-1.5">
        {buckets.map((b) => (
          <span key={b.score} class="flex-1 text-center text-[10px] text-[#7a746e]">
            {formatScore(b.score, scoreFormat)}
          </span>
        ))}
      </div>
    </div>
  );
}

function StatusBar({ stats }: { stats: LibraryStats }) {
  const segments = [
    { key: "Watching", count: stats.countCurrent,   color: "#22c55e" },
    { key: "Completed", count: stats.countCompleted, color: "#d97452" },
    { key: "Planning",  count: stats.countPlanning,  color: "#60a5fa" },
    { key: "Dropped",   count: stats.countDropped,   color: "#ef4444" },
    { key: "Paused",    count: stats.countPaused,    color: "#facc15" },
    { key: "Repeating", count: stats.countRepeating, color: "#a78bfa" },
  ].filter((s) => s.count > 0);

  const total = segments.reduce((a, s) => a + s.count, 0) || 1;

  return (
    <div class="flex flex-col gap-2">
      <div class="flex h-4 rounded-full overflow-hidden w-full gap-px">
        {segments.map((s) => (
          <div
            key={s.key}
            class="h-full first:rounded-l-full last:rounded-r-full"
            style={{ width: `${(s.count / total) * 100}%`, background: s.color }}
            title={`${s.key}: ${s.count}`}
          />
        ))}
      </div>
      <div class="flex flex-wrap gap-x-4 gap-y-1">
        {segments.map((s) => (
          <div key={s.key} class="flex items-center gap-1.5 text-xs text-[#b5b0a5]">
            <span class="w-2.5 h-2.5 rounded-sm shrink-0" style={{ background: s.color }} />
            <span>{s.key}</span>
            <span class="text-[#7a746e]">{s.count}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

const MONTH_LABELS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

// GitHub-style heatmap for a full year
function ActivityHeatmap({
  year,
  days,
  selectedDate,
  onSelectDate,
}: {
  year: number;
  days: HeatmapDay[];
  selectedDate: string | null;
  onSelectDate: (date: string) => void;
}) {
  const byDate = useMemo(() => {
    const m: Record<string, number> = {};
    for (const d of days) m[d.date] = d.count;
    return m;
  }, [days]);

  // Build Jan 1 -> Dec 31 grid aligned to Sunday columns.
  const cells = useMemo(() => {
    const jan1 = new Date(year, 0, 1);
    jan1.setHours(0, 0, 0, 0);
    const dec31 = new Date(year, 11, 31);
    dec31.setHours(0, 0, 0, 0);

    const start = new Date(jan1);
    start.setDate(start.getDate() - start.getDay());

    const result: { date: string; count: number; inYear: boolean }[] = [];
    const cur = new Date(start);
    while (cur <= dec31 || cur.getDay() !== 6) {
      const key = cur.toISOString().slice(0, 10);
      result.push({
        date: key,
        count: byDate[key] ?? 0,
        inYear: cur.getFullYear() === year,
      });
      cur.setDate(cur.getDate() + 1);
    }
    return result;
  }, [byDate, year]);

  const maxCount = useMemo(() => Math.max(...cells.map((c) => c.count), 1), [cells]);

  function intensity(count: number) {
    if (count === 0) return "#2e2c2a";
    const t = Math.min(count / maxCount, 1);
    const r = Math.round(30 + t * (217 - 30));
    const g = Math.round(28 + t * (116 - 28));
    const b = Math.round(26 + t * (82 - 26));
    return `rgb(${r},${g},${b})`;
  }

  // group into weeks
  const weeks: typeof cells[] = [];
  for (let i = 0; i < cells.length; i += 7) weeks.push(cells.slice(i, i + 7));

  const monthMarkers = useMemo(() => {
    const firstCellIndexByMonth = new Map<number, number>();
    cells.forEach((cell, idx) => {
      if (!cell.inYear) return;
      const d = new Date(cell.date);
      const month = d.getMonth();
      if (!firstCellIndexByMonth.has(month)) {
        firstCellIndexByMonth.set(month, Math.floor(idx / 7));
      }
    });
    return Array.from(firstCellIndexByMonth.entries());
  }, [cells]);

  return (
    <div class="overflow-x-auto">
      <div class="mb-1.5 relative h-3 min-w-max text-[10px] text-[#7a746e]">
        {monthMarkers.map(([month, weekColumn]) => (
          <span
            key={month}
            class="absolute"
            style={{ left: `${weekColumn * 14}px` }}
          >
            {MONTH_LABELS[month]}
          </span>
        ))}
      </div>
      <div class="flex gap-0.5 min-w-max">
        {weeks.map((week, wi) => (
          <div key={wi} class="flex flex-col gap-0.5">
            {week.map((cell) => (
              <button
                key={cell.date}
                type="button"
                class={`h-3 w-3 rounded-sm ${cell.inYear ? "" : "opacity-35"} ${selectedDate === cell.date ? "ring-1 ring-[#f1efe7]" : ""}`}
                style={{ background: intensity(cell.count) }}
                title={`${cell.date}: ${cell.count} action${cell.count !== 1 ? "s" : ""}`}
                onClick={() => cell.inYear && onSelectDate(cell.date)}
                disabled={!cell.inYear}
              />
            ))}
          </div>
        ))}
      </div>
      {days.length === 0 && (
        <p class="mt-2 text-sm text-[#7a746e]">No activity recorded for {year} yet.</p>
      )}
    </div>
  );
}

function MonthlyProgressChart({ rows }: { rows: MonthlyActivityCount[] }) {
  const nonEmptyRows = useMemo(
    () => rows.filter((r) => r.episodes > 0 || r.chapters > 0),
    [rows],
  );

  const max = useMemo(
    () => Math.max(...nonEmptyRows.map((r) => Math.max(r.episodes, r.chapters)), 1),
    [nonEmptyRows],
  );

  if (nonEmptyRows.length === 0) {
    return <p class="text-sm text-[#7a746e]">No progress updates in this year.</p>;
  }

  return (
    <div class="flex flex-col gap-2">
      {nonEmptyRows.map((row) => {
        const month = MONTH_LABELS[Math.max(0, Math.min(11, row.month - 1))] ?? String(row.month);
        const epPct = (row.episodes / max) * 100;
        const chPct = (row.chapters / max) * 100;
        return (
          <div key={row.month} class="flex items-center gap-2 text-xs">
            <span class="w-8 text-[#7a746e]">{month}</span>
            <div class="flex-1 space-y-1">
              <div class="flex items-center gap-1.5">
                <span class="w-12 text-[#9a9488]">Anime</span>
                <div class="h-2.5 flex-1 overflow-hidden rounded bg-[#2e2c2a]">
                  <div class="h-full rounded bg-[#d97452]" style={{ width: `${epPct}%` }} />
                </div>
                <span class="w-7 text-right text-[#b5b0a5]">{row.episodes}</span>
              </div>
              <div class="flex items-center gap-1.5">
                <span class="w-12 text-[#9a9488]">Manga</span>
                <div class="h-2.5 flex-1 overflow-hidden rounded bg-[#2e2c2a]">
                  <div class="h-full rounded bg-[#7ca4be]" style={{ width: `${chPct}%` }} />
                </div>
                <span class="w-7 text-right text-[#b5b0a5]">{row.chapters}</span>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

function ActivityFeed({ entries, scoreFormat }: { entries: ActivityEntry[]; scoreFormat: string }) {
  if (!entries.length) {
    return (
      <p class="text-sm text-[#7a746e]">No activity yet. Make some changes to your library!</p>
    );
  }
  return (
    <div class="flex flex-col divide-y divide-[#2e2c2a]">
      {entries.slice(0, 50).map((e) => (
        <div key={e.id} class="flex items-center gap-3 py-2.5">
          {e.coverImage ? (
            <img
              src={e.coverImage}
              alt=""
              class="w-8 h-11 rounded object-cover shrink-0 bg-[#2e2c2a]"
            />
          ) : (
            <div class="w-8 h-11 rounded bg-[#2e2c2a] shrink-0" />
          )}
          <div class="flex-1 min-w-0">
            <p class="text-sm text-[#e8e3dc] truncate">{e.title}</p>
            <p class="text-xs text-[#b5b0a5]">{activityLabel(e, scoreFormat)}</p>
          </div>
          <span class="text-xs text-[#7a746e] shrink-0">{relativeTime(e.createdAt)}</span>
        </div>
      ))}
    </div>
  );
}

// ─── Main surface ─────────────────────────────────────────────────────────────

export function StatisticsSurface() {
  const currentYear = new Date().getFullYear();
  const [stats, setStats] = useState<LibraryStats | null>(null);
  const [heatmap, setHeatmap] = useState<HeatmapDay[]>([]);
  const [monthlyTotals, setMonthlyTotals] = useState<MonthlyActivityCount[]>([]);
  const [annualWrapUp, setAnnualWrapUp] = useState<AnnualWrapUp | null>(null);
  const [scoreFormat, setScoreFormat] = useState("POINT_10_DECIMAL");
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [selectedDateEntries, setSelectedDateEntries] = useState<ActivityEntry[]>([]);
  const [loadingDateEntries, setLoadingDateEntries] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [s, h, monthly, annual, settings] = await Promise.all([
        getLibraryStats(),
        getActivityHeatmap(selectedYear),
        getActivityMonthlyTotals(selectedYear),
        getAnnualWrapUp(selectedYear),
        getAppSettings(),
      ]);
      setStats(s);
      setHeatmap(h);
      setMonthlyTotals(monthly);
      setAnnualWrapUp(annual);
      setScoreFormat(settings.scoreFormat || "POINT_10_DECIMAL");
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }, [selectedYear]);

  useEffect(() => {
    load();
  }, [load]);

  const yearOptions = useMemo(() => {
    return Array.from({ length: 6 }, (_, i) => currentYear - i);
  }, [currentYear]);

  const handleSelectDate = useCallback(async (date: string) => {
    setSelectedDate(date);
    setLoadingDateEntries(true);
    try {
      const entries = await getActivityLogByDate(date, 200);
      setSelectedDateEntries(entries);
    } catch {
      setSelectedDateEntries([]);
    } finally {
      setLoadingDateEntries(false);
    }
  }, []);

  const maxGenre = useMemo(
    () => Math.max(...(stats?.genreBreakdown.map((g) => g.count) ?? [1]), 1),
    [stats],
  );
  const maxFormat = useMemo(
    () => Math.max(...(stats?.formatBreakdown.map((f) => f.count) ?? [1]), 1),
    [stats],
  );

  if (loading) {
    return (
      <div class="flex items-center justify-center h-48 text-[#7a746e] text-sm">
        Loading statistics…
      </div>
    );
  }

  if (error) {
    return (
      <div class="flex flex-col items-center justify-center h-48 gap-3">
        <p class="text-sm text-[#ef4444]">{error}</p>
        <button
          class="text-sm text-[#d97452] hover:underline"
          onClick={load}
        >
          Retry
        </button>
      </div>
    );
  }

  if (!stats) return null;

  return (
    <div class="flex flex-col gap-6 p-4 max-w-4xl mx-auto">
      {/* header */}
      <div class="flex items-center">
        <h1 class="text-xl font-bold text-[#e8e3dc]">Statistics</h1>
      </div>

      {/* key numbers */}
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatCard label="Total entries" value={fmt(stats.totalEntries)} />
        <StatCard
          label="Mean score"
          value={formatScore(stats.meanScore, scoreFormat)}
        />
        <StatCard
          label="Episodes watched"
          value={fmt(stats.episodesWatched)}
          sub={
            stats.estimatedMinutes > 0
              ? `≈ ${minutesToHours(stats.estimatedMinutes)}`
              : undefined
          }
        />
        <StatCard
          label="Chapters read"
          value={fmt(stats.chaptersRead)}
          sub={stats.volumesRead > 0 ? `${fmt(stats.volumesRead)} volumes` : undefined}
        />
      </div>

      {/* media type split */}
      <div class="grid grid-cols-3 gap-3">
        <StatCard label="Anime" value={fmt(stats.totalAnime)} />
        <StatCard label="Manga" value={fmt(stats.totalManga)} />
        <StatCard label="Novels" value={fmt(stats.totalNovels)} />
      </div>

      {/* status bar */}
      <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
        <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
          Status breakdown
        </h2>
        <StatusBar stats={stats} />
      </section>

      {/* score distribution */}
      <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
        <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
          Score distribution
        </h2>
        {stats.scoreDistribution.every((b) => b.count === 0) ? (
          <p class="text-sm text-[#7a746e]">No scores recorded yet.</p>
        ) : (
          <ScoreHistogram buckets={stats.scoreDistribution} scoreFormat={scoreFormat} />
        )}
      </section>

          <div class="grid gap-4 md:grid-cols-2">
            {/* format breakdown */}
            <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
              <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
                Format
              </h2>
              <BarChart items={stats.formatBreakdown} maxCount={maxFormat} />
            </section>

            {/* top genres */}
            <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
              <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
                Top genres
              </h2>
              <BarChart items={stats.genreBreakdown} maxCount={maxGenre} />
            </section>
          </div>

          {/* heatmap */}
          <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
            <div class="flex items-center justify-between gap-3">
              <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
                Activity heatmap (from list updates)
              </h2>
              <select
                class="rounded-md border border-[#2e2c2a] bg-[#121110] px-2 py-1 text-xs text-[#e8e3dc]"
                value={selectedYear}
                onChange={(e) => {
                  const next = Number((e.currentTarget as HTMLSelectElement).value);
                  setSelectedYear(next);
                  setSelectedDate(null);
                  setSelectedDateEntries([]);
                }}
              >
                {yearOptions.map((year) => (
                  <option key={year} value={year}>{year}</option>
                ))}
              </select>
            </div>
            <ActivityHeatmap
              year={selectedYear}
              days={heatmap}
              selectedDate={selectedDate}
              onSelectDate={handleSelectDate}
            />
            {selectedDate && (
              <div class="rounded-lg border border-[#2e2c2a] bg-[#171512] p-3">
                <div class="mb-2 flex items-center justify-between">
                    <p class="text-xs font-semibold uppercase tracking-wider text-[#b5b0a5]">
                      List updates on {selectedDate}
                  </p>
                  <button
                    type="button"
                    class="text-[0.72rem] text-[#9a9488] hover:text-[#e8e3dc]"
                    onClick={() => {
                      setSelectedDate(null);
                      setSelectedDateEntries([]);
                    }}
                  >
                    Close
                  </button>
                </div>
                {loadingDateEntries ? (
                  <p class="text-xs text-[#7a746e]">Loading day details…</p>
                ) : selectedDateEntries.length === 0 ? (
                  <p class="text-xs text-[#7a746e]">No entries for this date.</p>
                ) : (
                  <div class="max-h-64 overflow-y-auto">
                    <ActivityFeed entries={selectedDateEntries} scoreFormat={scoreFormat} />
                  </div>
                )}
              </div>
            )}
          </section>

          <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
            <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
              Monthly updates ({selectedYear}, list-based)
            </h2>
            <MonthlyProgressChart rows={monthlyTotals} />
      </section>

          {annualWrapUp && (
            <section class="flex flex-col gap-3 rounded-xl bg-[#1e1c1a] border border-[#2e2c2a] px-4 py-4">
              <div class="flex items-center justify-between gap-3">
                <h2 class="text-sm font-semibold text-[#b5b0a5] uppercase tracking-wider">
                  Annual wrap-up ({selectedYear})
                </h2>
                <button
                  type="button"
                  class="rounded-full border border-[rgba(124,164,190,0.35)] bg-[rgba(124,164,190,0.15)] px-3 py-1 text-xs font-semibold text-[#dfe9ff] transition hover:bg-[rgba(124,164,190,0.24)]"
                  onClick={() => downloadAnnualWrapUpImage(annualWrapUp, scoreFormat)}
                >
                  Export wrap-up PNG
                </button>
              </div>

              <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
                <StatCard label="Days active" value={fmt(annualWrapUp.daysActive)} />
                <StatCard label="Completed anime" value={fmt(annualWrapUp.completedAnime)} />
                <StatCard label="Episodes" value={fmt(annualWrapUp.episodesWatched)} />
                <StatCard label="Chapters" value={fmt(annualWrapUp.chaptersRead)} />
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <div class="rounded-lg border border-[#2e2c2a] bg-[#171512] p-3">
                  <p class="mb-2 text-xs font-semibold uppercase tracking-wider text-[#9a9488]">Top genres</p>
                  {annualWrapUp.topGenres.length === 0 ? (
                    <p class="text-sm text-[#7a746e]">No genre data for this year.</p>
                  ) : (
                    <ol class="space-y-1 text-sm text-[#e8e3dc]">
                      {annualWrapUp.topGenres.map((g, idx) => (
                        <li key={g.label}>{idx + 1}. {g.label} <span class="text-[#9a9488]">({g.count})</span></li>
                      ))}
                    </ol>
                  )}
                </div>

                <div class="rounded-lg border border-[#2e2c2a] bg-[#171512] p-3 text-sm text-[#e8e3dc] space-y-2">
                  <p><span class="text-[#9a9488]">Top studio:</span> {annualWrapUp.topStudio ?? "N/A"}</p>
                  <p><span class="text-[#9a9488]">Most active weekday:</span> {annualWrapUp.mostWatchedWeekday ?? "N/A"}</p>
                  <p><span class="text-[#9a9488]">First completed:</span> {annualWrapUp.firstCompletedTitle ?? "N/A"}</p>
                  <p><span class="text-[#9a9488]">Last completed:</span> {annualWrapUp.lastCompletedTitle ?? "N/A"}</p>
                  <p><span class="text-[#9a9488]">Mean score:</span> {formatScore(annualWrapUp.meanScore, scoreFormat)}</p>
                </div>
              </div>
            </section>
          )}
    </div>
  );
}
