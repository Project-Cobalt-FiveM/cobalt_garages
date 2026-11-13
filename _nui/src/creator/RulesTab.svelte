<script lang="ts">
  import CheckCircleIcon from 'phosphor-svelte/lib/CheckCircleIcon'
  import type { ChargeFrom, CreatorData, Fees, Garage, ValidationError } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import Field from '../components/Field.svelte'
  import Input from '../components/Input.svelte'
  import SectionTitle from '../components/SectionTitle.svelte'
  import Select from '../components/Select.svelte'
  import Toggle from '../components/Toggle.svelte'
  import TagInput from './TagInput.svelte'
  import FleetList from './FleetList.svelte'

  type Props = { data: CreatorData; garage: Garage; errors: ValidationError[]; onchange: (garage: Garage) => void }

  const LAND_EXCLUDED = [14, 15, 16, 21]
  const STANDARD_FEES: { key: keyof Fees; label: string }[] = [
    { key: 'takeOut', label: 'Take out' },
    { key: 'store', label: 'Store' },
    { key: 'transferIn', label: 'Transfer in' },
  ]

  let { data, garage, errors, onchange }: Props = $props()

  const rules = $derived(garage.rules)
  const isOrg = $derived(garage.type === 'job' || garage.type === 'gang')
  const impound = $derived(garage.type === 'impound')
  const societies = $derived([...data.jobs, ...data.gangs].filter((org) => org.name !== 'none' && org.name !== 'unemployed'))

  function error(field: string): string | undefined {
    return errors.find((item) => item.field === field)?.message
  }

  function setRules(patch: Partial<Garage['rules']>) {
    onchange({ ...garage, rules: { ...rules, ...patch } })
  }

  function setFee(key: keyof Fees, value: number) {
    setRules({ fees: { ...rules.fees, [key]: Math.max(0, Math.floor(value || 0)) } })
  }

  function toggleClass(id: number) {
    setRules({
      classes: rules.classes.includes(id) ? rules.classes.filter((item) => item !== id) : [...rules.classes, id].sort((a, b) => a - b),
    })
  }

  function toChargeFrom(value: string): ChargeFrom {
    return value === 'bank' || value === 'cash' ? value : 'cash_bank'
  }

  function toLimit(value: string): number | undefined {
    return value === '' ? undefined : Math.max(1, Number(value))
  }
</script>

{#snippet textButton(label: string, onclick: () => void)}
  <button
    type="button"
    {onclick}
    class="rounded-sm text-[0.8125rem] text-foreground transition-colors duration-150 hover:text-cobalt-foreground {focusRing}"
  >
    {label}
  </button>
{/snippet}

{#snippet feeField(key: keyof Fees, label: string, hint?: string)}
  <Field {label} {hint}>
    <Input
      type="number"
      min={0}
      prefix="$"
      value={rules.fees[key]}
      oninput={(event) => setFee(key, Number(event.currentTarget.value))}
    />
  </Field>
{/snippet}

{#snippet toggleRow(title: string, text: string, checked: boolean, onflip: (checked: boolean) => void)}
  <div class="flex items-center justify-between gap-3 rounded-md border border-border p-3">
    <div class="flex flex-col gap-0.5">
      <span class="text-sm font-medium text-foreground">{title}</span>
      <span class="text-xs text-muted-foreground">{text}</span>
    </div>
    <Toggle {checked} label={title} onchange={onflip} />
  </div>
{/snippet}

<div class="flex flex-col gap-7">
  {#if !impound}
    <section class="flex flex-col gap-3">
      <SectionTitle
        title="Vehicle classes"
        description="Players can only store vehicles of a ticked class. {rules.classes.length} of {data.classes.length} allowed."
      >
        {#snippet action()}
          {@render textButton('Select all land', () =>
            setRules({ classes: data.classes.map((item) => item.id).filter((id) => !LAND_EXCLUDED.includes(id)) }),
          )}
          {@render textButton('Clear', () => setRules({ classes: [] }))}
        {/snippet}
      </SectionTitle>
      <div class="flex flex-wrap gap-1.5">
        {#each data.classes as item (item.id)}
          {@const active = rules.classes.includes(item.id)}
          <button
            type="button"
            aria-pressed={active}
            onclick={() => toggleClass(item.id)}
            class="flex h-7.5 items-center gap-1.5 rounded-md border px-2.5 text-[0.8125rem] font-medium transition-colors duration-150 {focusRing} {active
              ? 'border-primary bg-primary text-primary-foreground'
              : 'border-border text-foreground hover:bg-muted'}"
          >
            {#if active}
              <CheckCircleIcon weight="fill" class="size-3.5" />
            {/if}
            {item.label}
            <span class="text-[0.6875rem] font-normal tabular-nums {active ? 'text-foreground' : 'text-muted-foreground'}">{item.id}</span>
          </button>
        {/each}
      </div>
      {#if error('classes')}
        <span class="text-xs text-destructive">{error('classes')}</span>
      {/if}
      <div class="grid grid-cols-2 gap-4">
        <Field label="Also allow these models">
          <TagInput values={rules.allowModels} onchange={(allowModels) => setRules({ allowModels })} />
        </Field>
        <Field label="Block these models">
          <TagInput values={rules.blockModels} onchange={(blockModels) => setRules({ blockModels })} />
        </Field>
      </div>
    </section>
  {/if}

  {#if isOrg && garage.owners !== 'player'}
    <section class="flex flex-col gap-3">
      <SectionTitle
        title="Fleet vehicles"
        description="Members with the right grade take these out with a full tank. They go back when stored or when the city restarts."
      />
      <FleetList fleet={garage.fleet} onchange={(fleet) => onchange({ ...garage, fleet })} />
      {#if error('fleet')}
        <span class="text-xs text-destructive">{error('fleet')}</span>
      {/if}
    </section>
  {/if}

  <div class="grid grid-cols-2 gap-6">
    <section class="flex flex-col gap-4">
      <SectionTitle title="Fees" description="Leave at $0 to make an action free." />
      {#if impound}
        <div class="grid grid-cols-2 gap-3">
          {@render feeField('release', 'Release fee', 'Charged for cars the city tows here.')}
        </div>
      {:else}
        <div class="grid grid-cols-3 gap-3">
          {#each STANDARD_FEES as fee (fee.key)}
            {@render feeField(fee.key, fee.label)}
          {/each}
        </div>
      {/if}
      <div class="grid grid-cols-2 gap-3">
        {#if !impound}
          <Field label="Charge from">
            <Select value={rules.chargeFrom} onchange={(value) => setRules({ chargeFrom: toChargeFrom(value) })}>
              <option value="cash_bank">Cash, then bank</option>
              <option value="bank">Bank only</option>
              <option value="cash">Cash only</option>
            </Select>
          </Field>
        {/if}
        <Field label="Money goes to">
          <Select value={rules.payTo ?? ''} onchange={(value) => setRules({ payTo: value === '' ? undefined : value })}>
            <option value="">Nobody, the money leaves the economy</option>
            {#each societies as org (org.name)}
              <option value={org.name}>{org.label} society account</option>
            {/each}
          </Select>
        </Field>
      </div>
    </section>

    {#if !impound}
      <section class="flex flex-col gap-4">
        <SectionTitle title="Limits and upkeep" description="Empty fields mean no limit." />
        <div class="grid grid-cols-2 gap-3">
          <Field label="Per player">
            <Input
              type="number"
              min={1}
              suffix="vehicles"
              placeholder="No limit"
              value={rules.perPlayer ?? ''}
              oninput={(event) => setRules({ perPlayer: toLimit(event.currentTarget.value) })}
            />
          </Field>
          <Field label="Whole garage">
            <Input
              type="number"
              min={1}
              suffix="vehicles"
              placeholder="No limit"
              value={rules.capacity ?? ''}
              oninput={(event) => setRules({ capacity: toLimit(event.currentTarget.value) })}
            />
          </Field>
        </div>
        {@render toggleRow(
          'Return vehicles left out after a restart',
          rules.returnOnRestart ? 'On. Cars taken from here come back here.' : 'Off. Cars left out go to the impound lot.',
          rules.returnOnRestart,
          (returnOnRestart) => setRules({ returnOnRestart }),
        )}
        {@render toggleRow(
          'Repair and refuel on store',
          rules.repairOnStore ? 'On. Cars come out repaired with a full tank.' : 'Off. Cars keep their fuel, engine and body values.',
          rules.repairOnStore,
          (repairOnStore) => setRules({ repairOnStore }),
        )}
      </section>
    {/if}
  </div>
</div>
