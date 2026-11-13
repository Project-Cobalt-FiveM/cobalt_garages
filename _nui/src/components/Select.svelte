<script lang="ts">
  import type { Snippet } from 'svelte'
  import { focusRing } from '../lib/ui'

  const sizes = { default: 'h-9', small: 'h-8' } as const

  type Props = { value: string; size?: keyof typeof sizes; onchange?: (value: string) => void; class?: string; children: Snippet }

  let { value = $bindable(), size = 'default', onchange, class: className = '', children }: Props = $props()
</script>

<select
  bind:value
  onchange={() => onchange?.(value)}
  class="select-caret {sizes[size]} w-full appearance-none rounded-md border border-input bg-card px-3 pr-9 text-sm text-foreground {focusRing} {className}"
>
  {@render children()}
</select>

<style>
  .select-caret {
    background-image: url("data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20256%20256'%3E%3Cpath%20fill='%23A3A3A3'%20d='M213.66,101.66l-80,80a8,8,0,0,1-11.32,0l-80-80A8,8,0,0,1,48,88H208a8,8,0,0,1,5.66,13.66Z'/%3E%3C/svg%3E");
    background-size: 0.875rem;
    background-position: right 0.75rem center;
    background-repeat: no-repeat;
  }
</style>
