<script lang="ts">
  import type { Snippet } from 'svelte'
  import { focusRing } from '../lib/ui'

  let { selected, onselect, children }: { selected: boolean; onselect: () => void; children: Snippet } = $props()
</script>

<button
  type="button"
  onclick={onselect}
  aria-pressed={selected}
  class="flex h-[3.75rem] w-full shrink-0 items-center gap-3 rounded-md border px-3 text-left transition-colors duration-150 {focusRing} {selected
    ? 'border-primary bg-primary'
    : 'border-border bg-card hover:bg-muted'}"
>
  <span class="size-1.5 shrink-0 rounded-full {selected ? 'bg-foreground' : ''}"></span>
  {@render children()}
</button>
