<script lang="ts">
  import { focusRing } from '../lib/ui'

  type Props = { label: string; detail: string; price: string; available: boolean; active: boolean; onselect: () => void }

  let { label, detail, price, available, active, onselect }: Props = $props()

  const radio = $derived.by(() => {
    if (active) return 'border-foreground'
    return available ? 'border-input' : 'border-border bg-muted'
  })
</script>

<button
  type="button"
  disabled={!available}
  onclick={onselect}
  class="flex h-14 shrink-0 items-center gap-3 rounded-md border px-3 text-left transition-colors duration-150 {focusRing} {active
    ? 'border-primary bg-primary'
    : 'border-border bg-popover hover:bg-muted disabled:hover:bg-popover'}"
>
  <span class="flex size-4 shrink-0 items-center justify-center rounded-full border {radio}">
    {#if active}
      <span class="size-2 rounded-full bg-foreground"></span>
    {/if}
  </span>
  <span class="flex min-w-0 flex-1 flex-col gap-0.5">
    <span class="truncate text-sm font-medium {available ? 'text-foreground' : 'text-muted-foreground'}">{label}</span>
    <span class="truncate text-xs {active ? 'text-foreground' : 'text-muted-foreground'}">{detail}</span>
  </span>
  <span class="w-16 shrink-0 text-right text-sm font-medium tabular-nums {available ? 'text-foreground' : 'text-muted-foreground'}">{price}</span>
</button>
