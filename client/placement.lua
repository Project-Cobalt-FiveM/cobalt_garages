local Nui <const> = require 'client.nui'

---@alias PlacementKind 'interact' | 'spawn' | 'zone'

---@class PlacementRequest
---@field kind PlacementKind
---@field garage string
---@field index integer
---@field interact? Vec4
---@field spawns Vec4[]
---@field clearRadius number
---@field heading? number

---@class PlacementCheck
---@field ok boolean
---@field label string

local CONTROLS <const> = {
    aimLeft = 14,
    aimRight = 15,
    sprint = 21,
    cover = 44,
    interact = 38,
    snap = 47,
    tab = 37,
    finish = 23,
    undo = 177,
    confirm = 191,
    pause = 200,
}

local DISABLED <const> = { 14, 15, 16, 17, 21, 24, 25, 37, 38, 44, 45, 47, 23, 140, 141, 142, 177, 191, 199, 200, 201, 322 }
local RAY_DISTANCE <const> = 60.0
local COBALT <const> = { 80, 120, 215 }
local WHITE <const> = { 250, 250, 250 }
local PREVIEW_SIZES <const> = {
    { label = locale('placement.size_compact'), model = `blista` },
    { label = locale('placement.size_sedan'), model = `asea` },
    { label = locale('placement.size_suv'), model = `baller` },
    { label = locale('placement.size_van'), model = `speedo` },
}
local CLOSE_SPAWN <const> = 3.0

local Placement <const> = {}

---@return vector3?
local function aim()
    local hit, _, coords = lib.raycast.cam(1 | 16, 4, RAY_DISTANCE)

    return hit and coords or nil
end

local function disableControls()
    for _, control in ipairs(DISABLED) do
        DisableControlAction(0, control, true)
    end
end

---@param control integer
---@return boolean
local function pressed(control)
    return IsDisabledControlJustPressed(0, control)
end

---@param from vector3
---@param to vector3
local function line(from, to)
    DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, COBALT[1], COBALT[2], COBALT[3], 255)
end

---@param coords vector3
---@param heading number
local function drawPoint(coords, heading)
    DrawMarker(
        1,
        coords.x, coords.y, coords.z - 0.02,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.6, 0.6, 0.15,
        COBALT[1], COBALT[2], COBALT[3], 255,
        false, false, 2, false, nil, nil, false
    )
    DrawMarker(
        3,
        coords.x, coords.y, coords.z + 0.6,
        0.0, 0.0, 0.0,
        90.0, 0.0, -heading,
        0.4, 0.4, 0.4,
        WHITE[1], WHITE[2], WHITE[3], 255,
        false, false, 2, false, nil, nil, false
    )
end

---@param points vector3[]
---@param cursor? vector3
local function drawPolygon(points, cursor)
    for i = 2, #points do
        line(points[i - 1], points[i])
    end

    if cursor and #points > 0 then
        line(points[#points], cursor)

        if #points >= 2 then line(cursor, points[1]) end
    end

    for _, point in ipairs(points) do
        line(point, point + vector3(0.0, 0.0, 2.0))
    end
end

---@param model integer
---@return integer
local function createGhost(model)
    lib.requestModel(model)

    local ghost <const> = CreateVehicle(model, 0.0, 0.0, 0.0, 0.0, false, false)

    SetModelAsNoLongerNeeded(model)
    SetEntityAlpha(ghost, 170, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetVehicleDoorsLocked(ghost, 2)

    return ghost
end

---@param coords vector3
---@return boolean
local function onGround(coords)
    local found, ground = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)

    return found and math.abs(ground - coords.z) <= 0.5
end

---@param coords vector3
---@param radius number
---@param ghost? integer
---@return boolean
local function areaClear(coords, radius, ghost)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if vehicle ~= ghost and #(GetEntityCoords(vehicle) - coords) <= radius then return false end
    end

    return true
end

---@param request PlacementRequest
---@param coords vector3
---@param ghost? integer
---@return PlacementCheck[]
local function checks(request, coords, ghost)
    local grounded <const> = onGround(coords)
    local groundLabel <const> = locale(grounded and 'placement.on_ground' or 'placement.off_ground')
    local list <const> = { { ok = grounded, label = groundLabel } }

    if request.kind ~= 'spawn' then return list end

    local clear <const> = areaClear(coords, request.clearRadius, ghost)

    local radius <const> = request.clearRadius

    list[#list + 1] = {
        ok = clear,
        label = locale(clear and 'placement.clear' or 'placement.blocked', radius),
    }

    for index, spawn in ipairs(request.spawns) do
        local distance <const> = #(coords - vector3(spawn.x, spawn.y, spawn.z))

        if index ~= request.index and distance < CLOSE_SPAWN then
            list[#list + 1] = { ok = false, label = locale('placement.too_close', distance, index) }
        end
    end

    return list
end

---@param request PlacementRequest
---@return string
local function title(request)
    if request.kind == 'interact' then return locale('placement.interact') end
    if request.kind == 'zone' then return locale('placement.zone') end

    return locale('placement.spawn', request.index)
end

---@param request PlacementRequest
---@return Vec4 | Vec3[] | nil
function Placement.run(request)
    local heading = request.heading or (GetGameplayCamRot(2).z + 180.0) % 360.0
    local lift = 0.0
    local sizeIndex = 2
    local ghost = request.kind == 'spawn' and createGhost(PREVIEW_SIZES[sizeIndex].model) or nil
    local points <const> = {}
    local origin <const> = request.interact and vector3(request.interact.x, request.interact.y, request.interact.z)
    local nextUpdate = 0
    local result

    Nui.send('placement', { active = true, kind = request.kind, garage = request.garage, title = title(request) })
    Nui.focus(false)

    while true do
        Wait(0)
        disableControls()

        local hit <const> = aim()
        local coords <const> = hit and hit + vector3(0.0, 0.0, lift)
        local step <const> = IsDisabledControlPressed(0, CONTROLS.sprint) and 1.0 or 5.0

        if pressed(CONTROLS.aimLeft) then heading = (heading + step) % 360.0 end
        if pressed(CONTROLS.aimRight) then heading = (heading - step) % 360.0 end
        if IsDisabledControlPressed(0, CONTROLS.cover) then lift -= 0.02 end
        if IsDisabledControlPressed(0, CONTROLS.interact) then lift += 0.02 end
        if pressed(CONTROLS.snap) then lift = 0.0 end

        if ghost and pressed(CONTROLS.tab) then
            sizeIndex = sizeIndex % #PREVIEW_SIZES + 1
            DeleteEntity(ghost)
            ghost = createGhost(PREVIEW_SIZES[sizeIndex].model)
        end

        if ghost then
            SetEntityVisible(ghost, coords ~= nil, false)

            if coords then
                SetEntityCoordsNoOffset(ghost, coords.x, coords.y, coords.z, false, false, false)
                SetEntityHeading(ghost, heading)
            end
        elseif coords then
            drawPoint(coords, heading)
        end

        if request.kind == 'zone' then drawPolygon(points, coords) end

        if coords and GetGameTimer() >= nextUpdate then
            nextUpdate = GetGameTimer() + 100
            Nui.send('placement', {
                active = true,
                kind = request.kind,
                garage = request.garage,
                title = title(request),
                coords = { x = coords.x, y = coords.y, z = coords.z, w = heading },
                fromPed = origin and #(coords - origin) or nil,
                previewSize = ghost and PREVIEW_SIZES[sizeIndex].label or nil,
                corners = #points,
                checks = checks(request, coords, ghost),
            })
        end

        if pressed(CONTROLS.pause) then break end

        if request.kind == 'zone' then
            if pressed(CONTROLS.undo) then points[#points] = nil end
            if coords and pressed(CONTROLS.confirm) and #points < 32 then points[#points + 1] = coords end

            if pressed(CONTROLS.finish) and #points >= 3 then
                result = points
                break
            end
        elseif pressed(CONTROLS.undo) then
            break
        elseif coords and pressed(CONTROLS.confirm) then
            result = { x = coords.x, y = coords.y, z = coords.z, w = heading }
            break
        end
    end

    if ghost then DeleteEntity(ghost) end

    Nui.send('placement', { active = false })
    Nui.focus(true)

    if not result or request.kind ~= 'zone' then return result end

    local zone <const> = {}

    for i, point in ipairs(result) do
        zone[i] = { x = point.x, y = point.y, z = point.z }
    end

    return zone
end

---@param spawn Vec4
function Placement.preview(spawn)
    local ghost <const> = createGhost(PREVIEW_SIZES[2].model)

    SetEntityCoordsNoOffset(ghost, spawn.x, spawn.y, spawn.z, false, false, false)
    SetEntityHeading(ghost, spawn.w)
    SetTimeout(6000, function()
        if DoesEntityExist(ghost) then DeleteEntity(ghost) end
    end)
end

---@param spawns Vec4[]
---@param radius number
---@return boolean[]
function Placement.clearance(spawns, radius)
    local result <const> = {}

    for index, spawn in ipairs(spawns) do
        result[index] = areaClear(vector3(spawn.x, spawn.y, spawn.z), radius)
    end

    return result
end

return Placement
