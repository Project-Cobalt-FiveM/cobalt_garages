import { num, str, type CallbackName, type MessageAction, type MockHandler } from './nui'
import type { Account, GarageView, Outcome, TransferTarget, VehicleView } from './types'

type Post = (action: MessageAction, data?: unknown) => void

const HOUR = 3600

function now(): number {
  return Math.floor(Date.now() / 1000)
}

function vehicle(fields: Partial<VehicleView> & Pick<VehicleView, 'plate' | 'model' | 'label' | 'classLabel' | 'status'>): VehicleView {
  return { seats: 4, drivenByYou: false, fuel: 100, engine: 1000, body: 1000, fee: 0, ...fields }
}

function publicGarage(): GarageView {
  const at = now()
  return {
    id: 'legion_square',
    label: 'Legion Square',
    type: 'car',
    owners: 'player',
    isHouse: false,
    fees: { takeOut: 0, store: 0, transferIn: 150, release: 0 },
    spawn: { bay: 2, total: 3 },
    balances: { cash: 350, bank: 55000 },
    store: { label: 'Ubermacht Zion' },
    now: at,
    fleet: [],
    vehicles: [
      vehicle({
        plate: '48KDJ203',
        model: 'zentorno',
        label: 'Pegassi Zentorno',
        classLabel: 'Super',
        seats: 2,
        status: 'here',
        fuel: 72,
        engine: 940,
        body: 410,
        parkedAt: at - 2 * HOUR,
        mileage: 2184000,
      }),
      vehicle({
        plate: '61ROM884',
        model: 'sultanrs',
        label: 'Karin Sultan RS',
        classLabel: 'Sports',
        status: 'here',
        fuel: 18,
        engine: 720,
        body: 860,
        parkedAt: at - 26 * HOUR,
        mileage: 41730000,
      }),
      vehicle({
        plate: '09TRK551',
        model: 'buffalo4',
        label: 'Bravado Buffalo STX',
        classLabel: 'Muscle',
        status: 'here',
        engine: 210,
        body: 980,
        parkedAt: at - 5 * HOUR,
        mileage: 880000,
      }),
      vehicle({
        plate: '33LNE170',
        model: 'vigero',
        label: 'Declasse Vigero',
        classLabel: 'Muscle',
        seats: 2,
        status: 'elsewhere',
        location: 'Pillbox Hill',
        fuel: 54,
        mileage: 12950000,
      }),
      vehicle({
        plate: '72BLS019',
        model: 'sandking',
        label: 'Vapid Sandking',
        classLabel: 'Off-road',
        status: 'out',
        drivenByYou: true,
        fuel: 63,
      }),
      vehicle({
        plate: '15QXC640',
        model: 'tailgater',
        label: 'Obey Tailgater',
        classLabel: 'Sedans',
        status: 'impounded',
        location: 'Davis Impound',
        fee: 250,
      }),
    ],
  }
}

function impoundLot(): GarageView {
  const at = now()
  return {
    id: 'davis_impound',
    label: 'Davis Impound',
    type: 'impound',
    owners: 'player',
    isHouse: false,
    fees: { takeOut: 0, store: 0, transferIn: 0, release: 250 },
    spawn: { bay: 1, total: 2 },
    balances: { cash: 350, bank: 55000 },
    now: at,
    fleet: [],
    vehicles: [
      vehicle({
        plate: '15QXC640',
        model: 'tailgater',
        label: 'Obey Tailgater',
        classLabel: 'Sedans',
        status: 'impounded',
        fuel: 72,
        engine: 940,
        body: 410,
        fee: 250,
        impoundedAt: at - 15 * HOUR,
        impoundReason: 'Left parked while you were offline for 8 hours',
      }),
      vehicle({
        plate: '61ROM884',
        model: 'sultanrs',
        label: 'Karin Sultan RS',
        classLabel: 'Sports',
        status: 'impounded',
        fuel: 31,
        engine: 180,
        body: 240,
        fee: 1200,
        impoundedAt: at - HOUR,
        impoundReason: 'Seized by LSPD after a pursuit',
        holdUntil: at + 3 * HOUR,
      }),
    ],
  }
}

const TARGETS: TransferTarget[] = [
  { id: 'pillbox_hill', label: 'Pillbox Hill garage', kind: 'Public', distance: 1200, fee: 150, available: true },
  { id: 'eclipse_tower_4', label: '4 Eclipse Tower', kind: 'Your house', distance: 2800, fee: 0, available: true },
  { id: 'sandy_shores', label: 'Sandy Shores garage', kind: 'Public', distance: 4900, fee: 400, available: true },
  { id: 'lsia_hangar', label: 'LSIA hangar', kind: 'Hangar', distance: 7300, fee: 0, available: false, reason: 'Takes aircraft only' },
]

let current: GarageView = publicGarage()

export function garagePayload(): unknown {
  current = publicGarage()
  return current
}

export function impoundPayload(): unknown {
  current = impoundLot()
  return current
}

function find(plate: unknown): VehicleView | undefined {
  const wanted = str(plate)
  return current.vehicles.find((item) => item.plate === wanted)
}

function account(value: unknown): Account {
  return value === 'cash' ? 'cash' : 'bank'
}

function fail(message: string): Outcome {
  return { ok: false, message }
}

export function garageHandlers(post: Post): Partial<Record<CallbackName, MockHandler>> {
  function refresh(): Outcome {
    current = { ...current, now: now() }
    post('garage', current)
    return { ok: true, message: '' }
  }

  return {
    'garage:close': () => true,

    'garage:takeOut': (data) => {
      const target = find(data.plate)
      if (!target || target.status !== 'here') return fail('That vehicle is not parked here')
      if (current.balances.bank < current.fees.takeOut) return fail('Not enough money in the bank')
      current.balances.bank -= current.fees.takeOut
      current.vehicles = current.vehicles.map((item) =>
        item === target ? { ...item, status: 'out', drivenByYou: true, parkedAt: undefined } : item,
      )
      return refresh()
    },

    'garage:takeFleet': (data) => {
      const index = num(data.index)
      if (!current.fleet.some((item) => item.index === index)) return fail('That fleet vehicle is not available')
      return { ok: true, message: '' }
    },

    'garage:release': (data) => {
      const target = find(data.plate)
      if (!target) return fail('That vehicle is not held here')
      if (target.holdUntil !== undefined && target.holdUntil > now()) return fail('That vehicle is on police hold')
      const from = account(data.account)
      if (current.balances[from] < target.fee) return fail(`Not enough ${from === 'bank' ? 'money in the bank' : 'cash'}`)
      current.balances = { ...current.balances, [from]: current.balances[from] - target.fee }
      current.vehicles = current.vehicles.filter((item) => item !== target)
      return refresh()
    },

    'garage:store': () => {
      if (!current.store) return fail('You are not in a vehicle you own')
      current.vehicles = [
        vehicle({
          plate: '27ZNE418',
          model: 'zion',
          label: current.store.label,
          classLabel: 'Coupes',
          seats: 2,
          status: 'here',
          fuel: 46,
          engine: 990,
          body: 870,
          parkedAt: now(),
          mileage: 6410000,
        }),
        ...current.vehicles,
      ]
      current.store = undefined
      return refresh()
    },

    'garage:transferTargets': () => TARGETS,

    'garage:transfer': (data) => {
      const target = find(data.plate)
      const destination = TARGETS.find((item) => item.id === str(data.to))
      if (!target || !destination?.available) return fail('You cannot move it there')
      if (current.balances.bank < destination.fee) return fail('Not enough money in the bank')
      current.balances = { ...current.balances, bank: current.balances.bank - destination.fee }
      current.vehicles = current.vehicles.map((item) =>
        item === target ? { ...item, status: 'elsewhere', location: destination.label, parkedAt: undefined } : item,
      )
      return refresh()
    },
  }
}
