<script lang="ts">
  import Button from '../components/Button.svelte'
  import { formatDistance, formatMoney } from '../lib/format'
  import { nui } from '../lib/nui'
  import { toOutcome, toTargets, type TransferTarget, type VehicleView } from '../lib/types'
  import TransferOption from './TransferOption.svelte'

  type Props = { vehicle: VehicleView; bank: number; onclose: () => void }

  let { vehicle, bank, onclose }: Props = $props()

  let targets = $state<TransferTarget[]>()
  let choice = $state<string>()
  let busy = $state(false)

  const target = $derived(targets?.find((item) => item.id === choice))
  const fee = $derived(target?.fee ?? 0)

  $effect(() => {
    const plate = vehicle.plate
    let live = true
    void nui('garage:transferTargets', { plate }).then((result) => {
      if (!live) return
      const found = toTargets(result)
      targets = found
      choice = found.find((item) => item.available)?.id
    })
    return () => {
      live = false
    }
  })

  function onkeydown(event: KeyboardEvent) {
    if (event.key !== 'Escape') return
    event.stopPropagation()
    onclose()
  }

  async function confirm() {
    if (!target || busy) return
    busy = true
    const result = toOutcome(await nui('garage:transfer', { plate: vehicle.plate, to: target.id }))
    busy = false
    if (result.ok) onclose()
  }

  function detailOf(item: TransferTarget): string {
    return item.available ? `${item.kind}, ${formatDistance(item.distance)}` : (item.reason ?? '')
  }

  function priceOf(item: TransferTarget): string {
    if (!item.available) return 'Locked'
    return item.fee > 0 ? formatMoney(item.fee) : 'Free'
  }
</script>

<svelte:window onkeydowncapture={onkeydown} />

<div class="absolute inset-0 flex items-start justify-center pt-[6.25rem]">
  <div
    role="dialog"
    aria-label="Transfer {vehicle.label}"
    class="flex w-[27.5rem] animate-rise flex-col gap-5 rounded-lg border border-border bg-popover p-6 shadow-[0_10px_15px_-3px_#000000,0_4px_6px_-4px_#000000]"
  >
    <div class="flex flex-col gap-1.5">
      <h2 class="text-lg font-semibold text-foreground">Transfer {vehicle.label}</h2>
      <p class="text-sm text-muted-foreground">Only garages you can use are listed. The car moves there right away.</p>
    </div>

    <div class="flex max-h-[15.125rem] flex-col gap-1.5 overflow-y-auto">
      {#if targets === undefined}
        <p class="py-6 text-center text-sm text-muted-foreground">Finding garages</p>
      {:else if targets.length === 0}
        <p class="py-6 text-center text-sm text-muted-foreground">There is no other garage you can use.</p>
      {:else}
        {#each targets as item (item.id)}
          <TransferOption
            label={item.label}
            detail={detailOf(item)}
            price={priceOf(item)}
            available={item.available}
            active={item.id === choice}
            onselect={() => (choice = item.id)}
          />
        {/each}
      {/if}
    </div>

    <div class="flex items-center justify-between border-t border-border pt-4 text-sm">
      <span class="text-muted-foreground">Paid from bank, balance <span class="tabular-nums">{formatMoney(bank)}</span></span>
      <span class="font-semibold tabular-nums text-foreground">{fee > 0 ? formatMoney(fee) : 'Free'}</span>
    </div>

    <div class="flex justify-end gap-2">
      <Button onclick={onclose}>Cancel</Button>
      <Button variant="primary" disabled={!target || busy || bank < fee} onclick={confirm}>
        {fee > 0 ? `Transfer for ${formatMoney(fee)}` : 'Transfer'}
      </Button>
    </div>
  </div>
</div>
