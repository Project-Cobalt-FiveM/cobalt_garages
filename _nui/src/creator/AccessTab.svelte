<script lang="ts">
  import type { CreatorData, Garage, ValidationError } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import SectionTitle from '../components/SectionTitle.svelte'
  import Select from '../components/Select.svelte'
  import OrgRules from './OrgRules.svelte'
  import Citizens from './Citizens.svelte'
  import PlayerCheck from './PlayerCheck.svelte'

  type Props = { data: CreatorData; garage: Garage; errors: ValidationError[]; onchange: (garage: Garage) => void }

  let { data, garage, errors, onchange }: Props = $props()

  const access = $derived(garage.access)
  const fleet = $derived((garage.type === 'job' || garage.type === 'gang') && garage.owners !== 'player')
  const fleetOrgs = $derived(garage.type === 'job' ? data.jobs : data.gangs)
  const fleetRule = $derived(garage.type === 'job' ? access.jobs[0] : access.gangs[0])
  const fleetGrades = $derived(fleetOrgs.find((org) => org.name === fleetRule?.name)?.grades ?? [{ level: 0, name: 'Any' }])

  function error(field: string): string | undefined {
    return errors.find((item) => item.field === field)?.message
  }

  function setAccess(patch: Partial<Garage['access']>) {
    onchange({ ...garage, access: { ...access, ...patch } })
  }
</script>

{#snippet modeCard(active: boolean, title: string, text: string, onselect: () => void)}
  <button
    type="button"
    onclick={onselect}
    class="flex flex-1 items-start gap-3 rounded-md border p-3.5 text-left transition-colors duration-150 {focusRing} {active
      ? 'border-primary bg-primary'
      : 'border-border hover:bg-muted'}"
  >
    <span class="mt-0.5 flex size-4 shrink-0 items-center justify-center rounded-full border {active ? 'border-foreground' : 'border-input'}">
      {#if active}
        <span class="size-2 rounded-full bg-foreground"></span>
      {/if}
    </span>
    <span class="flex flex-col gap-0.5">
      <span class="text-sm font-medium text-foreground">{title}</span>
      <span class="text-xs {active ? 'text-foreground' : 'text-muted-foreground'}">{text}</span>
    </span>
  </button>
{/snippet}

<div class="grid grid-cols-[1fr_22.5rem] gap-6">
  <div class="flex min-w-0 flex-col gap-7">
    <section class="flex flex-col gap-3">
      <SectionTitle title="Who can use this garage" description="A player gets in if they match any rule below. Admins always can." />
      {#if garage.type === 'house'}
        <p class="rounded-md border border-border px-4 py-3 text-sm text-muted-foreground">
          Only the owner of property {garage.propertyId ?? 'with this ID'} can use a house garage. cobalt_housing decides who that is.
        </p>
      {:else}
        <div class="flex gap-2">
          {@render modeCard(access.mode === 'everyone', 'Everyone', 'Any player can store and take out their own vehicles.', () =>
            setAccess({ mode: 'everyone' }),
          )}
          {@render modeCard(access.mode === 'locked', 'Locked', 'Only the citizens, jobs and gangs listed here.', () =>
            setAccess({ mode: 'locked' }),
          )}
        </div>
      {/if}
    </section>

    {#if garage.type !== 'house'}
      <OrgRules
        title="Jobs"
        noun="job"
        options={data.jobs}
        rules={access.jobs}
        error={error('jobs')}
        withDuty
        onchange={(jobs) => setAccess({ jobs: jobs.map((rule) => ({ ...rule, onDuty: rule.onDuty ?? false })) })}
      />
      <OrgRules
        title="Gangs"
        noun="gang"
        options={data.gangs}
        rules={access.gangs}
        error={error('gangs')}
        onchange={(gangs) => setAccess({ gangs: gangs.map((rule) => ({ name: rule.name, grade: rule.grade })) })}
      />
      <Citizens citizens={access.citizens} onchange={(citizens) => setAccess({ citizens })} />
    {/if}
  </div>

  <div class="flex flex-col gap-4">
    {#if fleet}
      <aside class="flex flex-col gap-3 rounded-lg border border-border p-4">
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-semibold text-foreground">What allowed players can do</span>
          <span class="text-xs text-muted-foreground">Applies to the shared {garage.type} fleet.</span>
        </div>
        <div class="flex items-center justify-between gap-3 text-[0.8125rem]">
          <span class="text-foreground">Take out and store fleet vehicles</span>
          <div class="w-40">
            <Select
              value={String(garage.rules.fleetGrade)}
              onchange={(value) => onchange({ ...garage, rules: { ...garage.rules, fleetGrade: Number(value) } })}
              size="small"
            >
              {#each fleetGrades as grade (grade.level)}
                <option value={String(grade.level)}>Grade {grade.level}+</option>
              {/each}
            </Select>
          </div>
        </div>
        <div class="flex items-center justify-between gap-3 text-[0.8125rem]">
          <span class="text-foreground">Add or remove fleet vehicles</span>
          <span class="text-muted-foreground">Admins, on Rules and fees</span>
        </div>
      </aside>
    {/if}
    <PlayerCheck {garage} />
  </div>
</div>
