local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config'
local db <const> = require 'server.db'
local Garages <const> = require 'server.garages'
local Access <const> = require 'server.access'
local Players <const> = require 'server.players'
local Parse <const> = require 'server.parse'

---@class OrgOption
---@field name string
---@field label string
---@field grades { level: integer, name: string }[]

---@class CitizenMatch
---@field citizenid string
---@field name string
---@field source? integer

local Creator <const> = {}

---@param definitions table<string, { label: string, grades: table<string, { name: string }> }>
---@return OrgOption[]
local function orgOptions(definitions)
    local options <const> = {}

    for name, definition in pairs(definitions or {}) do
        local grades <const> = {}

        for level, grade in pairs(definition.grades or {}) do
            grades[#grades + 1] = { level = tonumber(level) or 0, name = grade.name }
        end

        table.sort(grades, function(a, b) return a.level < b.level end)
        options[#options + 1] = { name = name, label = definition.label or name, grades = grades }
    end

    table.sort(options, function(a, b) return a.label < b.label end)

    return options
end

---@return table
function Creator.snapshot()
    return {
        garages = Garages.all(),
        counts = db.countsByGarage(),
        totals = db.totals(),
        defaultImpound = config.defaultImpound,
        jobs = orgOptions(Cobalt.Shared.Jobs),
        gangs = orgOptions(Cobalt.Shared.Gangs),
    }
end

---@param source integer
---@param payload any
---@param originalId? string
---@return { ok: boolean, errors?: ValidationError[], id?: string }
function Creator.save(source, payload, originalId)
    local garage <const> = Parse.garage(payload)
    local errors <const> = Parse.validate(garage)
    local renamed <const> = type(originalId) == 'string' and originalId ~= '' and originalId ~= garage.id

    if not renamed and type(originalId) ~= 'string' and Garages.get(garage.id) then
        errors[#errors + 1] = { tab = 'general', field = 'id', message = 'Another garage already uses this ID.' }
    end

    if renamed then
        if Garages.get(garage.id) then
            errors[#errors + 1] = { tab = 'general', field = 'id', message = 'Another garage already uses this ID.' }
        elseif (db.countsByGarage()[originalId] or 0) > 0 then
            errors[#errors + 1] = {
                tab = 'general',
                field = 'id',
                message = 'The ID is locked because vehicles are stored here.',
            }
        end
    end

    if #errors > 0 then return { ok = false, errors = errors } end

    if renamed then Garages.delete(originalId --[[@as string]]) end

    Garages.save(garage, Players.name(source))
    exports.cobalt_core:LogPlayer(source, 'garages.saved', ('Saved garage %s'):format(garage.id), { garage = garage.id })

    return { ok = true, id = garage.id }
end

---@param source integer
---@param id string
---@param moveTo? string
---@return boolean, string?
function Creator.delete(source, id, moveTo)
    local stored <const> = db.countsByGarage()[id] or 0

    if stored > 0 and not (moveTo and Garages.get(moveTo)) then return false, 'Pick where the stored vehicles go' end
    if not Garages.delete(id, stored > 0 and moveTo or nil) then return false, 'That garage no longer exists' end

    exports.cobalt_core:LogPlayer(source, 'garages.deleted', ('Deleted garage %s'):format(id), { garage = id, movedTo = moveTo })

    return true
end

---@param query string
---@return CitizenMatch[]
function Creator.findCitizens(query)
    local needle <const> = query:lower()
    local matches <const> = {}

    for _, playerId in ipairs(Cobalt.Functions.GetPlayers()) do
        local data <const> = Players.get(playerId).PlayerData
        local name <const> = Players.name(playerId)

        if data.citizenid:lower() == needle or name:lower():find(needle, 1, true) then
            matches[#matches + 1] = { citizenid = data.citizenid, name = name, source = data.source }
        end
    end

    if #matches > 0 then return matches end

    local citizenid <const> = query:upper()
    local name <const> = exports.cobalt_core:GetName(citizenid)

    if name then
        matches[1] = { citizenid = citizenid, name = name }
    end

    return matches
end

---@param source integer
---@return CitizenMatch[]
function Creator.nearby(source)
    local coords <const> = GetEntityCoords(GetPlayerPed(source))
    local nearby <const> = {}

    for _, entry in ipairs(lib.getNearbyPlayers(coords, 10.0)) do
        local citizenid <const> = entry.id ~= source and Players.citizenid(entry.id)

        if citizenid then
            nearby[#nearby + 1] = { citizenid = citizenid, name = Players.name(entry.id), source = entry.id }
        end
    end

    return nearby
end

---@param payload any
---@param query string
---@return { found: boolean, name?: string, allowed?: boolean, reason?: string }
function Creator.check(payload, query)
    local match <const> = Creator.findCitizens(query)[1]

    if not match then return { found = false } end

    if not match.source then
        return {
            found = true,
            name = match.name,
            allowed = false,
            reason = 'Not in the city right now, so their job and duty are unknown',
        }
    end

    local result <const> = Access.check(match.source, Parse.garage(payload))

    return { found = true, name = match.name, allowed = result.allowed, reason = result.reason }
end

return Creator
