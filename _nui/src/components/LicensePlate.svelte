<script lang="ts">
  const sizes = {
    row: {
      plate: 'h-8 w-20 rounded-sm border pt-px',
      bolt: 'size-1',
      spots: ['top-0.5 left-1', 'top-0.5 right-1', 'bottom-0.5 left-1', 'bottom-0.5 right-1'],
      script: 'text-[0.4375rem] leading-[0.5rem]',
      text: 'text-[0.8125rem] leading-5',
    },
    large: {
      plate: 'h-20 w-40 rounded-md border-2 pt-1',
      bolt: 'size-1.5 border',
      spots: ['top-1.5 left-2.5', 'top-1.5 right-2.5', 'bottom-1.5 left-2.5', 'bottom-1.5 right-2.5'],
      script: 'text-sm leading-4',
      text: 'text-[2rem] leading-11',
    },
  } as const

  type Props = { text: string; size?: keyof typeof sizes }

  let { text, size = 'row' }: Props = $props()

  const style = $derived(sizes[size])
</script>

<span class="relative flex shrink-0 flex-col items-center border-plate-ink bg-plate {style.plate}" aria-label="Plate {text}">
  {#each style.spots as spot (spot)}
    <span class="absolute rounded-full border-muted-foreground bg-plate-bolt {style.bolt} {spot}"></span>
  {/each}
  <span class="font-plate-script text-plate-script {style.script}">San Andreas</span>
  <span class="w-full truncate text-center font-plate font-semibold tracking-[0.04em] text-plate-ink {style.text}">{text}</span>
</span>
