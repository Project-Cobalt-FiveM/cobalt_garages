local Cobalt <const> = exports.cobalt_core:GetCoreObject()

---@class OrgMembership
---@field name string
---@field grade integer
---@field onDuty boolean
---@field isBoss boolean

local Players <const> = {}

---@param source integer
---@return table?
function Players.get(source)
    return Cobalt.Functions.GetPlayer(source)
end

---@param source integer
---@return string?
function Players.citizenid(source)
    local player <const> = Players.get(source)

    return player and player.PlayerData.citizenid
end

---@param citizenid string
---@return integer?
function Players.sourceOf(citizenid)
    local player <const> = Cobalt.Functions.GetPlayerByCitizenId(citizenid, true)

    return player and player.PlayerData.source
end

---@param source integer
---@return string
function Players.name(source)
    return exports.cobalt_core:GetName(source) or GetPlayerName(source) or locale('access.unknown_player')
end

---@param source integer
---@return OrgMembership?
function Players.job(source)
    local job <const> = exports.cobalt_management:GetJob(source)

    if not job then return nil end

    return {
        name = job.name,
        grade = job.grade.level,
        onDuty = job.onduty == true,
        isBoss = job.isboss == true,
    }
end

---@param source integer
---@return OrgMembership?
function Players.gang(source)
    local gang <const> = exports.cobalt_management:GetGang(source)

    if not gang then return nil end

    return {
        name = gang.name,
        grade = gang.grade.level,
        onDuty = true,
        isBoss = gang.isboss == true,
    }
end

---@param source integer
---@return boolean
function Players.isAdmin(source)
    return Cobalt.Functions.HasPermission(source, 'admin')
end

---@param source integer
---@return { cash: integer, bank: integer }
function Players.balances(source)
    local player <const> = Players.get(source)

    if not player then return { cash = 0, bank = 0 } end

    return { cash = player.Functions.GetMoney('cash') or 0, bank = player.Functions.GetMoney('bank') or 0 }
end

---@param source integer
---@param amount integer
---@param from ChargeFrom
---@param reason string
---@return boolean
function Players.charge(source, amount, from, reason)
    if amount <= 0 then return true end

    local player <const> = Players.get(source)

    if not player then return false end

    local order <const> = from == 'cash_bank' and { 'cash', 'bank' } or { from }

    for _, account in ipairs(order) do
        if (player.Functions.GetMoney(account) or 0) >= amount then
            return player.Functions.RemoveMoney(account, amount, reason) == true
        end
    end

    return false
end

---@param org string
---@param amount integer
---@param description string
function Players.payOrg(org, amount, description)
    if amount <= 0 then return end

    exports.cobalt_banking:Deposit('society_' .. org, amount, { note = description })
end

---@param source integer
---@param description string
---@param kind? 'inform' | 'success' | 'error' | 'warning'
---@param title? string
function Players.notify(source, description, kind, title)
    Cobalt.Functions.Notify(source, {
        title = title or locale('garage.title'),
        description = description,
        type = kind or 'inform',
    })
end

return Players
