local Players <const> = require 'server.players'
local Housing <const> = require 'server.housing'
local Garage <const> = require 'shared.garage'

---@class AccessResult
---@field allowed boolean
---@field reason string

local Access <const> = {}

---@param membership OrgMembership?
---@param rules (GarageJobRule | GarageGangRule)[]
---@return (GarageJobRule | GarageGangRule)?
local function matchOrg(membership, rules)
    if not membership then return nil end

    for _, rule in ipairs(rules) do
        local dutyOk <const> = not rule.onDuty or membership.onDuty

        if rule.name == membership.name and membership.grade >= rule.grade and dutyOk then return rule end
    end
end

---@param source integer
---@param garage Garage
---@return AccessResult
function Access.check(source, garage)
    local citizenid <const> = Players.citizenid(source)

    if not citizenid then return { allowed = false, reason = 'Your character is not loaded' } end

    if Players.isAdmin(source) then return { allowed = true, reason = 'Admins can use every garage' } end

    if not garage.enabled then return { allowed = false, reason = 'This garage is closed' } end

    if garage.propertyId then
        if Housing.hasAccess(citizenid, garage.propertyId) then
            return { allowed = true, reason = 'Owns the property' }
        end

        return { allowed = false, reason = 'Only the owner can use this garage' }
    end

    if garage.access.mode == 'everyone' then return { allowed = true, reason = 'Open to everyone' } end

    local job <const> = Players.job(source)

    if matchOrg(job, garage.access.jobs) then
        local duty <const> = job.onDuty and ', on duty' or ''

        return { allowed = true, reason = ('Matched job %s, grade %d%s'):format(job.name, job.grade, duty) }
    end

    local gang <const> = Players.gang(source)

    if matchOrg(gang, garage.access.gangs) then
        return { allowed = true, reason = ('Matched gang %s, grade %d'):format(gang.name, gang.grade) }
    end

    for _, citizen in ipairs(garage.access.citizens) do
        if citizen.citizenid == citizenid then return { allowed = true, reason = 'Listed by citizen ID' } end
    end

    return { allowed = false, reason = 'No job, gang or citizen rule matches' }
end

---@param source integer
---@param garage Garage
---@return boolean
function Access.canUse(source, garage)
    return Access.check(source, garage).allowed
end

---@param source integer
---@param garage Garage
---@return boolean
function Access.canUseFleet(source, garage)
    if not garage.enabled or not Garage.holdsFleet(garage) then return false end
    if Players.isAdmin(source) then return true end

    local membership <const> = garage.type == 'job' and Players.job(source) or Players.gang(source)
    local rules <const> = garage.type == 'job' and garage.access.jobs or garage.access.gangs
    local rule <const> = matchOrg(membership, rules)

    return rule ~= nil and membership.grade >= garage.rules.fleetGrade
end

return Access
