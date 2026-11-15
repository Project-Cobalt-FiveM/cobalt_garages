local config <const> = require 'config'
local db <const> = require 'server.db'
local Garage <const> = require 'shared.garage'
local Zone <const> = require 'shared.zone'
local Garages <const> = require 'server.garages'
local Housing <const> = require 'server.housing'
local Access <const> = require 'server.access'
local Players <const> = require 'server.players'

---@class OutVehicle
---@field entity integer
---@field garage? string
---@field citizenid? string
---@field fleet boolean
---@field droppedAt? integer

---@class Outcome
---@field ok boolean
---@field message string
---@field title? string

local VEHICLE_TYPES <const> = {
    automobile = true, bike = true, boat = true, heli = true, plane = true, submarine = true, trailer = true, train = true,
}

local CATEGORY_CLASSES <const> = {
    compacts = 0, sedans = 1, suvs = 2, suv = 2, coupes = 3, muscle = 4, sportsclassics = 5, sportsclassic = 5,
    sports = 6, super = 7, motorcycles = 8, offroad = 9, industrial = 10, utility = 11, vans = 12, cycles = 13,
    boats = 14, helicopters = 15, planes = 16, service = 17, emergency = 18, military = 19, commercial = 20,
    trains = 21, openwheel = 22,
}

local TYPE_CLASSES <const> = { boat = 14, submarine = 14, heli = 15, plane = 16, train = 21 }

local KIND_KEYS <const> = { boat = 'kind.boat', air = 'kind.air', car = 'kind.car' }

local PLATE_SYNC_TIMEOUT_MS <const> = 5000

local Vehicles <const> = {}

---@type table<string, OutVehicle>
local out <const> = {}

---@type table<integer, string>
local plateByEntity <const> = {}

---@param message string
---@param title? string
---@return Outcome
local function fail(message, title)
    return { ok = false, message = message, title = title }
end

---@param message string
---@return Outcome
local function done(message)
    return { ok = true, message = message }
end

---@param plate string?
---@return string?
local function trim(plate)
    if type(plate) ~= 'string' then return nil end

    local clean <const> = plate:gsub('^%s+', ''):gsub('%s+$', '')

    return clean ~= '' and clean or nil
end

---@param entity integer
---@return string?
local function plateOf(entity)
    return trim(GetVehicleNumberPlateText(entity))
end

---@param point Vec3
---@return vector3
local function vec(point)
    return vector3(point.x, point.y, point.z)
end

---@param model string
---@return integer
local function modelHash(model)
    return tonumber(model) or joaat(model)
end

---@param garage Garage
---@param coords vector3
---@return boolean
local function isNear(garage, coords)
    if Zone.contains(garage.zone, coords) then return true end

    local range <const> = garage.propertyId and config.houseRange or config.storeRange

    if #(coords - vec(garage.interact.coords)) <= range then return true end

    for _, spawn in ipairs(garage.spawns) do
        if #(coords - vec(spawn)) <= range then return true end
    end

    return false
end

---@param source integer
---@return vector3
local function playerCoords(source)
    return GetEntityCoords(GetPlayerPed(source))
end

---@param garage Garage
---@return integer?, Vec4?
local function clearSpawn(garage)
    local vehicles <const> = GetAllVehicles()

    for index, spawn in ipairs(garage.spawns) do
        local point <const> = vec(spawn)
        local blocked = false

        for _, vehicle in ipairs(vehicles) do
            if #(GetEntityCoords(vehicle) - point) <= garage.clearRadius then
                blocked = true
                break
            end
        end

        if not blocked then return index, spawn end
    end
end

---@param entity integer
---@param except? integer
---@return boolean
local function occupied(entity, except)
    for _, playerId in ipairs(GetPlayers()) do
        local id <const> = tonumber(playerId) --[[@as integer]]

        if id ~= except and GetVehiclePedIsIn(GetPlayerPed(id), false) == entity then return true end
    end

    return false
end

---@param entity integer
---@param props table
---@param repair boolean
---@return VehicleCondition
local function conditionOf(entity, props, repair)
    if repair then
        props.engineHealth, props.bodyHealth, props.tankHealth, props.fuelLevel = 1000.0, 1000.0, 1000.0, 100.0
        props.windows, props.doors, props.tyres = nil, nil, nil

        return { fuel = 100, engine = 1000.0, body = 1000.0, props = props }
    end

    local fuel <const> = Entity(entity).state.fuel or props.fuelLevel or 100

    props.fuelLevel = fuel

    return {
        fuel = math.floor(fuel),
        engine = GetVehicleEngineHealth(entity),
        body = GetVehicleBodyHealth(entity),
        props = props,
    }
end

local REPORTED_KEYS <const> = { 'engineHealth', 'bodyHealth', 'tankHealth', 'fuelLevel', 'oilLevel', 'dirtLevel', 'windows', 'doors', 'tyres' }

---Keeps the mods saved by the dealership and cobalt_mechanic, taking only wear and damage from the client
---@param savedMods? string
---@param reported table
---@return table
local function storedProps(savedMods, reported)
    local ok <const>, saved <const> = pcall(json.decode, savedMods or '{}')
    local props <const> = ok and type(saved) == 'table' and saved or {}

    for _, key in ipairs(REPORTED_KEYS) do props[key] = reported[key] end

    return props
end

---@param entity integer
---@param plate string
---@param entry OutVehicle
local function track(entity, plate, entry)
    out[plate] = entry
    plateByEntity[entity] = plate
end

---@param plate string
local function untrack(plate)
    local entry <const> = out[plate]

    if not entry then return end

    plateByEntity[entry.entity] = nil
    out[plate] = nil
end

---@param plate string
---@param entity integer
local function removeEntity(plate, entity)
    untrack(plate)

    if DoesEntityExist(entity) then DeleteEntity(entity) end
end

---@param entity integer
---@param plate string
---@param props table
local function setPropsOncePlated(entity, plate, props)
    CreateThread(function()
        pcall(lib.waitFor, function()
            if not DoesEntityExist(entity) then return false end
            if plateOf(entity) == trim(plate) then return true end
        end, nil, PLATE_SYNC_TIMEOUT_MS)

        if not DoesEntityExist(entity) then return end

        Entity(entity).state:set('ox_lib:setVehicleProperties', props, true)
    end)
end

---@class SpawnRequest
---@field source integer
---@field spawn Vec4
---@field model string
---@field vehicleType string
---@field plate string
---@field props? table
---@field fuel number

---@param request SpawnRequest
---@return integer?
local function spawn(request)
    local point <const> = request.spawn
    local model <const> = modelHash(request.model)
    local entity <const> = CreateVehicleServerSetter(model, request.vehicleType, point.x, point.y, point.z, point.w)

    if not entity or entity == 0 then return nil end

    local exists <const> = pcall(lib.waitFor, function()
        if DoesEntityExist(entity) then return true end
    end, nil, 2000)

    if not exists then return nil end

    SetEntityOrphanMode(entity, 2)
    SetVehicleNumberPlateText(entity, request.plate)

    Entity(entity).state:set('fuel', request.fuel + 0.0, true)
    setPropsOncePlated(entity, request.plate, request.props or { plate = request.plate })

    SetPedIntoVehicle(GetPlayerPed(request.source), entity, -1)

    if GetResourceState('cobalt_vehiclekeys') == 'started' then
        exports.cobalt_vehiclekeys:GiveKey(request.source, request.plate, entity)
    end

    return entity
end

---@param garage Garage
---@param amount integer
---@param description string
local function payGarage(garage, amount, description)
    if garage.rules.payTo then Players.payOrg(garage.rules.payTo, amount, description) end
end

---@param source integer
---@param garage Garage
---@param amount integer
---@param from ChargeFrom
---@param description string
---@return Charge
local function chargeFor(source, garage, amount, from, description)
    return function()
        if not Players.charge(source, amount, from, description) then return false end

        payGarage(garage, amount, description)

        return true
    end
end

---@param source integer
---@param model string
---@param class integer
---@return string
local function nearestFittingGarage(source, model, class)
    local coords <const> = playerCoords(source)
    local best, bestDistance

    for _, garage in ipairs(Garages.all()) do
        local distance <const> = #(coords - vec(garage.interact.coords))
        local usable <const> = Garage.holdsPlayerCars(garage) and Garage.fits(garage, model, class) and Access.canUse(source, garage)

        if usable and (not bestDistance or distance < bestDistance) then
            best, bestDistance = garage, distance
        end
    end

    if not best then return '' end

    return locale('garage.nearest', best.label, math.floor(bestDistance))
end

---@param garage Garage
---@return string
local function kindLabel(garage)
    return locale(KIND_KEYS[garage.type] or 'kind.other')
end

---@param source integer
---@param garageId string
---@return Garage?, string?
local function usableGarage(source, garageId)
    local garage <const> = type(garageId) == 'string' and Garages.get(garageId)

    if not garage then return nil, locale('retrieve.garage_gone') end

    local access <const> = Access.check(source, garage)

    if not access.allowed then return nil, access.reason end

    if not isNear(garage, playerCoords(source)) then return nil, locale('retrieve.too_far_garage') end

    return garage
end

---@param source integer
---@param garage Garage
---@param entity integer
---@param plate string
---@return Outcome
local function storeFleet(source, garage, entity, plate)
    local entry <const> = out[plate]

    if not Access.canUseFleet(source, garage) then return fail(locale('store.fleet_denied')) end
    if entry.garage ~= garage.id then return fail(locale('store.fleet_wrong_garage')) end

    removeEntity(plate, entity)

    return done(locale('store.fleet_stored'))
end

---@param model string
---@return string?
local function catalogueCategory(model)
    return exports.cobalt_core:GetShared('Vehicles', model)?.category
end

---@param row OwnedVehicleRow
---@param vehicleType string
---@return integer?
local function classOf(row, vehicleType)
    return CATEGORY_CLASSES[catalogueCategory(row.model:lower())] or row.class or TYPE_CLASSES[vehicleType]
end

---@class StoreRequest
---@field garageId string
---@field netId integer
---@field props table

---@param source integer
---@param request StoreRequest
---@return Outcome
function Vehicles.store(source, request)
    local garage, reason = usableGarage(source, request.garageId)

    if not garage then return fail(reason --[[@as string]]) end

    local entity <const> = NetworkGetEntityFromNetworkId(request.netId)

    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then
        return fail(locale('store.no_vehicle'))
    end

    if not isNear(garage, GetEntityCoords(entity)) then return fail(locale('store.bring_closer')) end
    if #(GetEntityCoords(entity) - playerCoords(source)) > 10.0 then return fail(locale('store.too_far_vehicle')) end
    if occupied(entity, source) then return fail(locale('store.occupied')) end

    local plate <const> = plateOf(entity)

    if not plate then return fail(locale('store.no_plate')) end

    if out[plate]?.fleet then return storeFleet(source, garage, entity, plate) end
    if out[plate] and out[plate].entity ~= entity and DoesEntityExist(out[plate].entity) then
        return fail(locale('store.wrong_entity'))
    end

    local citizenid <const> = Players.citizenid(source) --[[@as string]]
    local row <const> = db.vehicle(plate)
    local name <const> = request.props.modelLabel or plate

    local title <const> = locale('store.title', name)

    if not row or row.citizenid ~= citizenid then return fail(locale('retrieve.not_owner'), title) end
    if not Garage.holdsPlayerCars(garage) then return fail(locale('store.fleet_only'), title) end

    local vehicleType <const> = GetVehicleType(entity) or 'automobile'
    local class <const> = classOf(row, vehicleType)

    if not class then return fail(locale('store.unlisted_model'), title) end

    if not Garage.classMatchesType(vehicleType, class) then
        return fail(locale('store.class_mismatch'))
    end

    if not Garage.fits(garage, row.model, class) then
        local noun <const> = locale(garage.type == 'boat' and 'store.noun_boathouse' or 'store.noun_garage')
        local nearest <const> = nearestFittingGarage(source, row.model, class)

        return fail(locale('store.wrong_kind', noun, kindLabel(garage), nearest), title)
    end

    local rules <const> = garage.rules

    if rules.capacity and db.countStored(garage.id) >= rules.capacity then return fail(locale('store.full')) end
    if rules.perPlayer and db.countStored(garage.id, citizenid) >= rules.perPlayer then
        return fail(locale('store.per_player', rules.perPlayer))
    end

    local props <const> = storedProps(row.mods, request.props)
    props.plate = plate

    local condition <const> = conditionOf(entity, props, rules.repairOnStore)
    local description <const> = locale('charge.parking', garage.label)
    local charge <const> = chargeFor(source, garage, rules.fees.store, rules.chargeFrom, description)

    if not db.store(plate, citizenid, garage.id, condition, vehicleType, class, charge) then
        if rules.fees.store > 0 then return fail(locale('store.need_money', rules.fees.store)) end

        return fail(locale('store.failed'))
    end

    removeEntity(plate, entity)

    return done(locale('store.stored', name, garage.label))
end

---@param row OwnedVehicleRow
---@return table
local function parkedProps(row)
    local ok, props = pcall(json.decode, row.mods or '{}')

    props = ok and type(props) == 'table' and props or {}
    props.plate = row.plate
    props.fuelLevel = row.fuel or 100
    props.engineHealth = row.engine or 1000.0
    props.bodyHealth = row.body or 1000.0

    return props
end

---@param row OwnedVehicleRow
---@param requested string
---@return string
local function vehicleTypeOf(row, requested)
    if row.vehicleType and VEHICLE_TYPES[row.vehicleType] then return row.vehicleType end

    return VEHICLE_TYPES[requested] and requested or 'automobile'
end

---@param plate string
---@return boolean
local function isInWorld(plate)
    local entry <const> = out[plate]

    return entry ~= nil and DoesEntityExist(entry.entity)
end

---@param source integer
---@param garageId? string
---@param row OwnedVehicleRow
---@param vehicleType string
---@param point Vec4
---@return integer?
local function spawnOwned(source, garageId, row, vehicleType, point)
    local entity <const> = spawn({
        source = source,
        spawn = point,
        model = row.model,
        vehicleType = vehicleTypeOf(row, vehicleType),
        plate = row.plate,
        props = parkedProps(row),
        fuel = row.fuel or 100,
    })

    if entity then
        track(entity, row.plate, { entity = entity, garage = garageId, citizenid = row.citizenid, fleet = false })
    end

    return entity
end

---@class TakeOutRequest
---@field garageId string
---@field plate string
---@field vehicleType string

---@param source integer
---@param request TakeOutRequest
---@return Outcome
function Vehicles.takeOut(source, request)
    local garage, reason = usableGarage(source, request.garageId)

    if not garage then return fail(reason --[[@as string]]) end

    local citizenid <const> = Players.citizenid(source) --[[@as string]]
    local row <const> = db.vehicle(request.plate)

    if not row or row.citizenid ~= citizenid then return fail(locale('retrieve.not_owner')) end
    if row.state ~= 1 or row.garage ~= garage.id then return fail(locale('retrieve.not_here')) end
    if isInWorld(row.plate) then return fail(locale('retrieve.already_out')) end

    local _, point = clearSpawn(garage)

    if not point then return fail(locale('retrieve.bays_blocked')) end

    local rules <const> = garage.rules
    local description <const> = locale('charge.retrieval', garage.label)
    local charge <const> = chargeFor(source, garage, rules.fees.takeOut, rules.chargeFrom, description)

    if not db.takeOut(row.plate, citizenid, garage.id, charge) then
        return fail(locale('retrieve.need_money', rules.fees.takeOut))
    end

    if not spawnOwned(source, garage.id, row, request.vehicleType, point) then
        db.putBack(row.plate)

        return fail(locale('retrieve.spawn_failed'))
    end

    return done(locale('retrieve.spawned'))
end

---@param source integer
---@param plate string
---@param point Vec4
---@param vehicleType? string
---@return integer?
function Vehicles.spawnOut(source, plate, point, vehicleType)
    local row <const> = db.vehicle(plate)

    if not row or row.state ~= 0 then return nil end
    if row.citizenid ~= Players.citizenid(source) or isInWorld(row.plate) then return nil end

    return spawnOwned(source, row.garage, row, vehicleType or 'automobile', point)
end

---@param prefix string
---@return string
local function fleetPlate(prefix)
    local plate

    repeat
        plate = (prefix .. tostring(math.random(10000000, 99999999))):sub(1, 8)
    until not out[plate]

    return plate
end

---@class BoughtFleetVehicle
---@field plate string
---@field model string
---@field label string
---@field minGrade integer

---@param source integer
---@param garage table
---@return BoughtFleetVehicle[]
function Vehicles.boughtFleet(source, garage)
    if GetResourceState('cobalt_management') ~= 'started' then return {} end

    local membership <const> = garage.type == 'job' and Players.job(source) or Players.gang(source)

    if not membership then return {} end

    local out <const> = {}

    for _, vehicle in ipairs(exports.cobalt_management:GetFleet(membership.name)) do
        if membership.grade >= vehicle.minGrade then out[#out + 1] = vehicle end
    end

    return out
end

---@param citizenid string
---@return integer
local function fleetCount(citizenid)
    local count = 0

    for _, entry in pairs(out) do
        if entry.fleet and entry.citizenid == citizenid and DoesEntityExist(entry.entity) then count += 1 end
    end

    return count
end

---@class FleetRequest
---@field garageId string
---@field index integer
---@field vehicleType string

---@param source integer
---@param request FleetRequest
---@return Outcome
function Vehicles.takeFleet(source, request)
    local garage, reason = usableGarage(source, request.garageId)

    if not garage then return fail(reason --[[@as string]]) end
    if not Access.canUseFleet(source, garage) then return fail(locale('retrieve.fleet_grade')) end

    local vehicle = garage.fleet[request.index]
    local bought <const> = not vehicle and Vehicles.boughtFleet(source, garage)[request.index - #garage.fleet] or nil

    vehicle = vehicle or bought

    if not vehicle then return fail(locale('retrieve.fleet_gone')) end
    if bought and out[bought.plate] then return fail(locale('retrieve.already_out')) end

    local citizenid <const> = Players.citizenid(source) --[[@as string]]

    if fleetCount(citizenid) >= config.fleetPerPlayer then
        return fail(locale('retrieve.fleet_limit', config.fleetPerPlayer))
    end

    local _, point = clearSpawn(garage)

    if not point then return fail(locale('retrieve.bays_blocked')) end

    local membership <const> = garage.type == 'job' and Players.job(source) or Players.gang(source)
    local plate <const> = bought?.plate or fleetPlate(membership and config.fleetPlatePrefix[membership.name] or 'FLEET')
    local entity <const> = spawn({
        source = source,
        spawn = point,
        model = vehicle.model,
        vehicleType = VEHICLE_TYPES[request.vehicleType] and request.vehicleType or 'automobile',
        plate = plate,
        fuel = 100,
    })

    if not entity then return fail(locale('retrieve.spawn_failed')) end

    track(entity, plate, { entity = entity, garage = garage.id, citizenid = citizenid, fleet = true })

    return done(locale('retrieve.fleet_spawned', vehicle.label))
end

---@class TransferRequest
---@field plate string
---@field to string

---@param garage Garage
---@return string
local function kindKey(garage)
    if garage.propertyId then return 'garage.kind_house' end

    return garage.access.mode == 'everyone' and 'garage.kind_public' or 'garage.kind_private'
end

---@param source integer
---@param row OwnedVehicleRow
---@class TransferTarget
---@field id string
---@field label string
---@field kind string
---@field distance integer
---@field fee integer
---@field available boolean
---@field reason? string

---@return TransferTarget[]
function Vehicles.transferTargets(source, row)
    local coords <const> = playerCoords(source)
    local citizenid <const> = Players.citizenid(source) --[[@as string]]
    local candidates <const> = Garages.all()
    local targets <const> = {}

    for _, garage in ipairs(Housing.owned(citizenid)) do
        candidates[#candidates + 1] = garage
    end

    for _, garage in ipairs(candidates) do
        if garage.id ~= row.garage and Garage.holdsPlayerCars(garage) and garage.enabled then
            local usable <const> = Access.canUse(source, garage)
            local fits <const> = Garage.fits(garage, row.model, row.class or 0)
            local reason <const> = not usable and locale('garage.locked')
                or not fits and locale('garage.takes_only', kindLabel(garage))
                or nil

            targets[#targets + 1] = {
                id = garage.id,
                label = garage.label,
                kind = locale(kindKey(garage)),
                distance = math.floor(#(coords - vec(garage.interact.coords))),
                fee = garage.rules.fees.transferIn,
                available = usable and fits,
                reason = reason,
            }
        end
    end

    table.sort(targets, function(a, b)
        if a.available ~= b.available then return a.available end

        return a.distance < b.distance
    end)

    return targets
end

---@param source integer
---@param request TransferRequest
---@return Outcome
function Vehicles.transfer(source, request)
    local citizenid <const> = Players.citizenid(source) --[[@as string]]
    local row <const> = db.vehicle(request.plate)

    if not row or row.citizenid ~= citizenid then return fail(locale('retrieve.not_owner')) end
    if row.state ~= 1 or not row.garage then return fail(locale('transfer.parked_only')) end

    local from <const> = Garages.get(row.garage)

    if from and not isNear(from, playerCoords(source)) then return fail(locale('transfer.stand_at_garage')) end

    local target <const> = Garages.get(request.to)

    if not target or not target.enabled or not Garage.holdsPlayerCars(target) then
        return fail(locale('transfer.no_vehicles'))
    end

    if not Access.canUse(source, target) then return fail(locale('transfer.no_access')) end
    if not Garage.fits(target, row.model, row.class or 0) then
        return fail(locale('transfer.wrong_kind', kindLabel(target)))
    end

    local fee <const> = target.rules.fees.transferIn
    local charge <const> = chargeFor(source, target, fee, 'bank', locale('charge.transfer', target.label))

    if not db.transfer(row.plate, citizenid, row.garage, target.id, charge) then
        return fail(locale('transfer.need_money', fee))
    end

    return done(locale('transfer.moved', target.label))
end

---@class ReleaseRequest
---@field garageId string
---@field plate string
---@field account 'bank' | 'cash'
---@field vehicleType string

---@param source integer
---@param request ReleaseRequest
---@return Outcome
function Vehicles.release(source, request)
    local lot, reason = usableGarage(source, request.garageId)

    if not lot then return fail(reason --[[@as string]]) end
    if lot.type ~= 'impound' then return fail(locale('release.lot_only')) end

    local citizenid <const> = Players.citizenid(source) --[[@as string]]
    local row <const> = db.vehicle(request.plate)

    if not row or row.citizenid ~= citizenid then return fail(locale('retrieve.not_owner')) end
    if row.state ~= 2 or row.garage ~= lot.id then return fail(locale('release.not_here')) end

    if row.holdUntil and row.holdUntil > os.time() then
        return fail(locale('release.on_hold', os.date('%H:%M', row.holdUntil)))
    end

    local _, point = clearSpawn(lot)

    if not point then return fail(locale('release.bays_blocked')) end

    local account <const> = request.account == 'cash' and 'cash' or 'bank'
    local charge <const> = chargeFor(source, lot, row.depotprice, account, locale('charge.release', lot.label))

    if not db.release(row.plate, citizenid, lot.id, row.depotprice, charge) then
        return fail(locale(account == 'cash' and 'release.need_cash' or 'release.need_bank', row.depotprice))
    end

    if not spawnOwned(source, lot.id, row, request.vehicleType, point) then
        db.impound(row.plate, { lot = lot.id, fee = 0, reason = locale('impound.reason_spawn_failed'), by = 'City' })

        return fail(locale('release.spawn_failed'))
    end

    return done(locale('release.released'))
end

---@param plate string
---@param entity? integer
---@param record ImpoundRecord
---@return boolean
function Vehicles.impound(plate, entity, record)
    local entry <const> = out[plate]

    if entry?.fleet then
        removeEntity(plate, entry.entity)

        return true
    end

    local row <const> = db.vehicle(plate)

    if row and entity and DoesEntityExist(entity) then
        local props <const> = storedProps(row.mods, {})
        props.plate = plate

        record.condition = record.condition or conditionOf(entity, props, false)
    end

    local impounded <const> = db.impound(plate, record)

    if entity then
        removeEntity(plate, entity)
    else
        untrack(plate)
    end

    local owner <const> = impounded and row and Players.sourceOf(row.citizenid)

    if owner then
        local lot <const> = Garages.get(record.lot)
        local lotLabel <const> = lot?.label or locale('impound.default_lot')
        local message <const> = locale('impound.owner_notice', plate, lotLabel, record.reason)

        Players.notify(owner, message, 'warning', locale('impound.title'))
    end

    return impounded
end

---@param source integer
---@return OutVehicle?, string?
function Vehicles.drivenBy(source)
    local entity <const> = GetVehiclePedIsIn(GetPlayerPed(source), false)
    local plate <const> = entity ~= 0 and plateByEntity[entity]

    if plate then return out[plate], plate end
end

---@param plate string
---@return OutVehicle?
function Vehicles.outEntry(plate)
    return out[plate]
end

---@param reason string
---@return ImpoundRecord
local function impoundRecord(reason)
    local lot <const> = Garages.get(config.defaultImpound)
    local fee <const> = lot and lot.rules.fees.release > 0 and lot.rules.fees.release or config.impoundFee

    return { lot = config.defaultImpound, fee = fee, reason = reason, by = 'City' }
end

AddEventHandler('entityRemoved', function(entity)
    local plate <const> = plateByEntity[entity]

    if not plate then return end

    local entry <const> = out[plate]

    untrack(plate)

    if entry and not entry.fleet then
        db.impound(plate, impoundRecord(locale('impound.reason_removed')))
    end
end)

---@param citizenid? string
local function markDropped(citizenid)
    if not citizenid then return end

    for _, entry in pairs(out) do
        if entry.citizenid == citizenid then entry.droppedAt = os.time() end
    end
end

AddEventHandler('cobalt_core:Server:PlayerDropped', function(player)
    markDropped(player.PlayerData.citizenid)
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    markDropped(exports.cobalt_core:GetPlayer(source)?.PlayerData.citizenid)
end)

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    local citizenid <const> = player?.PlayerData?.citizenid

    for _, entry in pairs(out) do
        if entry.citizenid == citizenid then entry.droppedAt = nil end
    end
end)

local function sweepOffline()
    local cutoff <const> = os.time() - math.floor(config.offlineHours * 3600)
    local reason <const> = locale('impound.reason_offline', config.offlineHours)

    for plate, entry in pairs(out) do
        local stale <const> = entry.droppedAt and entry.droppedAt <= cutoff

        if stale and not occupied(entry.entity) then
            Vehicles.impound(plate, entry.entity, impoundRecord(reason))
        end
    end
end

---@return table<string, integer>
local function worldPlates()
    local plates <const> = {}

    for _, vehicle in ipairs(GetAllVehicles()) do
        local plate <const> = plateOf(vehicle)

        if plate then plates[plate] = vehicle end
    end

    return plates
end

function Vehicles.reconcile()
    local world <const> = worldPlates()
    local now <const> = os.time()
    local toReturn <const> = {}

    for _, row in ipairs(db.outVehicles()) do
        local entity <const> = world[row.plate]
        local garage <const> = row.garage and Garages.get(row.garage)

        if entity then
            local online <const> = Players.sourceOf(row.citizenid) ~= nil
            track(entity, row.plate, {
                entity = entity,
                garage = row.garage,
                citizenid = row.citizenid,
                fleet = false,
                droppedAt = not online and now or nil,
            })
        elseif garage and garage.rules.returnOnRestart then
            toReturn[#toReturn + 1] = row.plate
        else
            db.impound(row.plate, impoundRecord(locale('impound.reason_restart')))
        end
    end

    db.putBackAll(toReturn)
end

---@param garage Garage
---@return { bay?: integer, total: integer }
function Vehicles.spawnStatus(garage)
    return { bay = clearSpawn(garage), total = #garage.spawns }
end

Vehicles.usableGarage = usableGarage

function Vehicles.startSweep()
    SetInterval(sweepOffline, math.floor(config.sweepMinutes * 60000))
end

return Vehicles
