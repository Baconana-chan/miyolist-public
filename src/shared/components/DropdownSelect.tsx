import { useEffect, useRef, useState } from "preact/hooks";

export interface DropdownOption {
  value: string;
  label: string;
}

export function DropdownSelect({
  options,
  value,
  onChange,
  disabled,
  align = "left",
  buttonClass,
  menuClass,
  optionClass,
  selectedOptionClass,
}: {
  options: ReadonlyArray<DropdownOption>;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
  align?: "left" | "right";
  buttonClass?: string;
  menuClass?: string;
  optionClass?: string;
  selectedOptionClass?: string;
}) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement | null>(null);

  const selected = options.find((o) => o.value === value) ?? options[0];

  useEffect(() => {
    if (!open) return;

    const onPointerDown = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };

    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("keydown", onEscape);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("keydown", onEscape);
    };
  }, [open]);

  const triggerClass = buttonClass ?? "rounded-xl border border-white/10 bg-white/5 px-3 py-1.5 text-[0.82rem] text-[#c8c4bc]";
  const popupClass = menuClass ?? "min-w-48 overflow-hidden rounded-xl border border-white/10 bg-[#1a1b1d] shadow-[-2px_8px_28px_rgba(0,0,0,0.45)]";
  const itemClass = optionClass ?? "w-full px-3 py-2 text-left text-[0.8rem] text-[#b7b3aa] transition hover:bg-white/6 hover:text-[#f1efe7]";
  const itemSelectedClass = selectedOptionClass ?? "bg-[rgba(217,116,82,0.2)] text-[#f1efe7]";

  return (
    <div ref={rootRef} class="relative">
      <button
        class={`${triggerClass} flex items-center gap-2 transition hover:brightness-110 disabled:opacity-50`}
        onClick={() => setOpen((v) => !v)}
        disabled={disabled}
      >
        <span>{selected?.label ?? value}</span>
        <svg
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          class={`transition ${open ? "rotate-180" : ""}`}
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {open && (
        <div class={`absolute top-full z-40 mt-1.5 ${align === "right" ? "right-0" : "left-0"} ${popupClass}`}>
          <div class="max-h-60 overflow-y-auto [scrollbar-width:thin] [scrollbar-color:#2e2c29_transparent]">
            {options.map((opt) => (
              <button
                key={opt.value}
                class={`${itemClass} ${opt.value === value ? itemSelectedClass : ""}`}
                onClick={() => {
                  setOpen(false);
                  onChange(opt.value);
                }}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
