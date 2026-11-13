<script lang="ts">
  import type { OrgOption } from '../lib/types'
  import { focusRing } from '../lib/ui'
  import SectionTitle from '../components/SectionTitle.svelte'
  import Select from '../components/Select.svelte'
  import Toggle from '../components/Toggle.svelte'

  type Rule = { name: string; grade: number; onDuty?: boolean }

  type Props = {
    title: string
    noun: string
    options: OrgOption[]
    rules: Rule[]
    error?: string
    withDuty?: boolean
    onchange: (rules: Rule[]) => void
  }

  let { title, noun, options, rules, error, withDuty = false, onchange }: Props = $props()

  const available = $derived(
    options.filter((option) => !rules.some((rule) => rule.name === option.name) && option.name !== 'none' && option.name !== 'unemployed'),
  )

  function gradeName(org: string, level: number): string {
    const grade = options.find((option) => option.name === org)?.grades.find((item) => item.level === level)
    return grade ? `${grade.name}, grade ${level}` : `Grade ${level}`
  }

  function gradesFor(rule: Rule): { level: number; name: string }[] {
    return options.find((item) => item.name === rule.name)?.grades ?? [{ level: rule.grade, name: '' }]
  }

  function labelFor(rule: Rule): string {
    return options.find((item) => item.name === rule.name)?.label ?? rule.name
  }

  function update(index: number, patch: Partial<Rule>) {
    onchange(rules.map((rule, i) => (i === index ? { ...rule, ...patch } : rule)))
  }

  function add(name: string) {
    if (name) onchange([...rules, { name, grade: 0, onDuty: withDuty ? true : undefined }])
  }
</script>

<section class="flex flex-col gap-2.5">
  <SectionTitle {title} description="Members at or above the grade get in.">
    {#snippet action()}
      {#if available.length > 0}
        <div class="w-44">
          {#key rules.length}
            <Select value="" onchange={add} size="small">
              <option value="">Add {noun}</option>
              {#each available as option (option.name)}
                <option value={option.name}>{option.label}</option>
              {/each}
            </Select>
          {/key}
        </div>
      {/if}
    {/snippet}
  </SectionTitle>
  {#if rules.length === 0}
    <div class="rounded-md border border-dashed px-4 py-5 text-center text-sm text-muted-foreground {error ? 'border-destructive' : 'border-border'}">
      No {noun}s yet. Add one to let its members use this garage.
    </div>
  {:else}
    <div class="flex flex-col overflow-hidden rounded-md border border-border">
      {#each rules as rule, index (rule.name)}
        <div class="flex h-12 shrink-0 items-center gap-3 border-b border-border px-3 last:border-b-0">
          <span class="w-45 shrink-0 truncate text-sm font-medium text-foreground">{labelFor(rule)}</span>
          <div class="w-55 shrink-0">
            <Select value={String(rule.grade)} onchange={(value) => update(index, { grade: Number(value) })} size="small">
              {#each gradesFor(rule) as grade (grade.level)}
                <option value={String(grade.level)}>From {gradeName(rule.name, grade.level)}</option>
              {/each}
            </Select>
          </div>
          <div class="flex flex-1 items-center gap-2">
            {#if withDuty}
              <Toggle checked={rule.onDuty === true} label="On duty only" onchange={(onDuty) => update(index, { onDuty })} />
              <span class="text-[0.8125rem] {rule.onDuty ? 'text-foreground' : 'text-muted-foreground'}">On duty only</span>
            {/if}
          </div>
          <button
            type="button"
            onclick={() => onchange(rules.filter((_, i) => i !== index))}
            class="rounded-sm text-xs font-medium text-muted-foreground transition-colors duration-150 hover:text-foreground {focusRing}"
          >
            Remove
          </button>
        </div>
      {/each}
    </div>
  {/if}
  {#if error}
    <span class="text-xs text-destructive">{error}</span>
  {/if}
</section>
