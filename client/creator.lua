local Nui <const> = require 'client.nui'
local Placement <const> = require 'client.placement'
local Garage <const> = require 'shared.garage'

local core <const> = exports.cobalt_core

---@return table?
local function snapshot()
    local data <const> = lib.callback.await('cobalt_garages:creator:open', false)

    if not data then return nil end

    data.classes = {}

    for class = 0, #Garage.CLASSES do
        data.classes[#data.classes + 1] = { id = class, label = Garage.CLASSES[class] }
    end

    data.defaultClasses = Garage.DEFAULT_CLASSES
    data.defaultSprites = Garage.DEFAULT_SPRITES

    return data
end

local function open()
    local data <const> = snapshot()

    if not data then
        core:Notify({ description = locale('creator.admins_only'), type = 'error' })

        return
    end

    Nui.open('creator', data)
end

RegisterNetEvent('cobalt_garages:client:openCreator', open)

Nui.on('creator:save', function(data)
    local result <const> = lib.callback.await('cobalt_garages:creator:save', false, data.garage, data.originalId)

    if result?.ok then
        core:Notify({ description = locale('creator.saved'), type = 'success' })
        result.snapshot = snapshot()
    end

    return result
end)

Nui.on('creator:delete', function(data)
    local ok, reason = lib.callback.await('cobalt_garages:creator:delete', false, data.id, data.moveTo)

    if not ok then
        core:Notify({ description = reason or locale('creator.delete_failed'), type = 'error' })

        return { ok = false }
    end

    core:Notify({ description = locale('creator.deleted'), type = 'success' })

    return { ok = true, snapshot = snapshot() }
end)

Nui.on('creator:check', function(data)
    return lib.callback.await('cobalt_garages:creator:check', false, data.garage, data.query)
end)

Nui.on('creator:findCitizens', function(data)
    return lib.callback.await('cobalt_garages:creator:findCitizens', false, data.query)
end)

Nui.on('creator:nearby', function()
    return lib.callback.await('cobalt_garages:creator:nearby', false)
end)

Nui.on('creator:position', function()
    local coords <const> = GetEntityCoords(cache.ped)

    return { x = coords.x, y = coords.y, z = coords.z - 1.0, w = GetEntityHeading(cache.ped) }
end)

Nui.on('creator:teleport', function(data)
    local coords <const> = data.coords

    if type(coords) ~= 'table' or type(coords.x) ~= 'number' then return false end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z + 1.0, false, false, false, false)

    return true
end)

Nui.on('creator:place', function(data)
    return Placement.run({
        kind = data.kind,
        garage = data.garage or locale('creator.new_garage'),
        index = data.index or 1,
        interact = data.interact,
        spawns = data.spawns or {},
        clearRadius = data.clearRadius or 4.0,
        heading = data.heading,
    })
end)

Nui.on('creator:preview', function(data)
    if type(data.spawn) ~= 'table' then return false end

    Placement.preview(data.spawn)

    return true
end)

Nui.on('creator:clearance', function(data)
    return Placement.clearance(data.spawns or {}, data.clearRadius or 4.0)
end)
