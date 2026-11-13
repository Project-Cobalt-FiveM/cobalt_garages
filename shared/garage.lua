---@alias GarageType 'car' | 'boat' | 'air' | 'job' | 'gang' | 'house' | 'impound'
---@alias GarageOwners 'player' | 'fleet' | 'both'
---@alias InteractMode 'ped' | 'target' | 'marker'
---@alias ChargeFrom 'cash_bank' | 'bank' | 'cash'

---@class Vec3
---@field x number
---@field y number
---@field z number

---@class Vec4 : Vec3
---@field w number

---@class GarageBlip
---@field show boolean
---@field sprite integer
---@field colour integer
---@field scale number

---@class GarageInteract
---@field mode InteractMode
---@field coords Vec4
---@field ped string
---@field scenario string

---@class GarageZone
---@field kind 'none' | 'box' | 'poly'
---@field points? Vec3[]
---@field minZ? number
---@field maxZ? number
---@field coords? Vec3
---@field size? Vec3
---@field rotation? number

---@class GarageJobRule
---@field name string
---@field grade integer
---@field onDuty boolean

---@class GarageGangRule
---@field name string
---@field grade integer

---@class GarageCitizen
---@field citizenid string
---@field name string

---@class GarageAccess
---@field mode 'everyone' | 'locked'
---@field jobs GarageJobRule[]
---@field gangs GarageGangRule[]
---@field citizens GarageCitizen[]

---@class GarageFees
---@field takeOut integer
---@field store integer
---@field transferIn integer
---@field release integer

---@class GarageRules
---@field classes integer[]
---@field allowModels string[]
---@field blockModels string[]
---@field fees GarageFees
---@field chargeFrom ChargeFrom
---@field payTo? string
---@field perPlayer? integer
---@field capacity? integer
---@field returnOnRestart boolean
---@field repairOnStore boolean
---@field fleetGrade integer

---@class GarageFleetVehicle
---@field model string
---@field label string

---@class Garage
---@field id string
---@field label string
---@field type GarageType
---@field enabled boolean
---@field owners GarageOwners
---@field propertyId? integer
---@field blip GarageBlip
---@field interact GarageInteract
---@field spawns Vec4[]
---@field clearRadius number
---@field zone GarageZone
---@field access GarageAccess
---@field rules GarageRules
---@field fleet GarageFleetVehicle[]
---@field updatedBy? string
---@field updatedAt? integer

local Garage <const> = {}

Garage.TYPES = { 'car', 'boat', 'air', 'job', 'gang', 'house', 'impound' }

Garage.CLASSES = {
    [0] = 'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports classics', 'Sports', 'Super', 'Motorcycles',
    'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats', 'Helicopters', 'Planes', 'Service', 'Emergency',
    'Military', 'Commercial', 'Trains', 'Open wheel',
}

local LAND <const> = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 18, 19, 20, 22 }

---@type table<GarageType, integer[]>
Garage.DEFAULT_CLASSES = {
    car = LAND,
    job = LAND,
    gang = LAND,
    house = LAND,
    boat = { 14 },
    air = { 15, 16 },
    impound = {},
}

---@type table<GarageType, integer>
Garage.DEFAULT_SPRITES = { car = 357, job = 357, gang = 357, house = 357, boat = 356, air = 359, impound = 68 }

---@param vehicleType string
---@param class integer
---@return boolean
function Garage.classMatchesType(vehicleType, class)
    if vehicleType == 'boat' or vehicleType == 'submarine' then return class == 14 end
    if vehicleType == 'heli' then return class == 15 end
    if vehicleType == 'plane' then return class == 16 end
    if vehicleType == 'train' then return class == 21 end

    return class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21
end

---@param garage Garage
---@param model string
---@param class integer
---@return boolean
function Garage.fits(garage, model, class)
    model = model:lower()

    for _, blocked in ipairs(garage.rules.blockModels) do
        if blocked == model then return false end
    end

    for _, allowed in ipairs(garage.rules.allowModels) do
        if allowed == model then return true end
    end

    if garage.type == 'impound' then return true end

    for _, allowed in ipairs(garage.rules.classes) do
        if allowed == class then return true end
    end

    return false
end

---@param garage Garage
---@return boolean
function Garage.holdsPlayerCars(garage)
    return garage.owners ~= 'fleet' and garage.type ~= 'impound'
end

---@param garage Garage
---@return boolean
function Garage.holdsFleet(garage)
    return (garage.type == 'job' or garage.type == 'gang') and garage.owners ~= 'player' and #garage.fleet > 0
end

---@param id string
---@param label string
---@param type GarageType
---@return Garage
function Garage.blank(id, label, type)
    return {
        id = id,
        label = label,
        type = type,
        enabled = true,
        owners = 'player',
        blip = { show = true, sprite = Garage.DEFAULT_SPRITES[type], colour = 3, scale = 0.7 },
        interact = {
            mode = 'ped',
            coords = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
            ped = 's_m_y_valet_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {},
        clearRadius = 4.0,
        zone = { kind = 'none' },
        access = { mode = 'everyone', jobs = {}, gangs = {}, citizens = {} },
        rules = {
            classes = Garage.DEFAULT_CLASSES[type],
            allowModels = {},
            blockModels = {},
            fees = { takeOut = 0, store = 0, transferIn = 0, release = 0 },
            chargeFrom = 'cash_bank',
            returnOnRestart = false,
            repairOnStore = false,
            fleetGrade = 0,
        },
        fleet = {},
    }
end

return Garage
