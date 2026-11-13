local Zone <const> = {}

---@param points Vec3[]
---@param x number
---@param y number
---@return boolean
local function insidePolygon(points, x, y)
    local inside = false
    local j = #points

    for i = 1, #points do
        local a, b = points[i], points[j]

        if (a.y > y) ~= (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x then
            inside = not inside
        end

        j = i
    end

    return inside
end

---@param zone GarageZone
---@param point Vec3
---@return boolean
function Zone.contains(zone, point)
    if zone.kind == 'box' and zone.coords and zone.size then
        local dx, dy = point.x - zone.coords.x, point.y - zone.coords.y
        local angle <const> = math.rad(-(zone.rotation or 0.0))
        local x <const> = dx * math.cos(angle) - dy * math.sin(angle)
        local y <const> = dx * math.sin(angle) + dy * math.cos(angle)

        if math.abs(point.z - zone.coords.z) > zone.size.z / 2 then return false end

        return math.abs(x) <= zone.size.x / 2 and math.abs(y) <= zone.size.y / 2
    end

    if zone.kind == 'poly' and zone.points and #zone.points >= 3 then
        if zone.minZ and point.z < zone.minZ then return false end
        if zone.maxZ and point.z > zone.maxZ then return false end

        return insidePolygon(zone.points, point.x, point.y)
    end

    return false
end

---@param points Vec3[]
---@return number
function Zone.area(points)
    local total = 0.0
    local j = #points

    for i = 1, #points do
        total += (points[j].x + points[i].x) * (points[j].y - points[i].y)
        j = i
    end

    return math.abs(total / 2)
end

return Zone
