<script lang="ts">
  import XCircleIcon from 'phosphor-svelte/lib/XCircleIcon'

  let { values, onchange }: { values: string[]; onchange: (values: string[]) => void } = $props()

  let draft = $state('')

  function commit() {
    const model = draft.trim().toLowerCase()
    if (/^[a-z0-9_]+$/.test(model) && !values.includes(model)) onchange([...values, model])
    draft = ''
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key === 'Enter' || event.key === ',' || event.key === ' ') {
      event.preventDefault()
      commit()
    }
    if (event.key === 'Backspace' && draft === '' && values.length > 0) onchange(values.slice(0, -1))
  }
</script>

<div class="flex min-h-9 flex-wrap items-center gap-1.5 rounded-md border border-input px-1.5 py-1 focus-within:ring-2 focus-within:ring-cobalt">
  {#each values as value (value)}
    <span class="flex items-center gap-1 rounded-sm bg-secondary px-2 py-0.5 text-xs font-medium text-foreground">
      {value}
      <button
        type="button"
        aria-label="Remove {value}"
        onclick={() => onchange(values.filter((item) => item !== value))}
        class="text-muted-foreground transition-colors duration-150 hover:text-foreground"
      >
        <XCircleIcon weight="fill" class="size-3.5" />
      </button>
    </span>
  {/each}
  <input
    bind:value={draft}
    {onkeydown}
    onblur={commit}
    placeholder="Model name"
    class="min-w-24 flex-1 bg-transparent px-1.5 text-sm text-foreground outline-none placeholder:text-muted-foreground"
  />
</div>
