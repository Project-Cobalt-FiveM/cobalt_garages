local db <const> = require 'server.db'
local Garage <const> = require 'shared.garage'
local Garages <const> = require 'server.garages'
local Access <const> = require 'server.access'
local Players <const> = require 'server.players'
local Housing <const> = require 'server.housing'
local Vehicles <const> = require 'server.vehicles'

---@alias VehicleStatus 'here' | 'elsewhere' | 'out' | 'impounded'

---@class VehicleView
---@field plate string
---@field model string
---@field status VehicleStatus
---@field location? string
---@field drivenByYou boolean
---@field fuel number
---@field engine number
---@field body number
---@field class? integer
---@field parkedAt? integer
---@field mileage? integer
---@field fee integer
---@field impoundedAt? integer
---@field impoundReason? string
---@field holdUntil? integer

local View <const> = {}

---@param garage Garage
---@param row OwnedVehicleRow
---@return VehicleStatus
local function statusOf(garage, row)
    if row.state == 2 then return 'impounded' end
    if row.state == 0 then return 'out' end

    return row.garage == garage.id and 'here' or 'elsewhere'
end

---@type table<string, string>
local labelCache <const> = {}

---@param id? string
---@return string?
local function garageLabel(id)
    if not id then return nil end

    local garage <const> = Garages.get(id)

    if garage then labelCache[id] = garage.label end

    return labelCache[id]
end

---@param garage Garage
---@param row OwnedVehicleRow
---@param drivenPlate? string
---@return VehicleView
local function vehicleView(garage, row, drivenPlate)
    return {
        plate = row.plate,
        model = row.model,
        status = statusOf(garage, row),
        location = garageLabel(row.garage),
        drivenByYou = drivenPlate == row.plate,
        fuel = row.fuel or 100,
        engine = row.engine or 1000,
        body = row.body or 1000,
        class = row.class,
        parkedAt = row.parkedAt,
        mileage = row.mileage,
        fee = row.state == 2 and row.depotprice or garage.rules.fees.takeOut,
        impoundedAt = row.impoundedAt,
        impoundReason = row.impoundReason,
        holdUntil = row.holdUntil,
    }
end

---@param source integer
---@param garageId string
---@return table?, string?
function View.open(source, garageId)
    local garage, reason = Vehicles.usableGarage(source, garageId)

    if not garage then return nil, reason end

    local citizenid <const> = Players.citizenid(source) --[[@as string]]
    local isImpound <const> = garage.type == 'impound'
    local vehicles <const> = {}
    local _, drivenPlate = Vehicles.drivenBy(source)

    if Garage.holdsPlayerCars(garage) or isImpound then
        for _, row in ipairs(db.ownedVehicles(citizenid)) do
            if not isImpound or (row.state == 2 and row.garage == garage.id) then
                vehicles[#vehicles + 1] = vehicleView(garage, row, drivenPlate)
            end
        end
    end

    local fleet <const> = {}

    if Access.canUseFleet(source, garage) then
        for index, vehicle in ipairs(garage.fleet) do
            fleet[#fleet + 1] = { index = index, model = vehicle.model, label = vehicle.label }
        end

        for index, vehicle in ipairs(Vehicles.boughtFleet(source, garage)) do
            fleet[#fleet + 1] = { index = #garage.fleet + index, model = vehicle.model, label = ('%s, %s'):format(vehicle.label, vehicle.plate) }
        end
    end

    return {
        id = garage.id,
        label = garage.label,
        type = garage.type,
        owners = garage.owners,
        isHouse = garage.propertyId ~= nil,
        fees = garage.rules.fees,
        chargeFrom = garage.rules.chargeFrom,
        spawn = Vehicles.spawnStatus(garage),
        vehicles = vehicles,
        fleet = fleet,
        balances = Players.balances(source),
        now = os.time(),
    }
end

---@param source integer
---@return table[]
function View.garages(source)
    local citizenid <const> = Players.citizenid(source)
    local isAdmin <const> = Players.isAdmin(source)
    local list <const> = {}

    if not citizenid then return list end

    ---@param garage Garage
    ---@param canUse boolean
    local function add(garage, canUse)
        list[#list + 1] = {
            id = garage.id,
            label = garage.label,
            type = garage.type,
            canUse = canUse,
            storesHere = Garage.holdsPlayerCars(garage) or Garage.holdsFleet(garage),
            blip = garage.blip,
            interact = garage.interact,
            zone = garage.zone,
            classes = garage.rules.classes,
        }
    end

    for _, garage in ipairs(Garages.all()) do
        if garage.enabled or isAdmin then add(garage, Access.canUse(source, garage)) end
    end

    for _, garage in ipairs(Housing.owned(citizenid)) do
        add(garage, true)
    end

    return list
end

return View
