<script lang="ts">
  import LicensePlate from '../components/LicensePlate.svelte'

  type Props = { title: string; detail: string; selected: boolean; dim: boolean; plate?: string }

  let { title, detail, selected, dim, plate }: Props = $props()
</script>

{#if plate}
  <LicensePlate text={plate} />
{/if}

<span class="flex min-w-0 flex-1 flex-col gap-0.5">
  <span class="truncate text-sm font-medium {selected || !dim ? 'text-foreground' : 'text-muted-foreground'}">{title}</span>
  <span class="truncate text-xs tabular-nums {selected ? 'text-foreground' : 'text-muted-foreground'}">{detail}</span>
</span>
