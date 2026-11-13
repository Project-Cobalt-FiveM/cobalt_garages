<script lang="ts">
  import CheckCircleIcon from 'phosphor-svelte/lib/CheckCircleIcon'
  import WarningIcon from 'phosphor-svelte/lib/WarningIcon'
  import type { Placement } from '../lib/types'

  type Key = { keys: string[]; label: string; primary?: boolean; divider?: boolean }

  const MODES = [
    { kind: 'interact', label: 'Ped' },
    { kind: 'spawn', label: 'Spawn points' },
    { kind: 'zone', label: 'Store zone' },
  ] as const

  let { placement }: { placement: Placement } = $props()

  function keysFor(kind: Placement['kind']): Key[] {
    const vertical: Key[] = [
      { keys: ['Q', 'E'], label: 'Lower, raise' },
      { keys: ['G'], label: 'Snap to ground' },
    ]

    if (kind === 'zone') {
      return [
        { keys: ['Mouse'], label: 'Aim' },
        ...vertical,
        { keys: ['Backspace'], label: 'Undo corner', divider: true },
        { keys: ['Esc'], label: 'Cancel' },
        { keys: ['F'], label: 'Finish zone' },
        { keys: ['Enter'], label: 'Add corner', primary: true },
      ]
    }

    return [
      { keys: ['Mouse'], label: 'Aim' },
      { keys: ['Scroll'], label: 'Rotate 5°' },
      { keys: ['Shift', 'Scroll'], label: 'Rotate 1°' },
      ...vertical,
      ...(kind === 'spawn' ? [{ keys: ['Tab'], label: 'Preview size' }] : []),
      { keys: ['Backspace', 'Esc'], label: 'Cancel', divider: true },
      { keys: ['Enter'], label: 'Place point', primary: true },
    ]
  }

  const coords = $derived(placement.coords)
  const keys = $derived(keysFor(placement.kind))
</script>

{#snippet row(label: string, value: string)}
  <div class="flex justify-between gap-10 text-[0.8125rem]">
    <span class="text-muted-foreground">{label}</span>
    <span class="font-semibold tabular-nums text-foreground">{value}</span>
  </div>
{/snippet}

<div class="pointer-events-none fixed inset-0">
  <div class="absolute top-6 left-6 flex w-65 animate-rise flex-col gap-2 rounded-lg border border-border bg-card px-4 py-3.5">
    {@render row('X', coords ? coords.x.toFixed(2) : '-')}
    {@render row('Y', coords ? coords.y.toFixed(2) : '-')}
    {@render row('Z', coords ? coords.z.toFixed(2) : '-')}
    {#if placement.kind !== 'zone'}
      {@render row('Heading', coords ? `${coords.w.toFixed(1)}°` : '-')}
    {/if}
    <div class="h-px shrink-0 bg-border"></div>
    {#if placement.fromPed !== undefined && placement.kind !== 'interact'}
      {@render row('From the ped', `${placement.fromPed.toFixed(1)} m`)}
    {/if}
    {#if placement.previewSize}
      {@render row('Preview size', placement.previewSize)}
    {/if}
    {#if placement.kind === 'zone'}
      {@render row('Corners', String(placement.corners ?? 0))}
    {/if}
  </div>

  <div
    class="absolute top-6 left-1/2 flex w-[37.5rem] -translate-x-1/2 animate-rise items-center justify-between gap-3 rounded-lg border border-border bg-card px-4 py-3"
  >
    <div class="flex min-w-0 flex-col gap-0.5">
      <span class="truncate text-xs text-muted-foreground">{placement.garage}</span>
      <span class="truncate text-base font-semibold text-foreground">{placement.title}</span>
    </div>
    <div class="flex shrink-0 gap-1">
      {#each MODES as mode (mode.kind)}
        <span
          class="flex h-6.5 items-center rounded-sm px-2.5 text-[0.8125rem] font-medium transition-colors duration-150 {mode.kind === placement.kind
            ? 'bg-primary text-primary-foreground'
            : 'text-muted-foreground'}"
        >
          {mode.label}
        </span>
      {/each}
    </div>
  </div>

  <div class="absolute top-6 right-6 flex w-[18.75rem] flex-col gap-1.5">
    {#each placement.checks as check (check.label)}
      <div class="flex animate-rise items-center gap-2.5 rounded-md border border-border bg-card px-3 py-2.5">
        {#if check.ok}
          <CheckCircleIcon weight="fill" class="size-4 shrink-0 text-success" />
        {:else}
          <WarningIcon weight="fill" class="size-4 shrink-0 text-warning" />
        {/if}
        <span class="text-[0.8125rem] font-medium text-foreground tabular-nums">{check.label}</span>
      </div>
    {/each}
  </div>

  <div
    class="absolute bottom-6 left-1/2 flex -translate-x-1/2 animate-rise items-center gap-5 rounded-lg border border-border bg-card px-4 py-3 whitespace-nowrap"
  >
    {#each keys as key (key.label)}
      {#if key.divider}
        <span class="h-5 w-px shrink-0 bg-border"></span>
      {/if}
      <span class="flex shrink-0 items-center gap-1.5 text-[0.8125rem] text-muted-foreground">
        {#each key.keys as name (name)}
          <kbd
            class="rounded-sm border px-1.5 py-0.5 font-sans text-xs {key.primary
              ? 'border-primary bg-primary font-medium text-primary-foreground'
              : 'border-input bg-muted text-foreground'}"
          >
            {name}
          </kbd>
        {/each}
        <span class={key.primary ? 'font-medium text-foreground' : ''}>{key.label}</span>
      </span>
    {/each}
  </div>
</div>
