util.AddNetworkString("AmmoCrate_Sync")
util.AddNetworkString("AmmoCrate_Update")

AmmoCrate_Limits = AmmoCrate_Limits or {}

local function LoadAmmoLimits()
    local f = "ammocrate_limits.txt"
    table.Empty(AmmoCrate_Limits) 

    local defaultLimits = {
        ["Pistol"] = 150,
        ["357"] = 18,
        ["SMG1"] = 225,
        ["AR2"] = 120,
        ["Buckshot"] = 60,
        ["XBowBolt"] = 30,
        ["Grenade"] = 3,
        ["RPG_Round"] = 3,
        ["SMG1_Grenade"] = 3,
        ["AR2AltFire"] = 3
    }

    if file.Exists(f, "DATA") then
        local savedData = util.JSONToTable(file.Read(f, "DATA")) or {}
        for name, val in pairs(savedData) do
            AmmoCrate_Limits[tostring(name)] = tonumber(val)
        end
        for name, val in pairs(defaultLimits) do
            if AmmoCrate_Limits[name] == nil then
                AmmoCrate_Limits[name] = val
            end
        end
    else
        for k, v in pairs(defaultLimits) do AmmoCrate_Limits[k] = v end
        file.Write(f, util.TableToJSON(AmmoCrate_Limits, true))
    end
end

LoadAmmoLimits()

net.Receive("AmmoCrate_Sync", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    net.Start("AmmoCrate_Sync")
    net.WriteTable(AmmoCrate_Limits)
    net.Send(ply)
end)

net.Receive("AmmoCrate_Update", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local newData = net.ReadTable()
    if newData then
        AmmoCrate_Limits = newData
        file.Write("ammocrate_limits.txt", util.TableToJSON(AmmoCrate_Limits, true))
        ply:ChatPrint("[Ammo Crate] Limits updated")
    end
end)