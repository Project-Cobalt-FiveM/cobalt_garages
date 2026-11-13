<script lang="ts">
  let { label, value }: { label: string; value: string } = $props()
</script>

<div class="flex justify-between gap-6 border-b border-border py-2.5 text-sm">
  <span class="text-muted-foreground">{label}</span>
  <span class="text-right tabular-nums text-foreground">{value}</span>
</div>
