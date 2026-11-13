<script lang="ts">
  import { onMount } from 'svelte'
  import { isRecord, nui, onNuiMessage } from './lib/nui'
  import { toCreatorData, toGarageView, toPlacement } from './lib/types'
  import type { CreatorData, GarageView as GarageData, Placement } from './lib/types'
  import GarageView from './garage/GarageView.svelte'
  import Creator from './creator/Creator.svelte'
  import PlacementHud from './creator/PlacementHud.svelte'

  type View = { kind: 'garage'; data: GarageData } | { kind: 'creator'; data: CreatorData; session: number }

  const idle: Placement = { active: false, checks: [] }

  let view = $state<View>()
  let placement = $state<Placement>(idle)

  function open(message: unknown) {
    if (!isRecord(message)) return
    if (message.view === 'garage') {
      const data = toGarageView(message.payload)
      if (data) view = { kind: 'garage', data }
    }
    if (message.view === 'creator') {
      const data = toCreatorData(message.payload)
      if (data) view = { kind: 'creator', data, session: Date.now() }
    }
  }

  function refresh(message: unknown) {
    const data = toGarageView(message)
    if (data && view?.kind === 'garage') view = { kind: 'garage', data }
  }

  onMount(() =>
    onNuiMessage((action, data) => {
      if (action === 'open') open(data)
      if (action === 'garage') refresh(data)
      if (action === 'placement') placement = toPlacement(data)
      if (action === 'close') {
        view = undefined
        placement = idle
      }
    }),
  )

  function closeGarage() {
    view = undefined
    void nui('garage:close')
  }

  function closeCreator() {
    view = undefined
    void nui('close')
  }
</script>

{#if view?.kind === 'garage'}
  <GarageView data={view.data} onclose={closeGarage} />
{:else if view?.kind === 'creator'}
  <div class={placement.active ? 'hidden' : undefined}>
    {#key view.session}
      <Creator initial={view.data} onclose={closeCreator} />
    {/key}
  </div>
{/if}
{#if placement.active}
  <PlacementHud {placement} />
{/if}
