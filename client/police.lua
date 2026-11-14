local config <const> = require 'config'

local core <const> = exports.cobalt_core

local allowed = false

local function refresh()
    allowed = lib.callback.await('cobalt_garages:canImpound', false) == true
end

---@param entity integer
local function impound(entity)
    local values <const> = core:InputDialog(locale('impound.dialog_title'), {
        {
            type = 'input',
            label = locale('impound.reason'),
            placeholder = locale('impound.reason_placeholder'),
            required = true,
        },
        {
            type = 'number',
            label = locale('impound.fee'),
            default = config.impoundFee,
            min = 0,
            max = config.maxImpoundFee,
            prefix = '$',
        },
        { type = 'number', label = locale('impound.hold'), default = 0, min = 0, max = config.maxHoldHours },
    }, { submitText = locale('impound.submit') })

    if not values then return end

    local towed <const> = core:Progressbar({
        label = locale('impound.progress'),
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

    local title <const> = locale('impound.title')

    if not result then
        return core:Notify({ title = title, description = locale('impound.no_answer'), type = 'error' })
    end

    core:Notify({ title = title, description = result.message, type = result.ok and 'success' or 'error' })
end

if GetResourceState('ox_target') == 'started' then
    exports.ox_target:addGlobalVehicle({
        {
            name = 'cobalt_garages:impound',
            label = locale('impound.target'),
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
