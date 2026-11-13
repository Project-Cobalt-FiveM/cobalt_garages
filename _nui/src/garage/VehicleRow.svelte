<script lang="ts">
  import Meter from '../components/Meter.svelte'
  import { conditionBar, conditionOf } from '../lib/condition'
  import { formatClock, formatMoney } from '../lib/format'
  import type { VehicleStatus, VehicleView } from '../lib/types'
  import Row from './Row.svelte'
  import RowName from './RowName.svelte'
  import RowSide from './RowSide.svelte'
  import RowStatus, { type StatusTone } from './RowStatus.svelte'

  type Props = { vehicle: VehicleView; impound: boolean; held: boolean; selected: boolean; onselect: () => void }

  const statuses: Record<VehicleStatus, { tone: StatusTone; label: string }> = {
    here: { tone: 'solid', label: 'Here' },
    elsewhere: { tone: 'outline', label: 'Elsewhere' },
    out: { tone: 'outline', label: 'Out' },
    impounded: { tone: 'danger', label: 'Impounded' },
  }

  let { vehicle, impound, held, selected, onselect }: Props = $props()

  const parked = $derived(vehicle.status === 'here' || vehicle.status === 'elsewhere')

  const fuelTone = $derived(conditionBar[conditionOf(vehicle.fuel, 100)])

  const detail = $derived.by(() => {
    if (impound) return held && vehicle.holdUntil ? `Police hold until ${formatClock(vehicle.holdUntil)}` : vehicle.classLabel
    if (vehicle.status === 'out') return vehicle.drivenByYou ? 'Driven by you' : 'In the world'
    if (vehicle.location && vehicle.status !== 'here') return `At ${vehicle.location}`
    return vehicle.classLabel
  })

  const sideText = $derived.by(() => {
    if (vehicle.status === 'out') return 'In the world'
    if (vehicle.status === 'impounded') return `${formatMoney(vehicle.fee)} to release`
    return `Fuel ${Math.round(vehicle.fuel)}%`
  })
</script>

<Row {selected} {onselect}>
  {#if impound}
    <RowName title={vehicle.label} plate={vehicle.plate} {detail} {selected} dim={false} />
    <RowSide text={formatMoney(vehicle.fee)} {selected} />
    <RowStatus tone={held ? 'warning' : 'solid'} label={held ? 'On hold' : 'Ready'} />
  {:else}
    <RowName title={vehicle.label} plate={vehicle.plate} {detail} {selected} dim={vehicle.status !== 'here'} />
    <RowSide text={sideText} {selected}>
      {#if parked}
        <Meter value={vehicle.fuel} max={100} tone={fuelTone} height="h-1" track={selected ? 'bg-cobalt-hover' : 'bg-secondary'} />
      {/if}
    </RowSide>
    <RowStatus {...statuses[vehicle.status]} />
  {/if}
</Row>
