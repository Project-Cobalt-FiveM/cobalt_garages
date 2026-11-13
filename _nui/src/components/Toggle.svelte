<script lang="ts">
  import { focusRing } from '../lib/ui'

  let { checked = $bindable(), label, onchange }: { checked: boolean; label: string; onchange?: (checked: boolean) => void } = $props()

  function flip() {
    checked = !checked
    onchange?.(checked)
  }
</script>

<button
  type="button"
  role="switch"
  aria-checked={checked}
  aria-label={label}
  onclick={flip}
  class="relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition-colors duration-200 {checked ? 'bg-primary' : 'bg-[#3F3F3F]'} {focusRing}"
>
  <span class="size-4 rounded-full bg-foreground transition-transform duration-200 {checked ? 'translate-x-[1.125rem]' : 'translate-x-0.5'}"></span>
</button>
