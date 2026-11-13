<script lang="ts">
  import XCircleIcon from 'phosphor-svelte/lib/XCircleIcon'
  import { isRecord, list, nui, str } from '../lib/nui'
  import type { Citizen } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Button from '../components/Button.svelte'
  import Input from '../components/Input.svelte'
  import SectionTitle from '../components/SectionTitle.svelte'

  let { citizens, onchange }: { citizens: Citizen[]; onchange: (citizens: Citizen[]) => void } = $props()

  let query = $state('')
  let matches = $state<Citizen[]>([])
  let nearby = $state<Citizen[]>()

  const suggestions = $derived(nearby ?? matches)

  function toCitizens(value: unknown): Citizen[] {
    return list(value).flatMap((item) => {
      const citizenid = isRecord(item) ? str(item.citizenid) : undefined
      return isRecord(item) && citizenid ? [{ citizenid, name: str(item.name) ?? '' }] : []
    })
  }

  $effect(() => {
    const needle = query.trim()
    if (needle.length < 2) {
      matches = []
      return
    }
    let live = true
    const timer = window.setTimeout(async () => {
      const result = toCitizens(await nui('creator:findCitizens', { query: needle }))
      if (live) matches = result
    }, 250)
    return () => {
      live = false
      window.clearTimeout(timer)
    }
  })

  function add(citizen: Citizen) {
    if (!citizens.some((item) => item.citizenid === citizen.citizenid)) onchange([...citizens, citizen])
    query = ''
    matches = []
    nearby = undefined
  }

  async function pickNearby() {
    nearby = toCitizens(await nui('creator:nearby'))
  }
</script>

<section class="flex flex-col gap-3">
  <SectionTitle title="Citizens" description="Specific characters, whatever their job or gang." />
  <div class="relative flex gap-2">
    <div class="flex-1">
      <Input bind:value={query} oninput={() => (nearby = undefined)} placeholder="Citizen ID or character name" />
    </div>
    <Button onclick={pickNearby}>Pick a nearby player</Button>
    {#if suggestions.length > 0 || nearby?.length === 0}
      <div class="absolute top-11 right-0 left-0 z-10 flex animate-rise flex-col overflow-hidden rounded-md border border-border bg-popover">
        {#if nearby?.length === 0}
          <span class="px-3 py-2.5 text-sm text-muted-foreground">Nobody is within 10 m of you.</span>
        {/if}
        {#each suggestions as citizen (citizen.citizenid)}
          <button
            type="button"
            onclick={() => add(citizen)}
            class="flex items-center justify-between px-3 py-2.5 text-left text-sm transition-colors duration-150 hover:bg-muted {focusRing}"
          >
            <span class="font-medium text-foreground">{citizen.name}</span>
            <span class="tabular-nums text-muted-foreground">{citizen.citizenid}</span>
          </button>
        {/each}
      </div>
    {/if}
  </div>
  {#if citizens.length > 0}
    <div class="flex flex-wrap gap-1.5">
      {#each citizens as citizen (citizen.citizenid)}
        <span class="flex h-7 items-center gap-2 rounded-sm bg-secondary pr-1.5 pl-2.5">
          <span class="text-[0.8125rem] text-foreground">{citizen.name || citizen.citizenid}</span>
          <span class="text-xs tabular-nums text-muted-foreground">{citizen.citizenid}</span>
          <button
            type="button"
            aria-label="Remove {citizen.name}"
            onclick={() => onchange(citizens.filter((item) => item.citizenid !== citizen.citizenid))}
            class="rounded-full text-muted-foreground transition-colors duration-150 hover:text-foreground {focusRing}"
          >
            <XCircleIcon weight="fill" class="size-3.5" />
          </button>
        </span>
      {/each}
    </div>
  {/if}
</section>
