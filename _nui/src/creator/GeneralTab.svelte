<script lang="ts">
  import AirplaneIcon from 'phosphor-svelte/lib/AirplaneIcon'
  import BoatIcon from 'phosphor-svelte/lib/BoatIcon'
  import CarIcon from 'phosphor-svelte/lib/CarIcon'
  import HouseIcon from 'phosphor-svelte/lib/HouseIcon'
  import ShieldStarIcon from 'phosphor-svelte/lib/ShieldStarIcon'
  import TruckIcon from 'phosphor-svelte/lib/TruckIcon'
  import WarehouseIcon from 'phosphor-svelte/lib/WarehouseIcon'
  import { GARAGE_TYPES } from '../lib/types'
  import type { CreatorData, Garage, GarageType, InteractMode, Owners, ValidationError } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Field from '../components/Field.svelte'
  import Input from '../components/Input.svelte'
  import SectionTitle from '../components/SectionTitle.svelte'
  import Segmented from '../components/Segmented.svelte'
  import Select from '../components/Select.svelte'
  import Toggle from '../components/Toggle.svelte'
  import { TYPE_INFO, slug } from './model'

  type Props = {
    data: CreatorData
    garage: Garage
    stored: number
    isNew: boolean
    errors: ValidationError[]
    onchange: (garage: Garage) => void
  }

  const SPRITES: { id: number; icon: typeof WarehouseIcon; label: string }[] = [
    { id: 357, icon: WarehouseIcon, label: 'Garage' },
    { id: 225, icon: CarIcon, label: 'Car' },
    { id: 60, icon: ShieldStarIcon, label: 'Police' },
    { id: 40, icon: HouseIcon, label: 'House' },
    { id: 410, icon: BoatIcon, label: 'Boat' },
    { id: 359, icon: AirplaneIcon, label: 'Hangar' },
    { id: 68, icon: TruckIcon, label: 'Tow truck' },
  ]

  const COLOURS: { id: number; label: string }[] = [
    { id: 0, label: 'White' },
    { id: 1, label: 'Red' },
    { id: 2, label: 'Green' },
    { id: 3, label: 'Blue' },
    { id: 5, label: 'Yellow' },
    { id: 17, label: 'Orange' },
    { id: 27, label: 'Purple' },
    { id: 38, label: 'Dark blue' },
    { id: 40, label: 'Grey' },
    { id: 57, label: 'Cyan' },
  ]

  const SCENARIOS: { id: string; label: string }[] = [
    { id: 'WORLD_HUMAN_CLIPBOARD', label: 'Clipboard' },
    { id: 'WORLD_HUMAN_STAND_IMPATIENT', label: 'Standing' },
    { id: 'WORLD_HUMAN_GUARD_STAND', label: 'Guard' },
    { id: 'WORLD_HUMAN_STAND_MOBILE', label: 'On the phone' },
    { id: 'WORLD_HUMAN_SMOKING', label: 'Smoking' },
    { id: 'WORLD_HUMAN_LEANING', label: 'Leaning' },
    { id: '', label: 'None' },
  ]

  let { data, garage, stored, isNew, errors, onchange }: Props = $props()

  const isOrg = $derived(garage.type === 'job' || garage.type === 'gang')

  function error(field: string): string | undefined {
    return errors.find((item) => item.field === field)?.message
  }

  function setInteract(patch: Partial<Garage['interact']>) {
    onchange({ ...garage, interact: { ...garage.interact, ...patch } })
  }

  function setBlip(patch: Partial<Garage['blip']>) {
    onchange({ ...garage, blip: { ...garage.blip, ...patch } })
  }

  function setType(type: GarageType) {
    if (type === garage.type) return
    onchange({
      ...garage,
      type,
      owners: type === 'job' || type === 'gang' ? garage.owners : 'player',
      blip: { ...garage.blip, sprite: data.defaultSprites[type] },
      rules: { ...garage.rules, classes: [...data.defaultClasses[type]] },
    })
  }

  function setId(event: Event & { currentTarget: HTMLInputElement }) {
    const id = slug(event.currentTarget.value)
    event.currentTarget.value = id
    onchange({ ...garage, id })
  }

  function setPed(event: Event & { currentTarget: HTMLInputElement }) {
    const ped = event.currentTarget.value.toLowerCase()
    event.currentTarget.value = ped
    setInteract({ ped })
  }
</script>

<div class="flex flex-col gap-7">
  <div class="grid grid-cols-[1fr_18.75rem_11.25rem] gap-4">
    <Field label="Name" hint="Players see this on the blip and at the top of the garage." error={error('label')}>
      <Input
        value={garage.label}
        maxlength={100}
        invalid={!!error('label')}
        oninput={(event) => onchange({ ...garage, label: event.currentTarget.value })}
      />
    </Field>
    <Field
      label="ID"
      hint={stored > 0 ? 'Locked because vehicles are stored here.' : 'Set from the name. Locked once vehicles are stored.'}
      error={error('id')}
    >
      <Input
        value={garage.id}
        disabled={stored > 0}
        invalid={!!error('id')}
        oninput={setId}
        placeholder={isNew ? slug(garage.label) : undefined}
      />
    </Field>
    <Field label="Status" hint="Closed garages keep their cars.">
      <div class="flex h-9 items-center gap-3">
        <Toggle checked={garage.enabled} label="Open" onchange={(enabled) => onchange({ ...garage, enabled })} />
        <span class="text-sm font-medium text-foreground">{garage.enabled ? 'Open' : 'Closed'}</span>
      </div>
    </Field>
  </div>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title="Type" description="Sets which vehicles fit and which access rules apply." />
    <div class="flex gap-2">
      {#each GARAGE_TYPES as type (type)}
        {@const active = type === garage.type}
        <button
          type="button"
          onclick={() => setType(type)}
          class="flex flex-1 flex-col gap-1.5 rounded-md border p-3 text-left transition-colors duration-150 {focusRing} {active
            ? 'border-primary bg-primary'
            : 'border-border hover:bg-muted'}"
        >
          <span class="text-sm font-medium text-foreground">{TYPE_INFO[type].label}</span>
          <span class="text-xs {active ? 'text-foreground' : 'text-muted-foreground'}">{TYPE_INFO[type].hint}</span>
        </button>
      {/each}
    </div>
    {#if isOrg}
      <div class="flex items-center justify-between gap-4 rounded-md border border-border bg-muted px-4 py-3.5">
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-medium text-foreground">Vehicles stored here belong to</span>
          <span class="text-xs text-muted-foreground">
            {garage.type === 'job' ? 'Job' : 'Gang'} garages can hold a shared fleet as well as members' own cars.
          </span>
        </div>
        <Segmented
          value={garage.owners}
          onchange={(owners: Owners) => onchange({ ...garage, owners })}
          options={[
            { value: 'player', label: 'Each player' },
            { value: 'fleet', label: garage.type === 'job' ? 'Shared job fleet' : 'Shared gang fleet' },
            { value: 'both', label: 'Both' },
          ]}
        />
      </div>
    {/if}
    {#if garage.type === 'house'}
      <div class="w-72">
        <Field label="Property ID" hint="The cobalt_housing property this garage belongs to." error={error('propertyId')}>
          <Input
            type="number"
            min={1}
            value={garage.propertyId ?? ''}
            invalid={!!error('propertyId')}
            oninput={(event) =>
              onchange({ ...garage, propertyId: event.currentTarget.value === '' ? undefined : Number(event.currentTarget.value) })}
          />
        </Field>
      </div>
    {/if}
  </section>

  <section class="flex flex-col gap-3">
    <SectionTitle title="Map blip" description="Locked garages only show their blip to players who can use them.">
      {#snippet action()}
        <span class="text-sm text-foreground">Show on map</span>
        <Toggle checked={garage.blip.show} label="Show on map" onchange={(show) => setBlip({ show })} />
      {/snippet}
    </SectionTitle>
    <div class="flex flex-wrap items-start gap-4">
      <Field label="Sprite">
        <div class="flex items-center gap-1.5">
          {#each SPRITES as sprite (sprite.id)}
            {@const active = garage.blip.sprite === sprite.id}
            <button
              type="button"
              aria-label="{sprite.label}, sprite {sprite.id}"
              onclick={() => setBlip({ sprite: sprite.id })}
              class="flex size-11 items-center justify-center rounded-md border transition-colors duration-150 {focusRing} {active
                ? 'border-primary bg-primary'
                : 'border-border hover:bg-muted'}"
            >
              <sprite.icon weight="fill" class="size-5 {active ? 'text-foreground' : 'text-muted-foreground'}" />
            </button>
          {/each}
          <div class="w-24">
            <Input
              type="number"
              prefix="ID"
              class="h-11 pl-9"
              value={garage.blip.sprite}
              oninput={(event) => setBlip({ sprite: Number(event.currentTarget.value) || 1 })}
            />
          </div>
        </div>
      </Field>
      <Field label="Colour" class="w-50">
        <Select value={String(garage.blip.colour)} onchange={(value) => setBlip({ colour: Number(value) })}>
          {#each COLOURS as colour (colour.id)}
            <option value={String(colour.id)}>{colour.label}, {colour.id}</option>
          {/each}
        </Select>
      </Field>
      <Field label="Size" class="w-30">
        <Input
          type="number"
          step={0.1}
          min={0.3}
          max={2}
          value={garage.blip.scale}
          oninput={(event) => setBlip({ scale: Number(event.currentTarget.value) || 0.7 })}
        />
      </Field>
    </div>
  </section>

  <section class="flex flex-col gap-3">
    <SectionTitle title="How players open it" description="Place the point itself on the Location tab." />
    <div class="flex flex-wrap items-end gap-4">
      <Segmented
        value={garage.interact.mode}
        onchange={(mode: InteractMode) => setInteract({ mode })}
        options={[
          { value: 'ped', label: 'Ped with target' },
          { value: 'target', label: 'Target zone' },
          { value: 'marker', label: 'Marker and E key' },
        ]}
      />
      {#if garage.interact.mode === 'ped'}
        <Field label="Ped model" class="w-56" error={error('ped')}>
          <Input value={garage.interact.ped} invalid={!!error('ped')} oninput={setPed} />
        </Field>
        <Field label="Scenario" class="w-64">
          <Select value={garage.interact.scenario} onchange={(scenario) => setInteract({ scenario })}>
            {#each SCENARIOS as scenario (scenario.id)}
              <option value={scenario.id}>{scenario.label}</option>
            {/each}
          </Select>
        </Field>
      {/if}
    </div>
  </section>
</div>
