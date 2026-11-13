<script lang="ts">
  import Meter from '../components/Meter.svelte'
  import { conditionBar, conditionOf, conditionText } from '../lib/condition'

  type Props = { label: string; value: number; max: number; display: string }

  let { label, value, max, display }: Props = $props()

  const condition = $derived(conditionOf(value, max))
</script>

<div class="flex flex-1 flex-col gap-2.5 rounded-lg border border-border p-4">
  <div class="flex justify-between text-[0.8125rem]">
    <span class="text-muted-foreground">{label}</span>
    <span class="font-semibold tabular-nums {conditionText[condition]}">{display}</span>
  </div>
  <Meter {value} {max} tone={conditionBar[condition]} />
</div>
