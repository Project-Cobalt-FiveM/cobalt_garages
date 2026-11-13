<script lang="ts">
  import Kbd from './Kbd.svelte'

  let { keys, label }: { keys: string[]; label: string } = $props()
</script>

<span class="flex items-center gap-1.5 text-xs text-muted-foreground">
  {#each keys as key (key)}
    <Kbd {key} />
  {/each}
  {label}
</span>
