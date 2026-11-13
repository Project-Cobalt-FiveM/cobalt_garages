<script lang="ts">
  type Props = { value: number; max: number; tone: string; height?: string; track?: string }

  let { value, max, tone, height = 'h-1.5', track = 'bg-secondary' }: Props = $props()

  const width = $derived(Math.max(0, Math.min(100, (value / max) * 100)))
</script>

<div class="flex w-full rounded-full {track} {height}">
  <div class="rounded-full transition-[width] duration-300 {tone} {height}" style:width="{width}%"></div>
</div>
