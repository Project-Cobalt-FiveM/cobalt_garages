<script lang="ts">
  import type { FleetView } from '../lib/types'
  import Row from './Row.svelte'
  import RowName from './RowName.svelte'
  import RowSide from './RowSide.svelte'
  import RowStatus from './RowStatus.svelte'

  let { fleet, selected, onselect }: { fleet: FleetView; selected: boolean; onselect: () => void } = $props()
</script>

<Row {selected} {onselect}>
  <RowName title={fleet.label} detail={fleet.classLabel} {selected} dim={false} />
  <RowSide text="Full tank" {selected} />
  <RowStatus tone="solid" label="Fleet" />
</Row>
