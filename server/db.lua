---@class OwnedVehicleRow
---@field plate string
---@field citizenid string
---@field model string
---@field garage? string
---@field state integer
---@field fuel? number
---@field engine? number
---@field body? number
---@field depotprice integer
---@field mileage? integer
---@field mods? string
---@field vehicleType? string
---@field class? integer
---@field parkedAt? integer
---@field impoundedAt? integer
---@field impoundReason? string
---@field holdUntil? integer

---@class VehicleCondition
---@field fuel number
---@field engine number
---@field body number
---@field props table

local db <const> = {}

local VEHICLE_COLUMNS <const> = [[
    SELECT plate, citizenid, COALESCE(vehicle, hash) AS model, garage, state, fuel, engine, body, depotprice,
        drivingdistance AS mileage, mods, vehicle_type AS vehicleType, class, UNIX_TIMESTAMP(parked_at) AS parkedAt, UNIX_TIMESTAMP(impounded_at) AS impoundedAt,
        impound_reason AS impoundReason, UNIX_TIMESTAMP(hold_until) AS holdUntil
    FROM player_vehicles
]]

local LIST_OWNED <const> = VEHICLE_COLUMNS .. ' WHERE citizenid = ? ORDER BY id LIMIT 100'
local GET_VEHICLE <const> = VEHICLE_COLUMNS .. ' WHERE plate = ? LIMIT 1'
local LIST_OUT <const> = 'SELECT plate, citizenid, garage FROM player_vehicles WHERE state = 0 ORDER BY id LIMIT 5000'

local STORE <const> = [[
    UPDATE player_vehicles SET state = 1, garage = ?, fuel = ?, engine = ?, body = ?, mods = ?, depotprice = 0,
        vehicle_type = ?, class = ?, parked_at = NOW(), impounded_at = NULL, impound_reason = NULL,
        impounded_by = NULL, hold_until = NULL
    WHERE plate = ? AND citizenid = ? AND state <> 2
]]

local TAKE_OUT <const> = 'UPDATE player_vehicles SET state = 0 WHERE plate = ? AND citizenid = ? AND state = 1 AND garage = ?'
local PUT_BACK <const> = 'UPDATE player_vehicles SET state = 1 WHERE plate = ? AND state = 0'
local TRANSFER <const> = 'UPDATE player_vehicles SET garage = ? WHERE plate = ? AND citizenid = ? AND state = 1 AND garage = ?'

local IMPOUND <const> = [[
    UPDATE player_vehicles SET state = 2, garage = ?, depotprice = ?, impounded_at = NOW(), impound_reason = ?,
        impounded_by = ?, hold_until = FROM_UNIXTIME(?), parked_at = NULL
    WHERE plate = ? AND state <> 2
]]

local IMPOUND_CONDITION <const> = 'UPDATE player_vehicles SET fuel = ?, engine = ?, body = ?, mods = ? WHERE plate = ?'

local RELEASE <const> = [[
    UPDATE player_vehicles SET state = 0, depotprice = 0
    WHERE plate = ? AND citizenid = ? AND state = 2 AND garage = ? AND depotprice = ?
        AND (hold_until IS NULL OR hold_until <= NOW())
]]

local COUNT_STORED <const> = 'SELECT COUNT(*) FROM player_vehicles WHERE garage = ? AND state = 1'
local COUNT_STORED_BY <const> = 'SELECT COUNT(*) FROM player_vehicles WHERE garage = ? AND state = 1 AND citizenid = ?'
local COUNT_BY_GARAGE <const> = 'SELECT garage, COUNT(*) AS total FROM player_vehicles WHERE state IN (1, 2) GROUP BY garage'
local MOVE_GARAGE <const> = 'UPDATE player_vehicles SET garage = ? WHERE garage = ? AND state IN (1, 2)'
local MOVE_TO_IMPOUND <const> = [[
    UPDATE player_vehicles SET garage = ?, state = 2, depotprice = 0 WHERE garage = ? AND state IN (1, 2)
]]

local TOTALS <const> = [[
    SELECT COALESCE(SUM(state = 1), 0) AS stored, COALESCE(SUM(state = 2), 0) AS impounded,
        COALESCE(SUM(state = 2 AND hold_until > NOW()), 0) AS held, COUNT(DISTINCT citizenid) AS owners
    FROM player_vehicles
]]

local LIST_GARAGES <const> = [[
    SELECT id, label, type, enabled, data, updated_by AS updatedBy, UNIX_TIMESTAMP(updated_at) AS updatedAt
    FROM garages ORDER BY label LIMIT 500
]]

local SAVE_GARAGE <const> = [[
    INSERT INTO garages (id, label, type, enabled, data, updated_by) VALUES (?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type), enabled = VALUES(enabled),
        data = VALUES(data), updated_by = VALUES(updated_by)
]]

---@param citizenid string
---@return OwnedVehicleRow[]
function db.ownedVehicles(citizenid)
    return MySQL.query.await(LIST_OWNED, { citizenid }) or {}
end

---@param plate string
---@return OwnedVehicleRow?
function db.vehicle(plate)
    return MySQL.single.await(GET_VEHICLE, { plate })
end

---@return { plate: string, citizenid: string, garage?: string }[]
function db.outVehicles()
    return MySQL.query.await(LIST_OUT) or {}
end

---@alias Charge fun(): boolean

---@param charge? Charge
---@return boolean
local function settle(charge)
    return charge == nil or charge()
end

---@param plate string
---@param citizenid string
---@param garageId string
---@param condition VehicleCondition
---@param vehicleType string
---@param class integer
---@param charge? Charge
---@return boolean
function db.store(plate, citizenid, garageId, condition, vehicleType, class, charge)
    local props <const> = json.encode(condition.props)

    return MySQL.startTransaction(function(query)
        local stored <const> = query(STORE, {
            garageId, condition.fuel, condition.engine, condition.body, props, vehicleType, class, plate, citizenid,
        })

        if stored.affectedRows ~= 1 then return false end

        return settle(charge)
    end) == true
end

---@param plate string
---@param citizenid string
---@param garageId string
---@param charge? Charge
---@return boolean
function db.takeOut(plate, citizenid, garageId, charge)
    return MySQL.startTransaction(function(query)
        if query(TAKE_OUT, { plate, citizenid, garageId }).affectedRows ~= 1 then return false end

        return settle(charge)
    end) == true
end

---@param plate string
---@return boolean
function db.putBack(plate)
    return MySQL.update.await(PUT_BACK, { plate }) == 1
end

---@param plates string[]
---@return integer returned
function db.putBackAll(plates)
    if #plates == 0 then return 0 end

    return MySQL.update.await('UPDATE player_vehicles SET state = 1 WHERE plate IN (?) AND state = 0', { plates }) or 0
end

---@param plate string
---@param citizenid string
---@param from string
---@param to string
---@param charge? Charge
---@return boolean
function db.transfer(plate, citizenid, from, to, charge)
    return MySQL.startTransaction(function(query)
        if query(TRANSFER, { to, plate, citizenid, from }).affectedRows ~= 1 then return false end

        return settle(charge)
    end) == true
end

---@class ImpoundRecord
---@field lot string
---@field fee integer
---@field reason string
---@field by string
---@field holdUntil? integer
---@field condition? VehicleCondition

---@param plate string
---@param record ImpoundRecord
---@return boolean
function db.impound(plate, record)
    return MySQL.startTransaction(function(query)
        local impounded <const> = query(IMPOUND, {
            record.lot, record.fee, record.reason, record.by, record.holdUntil, plate,
        })

        if impounded.affectedRows ~= 1 then return false end

        local condition <const> = record.condition

        if condition then
            local props <const> = json.encode(condition.props)

            query(IMPOUND_CONDITION, { condition.fuel, condition.engine, condition.body, props, plate })
        end

        return true
    end) == true
end

---@param plate string
---@param citizenid string
---@param lot string
---@param fee integer
---@param charge? Charge
---@return boolean
function db.release(plate, citizenid, lot, fee, charge)
    return MySQL.startTransaction(function(query)
        if query(RELEASE, { plate, citizenid, lot, fee }).affectedRows < 1 then return false end

        return settle(charge)
    end) == true
end

---@param garageId string
---@param citizenid? string
---@return integer
function db.countStored(garageId, citizenid)
    if citizenid then
        return MySQL.scalar.await(COUNT_STORED_BY, { garageId, citizenid }) or 0
    end

    return MySQL.scalar.await(COUNT_STORED, { garageId }) or 0
end

---@return table<string, integer>
function db.countsByGarage()
    local counts <const> = {}

    for _, row in ipairs(MySQL.query.await(COUNT_BY_GARAGE) or {}) do
        counts[row.garage] = row.total
    end

    return counts
end

---@param from string
---@param to string
---@param impound boolean
---@return integer
function db.moveGarage(from, to, impound)
    return MySQL.update.await(impound and MOVE_TO_IMPOUND or MOVE_GARAGE, { to, from })
end

---@return { stored: integer, impounded: integer, held: integer, owners: integer }
function db.totals()
    return MySQL.single.await(TOTALS) or { stored = 0, impounded = 0, held = 0, owners = 0 }
end

---@class GarageRow
---@field id string
---@field label string
---@field type GarageType
---@field enabled integer | boolean
---@field data string
---@field updatedBy? string
---@field updatedAt? integer

---@return GarageRow[]
function db.garages()
    return MySQL.query.await(LIST_GARAGES) or {}
end

---@param garage Garage
---@param data table
---@param by? string
function db.saveGarage(garage, data, by)
    MySQL.insert.await(SAVE_GARAGE, { garage.id, garage.label, garage.type, garage.enabled, json.encode(data), by })
end

---@param id string
---@return boolean
function db.deleteGarage(id)
    return MySQL.update.await('DELETE FROM garages WHERE id = ?', { id }) == 1
end

---@return integer
function db.garageCount()
    return MySQL.scalar.await('SELECT COUNT(*) FROM garages') or 0
end

return db
