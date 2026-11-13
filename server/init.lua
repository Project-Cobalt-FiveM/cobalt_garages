local config <const> = require 'config'
local db <const> = require 'server.db'
local Garages <const> = require 'server.garages'
local Vehicles <const> = require 'server.vehicles'
local View <const> = require 'server.view'
local Players <const> = require 'server.players'
local Creator <const> = require 'server.creator'

---@param value any
---@return string
local function str(value)
    return type(value) == 'string' and value or ''
end

---@param value any
---@return integer
local function int(value)
    return type(value) == 'number' and math.floor(value) or 0
end

lib.callback.register('cobalt_garages:garages', function(source)
    return View.garages(source)
end)

lib.callback.register('cobalt_garages:open', function(source, garageId)
    return View.open(source, str(garageId))
end)

lib.callback.register('cobalt_garages:store', function(source, data)
    if type(data) ~= 'table' or type(data.props) ~= 'table' then return { ok = false, message = 'Nothing to store' } end

    local props <const> = data.props

    if #json.encode(props) > 16384 then return { ok = false, message = 'Nothing to store' } end

    props.modelLabel = type(data.label) == 'string' and data.label:sub(1, 60) or nil

    return Vehicles.store(source, {
        garageId = str(data.garageId),
        netId = int(data.netId),
        props = props,
    })
end)

lib.callback.register('cobalt_garages:takeOut', function(source, data)
    if type(data) ~= 'table' then return { ok = false, message = 'Nothing to take out' } end

    return Vehicles.takeOut(source, {
        garageId = str(data.garageId),
        plate = str(data.plate),
        vehicleType = str(data.vehicleType),
    })
end)

lib.callback.register('cobalt_garages:takeFleet', function(source, data)
    if type(data) ~= 'table' then return { ok = false, message = 'Nothing to take out' } end

    return Vehicles.takeFleet(source, {
        garageId = str(data.garageId),
        index = int(data.index),
        vehicleType = str(data.vehicleType),
    })
end)

lib.callback.register('cobalt_garages:transferTargets', function(source, plate)
    local row <const> = db.vehicle(str(plate))

    if not row or row.citizenid ~= Players.citizenid(source) or row.state ~= 1 then return {} end

    return Vehicles.transferTargets(source, row)
end)

lib.callback.register('cobalt_garages:transfer', function(source, data)
    if type(data) ~= 'table' then return { ok = false, message = 'Pick a garage' } end

    return Vehicles.transfer(source, { plate = str(data.plate), to = str(data.to) })
end)

lib.callback.register('cobalt_garages:release', function(source, data)
    if type(data) ~= 'table' then return { ok = false, message = 'Pick a vehicle' } end

    return Vehicles.release(source, {
        garageId = str(data.garageId),
        plate = str(data.plate),
        account = data.account == 'cash' and 'cash' or 'bank',
        vehicleType = str(data.vehicleType),
    })
end)

---@param source integer
---@return boolean
local function canImpound(source)
    local job <const> = Players.job(source)
    local rule <const> = job and config.impoundJobs[job.name]

    return rule ~= nil and job.grade >= rule.grade and (job.onDuty or not rule.onDuty)
end

lib.callback.register('cobalt_garages:canImpound', canImpound)

lib.callback.register('cobalt_garages:impound', function(source, data)
    if type(data) ~= 'table' or not canImpound(source) then
        return { ok = false, message = 'You cannot impound vehicles' }
    end

    local entity <const> = NetworkGetEntityFromNetworkId(int(data.netId))

    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then
        return { ok = false, message = 'There is no vehicle here' }
    end

    local playerCoords <const> = GetEntityCoords(GetPlayerPed(source))

    if #(GetEntityCoords(entity) - playerCoords) > 8.0 then return { ok = false, message = 'Stand next to the vehicle' } end

    for _, playerId in ipairs(GetPlayers()) do
        if GetVehiclePedIsIn(GetPlayerPed(playerId), false) == entity then
            return { ok = false, message = 'Someone is still in the vehicle' }
        end
    end

    local plate <const> = GetVehicleNumberPlateText(entity):gsub('^%s+', ''):gsub('%s+$', '')

    if not exports.cobalt_core:GetVehicleOwnerByPlate(plate) then
        Vehicles.impound(plate, entity, {})

        return { ok = true, message = 'Unowned vehicle towed' }
    end

    local reason <const> = str(data.reason):sub(1, 200)
    local hours <const> = math.min(math.max(int(data.holdHours), 0), config.maxHoldHours)
    local impounded <const> = Vehicles.impound(plate, entity, {
        lot = config.defaultImpound,
        fee = math.min(math.max(int(data.fee), 0), config.maxImpoundFee),
        reason = reason ~= '' and reason or 'Impounded by police',
        by = Players.name(source),
        holdUntil = hours > 0 and os.time() + hours * 3600 or nil,
    })

    if not impounded then return { ok = false, message = 'The vehicle could not be impounded' } end

    exports.cobalt_core:LogPlayer(source, 'garages.impounded', ('Impounded %s'):format(plate), { plate = plate, reason = reason, hours = hours })

    return { ok = true, message = ('%s sent to the impound'):format(plate) }
end)

lib.callback.register('cobalt_garages:creator:open', function(source)
    if not Players.isAdmin(source) then return nil end

    return Creator.snapshot()
end)

lib.callback.register('cobalt_garages:creator:save', function(source, payload, originalId)
    if not Players.isAdmin(source) then return { ok = false, errors = {} } end

    return Creator.save(source, payload, type(originalId) == 'string' and originalId or nil)
end)

lib.callback.register('cobalt_garages:creator:delete', function(source, id, moveTo)
    if not Players.isAdmin(source) then return false end

    return Creator.delete(source, str(id), type(moveTo) == 'string' and moveTo or nil)
end)

lib.callback.register('cobalt_garages:creator:check', function(source, payload, query)
    if not Players.isAdmin(source) or str(query) == '' then return { found = false } end

    return Creator.check(payload, str(query):sub(1, 50))
end)

lib.callback.register('cobalt_garages:creator:findCitizens', function(source, query)
    if not Players.isAdmin(source) or #str(query) < 2 then return {} end

    return Creator.findCitizens(str(query):sub(1, 50))
end)

lib.callback.register('cobalt_garages:creator:nearby', function(source)
    if not Players.isAdmin(source) then return {} end

    return Creator.nearby(source)
end)

lib.addCommand('garagecreator', { help = 'Open the garage creator' }, function(source)
    if not Players.isAdmin(source) then return end

    TriggerClientEvent('cobalt_garages:client:openCreator', source)
end)

exports('ImpoundVehicle', function(plate, reason, fee, by)
    local entry <const> = Vehicles.outEntry(plate)

    return Vehicles.impound(plate, entry and entry.entity, {
        lot = config.defaultImpound,
        fee = tonumber(fee) or config.impoundFee,
        reason = reason or 'Impounded',
        by = by or 'City',
    })
end)

exports('SpawnVehicle', function(source, plate, coords, vehicleType)
    if type(plate) ~= 'string' or type(coords) ~= 'vector4' then return nil end

    return Vehicles.spawnOut(source, plate, coords, vehicleType)
end)

CreateThread(function()
    Garages.load()
    Vehicles.reconcile()
    Vehicles.startSweep()
    TriggerClientEvent('cobalt_garages:client:changed', -1)
end)
