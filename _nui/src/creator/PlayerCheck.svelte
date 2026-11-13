<script lang="ts">
  import CheckCircleIcon from 'phosphor-svelte/lib/CheckCircleIcon'
  import WarningCircleIcon from 'phosphor-svelte/lib/WarningCircleIcon'
  import XCircleIcon from 'phosphor-svelte/lib/XCircleIcon'
  import { isRecord, nui, str } from '../lib/nui'
  import type { Garage } from '../lib/types'
  import Input from '../components/Input.svelte'

  type CheckResult = { found: false } | { found: true; name: string; allowed: boolean; reason?: string }

  let { garage }: { garage: Garage } = $props()

  let query = $state('')
  let result = $state<CheckResult>()

  function toResult(value: unknown): CheckResult | undefined {
    if (!isRecord(value)) return undefined
    if (value.found !== true) return { found: false }
    return { found: true, name: str(value.name) ?? '', allowed: value.allowed === true, reason: str(value.reason) }
  }

  $effect(() => {
    const needle = query.trim()
    const draft = $state.snapshot(garage)
    if (needle.length < 2) {
      result = undefined
      return
    }
    let live = true
    const timer = window.setTimeout(async () => {
      const next = toResult(await nui('creator:check', { garage: draft, query: needle }))
      if (live && next) result = next
    }, 300)
    return () => {
      live = false
      window.clearTimeout(timer)
    }
  })
</script>

<aside class="flex flex-col gap-3 rounded-lg border border-border p-4">
  <div class="flex flex-col gap-0.5">
    <span class="text-sm font-semibold text-foreground">Check a player</span>
    <span class="text-xs text-muted-foreground">See who gets in before you save.</span>
  </div>
  <Input bind:value={query} placeholder="Citizen ID or name" />
  {#if result}
    <div class="flex animate-rise gap-2.5 rounded-md border border-border bg-muted p-3">
      {#if !result.found}
        <WarningCircleIcon weight="fill" class="mt-0.5 size-4 shrink-0 text-muted-foreground" />
        <span class="text-[0.8125rem] text-muted-foreground">No character matches that.</span>
      {:else}
        {#if result.allowed}
          <CheckCircleIcon weight="fill" class="mt-0.5 size-4 shrink-0 text-success" />
        {:else}
          <XCircleIcon weight="fill" class="mt-0.5 size-4 shrink-0 text-destructive" />
        {/if}
        <span class="flex flex-col gap-0.5">
          <span class="text-[0.8125rem] font-medium text-foreground">{result.name} {result.allowed ? 'can' : "can't"} use this garage</span>
          {#if result.reason}
            <span class="text-xs text-muted-foreground">{result.reason}</span>
          {/if}
        </span>
      {/if}
    </div>
  {/if}
</aside>
