import type { CreatorData, CreatorTab, Garage, GarageType, ValidationError, Vec4 } from '../lib/types'

export const TYPE_INFO: Record<GarageType, { label: string; hint: string }> = {
  car: { label: 'Car', hint: 'Land vehicles' },
  boat: { label: 'Boat', hint: 'Docks and piers' },
  air: { label: 'Air', hint: 'Helipads, hangars' },
  job: { label: 'Job', hint: 'Shared job fleet' },
  gang: { label: 'Gang', hint: 'Shared gang fleet' },
  house: { label: 'House', hint: 'Tied to a property' },
  impound: { label: 'Impound', hint: 'Paid release' },
}

export const TABS: { id: CreatorTab; label: string }[] = [
  { id: 'general', label: 'General' },
  { id: 'location', label: 'Location' },
  { id: 'access', label: 'Access' },
  { id: 'rules', label: 'Rules and fees' },
]

export function slug(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 64)
}

export function blankGarage(data: CreatorData, type: GarageType, coords: Vec4): Garage {
  return {
    id: '',
    label: '',
    type,
    enabled: true,
    owners: 'player',
    blip: { show: true, sprite: data.defaultSprites[type], colour: 3, scale: 0.7 },
    interact: { mode: 'ped', coords, ped: 's_m_y_valet_01', scenario: 'WORLD_HUMAN_CLIPBOARD' },
    spawns: [],
    clearRadius: 4,
    zone: { kind: 'none' },
    access: { mode: 'everyone', jobs: [], gangs: [], citizens: [] },
    rules: {
      classes: [...data.defaultClasses[type]],
      allowModels: [],
      blockModels: [],
      fees: { takeOut: 0, store: 0, transferIn: 0, release: type === 'impound' ? 250 : 0 },
      chargeFrom: 'cash_bank',
      returnOnRestart: false,
      repairOnStore: false,
      fleetGrade: 0,
    },
    fleet: [],
  }
}

export function validate(garage: Garage, others: Garage[], isNew: boolean): ValidationError[] {
  const errors: ValidationError[] = []
  const add = (tab: CreatorTab, field: string, message: string) => errors.push({ tab, field, message })
  const isOrg = garage.type === 'job' || garage.type === 'gang'

  if (garage.label.trim() === '') add('general', 'label', 'Give the garage a name players will see.')
  if (garage.id === '') add('general', 'id', 'The ID needs at least one letter or number.')
  if (isNew && others.some((other) => other.id === garage.id)) add('general', 'id', 'Another garage already uses this ID.')
  if (garage.interact.mode === 'ped' && garage.interact.ped.trim() === '')
    add('general', 'ped', 'Pick a ped model, or open the garage another way.')
  if (garage.type === 'house' && !garage.propertyId) add('general', 'propertyId', 'Enter the property ID this garage belongs to.')

  if (garage.interact.coords.x === 0 && garage.interact.coords.y === 0) {
    add('location', 'interact', 'Place the interaction point. Players have nowhere to open this garage.')
  }
  if (garage.spawns.length === 0) add('location', 'spawns', 'Add at least one spawn point.')
  if (garage.zone.kind === 'poly' && garage.zone.points.length < 3) {
    add('location', 'zone', 'A polygon needs at least 3 points. Add one more, or set the zone to None.')
  }

  if (garage.type === 'job' && garage.access.jobs.length === 0) add('access', 'jobs', 'Add the job whose members use this garage.')
  if (garage.type === 'gang' && garage.access.gangs.length === 0) add('access', 'gangs', 'Add the gang whose members use this garage.')

  if (isOrg && garage.owners !== 'player' && garage.fleet.length === 0) {
    add('rules', 'fleet', 'Add a fleet vehicle, or let members park their own cars.')
  }
  if (garage.type !== 'impound' && garage.rules.classes.length === 0 && garage.rules.allowModels.length === 0) {
    add('rules', 'classes', 'Tick at least one vehicle class.')
  }

  return errors
}

const TRACKED: (keyof Garage)[] = [
  'id',
  'label',
  'type',
  'enabled',
  'owners',
  'propertyId',
  'blip',
  'interact',
  'spawns',
  'clearRadius',
  'zone',
  'access',
  'rules',
  'fleet',
]

export function countChanges(draft: Garage, original?: Garage): number {
  if (!original) return 0
  return TRACKED.filter((key) => JSON.stringify(draft[key]) !== JSON.stringify(original[key])).length
}

export function describe(garage: Garage, data: CreatorData): string {
  const type = TYPE_INFO[garage.type].label
  const parts = [type]

  if (garage.type === 'house') parts.push(garage.propertyId ? `property ${garage.propertyId}` : 'no property')
  else if (garage.access.mode === 'everyone') parts.push('public')
  else {
    const job = garage.access.jobs[0]
    const gang = garage.access.gangs[0]
    const org = job ?? gang
    if (org) {
      const options = job ? data.jobs : data.gangs
      const label = options.find((option) => option.name === org.name)?.label ?? org.name
      parts.push(`${label} grade ${org.grade}+`)
    } else parts.push(`${garage.access.citizens.length} citizens`)
  }

  if (!garage.enabled) parts.push('disabled')
  return parts.join(', ')
}

export function distance(a: { x: number; y: number; z: number }, b: { x: number; y: number; z: number }): number {
  return Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z)
}

export function polygonArea(points: { x: number; y: number }[]): number {
  const total = points.reduce((sum, point, index) => {
    const previous = points[(index + points.length - 1) % points.length] ?? point
    return sum + (previous.x + point.x) * (previous.y - point.y)
  }, 0)
  return Math.abs(total / 2)
}

const COMPASS = ['north', 'north-west', 'west', 'south-west', 'south', 'south-east', 'east', 'north-east'] as const

export function compass(heading: number): string {
  const normalized = ((heading % 360) + 360) % 360
  return COMPASS[Math.round(normalized / 45) % COMPASS.length] ?? 'north'
}
