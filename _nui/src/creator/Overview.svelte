<script lang="ts">
  import WarningIcon from 'phosphor-svelte/lib/WarningIcon'
  import { formatCount, formatWhen, plural } from '../lib/format'
  import type { CreatorData, Garage } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import { validate } from './model'

  type Attention = { garage: Garage; message: string }

  let { data, onopen }: { data: CreatorData; onopen: (garage: Garage) => void } = $props()

  const open = $derived(data.garages.filter((garage) => garage.enabled).length)
  const closed = $derived(data.garages.length - open)
  const houses = $derived(data.garages.filter((garage) => garage.type === 'house').length)
  const fleets = $derived(
    data.garages.filter((garage) => (garage.type === 'job' || garage.type === 'gang') && garage.owners !== 'player' && garage.fleet.length > 0)
      .length,
  )
  const now = Date.now() / 1000

  const attention = $derived(
    data.garages.flatMap((garage): Attention[] => {
      const first = validate(garage, [], false)[0]
      if (first) return [{ garage, message: `${garage.label}: ${first.message}` }]
      if (garage.spawns.length === 1 && garage.enabled) {
        return [{ garage, message: `${garage.label} has 1 spawn point. A parked car there blocks every take out.` }]
      }
      return []
    }),
  )

  const recent = $derived(
    data.garages
      .filter((garage) => garage.updatedAt !== undefined && garage.updatedBy !== 'seed')
      .sort((a, b) => (b.updatedAt ?? 0) - (a.updatedAt ?? 0))
      .slice(0, 6),
  )
</script>

{#snippet stat(label: string, value: number, detail: string)}
  <div class="flex flex-1 flex-col gap-1 rounded-lg border border-border p-4">
    <span class="text-[0.8125rem] text-muted-foreground">{label}</span>
    <span class="text-[1.75rem] leading-9 font-semibold tabular-nums text-foreground">{formatCount(value)}</span>
    <span class="text-xs text-muted-foreground tabular-nums">{detail}</span>
  </div>
{/snippet}

<header class="flex flex-col gap-1 border-b border-border px-7 py-5">
  <h2 class="text-2xl font-semibold tracking-tight text-foreground">Garage creator</h2>
  <p class="text-[0.8125rem] text-muted-foreground">Pick a garage on the left to edit it, or start a new one.</p>
</header>
<div class="flex min-h-0 flex-1 flex-col gap-7 overflow-y-auto px-7 py-6">
  <div class="flex gap-3">
    {@render stat('Garages', data.garages.length, `${open} open, ${closed} closed, ${houses} locked to houses`)}
    {@render stat(
      'Vehicles stored',
      data.totals.stored,
      `Across ${formatCount(data.totals.owners)} citizens and ${plural(fleets, 'fleet', 'fleets')}`,
    )}
    {@render stat('Impounded', data.totals.impounded, `${data.totals.held} on police hold`)}
  </div>

  <section class="flex flex-col gap-2.5">
    <h3 class="text-base font-semibold text-foreground">Needs attention</h3>
    {#if attention.length === 0}
      <p class="text-sm text-muted-foreground">Every garage has what it needs.</p>
    {:else}
      <div class="flex flex-col rounded-md border border-border">
        {#each attention as item (item.garage.id)}
          <div class="flex h-13 shrink-0 items-center gap-3 border-b border-border px-3.5 last:border-b-0">
            <WarningIcon weight="fill" class="size-4 shrink-0 text-warning" />
            <span class="flex-1 text-sm text-foreground">{item.message}</span>
            <button
              type="button"
              onclick={() => onopen(item.garage)}
              class="rounded-sm text-[0.8125rem] font-medium text-foreground transition-colors duration-150 hover:text-cobalt-foreground {focusRing}"
            >
              Open
            </button>
          </div>
        {/each}
      </div>
    {/if}
  </section>

  <section class="flex flex-col gap-2.5">
    <h3 class="text-base font-semibold text-foreground">Recent changes</h3>
    {#if recent.length === 0}
      <p class="text-sm text-muted-foreground">Edits made in the creator show up here.</p>
    {:else}
      <div class="flex flex-col">
        {#each recent as garage (garage.id)}
          <div class="flex gap-4 border-b border-border py-2.5 text-[0.8125rem]">
            <span class="w-36 shrink-0 tabular-nums text-muted-foreground">{formatWhen(garage.updatedAt ?? 0, now)}</span>
            <span class="text-foreground">{garage.updatedBy} saved {garage.label}</span>
          </div>
        {/each}
      </div>
    {/if}
  </section>
</div>
