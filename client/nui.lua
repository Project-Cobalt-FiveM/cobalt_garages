local Nui <const> = {}

local VECTOR_TYPES <const> = { vector2 = true, vector3 = true, vector4 = true }

---@param value any
---@return any
function Nui.plain(value)
    local kind <const> = type(value)

    if VECTOR_TYPES[kind] then
        return {
            x = value.x,
            y = value.y,
            z = kind ~= 'vector2' and value.z or nil,
            w = kind == 'vector4' and value.w or nil,
        }
    end

    if kind ~= 'table' then return value end

    local copy <const> = {}

    for key, item in pairs(value) do
        copy[key] = Nui.plain(item)
    end

    return copy
end

---@param action string
---@param data? any
function Nui.send(action, data)
    SendNUIMessage({ action = action, data = Nui.plain(data) })
end

---@param view 'garage' | 'creator'
---@param payload table
function Nui.open(view, payload)
    Nui.send('open', { view = view, payload = payload })
    SetNuiFocus(true, true)
end

---@param focused boolean
function Nui.focus(focused)
    SetNuiFocus(focused, focused)
end

function Nui.close()
    Nui.send('close')
    SetNuiFocus(false, false)
end

---@param name string
---@param handler fun(data: table): any
function Nui.on(name, handler)
    RegisterNUICallback(name, function(data, cb)
        cb(Nui.plain(handler(type(data) == 'table' and data or {})) or false)
    end)
end

Nui.on('close', function()
    SetNuiFocus(false, false)

    return true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then SetNuiFocus(false, false) end
end)

return Nui
