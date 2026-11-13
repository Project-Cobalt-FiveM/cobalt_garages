<script lang="ts">
  import KeyHint from '../components/KeyHint.svelte'
  import type { Icon } from './garage'

  type Props = { icon: Icon; title: string; text: string; hint: boolean }

  let { icon: EmptyIcon, title, text, hint }: Props = $props()
</script>

<div class="flex flex-1 flex-col items-center justify-center gap-4 px-8 text-center">
  <div class="flex size-12 shrink-0 items-center justify-center rounded-lg border border-border bg-muted">
    <EmptyIcon weight="fill" class="size-5 text-muted-foreground" />
  </div>
  <div class="flex flex-col items-center gap-1.5">
    <h2 class="text-base font-semibold text-foreground">{title}</h2>
    <p class="w-[23.75rem] max-w-full text-sm text-muted-foreground">{text}</p>
  </div>
  {#if hint}
    <div class="pt-1">
      <KeyHint keys={['E']} label="Store from the driver seat without opening this menu" />
    </div>
  {/if}
</div>
