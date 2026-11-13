<script lang="ts">
  import type { Snippet } from 'svelte'

  let { text, selected, children }: { text: string; selected: boolean; children?: Snippet } = $props()
</script>

<span class="flex w-24 shrink-0 flex-col items-end gap-1">
  <span class="text-xs tabular-nums {selected ? 'text-foreground' : 'text-muted-foreground'}">{text}</span>
  {@render children?.()}
</span>
