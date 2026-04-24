import type { ComponentChildren } from "preact";

const KAO = ["(・_・;)", "(；´∀｀)", "(￣▽￣*)ゞ", "(=w=;)", "(・`ω´・)"];

function SkeletonLine({ widthClass = "w-full", heightClass = "h-3" }: { widthClass?: string; heightClass?: string }) {
  return <div class={`skeleton-shimmer ${heightClass} ${widthClass} rounded-full`} />;
}

export function KaomojiLoadingText({
  label = "Loading",
  index = 0,
  className = "text-[0.82rem] text-[#7a766e]",
}: {
  label?: string;
  index?: number;
  className?: string;
}) {
  const face = KAO[Math.abs(index) % KAO.length];
  return <p class={className}>{label} {face}</p>;
}

export function MediaCardSkeleton({ compact = false }: { compact?: boolean }) {
  return (
    <div class={`rounded-2xl border border-white/7 bg-white/3 ${compact ? "p-2.5" : "px-4 py-3"}`}>
      <div class={`flex items-center ${compact ? "gap-3" : "gap-4"}`}>
        <div class={`skeleton-shimmer shrink-0 rounded-lg ${compact ? "h-11 w-8" : "h-14 w-10"}`} />
        <div class="min-w-0 flex-1 space-y-2">
          <SkeletonLine widthClass="w-3/5" heightClass="h-3" />
          <SkeletonLine widthClass="w-2/5" heightClass="h-2.5" />
        </div>
        {!compact && <div class="skeleton-shimmer h-6 w-18 rounded-full" />}
      </div>
    </div>
  );
}

export function PanelSkeleton({ label = "Loading panel", kaomojiIndex = 0 }: { label?: string; kaomojiIndex?: number }) {
  return (
    <div class="flex flex-col">
      <div class="skeleton-shimmer h-34 w-full" />
      <div class="flex gap-4 px-5 pt-3">
        <div class="skeleton-shimmer h-28 w-20 shrink-0 rounded-xl" />
        <div class="flex-1 space-y-2.5 pt-9">
          <SkeletonLine widthClass="w-4/5" heightClass="h-4" />
          <SkeletonLine widthClass="w-1/2" heightClass="h-3" />
          <SkeletonLine widthClass="w-2/3" heightClass="h-2.5" />
        </div>
      </div>
      <div class="mt-5 space-y-3 px-5">
        <SkeletonLine widthClass="w-11/12" heightClass="h-2.5" />
        <SkeletonLine widthClass="w-10/12" heightClass="h-2.5" />
        <SkeletonLine widthClass="w-9/12" heightClass="h-2.5" />
        <SkeletonLine widthClass="w-8/12" heightClass="h-2.5" />
      </div>
      <div class="px-5 pt-4">
        <KaomojiLoadingText label={label} index={kaomojiIndex} className="text-[0.78rem] text-[#6b665d]" />
      </div>
    </div>
  );
}

export function SkeletonStack({
  count,
  children,
  className = "grid gap-2",
}: {
  count: number;
  children: ComponentChildren;
  className?: string;
}) {
  return <div class={className}>{Array.from({ length: count }).map((_, i) => <div key={i}>{children}</div>)}</div>;
}
