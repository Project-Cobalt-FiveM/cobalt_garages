<script lang="ts">
  import type { Snippet } from 'svelte'
  import { focusRing } from '../lib/ui'

  let { active, onclick, children }: { active: boolean; onclick: () => void; children: Snippet } = $props()
</script>

<button
  type="button"
  {onclick}
  class="rounded-sm px-2.5 py-1 text-[0.8125rem] font-medium tabular-nums transition-colors duration-150 {focusRing} {active
    ? 'bg-primary text-primary-foreground'
    : 'text-muted-foreground hover:text-foreground'}"
>
  {@render children()}
</button>
