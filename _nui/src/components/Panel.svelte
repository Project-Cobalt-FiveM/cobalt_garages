<script lang="ts">
  import type { Snippet } from 'svelte'

  let { class: className = '', children }: { class?: string; children: Snippet } = $props()
</script>

<div class="flex animate-rise flex-col overflow-hidden rounded-lg border border-border bg-card {className}">
  {@render children()}
</div>
