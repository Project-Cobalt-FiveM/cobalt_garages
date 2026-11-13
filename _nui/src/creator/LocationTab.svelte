<script lang="ts">
  import PlusCircleIcon from 'phosphor-svelte/lib/PlusCircleIcon'
  import { list, nui } from '../lib/nui'
  import { formatCount } from '../lib/format'
  import { toVec3, toVec4 } from '../lib/types'
  import type { Garage, ValidationError, Vec3, Vec4, Zone } from '../lib/types'
  import Button from '../components/Button.svelte'
  import Input from '../components/Input.svelte'
  import SectionTitle from '../components/SectionTitle.svelte'
  import Segmented from '../components/Segmented.svelte'
  import { polygonArea } from './model'
  import LayoutMap from './LayoutMap.svelte'

  type Props = { garage: Garage; errors: ValidationError[]; onchange: (garage: Garage) => void }
  type PlaceKind = 'interact' | 'spawn' | 'zone'

  const AXES = ['x', 'y', 'z'] as const
  const BOX_LABELS = { x: 'Length', y: 'Width', z: 'Height' } as const

  let { garage, errors, onchange }: Props = $props()

  let clearance = $state<boolean[]>([])
  let previewing = $state<number>()

  const placed = $derived(!(garage.interact.coords.x === 0 && garage.interact.coords.y === 0))
  const spawns = $derived(garage.spawns)
  const clearRadius = $derived(garage.clearRadius)

  $effect(() => {
    const request = { spawns: $state.snapshot(spawns), clearRadius }
    let live = true
    void nui('creator:clearance', request).then((result) => {
      if (live) clearance = list(result).map((item) => item === true)
    })
    return () => {
      live = false
    }
  })

  function error(field: string): string | undefined {
    return errors.find((item) => item.field === field)?.message
  }

  function coordsText(point: Vec3): string {
    return `${point.x.toFixed(2)}, ${point.y.toFixed(2)}, ${point.z.toFixed(2)}`
  }

  function headingFor(kind: PlaceKind, index: number): number | undefined {
    if (kind === 'spawn') return garage.spawns[index - 1]?.w
    if (kind === 'interact') return garage.interact.coords.w
    return undefined
  }

  async function place(kind: PlaceKind, index = garage.spawns.length + 1) {
    const result = await nui('creator:place', {
      kind,
      garage: garage.label || 'New garage',
      index,
      interact: placed ? $state.snapshot(garage.interact.coords) : undefined,
      spawns: $state.snapshot(garage.spawns),
      clearRadius: garage.clearRadius,
      heading: headingFor(kind, index),
    })
    if (!result) return

    if (kind === 'interact') onchange({ ...garage, interact: { ...garage.interact, coords: toVec4(result) } })
    if (kind === 'spawn') {
      const next = [...garage.spawns]
      next[index - 1] = toVec4(result)
      onchange({ ...garage, spawns: next })
    }
    if (kind === 'zone') {
      const points = list(result).map(toVec3)
      if (points.length < 3) return
      const heights = points.map((point) => point.z)
      onchange({
        ...garage,
        zone: { kind: 'poly', points, minZ: Math.floor(Math.min(...heights) - 4), maxZ: Math.ceil(Math.max(...heights) + 10) },
      })
    }
  }

  async function useMyPosition() {
    const position = toVec4(await nui('creator:position'))
    onchange({ ...garage, interact: { ...garage.interact, coords: position } })
  }

  function setPoint(axis: keyof Vec4, value: number) {
    onchange({ ...garage, interact: { ...garage.interact, coords: { ...garage.interact.coords, [axis]: value } } })
  }

  function removeSpawn(index: number) {
    onchange({ ...garage, spawns: garage.spawns.filter((_, i) => i !== index) })
  }

  function moveSpawn(index: number, offset: number) {
    const target = index + offset
    const from = garage.spawns[index]
    const to = garage.spawns[target]
    if (!from || !to) return
    const next = [...garage.spawns]
    next[index] = to
    next[target] = from
    onchange({ ...garage, spawns: next })
  }

  function preview(index: number) {
    previewing = index
    void nui('creator:preview', { spawn: $state.snapshot(garage.spawns[index]) })
  }

  function setZoneKind(kind: Zone['kind']) {
    if (kind === garage.zone.kind) return
    const c = garage.interact.coords
    const zone: Zone =
      kind === 'none'
        ? { kind: 'none' }
        : kind === 'box'
          ? { kind: 'box', coords: { x: c.x, y: c.y, z: c.z }, size: { x: 30, y: 20, z: 8 }, rotation: c.w }
          : { kind: 'poly', points: [], minZ: Math.floor(c.z - 4), maxZ: Math.ceil(c.z + 10) }
    onchange({ ...garage, zone })
  }

  function setZone(zone: Zone) {
    onchange({ ...garage, zone })
  }

  function recentre() {
    if (garage.zone.kind !== 'box') return
    setZone({ ...garage.zone, coords: { ...garage.interact.coords }, rotation: garage.interact.coords.w })
  }

  function previewSelected() {
    if (garage.spawns.length > 0) preview(previewing ?? 0)
  }
</script>

{#snippet rowAction(label: string, active: boolean, onclick: () => void, disabled = false)}
  <button
    type="button"
    {onclick}
    {disabled}
    class="rounded-sm px-1 py-0.5 text-xs font-medium transition-colors duration-150 disabled:invisible {active
      ? 'text-foreground'
      : 'text-muted-foreground hover:text-foreground'}"
  >
    {label}
  </button>
{/snippet}

{#snippet zoneNumber(value: number, onvalue: (value: number) => void)}
  <input
    type="number"
    {value}
    oninput={(event) => onvalue(Number(event.currentTarget.value))}
    class="h-7 w-16 rounded-sm border border-input bg-transparent px-2 text-[0.8125rem] font-semibold tabular-nums text-foreground outline-none focus-visible:ring-2 focus-visible:ring-cobalt"
  />
{/snippet}

<div class="grid grid-cols-[1fr_25rem] gap-6">
  <div class="flex min-w-0 flex-col gap-7">
    <section class="flex flex-col gap-3">
      <SectionTitle title="Interaction point" description="Where the ped stands. Players open the garage here.">
        {#snippet action()}
          <Button size="small" onclick={useMyPosition}>Use my position</Button>
          <Button size="small" onclick={() => place('interact')}>Place in world</Button>
        {/snippet}
      </SectionTitle>
      {#if placed}
        <div class="grid grid-cols-4 gap-2">
          {#each AXES as axis (axis)}
            <Input
              prefix={axis.toUpperCase()}
              type="number"
              step={0.01}
              value={Number(garage.interact.coords[axis].toFixed(2))}
              oninput={(event) => setPoint(axis, Number(event.currentTarget.value))}
            />
          {/each}
          <div class="relative">
            <span class="pointer-events-none absolute inset-y-0 left-3 z-10 flex items-center text-xs text-muted-foreground">Heading</span>
            <Input
              type="number"
              step={0.5}
              class="pl-[4.25rem]"
              value={Number(garage.interact.coords.w.toFixed(1))}
              oninput={(event) => setPoint('w', Number(event.currentTarget.value) % 360)}
            />
          </div>
        </div>
      {:else}
        <div class="flex h-9 items-center rounded-md border border-destructive px-3 text-sm text-muted-foreground">Not placed</div>
        {#if error('interact')}
          <span class="text-xs text-destructive">{error('interact')}</span>
        {/if}
      {/if}
    </section>

    <section class="flex flex-col gap-3">
      <SectionTitle title="Spawn points" description="Cars come out at the first clear point, in this order.">
        {#snippet action()}
          <Button size="small" onclick={() => place('spawn')}>
            <PlusCircleIcon weight="fill" class="size-3.5" />
            Add spawn point
          </Button>
        {/snippet}
      </SectionTitle>
      {#if garage.spawns.length === 0}
        <div class="flex h-22 flex-col items-center justify-center gap-1 rounded-md border border-dashed border-destructive px-4 text-center">
          <span class="text-sm font-medium text-foreground">No spawn points</span>
          <span class="text-xs text-muted-foreground">Stand where a car should appear, face the exit, and press Add spawn point.</span>
        </div>
        {#if error('spawns')}
          <span class="text-xs text-destructive">{error('spawns')}</span>
        {/if}
      {:else}
        <div class="flex flex-col overflow-hidden rounded-md border border-border">
          {#each garage.spawns as spawn, index (`${index}-${spawn.x}-${spawn.y}`)}
            {@const active = previewing === index}
            {@const clear = clearance[index] !== false}
            <div
              class="flex h-11 shrink-0 items-center gap-3 border-b border-border px-3 text-[0.8125rem] transition-colors duration-150 last:border-b-0 {active
                ? 'bg-primary'
                : ''}"
            >
              <span class="w-5 shrink-0 font-semibold tabular-nums {active ? 'text-foreground' : 'text-muted-foreground'}">{index + 1}</span>
              <span class="flex-1 tabular-nums text-foreground">{coordsText(spawn)}</span>
              <span class="w-16 shrink-0 tabular-nums text-foreground">{spawn.w.toFixed(1)}°</span>
              <span class="w-18 shrink-0 text-xs {active ? 'text-foreground' : clear ? 'text-success' : 'text-warning'}">
                {clear ? 'Clear' : 'Blocked'}
              </span>
              <div class="flex shrink-0 items-center justify-end gap-2">
                {@render rowAction('Up', active, () => moveSpawn(index, -1), index === 0)}
                {@render rowAction(active ? 'Previewing' : 'Preview', active, () => preview(index))}
                {@render rowAction('Edit', active, () => place('spawn', index + 1))}
                {@render rowAction('Remove', active, () => removeSpawn(index))}
              </div>
            </div>
          {/each}
        </div>
      {/if}
      <div class="flex items-center gap-4">
        <span class="text-[0.8125rem] text-muted-foreground">Clear radius</span>
        <div class="w-24">
          <Input
            type="number"
            step={0.5}
            min={1}
            max={15}
            suffix="m"
            class="pr-8"
            value={garage.clearRadius}
            oninput={(event) => onchange({ ...garage, clearRadius: Number(event.currentTarget.value) || 4 })}
          />
        </div>
        <span class="text-[0.8125rem] text-muted-foreground">A point counts as blocked when any vehicle is this close.</span>
      </div>
    </section>

    <section class="flex flex-col gap-3">
      <SectionTitle title="Store zone" description="Optional. Players can store a vehicle anywhere inside it without walking to the ped.">
        {#snippet action()}
          <Segmented
            value={garage.zone.kind}
            onchange={setZoneKind}
            options={[
              { value: 'none', label: 'None' },
              { value: 'box', label: 'Box' },
              { value: 'poly', label: 'Polygon' },
            ]}
          />
          {#if garage.zone.kind === 'poly'}
            <Button size="small" onclick={() => place('zone')}>Edit in world</Button>
          {/if}
        {/snippet}
      </SectionTitle>
      {#if garage.zone.kind === 'poly'}
        {@const zone = garage.zone}
        <div class="flex flex-wrap items-center gap-6 text-[0.8125rem] text-muted-foreground">
          <span>
            Points
            <span class="tabular-nums {zone.points.length < 3 ? 'text-destructive' : 'font-semibold text-foreground'}">{zone.points.length}</span>
          </span>
          {#if zone.points.length >= 3}
            <span>
              Area
              <span class="font-semibold tabular-nums text-foreground">{formatCount(Math.round(polygonArea(zone.points)))} m²</span>
            </span>
          {/if}
          <span class="flex items-center gap-2">
            Height
            {@render zoneNumber(zone.minZ, (minZ) => setZone({ ...zone, minZ }))}
            to
            {@render zoneNumber(zone.maxZ, (maxZ) => setZone({ ...zone, maxZ }))}
          </span>
        </div>
        {#if error('zone')}
          <span class="text-xs text-destructive">{error('zone')}</span>
        {/if}
      {:else if garage.zone.kind === 'box'}
        {@const zone = garage.zone}
        <div class="flex flex-wrap items-center gap-3 text-[0.8125rem] text-muted-foreground">
          <span>Centred on the interaction point.</span>
          {#each AXES as axis (axis)}
            <span class="flex items-center gap-2">
              {BOX_LABELS[axis]}
              {@render zoneNumber(zone.size[axis], (value) => setZone({ ...zone, size: { ...zone.size, [axis]: value } }))}
            </span>
          {/each}
          <Button size="small" onclick={recentre}>Recentre</Button>
        </div>
      {/if}
    </section>
  </div>

  <LayoutMap {garage} highlighted={previewing} onpreview={previewSelected} />
</div>
