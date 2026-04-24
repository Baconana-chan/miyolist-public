import type { ModuleStatus } from "../types/app";

const STYLES: Record<ModuleStatus, string> = {
  ready: "bg-[rgba(95,166,123,0.18)] text-[#d9f2e1]",
  planned: "bg-[rgba(217,116,82,0.18)] text-[#ffd9cf]",
  research: "bg-[rgba(124,164,190,0.18)] text-[#dce8f1]",
};

const LABELS: Record<ModuleStatus, string> = {
  ready: "Ready",
  planned: "Planned",
  research: "Research",
};

export function StatusBadge(props: { status: ModuleStatus }) {
  return (
    <span
      class={`inline-flex min-w-[5.6rem] items-center justify-center rounded-full px-3 py-1.5 text-[0.82rem] font-bold ${STYLES[props.status]}`}
    >
      {LABELS[props.status]}
    </span>
  );
}