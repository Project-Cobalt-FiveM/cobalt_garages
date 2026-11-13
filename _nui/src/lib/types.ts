import { isRecord, list, num, str } from './nui'

export type GarageType = 'car' | 'boat' | 'air' | 'job' | 'gang' | 'house' | 'impound'
export type VehicleStatus = 'here' | 'elsewhere' | 'out' | 'impounded'
export type Owners = 'player' | 'fleet' | 'both'
export type InteractMode = 'ped' | 'target' | 'marker'
export type ChargeFrom = 'cash_bank' | 'bank' | 'cash'
export type Account = 'bank' | 'cash'

export const GARAGE_TYPES: readonly GarageType[] = ['car', 'boat', 'air', 'job', 'gang', 'house', 'impound']

export type Vec3 = { x: number; y: number; z: number }
export type Vec4 = Vec3 & { w: number }

export type Outcome = { ok: boolean; message: string }

export type Fees = { takeOut: number; store: number; transferIn: number; release: number }

export type VehicleView = {
  plate: string
  model: string
  label: string
  classLabel: string
  seats: number
  status: VehicleStatus
  location?: string
  drivenByYou: boolean
  fuel: number
  engine: number
  body: number
  parkedAt?: number
  mileage?: number
  fee: number
  impoundedAt?: number
  impoundReason?: string
  holdUntil?: number
}

export type FleetView = { index: number; model: string; label: string; classLabel: string; seats: number }

export type GarageView = {
  id: string
  label: string
  type: GarageType
  owners: Owners
  isHouse: boolean
  fees: Fees
  spawn: { bay?: number; total: number }
  vehicles: VehicleView[]
  fleet: FleetView[]
  balances: { cash: number; bank: number }
  store?: { label: string }
  now: number
}

export type TransferTarget = {
  id: string
  label: string
  kind: string
  distance: number
  fee: number
  available: boolean
  reason?: string
}

export type Zone =
  | { kind: 'none' }
  | { kind: 'box'; coords: Vec3; size: Vec3; rotation: number }
  | { kind: 'poly'; points: Vec3[]; minZ: number; maxZ: number }

export type JobRule = { name: string; grade: number; onDuty: boolean }
export type GangRule = { name: string; grade: number }
export type Citizen = { citizenid: string; name: string }

export type Garage = {
  id: string
  label: string
  type: GarageType
  enabled: boolean
  owners: Owners
  propertyId?: number
  blip: { show: boolean; sprite: number; colour: number; scale: number }
  interact: { mode: InteractMode; coords: Vec4; ped: string; scenario: string }
  spawns: Vec4[]
  clearRadius: number
  zone: Zone
  access: { mode: 'everyone' | 'locked'; jobs: JobRule[]; gangs: GangRule[]; citizens: Citizen[] }
  rules: {
    classes: number[]
    allowModels: string[]
    blockModels: string[]
    fees: Fees
    chargeFrom: ChargeFrom
    payTo?: string
    perPlayer?: number
    capacity?: number
    returnOnRestart: boolean
    repairOnStore: boolean
    fleetGrade: number
  }
  fleet: { model: string; label: string }[]
  updatedBy?: string
  updatedAt?: number
}

export type OrgOption = { name: string; label: string; grades: { level: number; name: string }[] }

export type CreatorData = {
  garages: Garage[]
  counts: Record<string, number>
  totals: { stored: number; impounded: number; held: number; owners: number }
  jobs: OrgOption[]
  gangs: OrgOption[]
  classes: { id: number; label: string }[]
  defaultClasses: Record<GarageType, number[]>
  defaultSprites: Record<GarageType, number>
  defaultImpound: string
}

export type ValidationError = { tab: CreatorTab; field: string; message: string }
export type CreatorTab = 'general' | 'location' | 'access' | 'rules'

export type PlacementCheck = { ok: boolean; label: string }

export type Placement = {
  active: boolean
  kind?: 'interact' | 'spawn' | 'zone'
  garage?: string
  title?: string
  coords?: Vec4
  fromPed?: number
  previewSize?: string
  corners?: number
  checks: PlacementCheck[]
}

function oneOf<T extends string>(value: unknown, options: readonly T[], fallback: T): T {
  return options.find((option) => option === value) ?? fallback
}

export function toVec3(value: unknown): Vec3 {
  const v = isRecord(value) ? value : {}
  return { x: num(v.x) ?? 0, y: num(v.y) ?? 0, z: num(v.z) ?? 0 }
}

export function toVec4(value: unknown): Vec4 {
  const v = isRecord(value) ? value : {}
  return { ...toVec3(v), w: num(v.w) ?? 0 }
}

function toFees(value: unknown): Fees {
  const v = isRecord(value) ? value : {}
  return { takeOut: num(v.takeOut) ?? 0, store: num(v.store) ?? 0, transferIn: num(v.transferIn) ?? 0, release: num(v.release) ?? 0 }
}

function strings(value: unknown): string[] {
  return list(value).flatMap((item) => (typeof item === 'string' ? [item] : []))
}

function numbers(value: unknown): number[] {
  return list(value).flatMap((item) => (typeof item === 'number' ? [item] : []))
}

export function toOutcome(value: unknown): Outcome {
  if (!isRecord(value)) return { ok: false, message: 'No reply from the server' }
  return { ok: value.ok === true, message: str(value.message) ?? '' }
}

function toVehicle(value: unknown): VehicleView | null {
  if (!isRecord(value)) return null
  const plate = str(value.plate)
  const model = str(value.model)
  if (!plate || !model) return null

  return {
    plate,
    model,
    label: str(value.label) ?? model,
    classLabel: str(value.classLabel) ?? 'Vehicle',
    seats: num(value.seats) ?? 0,
    status: oneOf(value.status, ['here', 'elsewhere', 'out', 'impounded'] as const, 'out'),
    location: str(value.location),
    drivenByYou: value.drivenByYou === true,
    fuel: num(value.fuel) ?? 100,
    engine: num(value.engine) ?? 1000,
    body: num(value.body) ?? 1000,
    parkedAt: num(value.parkedAt),
    mileage: num(value.mileage),
    fee: num(value.fee) ?? 0,
    impoundedAt: num(value.impoundedAt),
    impoundReason: str(value.impoundReason),
    holdUntil: num(value.holdUntil),
  }
}

function toFleet(value: unknown): FleetView | null {
  if (!isRecord(value)) return null
  const index = num(value.index)
  const model = str(value.model)
  if (index === undefined || !model) return null

  return {
    index,
    model,
    label: str(value.label) ?? model,
    classLabel: str(value.classLabel) ?? 'Vehicle',
    seats: num(value.seats) ?? 0,
  }
}

export function toGarageView(value: unknown): GarageView | null {
  if (!isRecord(value)) return null
  const id = str(value.id)
  if (!id) return null
  const spawn = isRecord(value.spawn) ? value.spawn : {}
  const balances = isRecord(value.balances) ? value.balances : {}
  const store = isRecord(value.store) ? str(value.store.label) : undefined

  return {
    id,
    label: str(value.label) ?? id,
    type: oneOf(value.type, GARAGE_TYPES, 'car'),
    owners: oneOf(value.owners, ['player', 'fleet', 'both'] as const, 'player'),
    isHouse: value.isHouse === true,
    fees: toFees(value.fees),
    spawn: { bay: num(spawn.bay), total: num(spawn.total) ?? 0 },
    vehicles: list(value.vehicles).flatMap((item) => toVehicle(item) ?? []),
    fleet: list(value.fleet).flatMap((item) => toFleet(item) ?? []),
    balances: { cash: num(balances.cash) ?? 0, bank: num(balances.bank) ?? 0 },
    store: store ? { label: store } : undefined,
    now: num(value.now) ?? Math.floor(Date.now() / 1000),
  }
}

export function toTargets(value: unknown): TransferTarget[] {
  return list(value).flatMap((item) => {
    if (!isRecord(item)) return []
    const id = str(item.id)
    if (!id) return []
    return [
      {
        id,
        label: str(item.label) ?? id,
        kind: str(item.kind) ?? 'Public',
        distance: num(item.distance) ?? 0,
        fee: num(item.fee) ?? 0,
        available: item.available === true,
        reason: str(item.reason),
      },
    ]
  })
}

function toZone(value: unknown): Zone {
  if (!isRecord(value)) return { kind: 'none' }
  if (value.kind === 'box') {
    return { kind: 'box', coords: toVec3(value.coords), size: toVec3(value.size), rotation: num(value.rotation) ?? 0 }
  }
  if (value.kind === 'poly') {
    return { kind: 'poly', points: list(value.points).map(toVec3), minZ: num(value.minZ) ?? 0, maxZ: num(value.maxZ) ?? 100 }
  }
  return { kind: 'none' }
}

export function toGarage(value: unknown): Garage | null {
  if (!isRecord(value)) return null
  const id = str(value.id)
  if (!id) return null
  const blip = isRecord(value.blip) ? value.blip : {}
  const interact = isRecord(value.interact) ? value.interact : {}
  const access = isRecord(value.access) ? value.access : {}
  const rules = isRecord(value.rules) ? value.rules : {}

  return {
    id,
    label: str(value.label) ?? id,
    type: oneOf(value.type, GARAGE_TYPES, 'car'),
    enabled: value.enabled !== false,
    owners: oneOf(value.owners, ['player', 'fleet', 'both'] as const, 'player'),
    propertyId: num(value.propertyId),
    blip: { show: blip.show !== false, sprite: num(blip.sprite) ?? 357, colour: num(blip.colour) ?? 3, scale: num(blip.scale) ?? 0.7 },
    interact: {
      mode: oneOf(interact.mode, ['ped', 'target', 'marker'] as const, 'ped'),
      coords: toVec4(interact.coords),
      ped: str(interact.ped) ?? '',
      scenario: str(interact.scenario) ?? '',
    },
    spawns: list(value.spawns).map(toVec4),
    clearRadius: num(value.clearRadius) ?? 4,
    zone: toZone(value.zone),
    access: {
      mode: access.mode === 'locked' ? 'locked' : 'everyone',
      jobs: list(access.jobs).flatMap((item) =>
        isRecord(item) && str(item.name) ? [{ name: str(item.name)!, grade: num(item.grade) ?? 0, onDuty: item.onDuty === true }] : [],
      ),
      gangs: list(access.gangs).flatMap((item) =>
        isRecord(item) && str(item.name) ? [{ name: str(item.name)!, grade: num(item.grade) ?? 0 }] : [],
      ),
      citizens: list(access.citizens).flatMap((item) =>
        isRecord(item) && str(item.citizenid) ? [{ citizenid: str(item.citizenid)!, name: str(item.name) ?? '' }] : [],
      ),
    },
    rules: {
      classes: numbers(rules.classes),
      allowModels: strings(rules.allowModels),
      blockModels: strings(rules.blockModels),
      fees: toFees(rules.fees),
      chargeFrom: oneOf(rules.chargeFrom, ['cash_bank', 'bank', 'cash'] as const, 'cash_bank'),
      payTo: str(rules.payTo),
      perPlayer: num(rules.perPlayer),
      capacity: num(rules.capacity),
      returnOnRestart: rules.returnOnRestart === true,
      repairOnStore: rules.repairOnStore === true,
      fleetGrade: num(rules.fleetGrade) ?? 0,
    },
    fleet: list(value.fleet).flatMap((item) =>
      isRecord(item) && str(item.model) ? [{ model: str(item.model)!, label: str(item.label) ?? str(item.model)! }] : [],
    ),
    updatedBy: str(value.updatedBy),
    updatedAt: num(value.updatedAt),
  }
}

function toOrgs(value: unknown): OrgOption[] {
  return list(value).flatMap((item) => {
    if (!isRecord(item) || !str(item.name)) return []
    return [
      {
        name: str(item.name)!,
        label: str(item.label) ?? str(item.name)!,
        grades: list(item.grades).flatMap((grade) =>
          isRecord(grade) ? [{ level: num(grade.level) ?? 0, name: str(grade.name) ?? '' }] : [],
        ),
      },
    ]
  })
}

export function toCreatorData(value: unknown): CreatorData | null {
  if (!isRecord(value)) return null
  const counts: Record<string, number> = {}
  if (isRecord(value.counts)) {
    for (const [key, count] of Object.entries(value.counts)) counts[key] = num(count) ?? 0
  }
  const totals = isRecord(value.totals) ? value.totals : {}
  const defaults = isRecord(value.defaultClasses) ? value.defaultClasses : {}
  const sprites = isRecord(value.defaultSprites) ? value.defaultSprites : {}
  const defaultClasses = {} as Record<GarageType, number[]>
  const defaultSprites = {} as Record<GarageType, number>
  for (const type of GARAGE_TYPES) {
    defaultClasses[type] = numbers(defaults[type])
    defaultSprites[type] = num(sprites[type]) ?? 357
  }

  return {
    garages: list(value.garages).flatMap((item) => toGarage(item) ?? []),
    counts,
    totals: {
      stored: num(totals.stored) ?? 0,
      impounded: num(totals.impounded) ?? 0,
      held: num(totals.held) ?? 0,
      owners: num(totals.owners) ?? 0,
    },
    jobs: toOrgs(value.jobs),
    gangs: toOrgs(value.gangs),
    classes: list(value.classes).flatMap((item) =>
      isRecord(item) && num(item.id) !== undefined ? [{ id: num(item.id)!, label: str(item.label) ?? '' }] : [],
    ),
    defaultClasses,
    defaultSprites,
    defaultImpound: str(value.defaultImpound) ?? 'davis_impound',
  }
}

export function toPlacement(value: unknown): Placement {
  if (!isRecord(value) || value.active !== true) return { active: false, checks: [] }

  return {
    active: true,
    kind: oneOf(value.kind, ['interact', 'spawn', 'zone'] as const, 'spawn'),
    garage: str(value.garage),
    title: str(value.title),
    coords: isRecord(value.coords) ? toVec4(value.coords) : undefined,
    fromPed: num(value.fromPed),
    previewSize: str(value.previewSize),
    corners: num(value.corners),
    checks: list(value.checks).flatMap((item) => (isRecord(item) ? [{ ok: item.ok === true, label: str(item.label) ?? '' }] : [])),
  }
}

export function toErrors(value: unknown): ValidationError[] {
  return list(value).flatMap((item) => {
    if (!isRecord(item)) return []
    return [
      {
        tab: oneOf(item.tab, ['general', 'location', 'access', 'rules'] as const, 'general'),
        field: str(item.field) ?? '',
        message: str(item.message) ?? '',
      },
    ]
  })
}
