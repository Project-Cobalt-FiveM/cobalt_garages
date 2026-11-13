---@meta

---@alias GaragesType 'car'|'boat'|'air'|'job'|'gang'|'house'|'impound'
---@alias GaragesOwners 'player'|'fleet'|'both'
---@alias GaragesInteractMode 'ped'|'target'|'marker'
---@alias GaragesChargeFrom 'cash_bank'|'bank'|'cash'

---@class GaragesVec3
---@field x number
---@field y number
---@field z number

---@class GaragesVec4 : GaragesVec3
---@field w number

---@class GaragesBlip
---@field show boolean
---@field sprite integer
---@field colour integer
---@field scale number

---@class GaragesInteract
---@field mode GaragesInteractMode
---@field coords GaragesVec4
---@field ped string
---@field scenario string

---@class GaragesZone
---@field kind 'none'|'box'|'poly'
---@field points? GaragesVec3[]
---@field minZ? number
---@field maxZ? number
---@field coords? GaragesVec3
---@field size? GaragesVec3
---@field rotation? number

---@class GaragesJobRule
---@field name string
---@field grade integer
---@field onDuty boolean

---@class GaragesGangRule
---@field name string
---@field grade integer

---@class GaragesCitizen
---@field citizenid string
---@field name string

---@class GaragesAccess
---@field mode 'everyone'|'locked'
---@field jobs GaragesJobRule[]
---@field gangs GaragesGangRule[]
---@field citizens GaragesCitizen[]

---@class GaragesFees
---@field takeOut integer
---@field store integer
---@field transferIn integer
---@field release integer

---@class GaragesRules
---@field classes integer[]
---@field allowModels string[]
---@field blockModels string[]
---@field fees GaragesFees
---@field chargeFrom GaragesChargeFrom
---@field payTo? string
---@field perPlayer? integer
---@field capacity? integer
---@field returnOnRestart boolean
---@field repairOnStore boolean
---@field fleetGrade integer

---@class GaragesFleetVehicle
---@field model string
---@field label string

---@class GaragesGarage
---@field id string
---@field label string
---@field type GaragesType
---@field enabled boolean
---@field owners GaragesOwners
---@field propertyId? integer
---@field blip GaragesBlip
---@field interact GaragesInteract
---@field spawns GaragesVec4[]
---@field clearRadius number
---@field zone GaragesZone
---@field access GaragesAccess
---@field rules GaragesRules
---@field fleet GaragesFleetVehicle[]
---@field updatedBy? string
---@field updatedAt? integer

---@class CobaltGaragesExports
local CobaltGaragesExports = {}

---**Server.** Sends an owned vehicle to the default impound; true when it was impounded.
---@param plate string
---@param reason? string default 'Impounded'
---@param fee? integer default from config
---@param by? string default 'City'
---@return boolean
function CobaltGaragesExports:ImpoundVehicle(plate, reason, fee, by) end

---**Server.** Spawns an owned vehicle that is out of its garage (`state = 0`) at `coords`, seats its owner `source` in it with keys and tracks it like a garage takeout. Returns the entity, or nil when the row is not out, belongs to someone else, is already in the world or failed to spawn.
---@param source integer
---@param plate string
---@param coords vector4
---@param vehicleType? string default 'automobile', used when the vehicle has never been parked
---@return integer?
function CobaltGaragesExports:SpawnVehicle(source, plate, coords, vehicleType) end

exports.cobalt_garages = CobaltGaragesExports
