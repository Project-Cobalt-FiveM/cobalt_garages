import type { Component } from 'svelte'
import type { IconComponentProps } from 'phosphor-svelte'
import AirplaneIcon from 'phosphor-svelte/lib/AirplaneIcon'
import BoatIcon from 'phosphor-svelte/lib/BoatIcon'
import CarIcon from 'phosphor-svelte/lib/CarIcon'
import HouseIcon from 'phosphor-svelte/lib/HouseIcon'
import { plural } from '../lib/format'
import type { FleetView, GarageType, GarageView, VehicleView } from '../lib/types'

export type Icon = Component<IconComponentProps>

export type Filter = 'all' | 'here' | 'elsewhere' | 'out' | 'impounded' | 'fleet' | 'ready' | 'hold'

export type Selection = { kind: 'vehicle'; vehicle: VehicleView } | { kind: 'fleet'; fleet: FleetView }

export type Kind = { noun: string; nouns: string; icon: Icon; matches: (vehicle: VehicleView) => boolean }

const CLASS_BOAT = 'Boats'
const AIR_CLASSES: readonly string[] = ['Helicopters', 'Planes']

const KINDS: Record<'car' | 'boat' | 'air', Kind> = {
  car: { noun: 'car', nouns: 'cars', icon: CarIcon, matches: (v) => v.classLabel !== CLASS_BOAT && !AIR_CLASSES.includes(v.classLabel) },
  boat: { noun: 'boat', nouns: 'boats', icon: BoatIcon, matches: (v) => v.classLabel === CLASS_BOAT },
  air: { noun: 'aircraft', nouns: 'aircraft', icon: AirplaneIcon, matches: (v) => AIR_CLASSES.includes(v.classLabel) },
}

export const FILTER_LABELS: Record<Filter, string> = {
  all: 'All',
  here: 'Here',
  elsewhere: 'Elsewhere',
  out: 'Out',
  impounded: 'Impounded',
  fleet: 'Fleet',
  ready: 'Ready',
  hold: 'On hold',
}

export const STATUS_ORDER: Record<VehicleView['status'], number> = { here: 0, elsewhere: 1, out: 2, impounded: 3 }

export function kindOf(type: GarageType): Kind {
  if (type === 'boat') return KINDS.boat
  if (type === 'air') return KINDS.air
  return KINDS.car
}

export function headerIcon(garage: GarageView): Icon {
  if (garage.isHouse) return HouseIcon
  return kindOf(garage.type).icon
}

export function title(garage: GarageView): string {
  const named = /garage|park|lot|impound|boathouse|hangar|motel|pd$/i.test(garage.label)
  return named || garage.isHouse ? garage.label : `${garage.label} garage`
}

export function subtitle(garage: GarageView, kind: Kind, here: number, total: number): string {
  if (garage.type === 'impound') {
    return total === 0 ? 'Impound lot.' : `Impound lot. ${total} of your vehicles ${total === 1 ? 'is' : 'are'} held here.`
  }
  const owned =
    total === 0
      ? `You own no ${kind.nouns} yet.`
      : here === 0
        ? `None of your ${plural(total, kind.noun, kind.nouns)} are here.`
        : `${here} of your ${plural(total, kind.noun, kind.nouns)} ${here === 1 ? 'is' : 'are'} parked here.`
  if (garage.isHouse) return `Your property garage. ${owned}`
  if (garage.type === 'job' || garage.type === 'gang') {
    const fleet = garage.fleet.length > 0 ? `${plural(garage.fleet.length, 'fleet vehicle', 'fleet vehicles')} to sign out.` : ''
    const label = garage.type === 'job' ? 'Job' : 'Gang'
    return garage.owners === 'fleet' ? `${label} garage. ${fleet}` : `${label} garage. ${fleet} ${owned}`.replace(/\s+/g, ' ')
  }
  const label = garage.type === 'boat' ? 'Boat garage' : garage.type === 'air' ? 'Hangar' : 'Public car garage'
  return `${label}. ${owned}`
}

export function emptyText(garage: GarageView, kind: Kind): string {
  if (garage.type === 'impound') return `None of your vehicles are impounded at ${garage.label}.`
  if (garage.type === 'boat') return 'Sail a boat you own into the dock zone and press Store. Your cars stay in car garages.'
  if (garage.type === 'air') return 'Fly an aircraft you own onto the pad and press Store. Your cars stay in car garages.'
  return `Drive a ${kind.noun} you own here and press Store.`
}

export function isHeld(vehicle: VehicleView, now: number): boolean {
  return vehicle.holdUntil !== undefined && vehicle.holdUntil > now
}

export function keyOf(item: Selection): string {
  return item.kind === 'fleet' ? `fleet:${item.fleet.index}` : item.vehicle.plate
}
