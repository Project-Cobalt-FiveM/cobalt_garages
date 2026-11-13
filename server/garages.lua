local db <const> = require 'server.db'
local Garage <const> = require 'shared.garage'
local Housing <const> = require 'server.housing'

local Garages <const> = {}

---@type table<string, Garage>
local registry <const> = {}

local TOP_LEVEL <const> = { id = true, label = true, type = true, enabled = true, updatedBy = true, updatedAt = true }

---@param base table
---@param patch table
---@return table
local function merge(base, patch)
    for key, value in pairs(patch) do
        if type(value) == 'table' and table.type(value) == 'hash' and type(base[key]) == 'table' then
            merge(base[key], value)
        else
            base[key] = value
        end
    end

    return base
end

---@param id string
---@param label string
---@param garageType GarageType
---@param data table
---@return Garage
local function build(id, label, garageType, data)
    return merge(Garage.blank(id, label, garageType), data)
end

---@param garage Garage
---@return table
local function payload(garage)
    local data <const> = {}

    for key, value in pairs(garage) do
        if not TOP_LEVEL[key] then data[key] = value end
    end

    return data
end

local SEEDED_KEY <const> = 'seeded'

local function seed()
    for _, entry in ipairs(lib.load('data.garages') or {}) do
        local garage <const> = build(entry.id, entry.label, entry.type, entry)
        db.saveGarage(garage, payload(garage), 'seed')
    end
end

function Garages.load()
    if GetResourceKvpInt(SEEDED_KEY) == 0 then
        if db.garageCount() == 0 then seed() end

        SetResourceKvpInt(SEEDED_KEY, 1)
    end

    table.wipe(registry)

    for _, row in ipairs(db.garages()) do
        local ok, data = pcall(json.decode, row.data)
        local garage <const> = build(row.id, row.label, row.type, ok and type(data) == 'table' and data or {})

        garage.enabled = row.enabled == true or row.enabled == 1
        garage.updatedBy = row.updatedBy
        garage.updatedAt = row.updatedAt
        registry[garage.id] = garage
    end
end

---@param id string
---@return Garage?
function Garages.get(id)
    return registry[id] or Housing.garage(id)
end

---@return Garage[]
function Garages.all()
    local list <const> = {}

    for _, garage in pairs(registry) do
        list[#list + 1] = garage
    end

    table.sort(list, function(a, b) return a.label < b.label end)

    return list
end

---@param garage Garage
---@param by string
function Garages.save(garage, by)
    db.saveGarage(garage, payload(garage), by)
    garage.updatedBy = by
    garage.updatedAt = os.time()
    registry[garage.id] = garage
    TriggerClientEvent('cobalt_garages:client:changed', -1)
end

---@param id string
---@param moveTo? string
---@return boolean
function Garages.delete(id, moveTo)
    if not registry[id] then return false end

    local target <const> = moveTo and registry[moveTo]

    if target then db.moveGarage(id, target.id, target.type == 'impound') end

    db.deleteGarage(id)
    registry[id] = nil
    TriggerClientEvent('cobalt_garages:client:changed', -1)

    return true
end

return Garages
