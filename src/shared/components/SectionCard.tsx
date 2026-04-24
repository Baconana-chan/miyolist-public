import type { ComponentChildren } from "preact";
import { eyebrowClass, mutedTextClass, panelClass, titleClass } from "../tw";

interface SectionCardProps {
  eyebrow: string;
  title: string;
  description: string;
  children?: ComponentChildren;
}

export function SectionCard(props: SectionCardProps) {
  return (
    <section class={`${panelClass} grid gap-4 p-[1.35rem]`}>
      <div>
        <p class={eyebrowClass}>{props.eyebrow}</p>
        <h2 class={titleClass}>{props.title}</h2>
        <p class={mutedTextClass}>{props.description}</p>
      </div>
      {props.children}
    </section>
  );
}