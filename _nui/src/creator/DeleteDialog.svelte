<script lang="ts">
  import type { Garage } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Button from '../components/Button.svelte'
  import Input from '../components/Input.svelte'
  import Select from '../components/Select.svelte'

  type Props = {
    garage: Garage
    stored: number
    targets: Garage[]
    impound?: Garage
    busy: boolean
    oncancel: () => void
    onconfirm: (moveTo?: string) => void
  }

  let { garage, stored, targets, impound, busy, oncancel, onconfirm }: Props = $props()

  function firstTarget(): Garage | undefined {
    return targets[0]
  }

  let mode = $state<'move' | 'impound'>(firstTarget() ? 'move' : 'impound')
  let target = $state(firstTarget()?.id ?? '')
  let typed = $state('')
  let dialog = $state<HTMLDivElement>()

  const moveTo = $derived(stored === 0 ? undefined : mode === 'move' ? target : impound?.id)
  const ready = $derived(typed === garage.id && (stored === 0 || (moveTo !== undefined && moveTo !== '')))

  $effect(() => {
    dialog?.querySelector('input')?.focus()
  })

  function pickTarget(value: string) {
    target = value
    mode = 'move'
  }
</script>

{#snippet radio(active: boolean)}
  <span class="flex size-4 shrink-0 items-center justify-center rounded-full border {active ? 'border-foreground' : 'border-input'}">
    {#if active}
      <span class="size-2 rounded-full bg-foreground"></span>
    {/if}
  </span>
{/snippet}

<div class="absolute inset-0 flex items-start justify-center pt-[13rem]">
  <div
    bind:this={dialog}
    role="dialog"
    aria-label="Delete {garage.label}"
    class="flex w-[28.75rem] animate-rise flex-col gap-5 rounded-lg border border-border bg-popover p-6 shadow-[0_10px_15px_-3px_#000000,0_4px_6px_-4px_#000000]"
  >
    <div class="flex flex-col gap-1.5">
      <h2 class="text-lg font-semibold text-foreground">Delete {garage.label}?</h2>
      <p class="text-sm text-muted-foreground tabular-nums">
        {stored > 0
          ? `${stored} ${stored === 1 ? 'vehicle is' : 'vehicles are'} stored here. Pick where they go. Deleting the garage can't be undone.`
          : "No vehicles are stored here. Deleting the garage can't be undone."}
      </p>
    </div>

    {#if stored > 0}
      <div class="flex flex-col gap-1.5">
        {#if targets.length > 0}
          <div
            class="flex items-center gap-3 rounded-md border p-3 transition-colors duration-150 {mode === 'move'
              ? 'border-primary bg-primary'
              : 'border-border'}"
          >
            <button type="button" onclick={() => (mode = 'move')} class="flex flex-1 items-center gap-3 text-left {focusRing}">
              {@render radio(mode === 'move')}
              <span class="text-sm text-foreground">Move them to</span>
            </button>
            <div class="w-44">
              <Select value={target} onchange={pickTarget} size="small">
                {#each targets as item (item.id)}
                  <option value={item.id}>{item.label}</option>
                {/each}
              </Select>
            </div>
          </div>
        {/if}
        {#if impound}
          <button
            type="button"
            onclick={() => (mode = 'impound')}
            class="flex items-center gap-3 rounded-md border p-3 text-left transition-colors duration-150 {focusRing} {mode === 'impound'
              ? 'border-primary bg-primary'
              : 'border-border'}"
          >
            {@render radio(mode === 'impound')}
            <span class="text-sm text-foreground">Send them to {impound.label}, no fee</span>
          </button>
        {/if}
      </div>
    {/if}

    <div class="flex flex-col gap-2">
      <span class="text-sm font-medium text-foreground">Type {garage.id} to confirm</span>
      <Input bind:value={typed} placeholder={garage.id} />
    </div>

    <div class="flex justify-end gap-2">
      <Button onclick={oncancel}>Cancel</Button>
      <Button variant="destructive" disabled={!ready || busy} onclick={() => onconfirm(moveTo)}>Delete garage</Button>
    </div>
  </div>
</div>
