const money = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 })
const count = new Intl.NumberFormat('en-US')
const clock = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit' })
const day = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short' })

export function formatMoney(amount: number): string {
  return money.format(amount)
}

export function formatCount(value: number): string {
  return count.format(value)
}

export function formatClock(seconds: number): string {
  return clock.format(new Date(seconds * 1000))
}

export function formatWhen(seconds: number, now: number): string {
  const date = new Date(seconds * 1000)
  const today = new Date(now * 1000)
  const yesterday = new Date(today)
  yesterday.setDate(today.getDate() - 1)

  if (date.toDateString() === today.toDateString()) return `Today at ${clock.format(date)}`
  if (date.toDateString() === yesterday.toDateString()) return `Yesterday at ${clock.format(date)}`
  return `${day.format(date)} at ${clock.format(date)}`
}

export function formatDistance(meters: number): string {
  return meters >= 1000 ? `${(meters / 1000).toFixed(1)} km away` : `${Math.round(meters)} m away`
}

export function plural(value: number, one: string, many: string): string {
  return `${value} ${value === 1 ? one : many}`
}
