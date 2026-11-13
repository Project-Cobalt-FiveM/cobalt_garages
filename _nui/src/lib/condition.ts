export const HEALTHY = 0.6
export const WORN = 0.3

export type Condition = 'good' | 'fair' | 'poor'

export function conditionOf(value: number, max: number): Condition {
  const ratio = value / max
  if (ratio >= HEALTHY) return 'good'
  if (ratio >= WORN) return 'fair'
  return 'poor'
}

export const conditionBar: Record<Condition, string> = {
  good: 'bg-success',
  fair: 'bg-warning',
  poor: 'bg-destructive',
}

export const conditionText: Record<Condition, string> = {
  good: 'text-foreground',
  fair: 'text-warning',
  poor: 'text-destructive',
}
