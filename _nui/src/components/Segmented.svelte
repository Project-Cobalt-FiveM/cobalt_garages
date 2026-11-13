<script lang="ts" generics="T extends string">
  import { focusRing, type SegmentOption } from '../lib/ui'

  const sizes = {
    default: { track: 'bg-card', option: 'h-7' },
    large: { track: 'h-10 bg-muted', option: 'h-8' },
  } as const

  type Props = { value: T; options: SegmentOption<T>[]; size?: keyof typeof sizes; onchange?: (value: T) => void }

  let { value = $bindable(), options, size = 'default', onchange }: Props = $props()

  function pick(next: T) {
    value = next
    onchange?.(next)
  }
</script>

<div class="inline-flex shrink-0 items-center gap-0.5 rounded-md border border-border p-0.5 {sizes[size].track}">
  {#each options as option (option.value)}
    <button
      type="button"
      onclick={() => pick(option.value)}
      class="rounded-sm px-3 text-[0.8125rem] font-medium transition-colors duration-150 {sizes[size].option} {focusRing} {option.value === value
        ? 'bg-primary text-primary-foreground'
        : 'text-muted-foreground hover:text-foreground'}"
    >
      {option.label}
    </button>
  {/each}
</div>
