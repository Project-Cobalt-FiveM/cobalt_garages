<script lang="ts">
  import type { Garage } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Button from '../components/Button.svelte'
  import Input from '../components/Input.svelte'

  type Fleet = Garage['fleet']

  let { fleet, onchange }: { fleet: Fleet; onchange: (fleet: Fleet) => void } = $props()

  let model = $state('')
  let label = $state('')

  const clean = $derived(model.trim().toLowerCase())
  const valid = $derived(/^[a-z0-9_]+$/.test(clean))

  function add() {
    if (!valid) return
    onchange([...fleet, { model: clean, label: label.trim() || clean }])
    model = ''
    label = ''
  }
</script>

<div class="flex flex-col gap-2">
  {#if fleet.length > 0}
    <div class="flex flex-col overflow-hidden rounded-md border border-border">
      {#each fleet as vehicle, index (`${vehicle.model}-${index}`)}
        <div class="flex items-center gap-4 border-b border-border px-3 py-2 text-sm last:border-b-0">
          <span class="w-48 font-medium text-foreground">{vehicle.label}</span>
          <span class="flex-1 text-muted-foreground">{vehicle.model}</span>
          <button
            type="button"
            onclick={() => onchange(fleet.filter((_, i) => i !== index))}
            class="rounded-sm text-xs font-medium text-muted-foreground transition-colors duration-150 hover:text-foreground {focusRing}"
          >
            Remove
          </button>
        </div>
      {/each}
    </div>
  {/if}
  <div class="flex gap-2">
    <div class="w-48">
      <Input bind:value={model} placeholder="Model, like police2" />
    </div>
    <div class="flex-1">
      <Input bind:value={label} placeholder="Name players see, like Police Buffalo" />
    </div>
    <Button disabled={!valid} onclick={add}>Add vehicle</Button>
  </div>
</div>
