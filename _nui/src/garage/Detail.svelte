<script lang="ts">
  import Button from '../components/Button.svelte'
  import KeyHint from '../components/KeyHint.svelte'
  import LicensePlate from '../components/LicensePlate.svelte'
  import Segmented from '../components/Segmented.svelte'
  import { formatCount, formatMoney, formatWhen } from '../lib/format'
  import type { Account, GarageView, VehicleView } from '../lib/types'
  import Fact from './Fact.svelte'
  import Stat from './Stat.svelte'
  import { isHeld, type Selection } from './garage'

  type Props = {
    garage: GarageView
    item: Selection
    busy: boolean
    account: Account
    onaccount: (account: Account) => void
    onprimary: () => void
    ontransfer: (vehicle: VehicleView) => void
  }

  let { garage, item, busy, account, onaccount, onprimary, ontransfer }: Props = $props()

  const impound = $derived(garage.type === 'impound')
  const blocked = $derived(garage.spawn.bay === undefined)
  const fleet = $derived(item.kind === 'fleet' ? item.fleet : undefined)
  const vehicle = $derived(item.kind === 'vehicle' ? item.vehicle : undefined)
  const held = $derived(vehicle ? isHeld(vehicle, garage.now) : false)
  const balance = $derived(account === 'bank' ? garage.balances.bank : garage.balances.cash)

  const eyebrow = $derived.by(() => {
    const source = fleet ?? vehicle
    if (!source) return ''
    return source.seats > 0 ? `${source.classLabel}, ${source.seats} ${source.seats === 1 ? 'seat' : 'seats'}` : source.classLabel
  })

  function bayText(exit: boolean): string {
    if (garage.spawn.total === 0) return 'No bays set up'
    if (garage.spawn.bay === undefined) return `All ${garage.spawn.total} bays blocked`
    return `${exit ? 'Exit bay' : 'Bay'} ${garage.spawn.bay} of ${garage.spawn.total}, clear`
  }

  function feeText(fee: number): string {
    return fee > 0 ? formatMoney(fee) : 'Free'
  }

  function releaseLabel(target: VehicleView): string {
    if (held) return 'On police hold'
    return target.fee > 0 ? `Pay ${formatMoney(target.fee)} and take out` : 'Take out'
  }

  function idleText(target: VehicleView): string {
    if (target.status === 'elsewhere') return `Parked at ${target.location ?? 'another garage'}. Take it out there, or transfer it from there.`
    if (target.status === 'out') return 'It is out in the city. Drive it here and press Store to park it.'
    if (target.status === 'impounded') return `Pay the release fee at ${target.location ?? 'the impound lot'} to get it back.`
    return ''
  }
</script>

{#snippet enterHint(label: string)}
  <div class="flex-1"></div>
  <KeyHint keys={['Enter']} {label} />
{/snippet}

<section class="flex min-w-0 flex-1 animate-enter flex-col gap-6 px-7 py-6">
  <div class="flex items-end justify-between gap-6">
    <div class="flex min-w-0 flex-col gap-1.5">
      <span class="text-[0.8125rem] text-muted-foreground">{eyebrow}</span>
      <h2 class="truncate text-4xl font-semibold tracking-[-0.02em] text-foreground">{fleet?.label ?? vehicle?.label}</h2>
    </div>
    <LicensePlate text={vehicle?.plate ?? 'FLEET'} size="large" />
  </div>

  {#if fleet}
    <div class="flex flex-1 flex-col">
      <Fact label="Belongs to" value="The shared fleet" />
      <Fact label="Spawns at" value={bayText(false)} />
      <Fact label="Fuel" value="Full tank" />
    </div>
    <div class="flex items-center gap-2">
      <Button variant="primary" size="large" disabled={busy || blocked} onclick={onprimary}>Take out</Button>
      {@render enterHint('Take out')}
    </div>
  {:else if vehicle}
    {@const fuel = Math.round(vehicle.fuel)}
    {@const engine = Math.round(vehicle.engine)}
    {@const body = Math.round(vehicle.body)}
    <div class="flex gap-3">
      <Stat label="Fuel" value={fuel} max={100} display="{fuel}%" />
      <Stat label="Engine" value={engine} max={1000} display="{engine} / 1000" />
      <Stat label="Body" value={body} max={1000} display="{body} / 1000" />
    </div>

    <div class="flex flex-1 flex-col">
      {#if impound}
        {#if vehicle.impoundedAt !== undefined}
          <Fact label="Impounded" value={formatWhen(vehicle.impoundedAt, garage.now)} />
        {/if}
        <Fact label="Reason" value={vehicle.impoundReason ?? 'No reason recorded'} />
        {#if held && vehicle.holdUntil !== undefined}
          <Fact label="Police hold" value="Until {formatWhen(vehicle.holdUntil, garage.now)}" />
        {/if}
        <Fact label="Spawns at" value={bayText(true)} />
        <Fact label="Release fee" value={feeText(vehicle.fee)} />
      {:else}
        {#if vehicle.status === 'here' && vehicle.parkedAt !== undefined}
          <Fact label="Parked" value={formatWhen(vehicle.parkedAt, garage.now)} />
        {/if}
        {#if vehicle.status === 'elsewhere'}
          <Fact label="Parked at" value={vehicle.location ?? 'Another garage'} />
        {/if}
        {#if vehicle.status === 'out'}
          <Fact label="Where" value={vehicle.drivenByYou ? 'You are driving it' : 'Somewhere in the city'} />
        {/if}
        {#if vehicle.status === 'impounded'}
          <Fact label="Held at" value={vehicle.location ?? 'The impound lot'} />
        {/if}
        {#if vehicle.mileage !== undefined}
          <Fact label="Mileage" value="{formatCount(Math.round(vehicle.mileage / 1000))} km" />
        {/if}
        {#if vehicle.status === 'here'}
          <Fact label="Spawns at" value={bayText(false)} />
        {/if}
        {#if vehicle.status === 'impounded'}
          <Fact label="Release fee" value={feeText(vehicle.fee)} />
        {:else}
          <Fact label="Retrieval fee" value={feeText(garage.fees.takeOut)} />
        {/if}
      {/if}
    </div>

    {#if impound}
      <div class="flex items-center gap-2">
        <Button variant="primary" size="large" disabled={busy || held || blocked || balance < vehicle.fee} onclick={onprimary}>
          {releaseLabel(vehicle)}
        </Button>
        {#if vehicle.fee > 0 && !held}
          <Segmented
            value={account}
            size="large"
            onchange={onaccount}
            options={[
              { value: 'bank', label: `Bank ${formatMoney(garage.balances.bank)}` },
              { value: 'cash', label: `Cash ${formatMoney(garage.balances.cash)}` },
            ]}
          />
        {/if}
        {#if !held}
          {@render enterHint('Release')}
        {/if}
      </div>
    {:else if vehicle.status === 'here'}
      {@const target = vehicle}
      <div class="flex items-center gap-2">
        <Button variant="primary" size="large" disabled={busy || blocked} onclick={onprimary}>
          {garage.fees.takeOut > 0 ? `Take out for ${formatMoney(garage.fees.takeOut)}` : 'Take out'}
        </Button>
        <Button size="large" class="px-4!" disabled={busy} onclick={() => ontransfer(target)}>Transfer to another garage</Button>
        {@render enterHint('Take out')}
      </div>
    {:else}
      <p class="text-sm text-muted-foreground">{idleText(vehicle)}</p>
    {/if}
  {/if}
</section>
