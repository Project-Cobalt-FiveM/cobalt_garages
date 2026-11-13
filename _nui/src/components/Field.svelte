<script lang="ts">
  import type { Snippet } from 'svelte'

  type Props = { label: string; hint?: string; error?: string; class?: string; children: Snippet }

  let { label, hint, error, class: className = '', children }: Props = $props()
</script>

<div class="flex flex-col gap-2 {className}">
  <span class="text-sm font-medium text-foreground">{label}</span>
  {@render children()}
  {#if error}
    <span class="text-xs text-destructive">{error}</span>
  {:else if hint}
    <span class="text-xs text-muted-foreground">{hint}</span>
  {/if}
</div>
