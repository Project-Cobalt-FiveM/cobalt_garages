local config <const> = require 'config'
local Zone <const> = require 'shared.zone'
local Menu <const> = require 'client.menu'
local Vehicle <const> = require 'client.vehicle'

---@class ClientGarage
---@field id string
---@field label string
---@field type GarageType
---@field canUse boolean
---@field storesHere boolean
---@field blip GarageBlip
---@field interact GarageInteract
---@field zone GarageZone
---@field classes integer[]

---@class GarageHandles
---@field blip? integer
---@field point? CPoint
---@field ped? integer
---@field targetZone? integer
---@field groundZ? number
---@field near? boolean

local PED_RANGE <const> = 40.0
local MARKER_RANGE <const> = 12.0
local MARKER_REACH <const> = 2.0
local COBALT <const> = { 80, 120, 215 }
local INTERACT <const> = 38
local GROUND_PROBE <const> = 1.0
local PAD_LIFT <const> = 0.03
local ICON_LIFT <const> = 0.6

local core <const> = exports.cobalt_core
local hasTarget <const> = GetResourceState('ox_target') == 'started'

---@type ClientGarage[]
local garages = {}

---@type table<string, GarageHandles>
local handles <const> = {}

local generation = 0

local textShown = false

---@param text? string
local function setText(text)
    if text and not textShown then
        core:ShowTextUI(text)
    elseif not text and textShown then
        core:HideTextUI()
    end

    textShown = text ~= nil
end

---@param point Vec3
---@return vector3
local function vec(point)
    return vector3(point.x, point.y, point.z)
end

for name, category in pairs(config.blipCategories) do
    AddTextEntry(('BLIP_CAT_%d'):format(category.id), locale(('garage.blip_%s'):format(name)))
end

---@param garage ClientGarage
---@return integer
local function createBlip(garage)
    local coords <const> = garage.interact.coords
    local blip <const> = AddBlipForCoord(coords.x, coords.y, coords.z)
    local category <const> = garage.type == 'impound' and config.blipCategories.impound or config.blipCategories.garage

    SetBlipSprite(blip, garage.blip.sprite)
    SetBlipColour(blip, garage.blip.colour)
    SetBlipScale(blip, garage.blip.scale)
    SetBlipAsShortRange(blip, true)
    SetBlipCategory(blip, category.id)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(garage.label)
    EndTextCommandSetBlipName(blip)

    return blip
end

---@param garage ClientGarage
---@return table[]
local function targetOptions(garage)
    return {
        {
            name = 'cobalt_garages:open',
            label = locale(garage.type == 'impound' and 'garage.open_impound' or 'garage.open_garage'),
            icon = 'fas fa-warehouse',
            distance = 2.5,
            onSelect = function()
                Menu.open(garage.id)
            end,
        },
    }
end

---@param garage ClientGarage
---@param handle GarageHandles
---@return number
local function groundZ(garage, handle)
    if handle.groundZ then return handle.groundZ end

    local coords <const> = garage.interact.coords
    local found <const>, ground <const> = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + GROUND_PROBE, false)

    if not found then return coords.z end

    handle.groundZ = ground

    return ground
end

---@param garage ClientGarage
---@param handle GarageHandles
local function spawnPed(garage, handle)
    local coords <const> = garage.interact.coords
    local model <const> = joaat(garage.interact.ped)

    if not IsModelInCdimage(model) then return end

    local built <const> = generation

    lib.requestModel(model)

    if built ~= generation or not handle.near or handle.ped then return SetModelAsNoLongerNeeded(model) end

    local ped <const> = CreatePed(4, model, coords.x, coords.y, groundZ(garage, handle), coords.w, false, true)

    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if garage.interact.scenario ~= '' then TaskStartScenarioInPlace(ped, garage.interact.scenario, 0, true) end

    handle.ped = ped

    if hasTarget then exports.ox_target:addLocalEntity(ped, targetOptions(garage)) end
end

---@param handle GarageHandles
local function removePed(handle)
    if not handle.ped then return end

    if hasTarget then exports.ox_target:removeLocalEntity(handle.ped, 'cobalt_garages:open') end

    DeleteEntity(handle.ped)
    handle.ped = nil
end

---@param garage ClientGarage
---@param handle GarageHandles
---@param point CPoint
local function drawMarker(garage, handle, point)
    local coords <const> = garage.interact.coords
    local z <const> = groundZ(garage, handle)

    DrawMarker(
        25,
        coords.x, coords.y, z + PAD_LIFT,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.2, 1.2, 1.0,
        COBALT[1], COBALT[2], COBALT[3], 255,
        false, false, 2, false, nil, nil, false
    )
    DrawMarker(
        36,
        coords.x, coords.y, z + ICON_LIFT,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.5, 0.5, 0.5,
        COBALT[1], COBALT[2], COBALT[3], 255,
        false, true, 2, false, nil, nil, false
    )

    if cache.vehicle then return end

    local inReach <const> = point.currentDistance <= MARKER_REACH

    setText(inReach and locale('garage.open_prompt', garage.label) or nil)

    if inReach and IsControlJustReleased(0, INTERACT) then Menu.open(garage.id) end
end

---@param garage ClientGarage
---@return GarageHandles
local function build(garage)
    local handle <const> = {}
    local mode = garage.interact.mode
    local coords <const> = vec(garage.interact.coords)

    if garage.blip.show and garage.canUse then handle.blip = createBlip(garage) end

    if not garage.canUse then return handle end

    if not hasTarget then mode = 'marker' end

    if mode == 'ped' and garage.interact.ped ~= '' then
        handle.point = lib.points.new({
            coords = coords,
            distance = PED_RANGE,
            onEnter = function()
                handle.near = true
                spawnPed(garage, handle)
            end,
            onExit = function()
                handle.near = false
                removePed(handle)
            end,
        })
    elseif mode == 'target' and hasTarget then
        handle.targetZone = exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.5,
            options = targetOptions(garage),
        })
    else
        handle.point = lib.points.new({
            coords = coords,
            distance = MARKER_RANGE,
            nearby = function(point) drawMarker(garage, handle, point) end,
            onExit = function() setText(nil) end,
        })
    end

    return handle
end

---@param handle GarageHandles
local function destroy(handle)
    if handle.blip then RemoveBlip(handle.blip) end
    if handle.point then handle.point:remove() end
    if handle.targetZone then exports.ox_target:removeZone(handle.targetZone) end

    removePed(handle)
end

local function clear()
    generation += 1

    for _, handle in pairs(handles) do
        destroy(handle)
    end

    table.wipe(handles)
    setText(nil)
end

local function refresh()
    local list <const> = lib.callback.await('cobalt_garages:garages', false)

    if not list then return end

    clear()
    garages = list

    for _, garage in ipairs(garages) do
        handles[garage.id] = build(garage)
    end
end

---@param coords vector3
---@return ClientGarage?
local function storeZoneAt(coords)
    for _, garage in ipairs(garages) do
        local usable <const> = garage.canUse and garage.storesHere and garage.type ~= 'impound'

        if usable and (Zone.contains(garage.zone, coords) or #(coords - vec(garage.interact.coords)) <= 6.0) then
            return garage
        end
    end
end

---@type ClientGarage?
local zoneGarage

local storeKeybind <const> = lib.addKeybind({
    name = 'cobalt_garages_store',
    description = locale('garage.store_keybind'),
    defaultKey = config.storeKey,
    disabled = true,
    onReleased = function()
        if not zoneGarage then return end

        local result <const> = Menu.store(zoneGarage.id) or {
            ok = false,
            title = locale('garage.title'),
            message = locale('garage.no_answer'),
        }

        core:Notify({ title = result.title, description = result.message, type = result.ok and 'success' or 'error' })
    end,
})

---@type number?
local zoneInterval

lib.onCache('vehicle', function(vehicle)
    if zoneInterval then
        ClearInterval(zoneInterval)
        zoneInterval = nil
    end

    zoneGarage = nil
    storeKeybind:disable(true)
    setText(nil)

    if not vehicle then return end

    zoneInterval = SetInterval(function()
        local inside <const> = cache.seat == -1 and storeZoneAt(GetEntityCoords(vehicle)) or nil

        if inside == zoneGarage then return end

        zoneGarage = inside
        storeKeybind:disable(inside == nil)
        setText(inside and locale('garage.store_prompt', config.storeKey, Vehicle.labelOf(vehicle)) or nil)
    end, 500)
end)

RegisterNetEvent('cobalt_garages:client:changed', refresh)
RegisterNetEvent('cobalt_core:Client:OnPlayerLoaded', refresh)

local refreshTicket = 0

local function refreshSoon()
    refreshTicket += 1

    local ticket <const> = refreshTicket

    SetTimeout(250, function()
        if ticket == refreshTicket then refresh() end
    end)
end

RegisterNetEvent('cobalt_management:membershipChanged', refreshSoon)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then clear() end
end)

CreateThread(function()
    if LocalPlayer.state.LoggedIn ~= false then refresh() end
end)
