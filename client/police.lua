local config <const> = require 'config'

local core <const> = exports.cobalt_core

local allowed = false

local function refresh()
    allowed = lib.callback.await('cobalt_garages:canImpound', false) == true
end

---@param entity integer
local function impound(entity)
    local values <const> = core:InputDialog('Impound vehicle', {
        { type = 'input', label = 'Reason', placeholder = 'Parked on the sidewalk', required = true },
        {
            type = 'number',
            label = 'Release fee',
            default = config.impoundFee,
            min = 0,
            max = config.maxImpoundFee,
            prefix = '$',
        },
        { type = 'number', label = 'Police hold (hours)', default = 0, min = 0, max = config.maxHoldHours },
    }, { submitText = 'Impound' })

    if not values then return end

    local towed <const> = core:Progressbar({
        label = 'Calling the tow truck',
        duration = 5000,
        disable = { move = true, car = true, combat = true },
        anim = { scenario = 'WORLD_HUMAN_CLIPBOARD' },
    })

    if not towed or not DoesEntityExist(entity) then return end

    local result <const> = lib.callback.await('cobalt_garages:impound', false, {
        netId = NetworkGetNetworkIdFromEntity(entity),
        reason = values[1],
        fee = values[2] or 0,
        holdHours = values[3] or 0,
    })

    if not result then return core:Notify({ title = 'Impound', description = 'The impound did not answer', type = 'error' }) end

    core:Notify({ title = 'Impound', description = result.message, type = result.ok and 'success' or 'error' })
end

if GetResourceState('ox_target') == 'started' then
    exports.ox_target:addGlobalVehicle({
        {
            name = 'cobalt_garages:impound',
            label = 'Impound vehicle',
            icon = 'fas fa-truck-pickup',
            distance = 3.0,
            canInteract = function(entity)
                return allowed and not cache.vehicle and NetworkGetEntityIsNetworked(entity)
            end,
            onSelect = function(data)
                impound(data.entity)
            end,
        },
    })
end

local refreshTicket = 0

local function refreshSoon()
    refreshTicket += 1

    local ticket <const> = refreshTicket

    SetTimeout(250, function()
        if ticket == refreshTicket then refresh() end
    end)
end

RegisterNetEvent('cobalt_management:membershipChanged', refreshSoon)

RegisterNetEvent('cobalt_core:Client:OnPlayerLoaded', refresh)

CreateThread(refresh)
