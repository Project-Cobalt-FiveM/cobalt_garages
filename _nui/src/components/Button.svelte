<script lang="ts">
  import type { Snippet } from 'svelte'
  import type { HTMLButtonAttributes } from 'svelte/elements'
  import { focusRing } from '../lib/ui'

  const variants = {
    primary: 'bg-primary text-primary-foreground hover:bg-cobalt-hover',
    secondary: 'border border-input bg-secondary text-foreground hover:bg-[#2E2E2E]',
    ghost: 'text-muted-foreground hover:bg-muted hover:text-foreground',
    destructive: 'bg-destructive-solid text-[#FAFAFA] hover:bg-[#B91C1C]',
  } as const

  const sizes = {
    default: 'h-9 px-4 text-sm',
    large: 'h-10 px-6 text-sm',
    small: 'h-8 px-3 text-[0.8125rem]',
    icon: 'size-9',
  } as const

  type Props = HTMLButtonAttributes & {
    variant?: keyof typeof variants
    size?: keyof typeof sizes
    children?: Snippet
  }

  let { variant = 'secondary', size = 'default', class: className = '', type = 'button', children, ...rest }: Props = $props()
</script>

<button
  {type}
  class="inline-flex shrink-0 items-center justify-center gap-2 rounded-md font-medium transition-colors duration-150 disabled:pointer-events-none disabled:border-border disabled:bg-secondary disabled:text-muted-foreground {focusRing} {variants[variant]} {sizes[size]} {className}"
  {...rest}
>
  {@render children?.()}
</button>
