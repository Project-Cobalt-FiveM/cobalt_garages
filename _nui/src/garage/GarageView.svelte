<script lang="ts">
  import { untrack } from 'svelte'
  import DownloadSimpleIcon from 'phosphor-svelte/lib/DownloadSimpleIcon'
  import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon'
  import WarehouseIcon from 'phosphor-svelte/lib/WarehouseIcon'
  import Button from '../components/Button.svelte'
  import Chip from '../components/Chip.svelte'
  import KeyHint from '../components/KeyHint.svelte'
  import Panel from '../components/Panel.svelte'
  import { nui, type CallbackName } from '../lib/nui'
  import type { Account, GarageView } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Detail from './Detail.svelte'
  import EmptyState from './EmptyState.svelte'
  import FleetRow from './FleetRow.svelte'
  import TransferDialog from './TransferDialog.svelte'
  import VehicleRow from './VehicleRow.svelte'
  import {
    FILTER_LABELS,
    STATUS_ORDER,
    emptyText,
    headerIcon,
    isHeld,
    keyOf,
    kindOf,
    subtitle,
    title,
    type Filter,
    type Selection,
  } from './garage'

  let { data, onclose }: { data: GarageView; onclose: () => void } = $props()

  let query = $state('')
  let filter = $state<Filter>('all')
  let selectedKey = $state<string>()
  let account = $state<Account>(untrack(() => (data.balances.bank >= data.balances.cash ? 'bank' : 'cash')))
  let transferPlate = $state<string>()
  let busy = $state(false)

  const impound = $derived(data.type === 'impound')
  const kind = $derived(kindOf(data.type))
  const HeaderIcon = $derived(headerIcon(data))
  const canStore = $derived(!impound && data.store !== undefined)

  const vehicles = $derived(
    data.vehicles.filter((vehicle) => impound || kind.matches(vehicle)).sort((a, b) => STATUS_ORDER[a.status] - STATUS_ORDER[b.status]),
  )

  const counts = $derived<Record<Filter, number>>({
    all: vehicles.length + data.fleet.length,
    here: vehicles.filter((v) => v.status === 'here').length,
    elsewhere: vehicles.filter((v) => v.status === 'elsewhere').length,
    out: vehicles.filter((v) => v.status === 'out').length,
    impounded: vehicles.filter((v) => v.status === 'impounded').length,
    fleet: data.fleet.length,
    ready: vehicles.filter((v) => !isHeld(v, data.now)).length,
    hold: vehicles.filter((v) => isHeld(v, data.now)).length,
  })

  const filters = $derived<Filter[]>(
    impound ? ['all', 'ready', 'hold'] : ['all', ...(data.fleet.length > 0 ? (['fleet'] as const) : []), 'here', 'elsewhere', 'out', 'impounded'],
  )

  const needle = $derived(query.trim().toLowerCase())

  function matchesQuery(label: string, plate?: string): boolean {
    return needle === '' || label.toLowerCase().includes(needle) || (plate?.toLowerCase().includes(needle) ?? false)
  }

  const items = $derived.by<Selection[]>(() => {
    const visibleVehicles = vehicles.filter((vehicle) => {
      if (!matchesQuery(vehicle.label, vehicle.plate)) return false
      if (filter === 'all') return true
      if (filter === 'fleet') return false
      if (filter === 'ready') return !isHeld(vehicle, data.now)
      if (filter === 'hold') return isHeld(vehicle, data.now)
      return vehicle.status === filter
    })
    const visibleFleet = filter === 'all' || filter === 'fleet' ? data.fleet.filter((fleet) => matchesQuery(fleet.label)) : []

    return [
      ...visibleFleet.map((fleet) => ({ kind: 'fleet' as const, fleet })),
      ...visibleVehicles.map((vehicle) => ({ kind: 'vehicle' as const, vehicle })),
    ]
  })

  const selected = $derived(items.find((item) => keyOf(item) === selectedKey) ?? items[0])
  const transferring = $derived(data.vehicles.find((v) => v.plate === transferPlate && v.status === 'here'))

  async function run(name: CallbackName, payload: Record<string, unknown> = {}) {
    if (busy) return
    busy = true
    await nui(name, payload)
    busy = false
  }

  function primary() {
    if (!selected) return
    if (selected.kind === 'fleet') return run('garage:takeFleet', { index: selected.fleet.index, model: selected.fleet.model })
    const vehicle = selected.vehicle
    if (impound && !isHeld(vehicle, data.now)) return run('garage:release', { plate: vehicle.plate, model: vehicle.model, account })
    if (vehicle.status === 'here') return run('garage:takeOut', { plate: vehicle.plate, model: vehicle.model })
  }

  function step(offset: number) {
    const index = items.findIndex((item) => item === selected)
    const next = items[Math.max(0, Math.min(items.length - 1, index + offset))]
    if (next) selectedKey = keyOf(next)
  }

  function onkeydown(event: KeyboardEvent) {
    if (transferring) return
    if (event.key === 'Escape') onclose()
    if (event.key === 'Enter' && !(event.target instanceof HTMLInputElement)) void primary()
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault()
      step(event.key === 'ArrowDown' ? 1 : -1)
    }
  }
</script>

<svelte:window {onkeydown} />

<div class="fixed inset-0 flex items-center justify-center p-8">
  <Panel class="relative max-h-full w-[82.5rem] max-w-full {counts.all === 0 ? 'h-[30rem]' : 'h-[43.75rem]'}">
    <header class="flex items-center gap-4 border-b border-border px-6 py-5">
      <div class="flex size-9 shrink-0 items-center justify-center rounded-md bg-secondary">
        <HeaderIcon weight="fill" class="size-5 text-foreground" />
      </div>
      <div class="flex min-w-0 flex-1 flex-col gap-0.5">
        <h1 class="truncate text-xl font-semibold tracking-[-0.01em] text-foreground">{title(data)}</h1>
        <p class="truncate text-[0.8125rem] text-muted-foreground">{subtitle(data, kind, counts.here, vehicles.length)}</p>
      </div>
      {#if canStore}
        <Button variant="primary" onclick={() => run('garage:store')} disabled={busy}>
          <DownloadSimpleIcon weight="fill" class="size-4" />
          Store {data.store?.label}
        </Button>
      {/if}
      <button type="button" onclick={onclose} class="rounded-sm {focusRing}">
        <KeyHint keys={['Esc']} label="Close" />
      </button>
    </header>

    {#if counts.all === 0}
      <EmptyState
        icon={impound ? WarehouseIcon : kind.icon}
        title={impound ? 'Nothing held here' : `No ${kind.nouns} stored here`}
        text={emptyText(data, kind)}
        hint={!impound}
      />
    {:else}
      <div class="flex min-h-0 flex-1">
        <aside class="flex w-[30rem] shrink-0 flex-col gap-3 border-r border-border p-4">
          <label class="flex h-9 shrink-0 items-center gap-2 rounded-md border border-input px-3 focus-within:ring-2 focus-within:ring-cobalt">
            <MagnifyingGlassIcon weight="fill" class="size-4 shrink-0 text-muted-foreground" />
            <input
              bind:value={query}
              placeholder="Search by name or plate"
              class="w-full bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
            />
          </label>
          <div class="flex flex-wrap gap-1">
            {#each filters as key (key)}
              <Chip active={filter === key} onclick={() => (filter = key)}>{FILTER_LABELS[key]} {counts[key]}</Chip>
            {/each}
          </div>
          <div class="-mr-2 flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto pr-2">
            {#each items as item (keyOf(item))}
              {#if item.kind === 'fleet'}
                <FleetRow fleet={item.fleet} selected={item === selected} onselect={() => (selectedKey = keyOf(item))} />
              {:else}
                <VehicleRow
                  vehicle={item.vehicle}
                  {impound}
                  held={isHeld(item.vehicle, data.now)}
                  selected={item === selected}
                  onselect={() => (selectedKey = keyOf(item))}
                />
              {/if}
            {:else}
              <p class="px-1 py-6 text-center text-sm text-muted-foreground">Nothing matches that search.</p>
            {/each}
          </div>
        </aside>
        {#if selected}
          {#key keyOf(selected)}
            <Detail
              garage={data}
              item={selected}
              {busy}
              {account}
              onaccount={(next) => (account = next)}
              onprimary={primary}
              ontransfer={(vehicle) => (transferPlate = vehicle.plate)}
            />
          {/key}
        {/if}
      </div>
    {/if}

    {#if transferring}
      <TransferDialog vehicle={transferring} bank={data.balances.bank} onclose={() => (transferPlate = undefined)} />
    {/if}
  </Panel>
</div>
