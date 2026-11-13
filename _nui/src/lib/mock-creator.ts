import { isRecord, list, num, str, type CallbackName, type MessageAction, type MockHandler } from './nui'
import { toGarage, toVec4 } from './types'
import type { Citizen, CreatorData, Garage, GarageType, Vec4 } from './types'

type Post = (action: MessageAction, data?: unknown) => void
type Resident = Citizen & { job?: { name: string; grade: number; onDuty: boolean }; gang?: { name: string; grade: number } }
type GarageSeed = Pick<Garage, 'id' | 'label' | 'type'> & Partial<Omit<Garage, 'rules' | 'access'>> & {
  rules?: Partial<Garage['rules']>
  access?: Partial<Garage['access']>
}

const CLASSES = [
  'Compacts',
  'Sedans',
  'SUVs',
  'Coupes',
  'Muscle',
  'Sports classics',
  'Sports',
  'Super',
  'Motorcycles',
  'Off-road',
  'Industrial',
  'Utility',
  'Vans',
  'Cycles',
  'Boats',
  'Helicopters',
  'Planes',
  'Service',
  'Emergency',
  'Military',
  'Commercial',
  'Trains',
  'Open wheel',
].map((label, id) => ({ id, label }))

const DEFAULT_CLASSES: Record<GarageType, number[]> = {
  car: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12],
  boat: [14],
  air: [15, 16],
  job: [18],
  gang: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  house: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12],
  impound: [],
}

const DEFAULT_SPRITES: Record<GarageType, number> = {
  car: 357,
  boat: 410,
  air: 359,
  job: 357,
  gang: 357,
  house: 40,
  impound: 68,
}

const JOBS = [
  {
    name: 'police',
    label: 'Police',
    grades: [
      { level: 0, name: 'Cadet' },
      { level: 1, name: 'Officer' },
      { level: 2, name: 'Senior officer' },
      { level: 3, name: 'Sergeant' },
      { level: 4, name: 'Chief' },
    ],
  },
  {
    name: 'sheriff',
    label: 'Sheriff',
    grades: [
      { level: 0, name: 'Recruit' },
      { level: 1, name: 'Trainee' },
      { level: 2, name: 'Deputy' },
      { level: 3, name: 'Sergeant' },
      { level: 4, name: 'Sheriff' },
    ],
  },
  {
    name: 'ambulance',
    label: 'EMS',
    grades: [
      { level: 0, name: 'Trainee' },
      { level: 1, name: 'Paramedic' },
      { level: 2, name: 'Doctor' },
      { level: 3, name: 'Chief of medicine' },
    ],
  },
  {
    name: 'mechanic',
    label: 'Mechanic',
    grades: [
      { level: 0, name: 'Apprentice' },
      { level: 1, name: 'Mechanic' },
      { level: 2, name: 'Owner' },
    ],
  },
  { name: 'unemployed', label: 'Civilian', grades: [{ level: 0, name: 'Freelancer' }] },
]

const GANGS = [
  { name: 'none', label: 'No gang', grades: [{ level: 0, name: 'Unaffiliated' }] },
  {
    name: 'families',
    label: 'Families',
    grades: [
      { level: 0, name: 'Recruit' },
      { level: 1, name: 'Hustler' },
      { level: 2, name: 'Enforcer' },
      { level: 3, name: 'Shot caller' },
    ],
  },
  {
    name: 'ballas',
    label: 'Ballas',
    grades: [
      { level: 0, name: 'Recruit' },
      { level: 1, name: 'Soldier' },
      { level: 2, name: 'OG' },
    ],
  },
  {
    name: 'vagos',
    label: 'Vagos',
    grades: [
      { level: 0, name: 'Recruit' },
      { level: 1, name: 'Soldado' },
      { level: 2, name: 'Jefe' },
    ],
  },
]

const RESIDENTS: Resident[] = [
  { citizenid: 'HXK40213', name: 'Maya Chen', job: { name: 'police', grade: 3, onDuty: true } },
  { citizenid: 'QJS77120', name: 'Dario Vance', job: { name: 'sheriff', grade: 1, onDuty: false } },
  { citizenid: 'LRT20984', name: 'Ines Okafor', job: { name: 'ambulance', grade: 2, onDuty: true } },
  { citizenid: 'MPV55031', name: 'Tyrell Banks', gang: { name: 'families', grade: 2 } },
  { citizenid: 'ZKE19876', name: 'Lucia Moreno', gang: { name: 'vagos', grade: 1 } },
  { citizenid: 'BWN33402', name: 'Sam Whitlock', job: { name: 'mechanic', grade: 1, onDuty: true } },
]

const EDITOR = 'Maya Chen'

function vec(x: number, y: number, z: number, w = 0): Vec4 {
  return { x, y, z, w }
}

function todayAt(hours: number, minutes: number, daysAgo = 0): number {
  const date = new Date()
  date.setDate(date.getDate() - daysAgo)
  date.setHours(hours, minutes, 0, 0)
  return Math.floor(date.getTime() / 1000)
}

function makeGarage(seed: GarageSeed): Garage {
  const { rules, access, ...rest } = seed
  return {
    enabled: true,
    owners: 'player',
    blip: { show: true, sprite: DEFAULT_SPRITES[seed.type], colour: 3, scale: 0.7 },
    interact: { mode: 'ped', coords: vec(0, 0, 0), ped: 's_m_y_valet_01', scenario: 'WORLD_HUMAN_CLIPBOARD' },
    spawns: [],
    clearRadius: 4,
    zone: { kind: 'none' },
    fleet: [],
    updatedBy: 'seed',
    updatedAt: todayAt(9, 0, 30),
    ...rest,
    access: { mode: 'everyone', jobs: [], gangs: [], citizens: [], ...access },
    rules: {
      classes: [...DEFAULT_CLASSES[seed.type]],
      allowModels: [],
      blockModels: [],
      fees: { takeOut: 0, store: 0, transferIn: 0, release: 0 },
      chargeFrom: 'cash_bank',
      returnOnRestart: false,
      repairOnStore: false,
      fleetGrade: 0,
      ...rules,
    },
  }
}

function seedGarages(): Garage[] {
  return [
    makeGarage({
      id: 'legion_square',
      label: 'Legion Square',
      type: 'car',
      interact: { mode: 'ped', coords: vec(215.8, -810.06, 30.73, 157), ped: 's_m_y_valet_01', scenario: 'WORLD_HUMAN_CLIPBOARD' },
      spawns: [vec(222.4, -804.2, 30.6, 248), vec(225.1, -798.9, 30.6, 248), vec(227.9, -793.5, 30.6, 248)],
      rules: { fees: { takeOut: 0, store: 0, transferIn: 150, release: 0 } },
    }),
    makeGarage({
      id: 'pillbox_hill',
      label: 'Pillbox Hill',
      type: 'car',
      interact: { mode: 'target', coords: vec(275.3, -345.1, 45.17, 70), ped: '', scenario: '' },
      spawns: [vec(266.9, -332.4, 44.9, 250), vec(269.1, -327.2, 44.9, 250)],
      zone: { kind: 'box', coords: vec(272, -338, 45), size: vec(30, 20, 8), rotation: 70 },
    }),
    makeGarage({
      id: 'mission_row_pd',
      label: 'Mission Row PD',
      type: 'job',
      owners: 'both',
      blip: { show: true, sprite: 60, colour: 3, scale: 0.8 },
      interact: { mode: 'ped', coords: vec(441.2, -981.9, 30.69, 90), ped: 's_m_y_cop_01', scenario: 'WORLD_HUMAN_GUARD_STAND' },
      spawns: [vec(446.12, -986.4, 30.69, 270), vec(446.12, -990.85, 30.69, 270), vec(446.12, -995.3, 30.69, 270), vec(431.77, -996.02, 30.7, 180.5)],
      zone: {
        kind: 'poly',
        points: [vec(424, -974, 28), vec(456, -974, 28), vec(458, -990, 28), vec(452, -1004, 30), vec(428, -1004, 30), vec(422, -990, 28)],
        minZ: 24,
        maxZ: 40,
      },
      access: {
        mode: 'locked',
        jobs: [
          { name: 'police', grade: 1, onDuty: true },
          { name: 'sheriff', grade: 2, onDuty: false },
        ],
        citizens: [
          { citizenid: 'QJS77120', name: 'Dario Vance' },
          { citizenid: 'LRT20984', name: 'Ines Okafor' },
        ],
      },
      rules: { classes: [18], fleetGrade: 1, repairOnStore: true, returnOnRestart: true, payTo: 'police' },
      fleet: [
        { model: 'police', label: 'Police Cruiser' },
        { model: 'police2', label: 'Police Buffalo' },
        { model: 'policet', label: 'Police Transporter' },
      ],
      updatedBy: EDITOR,
      updatedAt: todayAt(13, 40),
    }),
    makeGarage({
      id: 'grove_street',
      label: 'Grove Street',
      type: 'gang',
      interact: { mode: 'marker', coords: vec(-58.2, -1832.6, 26.8, 320), ped: '', scenario: '' },
      spawns: [vec(-51.3, -1838.7, 26.2, 320), vec(-47.9, -1842.1, 26.0, 320)],
      access: { mode: 'locked', gangs: [{ name: 'families', grade: 2 }] },
      updatedBy: EDITOR,
      updatedAt: todayAt(22, 15, 1),
    }),
    makeGarage({
      id: 'eclipse_tower_4',
      label: '4 Eclipse Tower',
      type: 'house',
      propertyId: 4,
      blip: { show: false, sprite: 40, colour: 0, scale: 0.6 },
      interact: { mode: 'marker', coords: vec(-796.1, 318.4, 85.7, 180), ped: '', scenario: '' },
      spawns: [vec(-800.2, 312.9, 85.5, 180)],
    }),
    makeGarage({
      id: 'paleto_boathouse',
      label: 'Paleto Bay boathouse',
      type: 'boat',
      interact: { mode: 'ped', coords: vec(-1605.4, 5258.9, 2.08, 25), ped: 's_m_y_dockwork_01', scenario: 'WORLD_HUMAN_STAND_IMPATIENT' },
      spawns: [vec(-1600.1, 5262.3, 0.1, 25)],
    }),
    makeGarage({
      id: 'lsia_hangar',
      label: 'LSIA hangar',
      type: 'air',
      interact: { mode: 'ped', coords: vec(-1243.2, -3391.8, 13.94, 60), ped: 's_m_y_airworker', scenario: 'WORLD_HUMAN_CLIPBOARD' },
      spawns: [vec(-1270.4, -3381.2, 13.94, 330), vec(-1255.7, -3360.5, 13.94, 330)],
      rules: { fees: { takeOut: 500, store: 0, transferIn: 1000, release: 0 }, chargeFrom: 'bank' },
    }),
    makeGarage({
      id: 'davis_impound',
      label: 'Davis Impound',
      type: 'impound',
      interact: { mode: 'ped', coords: vec(409.2, -1623.5, 29.29, 230), ped: 's_m_m_autoshop_01', scenario: 'WORLD_HUMAN_CLIPBOARD' },
      spawns: [vec(401.8, -1631.6, 29.0, 230), vec(398.4, -1627.4, 29.0, 230), vec(395.1, -1623.2, 29.0, 230)],
      rules: { fees: { takeOut: 0, store: 0, transferIn: 0, release: 350 }, payTo: 'police' },
      updatedBy: 'Ines Okafor',
      updatedAt: todayAt(21, 48, 1),
    }),
    makeGarage({
      id: 'sandy_shores',
      label: 'Sandy Shores',
      type: 'car',
      enabled: false,
      interact: { mode: 'ped', coords: vec(1737.6, 3710.2, 34.14, 20), ped: 's_m_m_trucker_01', scenario: 'WORLD_HUMAN_SMOKING' },
      spawns: [vec(1730.9, 3712.4, 34.1, 20), vec(1726.5, 3709.1, 34.1, 20)],
      updatedBy: 'Dario Vance',
      updatedAt: todayAt(11, 2),
    }),
  ]
}

const store: { garages: Garage[]; counts: Record<string, number> } = {
  garages: seedGarages(),
  counts: {
    legion_square: 212,
    pillbox_hill: 148,
    mission_row_pd: 36,
    grove_street: 9,
    eclipse_tower_4: 3,
    paleto_boathouse: 14,
    lsia_hangar: 7,
    davis_impound: 41,
    sandy_shores: 0,
  },
}

function snapshot(): CreatorData {
  const stored = Object.entries(store.counts).reduce((sum, [id, count]) => (id === 'davis_impound' ? sum : sum + count), 0)
  return structuredClone({
    garages: store.garages,
    counts: store.counts,
    totals: { stored, impounded: store.counts.davis_impound ?? 0, held: 7, owners: 312 },
    jobs: JOBS,
    gangs: GANGS,
    classes: CLASSES,
    defaultClasses: DEFAULT_CLASSES,
    defaultSprites: DEFAULT_SPRITES,
    defaultImpound: 'davis_impound',
  })
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function findResidents(query: unknown): Resident[] {
  const needle = (str(query) ?? '').trim().toLowerCase()
  if (needle === '') return []
  return RESIDENTS.filter((resident) => resident.name.toLowerCase().includes(needle) || resident.citizenid.toLowerCase().includes(needle))
}

function orgLabel(name: string): string {
  return [...JOBS, ...GANGS].find((org) => org.name === name)?.label ?? name
}

function gradeLabel(org: string, level: number): string {
  return [...JOBS, ...GANGS].find((item) => item.name === org)?.grades.find((grade) => grade.level === level)?.name ?? 'Member'
}

function checkAccess(garage: Garage, resident: Resident): { allowed: boolean; reason: string } {
  if (garage.type === 'house') return { allowed: false, reason: `Only the owner of property ${garage.propertyId ?? '?'} can use it.` }
  if (garage.access.mode === 'everyone') return { allowed: true, reason: 'The garage is open to everyone.' }
  if (garage.access.citizens.some((citizen) => citizen.citizenid === resident.citizenid)) {
    return { allowed: true, reason: `Listed by citizen ID ${resident.citizenid}.` }
  }

  const { job, gang } = resident
  const jobRule = job ? garage.access.jobs.find((rule) => rule.name === job.name) : undefined
  if (job && jobRule) {
    const grade = `${orgLabel(job.name)}, ${gradeLabel(job.name, job.grade)} grade ${job.grade}`
    if (job.grade < jobRule.grade) return { allowed: false, reason: `Job ${grade} is below grade ${jobRule.grade}.` }
    if (jobRule.onDuty && !job.onDuty) return { allowed: false, reason: `Matched job ${grade}, but they are off duty.` }
    return { allowed: true, reason: `Matched job ${grade}${job.onDuty ? ', on duty' : ''}.` }
  }

  const gangRule = gang ? garage.access.gangs.find((rule) => rule.name === gang.name) : undefined
  if (gang && gangRule) {
    const grade = `${orgLabel(gang.name)}, ${gradeLabel(gang.name, gang.grade)} grade ${gang.grade}`
    if (gang.grade < gangRule.grade) return { allowed: false, reason: `Gang ${grade} is below grade ${gangRule.grade}.` }
    return { allowed: true, reason: `Matched gang ${grade}.` }
  }

  return { allowed: false, reason: 'No job, gang or citizen rule matches them.' }
}

function placed(data: Record<string, unknown>, title: string, result: unknown, post: Post): Promise<unknown> {
  post('placement', {
    active: true,
    kind: data.kind,
    garage: str(data.garage),
    title,
    coords: isRecord(data.interact) ? data.interact : vec(446.12, -990.85, 30.69, 270),
    fromPed: 9.4,
    previewSize: data.kind === 'spawn' ? 'Sedan' : undefined,
    corners: data.kind === 'zone' ? 6 : undefined,
    checks: [
      { ok: true, label: 'On the ground' },
      { ok: true, label: 'Nothing within 4.0 m' },
    ],
  })
  return delay(1500).then(() => {
    post('placement', { active: false })
    return result
  })
}

function place(data: Record<string, unknown>, post: Post): Promise<unknown> {
  const index = num(data.index) ?? 1
  if (data.kind === 'zone') {
    const points = [vec(424, -974, 28), vec(456, -974, 28), vec(458, -990, 28), vec(452, -1004, 30), vec(428, -1004, 30), vec(422, -990, 28)]
    return placed(data, 'Drawing the store zone', points, post)
  }
  if (data.kind === 'spawn') {
    const previous = list(data.spawns)[index - 2]
    const base = previous ? toVec4(previous) : vec(446.12, -986.4, 30.69, 270)
    const result = previous ? { ...base, y: base.y - 4.45 } : base
    return placed(data, `Placing spawn point ${index}`, result, post)
  }
  return placed(data, 'Placing the ped', vec(441.2, -981.9, 30.69, num(data.heading) ?? 90), post)
}

function save(data: Record<string, unknown>): unknown {
  const garage = toGarage(data.garage)
  if (!garage) return { ok: false, errors: [{ tab: 'general', field: 'id', message: 'The server could not read this garage.' }] }
  const originalId = str(data.originalId)
  if (garage.id !== originalId && store.garages.some((other) => other.id === garage.id)) {
    return { ok: false, errors: [{ tab: 'general', field: 'id', message: 'Another garage already uses this ID.' }] }
  }

  const saved: Garage = { ...garage, updatedBy: EDITOR, updatedAt: Math.floor(Date.now() / 1000) }
  const index = store.garages.findIndex((item) => item.id === (originalId ?? garage.id))
  if (index === -1) store.garages.push(saved)
  else store.garages[index] = saved
  if (originalId && originalId !== garage.id) {
    store.counts[garage.id] = store.counts[originalId] ?? 0
    delete store.counts[originalId]
  }
  store.counts[garage.id] ??= 0
  return { ok: true, snapshot: snapshot() }
}

function remove(data: Record<string, unknown>): unknown {
  const id = str(data.id)
  if (!id || !store.garages.some((garage) => garage.id === id)) return { ok: false }
  const moveTo = str(data.moveTo)
  if (moveTo) store.counts[moveTo] = (store.counts[moveTo] ?? 0) + (store.counts[id] ?? 0)
  store.garages = store.garages.filter((garage) => garage.id !== id)
  delete store.counts[id]
  return { ok: true, snapshot: snapshot() }
}

export function creatorHandlers(post: Post): Partial<Record<CallbackName, MockHandler>> {
  return {
    'creator:position': () => vec(425.1, -979.3, 30.71, 90),
    'creator:teleport': () => true,
    'creator:preview': () => true,
    'creator:clearance': (data) => list(data.spawns).map((_, index) => index !== 2),
    'creator:place': (data) => place(data, post),
    'creator:findCitizens': (data) => findResidents(data.query).map(({ citizenid, name }) => ({ citizenid, name })),
    'creator:nearby': () => RESIDENTS.slice(3, 5).map(({ citizenid, name }) => ({ citizenid, name })),
    'creator:check': (data) => {
      const garage = toGarage(data.garage)
      const resident = findResidents(data.query)[0]
      if (!garage || !resident) return { found: false }
      return { found: true, name: resident.name, ...checkAccess(garage, resident) }
    },
    'creator:save': save,
    'creator:delete': remove,
  }
}

export function creatorPayload(): unknown {
  return snapshot()
}

export function placementPayload(): unknown {
  return {
    active: true,
    kind: 'spawn',
    garage: 'Mission Row PD',
    title: 'Placing spawn point 2',
    coords: vec(446.12, -990.85, 30.69, 270),
    fromPed: 9.4,
    previewSize: 'Sedan',
    checks: [
      { ok: true, label: 'On the ground' },
      { ok: true, label: 'Nothing within 4.0 m' },
      { ok: false, label: '2.1 m from spawn point 1. Cars may touch.' },
    ],
  }
}
