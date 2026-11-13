<script lang="ts">
  import type { Snippet } from 'svelte'

  type Props = { title: string; description?: string; action?: Snippet }

  let { title, description, action }: Props = $props()
</script>

<div class="flex items-end justify-between gap-4">
  <div class="flex flex-col gap-0.5">
    <h3 class="text-base font-semibold text-foreground">{title}</h3>
    {#if description}
      <p class="text-[0.8125rem] text-muted-foreground">{description}</p>
    {/if}
  </div>
  {#if action}
    <div class="flex shrink-0 items-center gap-2">{@render action()}</div>
  {/if}
</div>
