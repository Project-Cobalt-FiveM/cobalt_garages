local Nui <const> = require 'client.nui'
local Vehicle <const> = require 'client.vehicle'

local core <const> = exports.cobalt_core

local Menu <const> = {}

---@type string?
local openGarage

---@param result? { ok: boolean, message: string, title?: string }
local function report(result)
    if not result then return end

    core:Notify({ title = result.title, description = result.message, type = result.ok and 'success' or 'error' })
end

---@param garageId string
---@return table?
local function load(garageId)
    local data, reason = lib.callback.await('cobalt_garages:open', false, garageId)

    if not data then
        if reason then core:Notify({ description = reason, type = 'error' }) end

        return nil
    end

    for _, vehicle in ipairs(data.vehicles) do
        local info <const> = Vehicle.describe(vehicle.model)

        vehicle.label = info.label
        vehicle.class = vehicle.class or info.class
        vehicle.classLabel = info.classLabel
        vehicle.seats = info.seats
    end

    for _, vehicle in ipairs(data.fleet) do
        local info <const> = Vehicle.describe(vehicle.model)

        vehicle.classLabel = info.classLabel
        vehicle.seats = info.seats
    end

    local candidate <const> = Vehicle.candidate()

    data.store = candidate and { label = Vehicle.labelOf(candidate) } or nil

    return data
end

---@param garageId string
function Menu.open(garageId)
    local data <const> = load(garageId)

    if not data then return end

    openGarage = garageId
    Nui.open('garage', data)
end

---@return boolean
local function refresh()
    if not openGarage then return false end

    local data <const> = load(openGarage)

    if data then Nui.send('garage', data) end

    return data ~= nil
end

---@param garageId string
---@return { ok: boolean, message: string, title?: string }
function Menu.store(garageId)
    local entity <const> = Vehicle.candidate()

    if not entity then return { ok = false, message = 'Drive your vehicle to the garage first' } end

    local payload <const> = Vehicle.capture(entity)

    payload.garageId = garageId
    Vehicle.leave(entity)

    return lib.callback.await('cobalt_garages:store', false, payload)
end

---@param result { ok: boolean, message: string }
---@return { ok: boolean, message: string }
local function closeOnSuccess(result)
    report(result)

    if result.ok then
        openGarage = nil
        Nui.close()
    end

    return result
end

Nui.on('garage:store', function()
    if not openGarage then return false end

    local result <const> = Menu.store(openGarage)

    report(result)
    refresh()

    return result
end)

Nui.on('garage:takeOut', function(data)
    if not openGarage or type(data.plate) ~= 'string' or type(data.model) ~= 'string' then return false end

    return closeOnSuccess(lib.callback.await('cobalt_garages:takeOut', false, {
        garageId = openGarage,
        plate = data.plate,
        vehicleType = Vehicle.describe(data.model).vehicleType,
    }))
end)

Nui.on('garage:takeFleet', function(data)
    if not openGarage or type(data.index) ~= 'number' or type(data.model) ~= 'string' then return false end

    return closeOnSuccess(lib.callback.await('cobalt_garages:takeFleet', false, {
        garageId = openGarage,
        index = data.index,
        vehicleType = Vehicle.describe(data.model).vehicleType,
    }))
end)

Nui.on('garage:release', function(data)
    if not openGarage or type(data.plate) ~= 'string' or type(data.model) ~= 'string' then return false end

    return closeOnSuccess(lib.callback.await('cobalt_garages:release', false, {
        garageId = openGarage,
        plate = data.plate,
        account = data.account,
        vehicleType = Vehicle.describe(data.model).vehicleType,
    }))
end)

Nui.on('garage:transferTargets', function(data)
    return lib.callback.await('cobalt_garages:transferTargets', false, data.plate) or {}
end)

Nui.on('garage:transfer', function(data)
    local result <const> = lib.callback.await('cobalt_garages:transfer', false, { plate = data.plate, to = data.to })

    report(result)
    refresh()

    return result
end)

Nui.on('garage:close', function()
    openGarage = nil
    Nui.close()

    return true
end)

return Menu
