local Garage <const> = require 'shared.garage'

---@class ModelInfo
---@field label string
---@field class integer
---@field classLabel string
---@field seats integer
---@field vehicleType string

local CANDIDATE_RANGE <const> = 15.0

local Vehicle <const> = {}

---@type table<string, ModelInfo>
local described <const> = {}

---@param hash integer
---@return string
local function vehicleType(hash)
    if IsThisModelABoat(hash) or IsThisModelAJetski(hash) then return 'boat' end
    if IsThisModelAHeli(hash) then return 'heli' end
    if IsThisModelAPlane(hash) then return 'plane' end
    if IsThisModelABike(hash) or IsThisModelABicycle(hash) then return 'bike' end
    if IsThisModelATrain(hash) then return 'train' end

    return 'automobile'
end

---@param model string
---@return ModelInfo
function Vehicle.describe(model)
    if described[model] then return described[model] end

    local hash <const> = tonumber(model) or joaat(model)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(hash))

    if not IsModelInCdimage(hash) then
        described[model] = {
            label = model,
            class = 0,
            classLabel = locale('class.unknown'),
            seats = 0,
            vehicleType = 'automobile',
        }

        return described[model]
    end

    local class <const> = GetVehicleClassFromName(hash)
    local make <const> = GetLabelText(GetMakeNameFromVehicleModel(hash))

    if label == 'NULL' then label = model end
    if make ~= 'NULL' and make ~= '' then label = ('%s %s'):format(make, label) end

    described[model] = {
        label = label,
        class = class,
        classLabel = Garage.CLASSES[class] or locale('class.generic'),
        seats = GetVehicleModelNumberOfSeats(hash),
        vehicleType = vehicleType(hash),
    }

    return described[model]
end

---@param entity integer
---@return string
function Vehicle.labelOf(entity)
    return Vehicle.describe(tostring(GetEntityModel(entity))).label
end

---@return integer?
function Vehicle.candidate()
    if cache.vehicle and cache.seat == -1 then return cache.vehicle end

    local last <const> = GetVehiclePedIsIn(cache.ped, true)

    if last == 0 or not DoesEntityExist(last) then return nil end
    if #(GetEntityCoords(last) - GetEntityCoords(cache.ped)) > CANDIDATE_RANGE then return nil end

    return last
end

---@param entity integer
function Vehicle.leave(entity)
    if cache.vehicle ~= entity then return end

    TaskLeaveVehicle(cache.ped, entity, 0)

    pcall(lib.waitFor, function()
        if not IsPedInAnyVehicle(cache.ped, false) then return true end
    end, nil, 3000)
end

---@param entity integer
---@return { netId: integer, props: table, label: string }
function Vehicle.capture(entity)
    return {
        netId = NetworkGetNetworkIdFromEntity(entity),
        props = lib.getVehicleProperties(entity) or {},
        label = Vehicle.labelOf(entity),
    }
end

return Vehicle
