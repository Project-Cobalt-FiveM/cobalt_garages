---@class GaragesConfig
---@field defaultImpound string
---@field impoundFee integer
---@field offlineHours number
---@field sweepMinutes number
---@field impoundJobs table<string, { grade: integer, onDuty: boolean }>
---@field maxImpoundFee integer
---@field maxHoldHours integer
---@field storeRange number
---@field houseRange number
---@field storeKey string
---@field fleetPerPlayer integer
---@field fleetPlatePrefix table<string, string>
---@field blipCategories { garage: GarageBlipCategory, impound: GarageBlipCategory }

---@class GarageBlipCategory
---@field id integer
---@field label string

---@type GaragesConfig
return {
    -- Impound
    defaultImpound = 'davis_impound', -- id in data/garages.lua of the lot impounded vehicles go to
    impoundFee = 250, -- release fee in dollars when neither the lot nor the officer sets one
    offlineHours = 8, -- hours a vehicle can stay out after its owner logs off before it is impounded
    sweepMinutes = 30, -- minutes between checks for vehicles left out by offline owners
    impoundJobs = { -- jobs that can impound vehicles: minimum grade, and whether they must be on duty
        police = { grade = 0, onDuty = true },
    },
    maxImpoundFee = 10000, -- highest fee an officer can set, in dollars
    maxHoldHours = 72, -- longest police hold an officer can set, in hours

    -- Storing vehicles
    storeRange = 30.0, -- meters from a garage's point where a vehicle can be stored
    houseRange = 12.0, -- the same for property garages
    storeKey = 'E', -- default key to store a vehicle from the driver seat inside a store zone; players can rebind it in GTA settings

    -- Job fleet vehicles
    fleetPerPlayer = 2, -- fleet vehicles one character can have out at once
    fleetPlatePrefix = { -- plate prefix per job; other jobs use FLEET
        police = 'LSPD',
        ambulance = 'EMS',
    },

    -- Map legend groups for the blips
    blipCategories = {
        garage = { id = 13, label = 'Garages' },
        impound = { id = 15, label = 'Impound' },
    },
}
