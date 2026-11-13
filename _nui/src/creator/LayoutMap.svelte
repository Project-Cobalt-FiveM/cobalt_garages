<script lang="ts">
  import type { Garage, Vec3 } from '../lib/types'
  import Button from '../components/Button.svelte'
  import { compass } from './model'

  type Props = { garage: Garage; highlighted?: number; onpreview: () => void }
  type View = { step: number; scale: number; toX: (x: number) => number; toY: (y: number) => number; lines: number[] }

  const SIZE = 360
  const PADDING = 36
  const CAR_LENGTH = 4.6
  const CAR_WIDTH = 2.0

  let { garage, highlighted, onpreview }: Props = $props()

  function gridStep(span: number): number {
    return [5, 10, 25, 50, 100].find((step) => span / step <= 16) ?? 200
  }

  function boxCorners(center: Vec3, size: Vec3, rotation: number): Vec3[] {
    const angle = (rotation * Math.PI) / 180
    const cos = Math.cos(angle)
    const sin = Math.sin(angle)
    const corners: [number, number][] = [
      [-size.x / 2, -size.y / 2],
      [size.x / 2, -size.y / 2],
      [size.x / 2, size.y / 2],
      [-size.x / 2, size.y / 2],
    ]
    return corners.map(([x, y]) => ({ x: center.x + x * cos - y * sin, y: center.y + x * sin + y * cos, z: center.z }))
  }

  const placed = $derived(!(garage.interact.coords.x === 0 && garage.interact.coords.y === 0))
  const zonePoints = $derived.by((): Vec3[] => {
    if (garage.zone.kind === 'poly') return garage.zone.points
    if (garage.zone.kind === 'box') return boxCorners(garage.zone.coords, garage.zone.size, garage.zone.rotation)
    return []
  })
  const points = $derived([...(placed ? [garage.interact.coords] : []), ...garage.spawns, ...zonePoints])

  const view = $derived.by((): View | undefined => {
    if (points.length === 0) return undefined
    const xs = points.map((point) => point.x)
    const ys = points.map((point) => point.y)
    const centerX = (Math.min(...xs) + Math.max(...xs)) / 2
    const centerY = (Math.min(...ys) + Math.max(...ys)) / 2
    const span = Math.max(Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys), 20)
    const scale = (SIZE - PADDING * 2) / span
    const step = gridStep(span)
    return {
      step,
      scale,
      toX: (x) => SIZE / 2 + (x - centerX) * scale,
      toY: (y) => SIZE / 2 - (y - centerY) * scale,
      lines: Array.from({ length: Math.ceil(SIZE / (step * scale)) + 1 }, (_, i) => i * step * scale),
    }
  })

  const interactLegend = $derived(
    placed && garage.interact.mode === 'ped' ? `Interaction point, ped faces ${compass(garage.interact.coords.w)}` : 'Interaction point',
  )
</script>

{#snippet heading(step: number)}
  <div class="flex items-center justify-between">
    <span class="text-sm font-semibold text-foreground">Layout from above</span>
    <span class="text-xs text-muted-foreground tabular-nums">North up, 1 square = {step} m</span>
  </div>
{/snippet}

<aside class="flex h-fit flex-col gap-3 self-start rounded-lg border border-border p-4">
  {#if !view}
    {@render heading(5)}
    <div
      class="flex aspect-square items-center justify-center rounded-md border border-border bg-background px-8 text-center text-sm text-muted-foreground"
    >
      Place the interaction point or a spawn point to see the layout.
    </div>
  {:else}
    {@const { toX, toY, scale } = view}
    {@const width = Math.max(CAR_WIDTH * scale, 14)}
    {@const length = Math.max(CAR_LENGTH * scale, 26)}
    {@render heading(view.step)}
    <svg
      viewBox="0 0 {SIZE} {SIZE}"
      class="aspect-square w-full rounded-md border border-border bg-background"
      role="img"
      aria-label="Garage layout seen from above"
    >
      {#each view.lines as offset (offset)}
        <line x1={offset} y1={0} x2={offset} y2={SIZE} stroke="#1C1C1C" stroke-width={1} />
        <line x1={0} y1={offset} x2={SIZE} y2={offset} stroke="#1C1C1C" stroke-width={1} />
      {/each}
      {#if zonePoints.length >= 2}
        <polygon
          points={zonePoints.map((point) => `${toX(point.x)},${toY(point.y)}`).join(' ')}
          fill="none"
          stroke="#A3A3A3"
          stroke-width={1.25}
          stroke-dasharray="4 4"
        />
      {/if}
      {#each zonePoints as point, index (index)}
        <circle cx={toX(point.x)} cy={toY(point.y)} r={2.5} fill="#A3A3A3" />
      {/each}
      {#each garage.spawns as spawn, index (index)}
        {@const active = index === highlighted}
        {@const line = active ? '#FAFAFA' : '#A3A3A3'}
        <g transform="translate({toX(spawn.x)} {toY(spawn.y)}) rotate({-spawn.w})">
          <rect
            x={-width / 2}
            y={-length / 2}
            {width}
            height={length}
            rx={3}
            fill={active ? '#FAFAFA' : '#141414'}
            stroke={active ? '#FAFAFA' : '#A3A3A3'}
            stroke-width={1.25}
          />
          <line x1={0} y1={-length / 2} x2={0} y2={-length / 2 - 10} stroke={line} stroke-width={1.5} />
          <path d="M -4 {-length / 2 - 6} L 0 {-length / 2 - 11} L 4 {-length / 2 - 6}" fill="none" stroke={line} stroke-width={1.5} />
          <text
            x={0}
            y={4}
            text-anchor="middle"
            font-size={11}
            font-weight={600}
            fill={active ? '#0A0A0A' : '#FAFAFA'}
            transform="rotate({spawn.w})"
          >
            {index + 1}
          </text>
        </g>
      {/each}
      {#if placed}
        <g transform="translate({toX(garage.interact.coords.x)} {toY(garage.interact.coords.y)})">
          <circle r={9} fill="none" stroke="#FAFAFA" stroke-width={1.5} />
          <circle r={3.5} fill="#FAFAFA" />
        </g>
      {/if}
    </svg>
    <ul class="flex flex-col gap-1.5 text-xs text-muted-foreground">
      <li class="flex items-center gap-2">
        <span class="size-3 rounded-full border-[1.5px] border-foreground bg-secondary"></span>
        {interactLegend}
      </li>
      <li class="flex items-center gap-2">
        <span class="h-2 w-3 rounded-[2px] bg-foreground"></span>
        Spawn point being previewed, arrow is heading
      </li>
      <li class="flex items-center gap-2">
        <span class="w-3 border-t-[1.5px] border-dashed border-muted-foreground"></span>
        Store zone outline
      </li>
    </ul>
    <Button size="small" class="w-full tabular-nums" disabled={garage.spawns.length === 0} onclick={onpreview}>
      Preview spawn {(highlighted ?? 0) + 1} with a ghost car
    </Button>
  {/if}
</aside>
