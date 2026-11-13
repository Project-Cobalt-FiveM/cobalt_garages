<script lang="ts" module>
  export type StatusTone = 'solid' | 'outline' | 'danger' | 'warning'
</script>

<script lang="ts">
  const tones: Record<StatusTone, string> = {
    solid: 'bg-secondary text-foreground',
    outline: 'border border-border text-muted-foreground',
    danger: 'bg-secondary text-destructive',
    warning: 'bg-secondary text-warning',
  }

  let { tone, label }: { tone: StatusTone; label: string } = $props()
</script>

<span class="flex w-[5.5rem] shrink-0 justify-end">
  <span class="rounded-sm px-2 py-0.5 text-xs font-medium {tones[tone]}">{label}</span>
</span>
