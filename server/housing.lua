local Garage <const> = require 'shared.garage'

local PREFIX <const> = 'property_'

local Housing <const> = {}

---@return boolean
local function started()
    return GetResourceState('cobalt_housing') == 'started'
end

---@param property { id: integer, name: string, garage?: vector4 }
---@return Garage?
local function fromProperty(property)
    local spot <const> = property.garage

    if not spot then return nil end

    local garage <const> = Garage.blank(PREFIX .. property.id, property.name, 'house')
    local point <const> = { x = spot.x, y = spot.y, z = spot.z, w = spot.w }

    garage.propertyId = property.id
    garage.blip.show = false
    garage.interact = { mode = 'marker', coords = point, ped = '', scenario = '' }
    garage.spawns = { point }
    garage.access.mode = 'locked'

    return garage
end

---@param id string
---@return Garage?
function Housing.garage(id)
    local propertyId <const> = tonumber(id:match('^' .. PREFIX .. '(%d+)$'))

    if not propertyId or not started() then return nil end

    local property <const> = exports.cobalt_housing:GetProperty(propertyId)

    return property and fromProperty(property)
end

---@param citizenid string
---@return Garage[]
function Housing.owned(citizenid)
    if not started() then return {} end

    local garages <const> = {}

    for _, property in ipairs(exports.cobalt_housing:GetOwnedProperties(citizenid) or {}) do
        garages[#garages + 1] = fromProperty(property)
    end

    return garages
end

---@param citizenid string
---@param propertyId integer
---@return boolean
function Housing.hasAccess(citizenid, propertyId)
    return started() and exports.cobalt_housing:HasAccess(citizenid, propertyId) == true
end

return Housing
