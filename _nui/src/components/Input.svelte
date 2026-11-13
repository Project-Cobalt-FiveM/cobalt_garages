<script lang="ts">
  import type { HTMLInputAttributes } from 'svelte/elements'
  import { focusRing } from '../lib/ui'

  type Props = Omit<HTMLInputAttributes, 'prefix'> & {
    value?: string | number | null
    prefix?: string
    suffix?: string
    invalid?: boolean
  }

  let { value = $bindable(), prefix, suffix, invalid = false, class: className = '', ...rest }: Props = $props()
</script>

<div class="relative">
  {#if prefix}
    <span class="pointer-events-none absolute inset-y-0 left-3 flex items-center text-sm text-muted-foreground">{prefix}</span>
  {/if}
  <input
    bind:value
    class="h-9 w-full rounded-md border bg-transparent px-3 text-sm tabular-nums text-foreground transition-colors duration-150 placeholder:text-muted-foreground disabled:text-muted-foreground {invalid
      ? 'border-destructive'
      : 'border-input'} {focusRing} {prefix ? 'pl-7' : ''} {suffix ? 'pr-16' : ''} {className}"
    {...rest}
  />
  {#if suffix}
    <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-sm text-muted-foreground">{suffix}</span>
  {/if}
</div>
