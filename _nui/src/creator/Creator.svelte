<script lang="ts">
  import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon'
  import MapPinIcon from 'phosphor-svelte/lib/MapPinIcon'
  import PlusCircleIcon from 'phosphor-svelte/lib/PlusCircleIcon'
  import TrashIcon from 'phosphor-svelte/lib/TrashIcon'
  import WarehouseIcon from 'phosphor-svelte/lib/WarehouseIcon'
  import WarningCircleIcon from 'phosphor-svelte/lib/WarningCircleIcon'
  import { isRecord, nui } from '../lib/nui'
  import { formatWhen } from '../lib/format'
  import { toCreatorData, toErrors, toVec4 } from '../lib/types'
  import type { CreatorData, CreatorTab, Garage, GarageType, ValidationError } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Button from '../components/Button.svelte'
  import Chip from '../components/Chip.svelte'
  import KeyHint from '../components/KeyHint.svelte'
  import Panel from '../components/Panel.svelte'
  import { TABS, TYPE_INFO, blankGarage, countChanges, describe, slug, validate } from './model'
  import Overview from './Overview.svelte'
  import GeneralTab from './GeneralTab.svelte'
  import LocationTab from './LocationTab.svelte'
  import AccessTab from './AccessTab.svelte'
  import RulesTab from './RulesTab.svelte'
  import DeleteDialog from './DeleteDialog.svelte'

  type Filter = 'all' | GarageType
  type Editing = { draft: Garage; original?: Garage }

  const FILTERS: Filter[] = ['all', 'car', 'boat', 'air', 'job', 'gang', 'house', 'impound']

  let { initial, onclose }: { initial: CreatorData; onclose: () => void } = $props()

  function initialData(): CreatorData {
    return $state.snapshot(initial)
  }

  let data = $state(initialData())
  let editing = $state<Editing>()
  let tab = $state<CreatorTab>('general')
  let query = $state('')
  let filter = $state<Filter>('all')
  let serverErrors = $state<ValidationError[]>([])
  let deleting = $state(false)
  let busy = $state(false)

  const lots = $derived(data.garages.filter((garage) => garage.type === 'impound').length)
  const isNew = $derived(editing !== undefined && editing.original === undefined)
  const errors = $derived.by(() => {
    if (!editing) return []
    const local = validate(editing.draft, data.garages, isNew)
    const extra = serverErrors.filter((error) => !local.some((item) => item.field === error.field))
    return [...local, ...extra]
  })
  const changes = $derived(editing ? countChanges(editing.draft, editing.original) : 0)
  const needle = $derived(query.trim().toLowerCase())
  const visible = $derived(
    data.garages.filter(
      (garage) =>
        (filter === 'all' || garage.type === filter) &&
        (needle === '' || garage.label.toLowerCase().includes(needle) || garage.id.includes(needle)),
    ),
  )
  const stored = $derived(editing?.original ? (data.counts[editing.original.id] ?? 0) : 0)
  const tabErrors = $derived(errors.filter((error) => error.tab === tab))

  function errorCount(id: CreatorTab): number {
    return errors.filter((error) => error.tab === id).length
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key === 'Escape' && !deleting) onclose()
  }

  function copy(garage: Garage): Garage {
    return $state.snapshot(garage)
  }

  function open(garage: Garage) {
    editing = { draft: copy(garage), original: copy(garage) }
    serverErrors = []
    tab = 'general'
  }

  async function create(base?: Garage) {
    const position = toVec4(await nui('creator:position'))
    const draft: Garage = base
      ? { ...copy(base), id: '', label: `${base.label} copy`, updatedAt: undefined, updatedBy: undefined }
      : blankGarage(data, 'car', position)
    if (base) draft.id = slug(draft.label)
    editing = { draft }
    serverErrors = []
    tab = 'general'
  }

  function update(next: Garage) {
    if (!editing) return
    const followsLabel = isNew && next.label !== editing.draft.label && editing.draft.id === slug(editing.draft.label)
    editing = { ...editing, draft: followsLabel ? { ...next, id: slug(next.label) } : next }
  }

  function applySnapshot(value: unknown, selectId?: string) {
    const next = toCreatorData(value)
    if (!next) return
    data = next
    const selected = selectId ? next.garages.find((garage) => garage.id === selectId) : undefined
    editing = selected ? { draft: copy(selected), original: copy(selected) } : undefined
  }

  async function save() {
    if (!editing || errors.length > 0 || busy) return
    const draftId = editing.draft.id
    busy = true
    const result = await nui('creator:save', { garage: copy(editing.draft), originalId: editing.original?.id })
    busy = false
    if (!isRecord(result)) return
    if (result.ok === true) {
      serverErrors = []
      applySnapshot(result.snapshot, draftId)
    } else serverErrors = toErrors(result.errors)
  }

  async function remove(moveTo?: string) {
    if (!editing?.original || busy) return
    busy = true
    const result = await nui('creator:delete', { id: editing.original.id, moveTo })
    busy = false
    if (isRecord(result) && result.ok === true) {
      deleting = false
      applySnapshot(result.snapshot)
    }
  }

  function discard() {
    if (!editing) return
    if (editing.original) open(editing.original)
    else editing = undefined
  }

  function subtitle(original: Garage): string {
    const edited = original.updatedAt ? `, last edited ${formatWhen(original.updatedAt, Date.now() / 1000).toLowerCase()}` : ''
    const by = original.updatedBy ? ` by ${original.updatedBy}` : ''
    return `${original.id}${edited}${by}`
  }
</script>

<svelte:window {onkeydown} />

{#snippet listRow(title: string, detail: string, count: number | undefined, selected: boolean, dim: boolean, onselect: () => void)}
  <button
    type="button"
    onclick={onselect}
    class="flex h-13 w-full shrink-0 items-center gap-2.5 rounded-md border px-2.5 text-left transition-colors duration-150 {focusRing} {selected
      ? 'border-primary bg-primary'
      : 'border-card hover:border-muted hover:bg-muted'}"
  >
    <span class="flex min-w-0 flex-1 flex-col gap-0.5">
      <span class="truncate text-sm font-medium {selected || !dim ? 'text-foreground' : 'text-muted-foreground'}">{title}</span>
      <span class="truncate text-xs {selected ? 'text-foreground' : 'text-muted-foreground'}">{detail}</span>
    </span>
    {#if count !== undefined}
      <span class="w-10 shrink-0 text-right text-xs tabular-nums {selected ? 'text-foreground' : 'text-muted-foreground'}">{count}</span>
    {/if}
  </button>
{/snippet}

{#snippet errorBanner(items: ValidationError[])}
  <div class="mb-7 flex gap-3 rounded-md border border-destructive bg-muted px-4 py-3.5">
    <WarningCircleIcon weight="fill" class="mt-0.5 size-4 shrink-0 text-destructive" />
    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-foreground">This garage can't be saved yet</span>
      <span class="text-[0.8125rem] text-muted-foreground">{items.map((error) => error.message).join(' ')}</span>
    </div>
  </div>
{/snippet}

{#snippet emptyCreator()}
  <header class="flex flex-col gap-1 border-b border-border px-7 py-5">
    <h2 class="text-2xl font-semibold tracking-tight text-foreground">Garage creator</h2>
    <p class="text-[0.8125rem] text-muted-foreground">No garages exist on this server yet.</p>
  </header>
  <div class="flex flex-1 flex-col items-center justify-center gap-2 text-center">
    <div class="mb-3 flex size-12 items-center justify-center rounded-md border border-border bg-secondary">
      <WarehouseIcon weight="fill" class="size-5 text-muted-foreground" />
    </div>
    <h3 class="text-lg font-semibold text-foreground">Create your first garage</h3>
    <p class="max-w-[28rem] text-sm text-muted-foreground">
      Walk to the spot, press New garage, and place the ped and spawn points in the world. Nothing goes in a config file.
    </p>
    <Button variant="primary" class="mt-4" onclick={() => create()}>New garage here</Button>
  </div>
{/snippet}

<div class="fixed inset-0 flex items-center justify-center p-8">
  <Panel class="relative h-[56.25rem] max-h-full w-[100rem] max-w-full">
    <div class="flex min-h-0 flex-1">
      <aside class="flex w-[22.5rem] shrink-0 flex-col gap-3 border-r border-border p-4">
        <div class="flex items-center justify-between gap-3 px-1 pt-1 pb-2">
          <div class="flex flex-col gap-0.5">
            <h1 class="text-lg font-semibold text-foreground">Garages</h1>
            <p class="text-xs text-muted-foreground tabular-nums">
              {data.garages.length === 0
                ? 'None yet'
                : `${data.garages.length - lots} garages, ${lots} impound ${lots === 1 ? 'lot' : 'lots'}`}
            </p>
          </div>
          <Button variant={data.garages.length === 0 ? 'secondary' : 'primary'} size="small" onclick={() => create()}>
            <PlusCircleIcon weight="fill" class="size-4" />
            New garage
          </Button>
        </div>
        <label class="flex h-9 shrink-0 items-center gap-2 rounded-md border border-input px-3 focus-within:ring-2 focus-within:ring-cobalt">
          <MagnifyingGlassIcon weight="fill" class="size-4 shrink-0 text-muted-foreground" />
          <input
            bind:value={query}
            placeholder="Search garages"
            class="w-full bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
          />
        </label>
        {#if data.garages.length > 0}
          <div class="flex flex-wrap gap-1">
            {#each FILTERS as key (key)}
              <Chip active={filter === key} onclick={() => (filter = key)}>{key === 'all' ? 'All' : TYPE_INFO[key].label}</Chip>
            {/each}
          </div>
        {/if}
        <div class="-mr-2 flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto pr-2">
          {#if data.garages.length === 0}
            <p class="px-2 py-3 text-sm text-muted-foreground">Garages you create show up here.</p>
          {/if}
          {#if isNew && editing}
            {@render listRow(
              editing.draft.label || 'New garage',
              `${TYPE_INFO[editing.draft.type].label}, draft, ${errors.length} to fix`,
              undefined,
              true,
              false,
              () => undefined,
            )}
          {/if}
          {#each visible as garage (garage.id)}
            {@render listRow(
              garage.label,
              describe(garage, data),
              data.counts[garage.id] ?? 0,
              garage.id === editing?.original?.id,
              !garage.enabled,
              () => open(garage),
            )}
          {/each}
        </div>
      </aside>

      <main class="flex min-w-0 flex-1 flex-col">
        {#if !editing}
          {#if data.garages.length === 0}
            {@render emptyCreator()}
          {:else}
            <Overview {data} onopen={open} />
          {/if}
        {:else}
          {@const draft = editing.draft}
          {@const original = editing.original}
          <header class="flex items-center gap-4 px-7 pt-5">
            <div class="flex min-w-0 flex-1 flex-col gap-1">
              <h2 class="truncate text-2xl font-semibold tracking-tight text-foreground">{draft.label || 'New garage'}</h2>
              <p class="text-[0.8125rem] text-muted-foreground">{original ? subtitle(original) : 'New garage, not saved yet'}</p>
            </div>
            {#if original}
              <Button size="small" onclick={() => nui('creator:teleport', { coords: copy(draft).interact.coords })}>
                <MapPinIcon weight="fill" class="size-4 text-muted-foreground" />
                Teleport there
              </Button>
              <Button size="small" onclick={() => create(original)}>Duplicate</Button>
              <Button variant="destructive" size="icon" class="size-8" aria-label="Delete garage" onclick={() => (deleting = true)}>
                <TrashIcon weight="fill" class="size-4" />
              </Button>
            {/if}
          </header>
          <nav class="flex gap-1 border-b border-border pt-4 pr-7 pb-3 pl-5">
            {#each TABS as item (item.id)}
              {@const count = errorCount(item.id)}
              <button
                type="button"
                onclick={() => (tab = item.id)}
                class="h-8 rounded-md px-3 text-sm font-medium tabular-nums transition-colors duration-150 {focusRing} {tab === item.id
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground'}"
              >
                {item.label}{count > 0 ? `, ${count} to fix` : ''}
              </button>
            {/each}
          </nav>

          {#key tab}
            <div class="min-h-0 flex-1 animate-enter overflow-y-auto px-7 py-6">
              {#if tabErrors.length > 1}
                {@render errorBanner(tabErrors)}
              {/if}
              {#if tab === 'general'}
                <GeneralTab {data} garage={draft} {stored} {isNew} {errors} onchange={update} />
              {:else if tab === 'location'}
                <LocationTab garage={draft} {errors} onchange={update} />
              {:else if tab === 'access'}
                <AccessTab {data} garage={draft} {errors} onchange={update} />
              {:else}
                <RulesTab {data} garage={draft} {errors} onchange={update} />
              {/if}
            </div>
          {/key}

          <footer class="flex items-center gap-2 border-t border-border px-7 py-3.5">
            {#if errors.length > 0}
              <span class="flex items-center gap-2 text-[0.8125rem] text-muted-foreground tabular-nums">
                <WarningCircleIcon weight="fill" class="size-4 text-destructive" />
                Fix {errors.length} {errors.length === 1 ? 'problem' : 'problems'} to save this garage
              </span>
            {:else if changes > 0}
              <span class="flex items-center gap-2 text-[0.8125rem] text-muted-foreground tabular-nums">
                <span class="size-1.5 rounded-full bg-warning"></span>
                {changes} unsaved {changes === 1 ? 'change' : 'changes'}
              </span>
            {:else}
              <span class="text-[0.8125rem] text-muted-foreground">{isNew ? 'Ready to save' : 'No unsaved changes'}</span>
            {/if}
            <div class="flex-1"></div>
            <span class="mr-2"><KeyHint keys={['Esc']} label="Close" /></span>
            <Button onclick={discard}>{isNew ? 'Discard draft' : 'Discard'}</Button>
            <Button variant="primary" disabled={errors.length > 0 || busy || (!isNew && changes === 0)} onclick={save}>Save garage</Button>
          </footer>
        {/if}
      </main>
    </div>

    {#if deleting && editing?.original}
      {@const original = editing.original}
      <DeleteDialog
        garage={original}
        {stored}
        targets={data.garages.filter((garage) => garage.id !== original.id && garage.type !== 'impound')}
        impound={data.garages.find((garage) => garage.id === data.defaultImpound)}
        {busy}
        oncancel={() => (deleting = false)}
        onconfirm={remove}
      />
    {/if}
  </Panel>
</div>
