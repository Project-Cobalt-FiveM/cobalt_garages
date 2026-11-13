local Garage <const> = require 'shared.garage'

---@alias CreatorTab 'general' | 'location' | 'access' | 'rules'

---@class ValidationError
---@field tab CreatorTab
---@field field string
---@field message string

local TYPES <const> = {}

for _, garageType in ipairs(Garage.TYPES) do
    TYPES[garageType] = true
end

local OWNERS <const> = { player = true, fleet = true, both = true }
local MODES <const> = { ped = true, target = true, marker = true }
local CHARGE_FROM <const> = { cash_bank = true, bank = true, cash = true }
local ZONE_KINDS <const> = { none = true, box = true, poly = true }
local MAX_LIST <const> = 64

local Parse <const> = {}

---@param value any
---@param maxLength integer
---@return string
local function text(value, maxLength)
    if type(value) ~= 'string' then return '' end

    return value:gsub('^%s+', ''):gsub('%s+$', ''):sub(1, maxLength)
end

---@param value any
---@param min number
---@param max number
---@param fallback number
---@return number
local function number(value, min, max, fallback)
    if type(value) ~= 'number' or value ~= value then return fallback end

    return math.min(math.max(value, min), max)
end

---@param value any
---@param min integer
---@param max integer
---@param fallback integer
---@return integer
local function integer(value, min, max, fallback)
    return math.floor(number(value, min, max, fallback))
end

---@param value any
---@return integer?
local function optionalInteger(value)
    if type(value) ~= 'number' or value < 1 then return nil end

    return math.min(math.floor(value), 10000)
end

---@param value any
---@return Vec3
local function vec3(value)
    value = type(value) == 'table' and value or {}

    return {
        x = number(value.x, -20000, 20000, 0.0),
        y = number(value.y, -20000, 20000, 0.0),
        z = number(value.z, -500, 3000, 0.0),
    }
end

---@param value any
---@return Vec4
local function vec4(value)
    local point <const> = vec3(value) --[[@as Vec4]]

    point.w = number(type(value) == 'table' and value.w, -360, 360, 0.0) % 360.0

    return point
end

---@param value any
---@param parse fun(item: any): any
---@return any[]
local function list(value, parse)
    local result <const> = {}

    if type(value) ~= 'table' then return result end

    for _, item in ipairs(value) do
        if #result >= MAX_LIST then break end

        local parsed <const> = parse(item)

        if parsed ~= nil then result[#result + 1] = parsed end
    end

    return result
end

---@param value any
---@return string?
local function modelName(value)
    local name <const> = text(value, 50):lower()

    return name:match('^[%w_]+$') and name or nil
end

---@param value any
---@return string
function Parse.slug(value)
    local slug <const> = text(value, 64):lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')

    return slug
end

---@param value any
---@return GarageZone
local function zone(value)
    value = type(value) == 'table' and value or {}

    local kind <const> = ZONE_KINDS[value.kind] and value.kind or 'none'

    if kind == 'box' then
        local size <const> = vec3(value.size)

        return {
            kind = 'box',
            coords = vec3(value.coords),
            size = { x = math.abs(size.x), y = math.abs(size.y), z = math.abs(size.z) },
            rotation = number(value.rotation, -360, 360, 0.0),
        }
    end

    if kind == 'poly' then
        return {
            kind = 'poly',
            points = list(value.points, vec3),
            minZ = number(value.minZ, -500, 3000, 0.0),
            maxZ = number(value.maxZ, -500, 3000, 100.0),
        }
    end

    return { kind = 'none' }
end

---@param value any
---@param withDuty boolean
---@return (GarageJobRule | GarageGangRule)?
local function orgRule(value, withDuty)
    if type(value) ~= 'table' then return nil end

    local name <const> = text(value.name, 50)

    if name == '' then return nil end

    return { name = name, grade = integer(value.grade, 0, 100, 0), onDuty = withDuty and value.onDuty == true or nil }
end

---@param value any
---@return GarageAccess
local function access(value)
    value = type(value) == 'table' and value or {}

    return {
        mode = value.mode == 'locked' and 'locked' or 'everyone',
        jobs = list(value.jobs, function(item) return orgRule(item, true) end),
        gangs = list(value.gangs, function(item) return orgRule(item, false) end),
        citizens = list(value.citizens, function(item)
            if type(item) ~= 'table' or text(item.citizenid, 50) == '' then return nil end

            return { citizenid = text(item.citizenid, 50), name = text(item.name, 100) }
        end),
    }
end

---@param value any
---@param garageType GarageType
---@return GarageRules
local function rules(value, garageType)
    value = type(value) == 'table' and value or {}

    local fees <const> = type(value.fees) == 'table' and value.fees or {}

    return {
        classes = type(value.classes) == 'table' and list(value.classes, function(class)
            return type(class) == 'number' and Garage.CLASSES[class] and math.floor(class) or nil
        end) or Garage.DEFAULT_CLASSES[garageType],
        allowModels = list(value.allowModels, modelName),
        blockModels = list(value.blockModels, modelName),
        fees = {
            takeOut = integer(fees.takeOut, 0, 1000000, 0),
            store = integer(fees.store, 0, 1000000, 0),
            transferIn = integer(fees.transferIn, 0, 1000000, 0),
            release = integer(fees.release, 0, 1000000, 0),
        },
        chargeFrom = CHARGE_FROM[value.chargeFrom] and value.chargeFrom or 'cash_bank',
        payTo = text(value.payTo, 50) ~= '' and text(value.payTo, 50) or nil,
        perPlayer = optionalInteger(value.perPlayer),
        capacity = optionalInteger(value.capacity),
        returnOnRestart = value.returnOnRestart == true,
        repairOnStore = value.repairOnStore == true,
        fleetGrade = integer(value.fleetGrade, 0, 100, 0),
    }
end

---@param value any
---@return Garage
function Parse.garage(value)
    value = type(value) == 'table' and value or {}

    local garageType <const> = TYPES[value.type] and value.type or 'car'
    local garage <const> = Garage.blank(Parse.slug(value.id), text(value.label, 100), garageType)
    local blip <const> = type(value.blip) == 'table' and value.blip or {}
    local interact <const> = type(value.interact) == 'table' and value.interact or {}

    garage.enabled = value.enabled ~= false
    garage.owners = OWNERS[value.owners] and value.owners or 'player'
    garage.propertyId = garageType == 'house' and optionalInteger(value.propertyId) or nil
    garage.blip = {
        show = blip.show ~= false,
        sprite = integer(blip.sprite, 1, 900, Garage.DEFAULT_SPRITES[garageType]),
        colour = integer(blip.colour, 0, 85, 3),
        scale = number(blip.scale, 0.3, 2.0, 0.7),
    }
    garage.interact = {
        mode = MODES[interact.mode] and interact.mode or 'ped',
        coords = vec4(interact.coords),
        ped = modelName(interact.ped) or '',
        scenario = text(interact.scenario, 64),
    }
    garage.spawns = list(value.spawns, vec4)
    garage.clearRadius = number(value.clearRadius, 1.0, 15.0, 4.0)
    garage.zone = zone(value.zone)
    garage.access = access(value.access)
    garage.rules = rules(value.rules, garageType)
    garage.fleet = list(value.fleet, function(item)
        local model <const> = type(item) == 'table' and modelName(item.model)

        if not model then return nil end

        local label <const> = text(item.label, 60)

        return { model = model, label = label ~= '' and label or model }
    end)

    return garage
end

---@param garage Garage
---@return ValidationError[]
function Parse.validate(garage)
    local errors <const> = {}

    ---@param tab CreatorTab
    ---@param field string
    ---@param message string
    local function add(tab, field, message)
        errors[#errors + 1] = { tab = tab, field = field, message = message }
    end

    local point <const> = garage.interact.coords
    local isOrg <const> = garage.type == 'job' or garage.type == 'gang'

    if garage.label == '' then add('general', 'label', 'Give the garage a name players will see.') end
    if garage.id == '' then add('general', 'id', 'The ID needs at least one letter or number.') end
    if garage.interact.mode == 'ped' and garage.interact.ped == '' then
        add('general', 'ped', 'Pick a ped model, or open the garage another way.')
    end

    if garage.type == 'house' and not garage.propertyId then
        add('general', 'propertyId', 'Enter the property ID this garage belongs to.')
    end

    if point.x == 0 and point.y == 0 then
        add('location', 'interact', 'Place the interaction point. Players have nowhere to open this garage.')
    end

    if #garage.spawns == 0 then add('location', 'spawns', 'Add at least one spawn point.') end

    if garage.zone.kind == 'poly' and #garage.zone.points < 3 then
        add('location', 'zone', 'A polygon needs at least 3 points. Add one more, or set the zone to None.')
    end

    if garage.type == 'job' and #garage.access.jobs == 0 then
        add('access', 'jobs', 'Add the job whose members use this garage.')
    end

    if garage.type == 'gang' and #garage.access.gangs == 0 then
        add('access', 'gangs', 'Add the gang whose members use this garage.')
    end

    if isOrg and garage.owners ~= 'player' and #garage.fleet == 0 then
        add('rules', 'fleet', 'Add a fleet vehicle, or let members park their own cars.')
    end

    if garage.type ~= 'impound' and #garage.rules.classes == 0 and #garage.rules.allowModels == 0 then
        add('rules', 'classes', 'Tick at least one vehicle class.')
    end

    return errors
end

return Parse
