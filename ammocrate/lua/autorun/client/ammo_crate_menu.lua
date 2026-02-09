local baseAmmo = {
    ["Pistol"] = true, ["357"] = true, ["SMG1"] = true, ["AR2"] = true,
    ["Buckshot"] = true, ["XBowBolt"] = true, ["Grenade"] = true,
    ["RPG_Round"] = true, ["SMG1_Grenade"] = true, ["AR2AltFire"] = true
}

local function OpenAmmoEditor(data)
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 550)
    frame:SetTitle("Ammo Crate Configuration")
    frame:Center()
    frame:MakePopup()

    local addPanel = vgui.Create("DPanel", frame)
    addPanel:Dock(TOP)
    addPanel:SetHeight(80)
    addPanel:DockMargin(0, 0, 0, 10)

    local newName = vgui.Create("DTextEntry", addPanel)
    newName:SetPlaceholderText("Type ammo name...")
    newName:Dock(TOP)
    newName:DockMargin(5, 5, 5, 0)

    local btnPanel = vgui.Create("DPanel", addPanel)
    btnPanel:Dock(FILL)
    btnPanel:SetPaintBackground(false)

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)

    local function RefreshList()
        if not IsValid(scroll) then return end
        scroll:Clear()
        
        local sortedKeys = {}
        for k, v in pairs(data) do table.insert(sortedKeys, tostring(k)) end
        table.sort(sortedKeys, function(a, b) return tostring(a) < tostring(b) end)

        for _, name in ipairs(sortedKeys) do
            local amt = data[name]
            local line = scroll:Add("DPanel")
            line:Dock(TOP)
            line:SetHeight(40)
            line:DockMargin(0, 0, 0, 5)

            if not baseAmmo[name] then
                local del = vgui.Create("DButton", line)
                del:SetText("X")
                del:SetTextColor(Color(255, 255, 255))
                del:SetWide(25)
                del:Dock(RIGHT)
                del:DockMargin(5, 7, 10, 7)
                del.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(200, 50, 50)) end
                del.DoClick = function()
                    data[name] = nil
                    RefreshList()
                end
            end

            local s = vgui.Create("DNumberWang", line)
            s:SetSize(60, 20)
            s:Dock(RIGHT)
            s:SetMinMax(0, 9999)
            s:SetValue(tonumber(amt) or 0)
            s.OnValueChanged = function(_, val) data[name] = tonumber(val) end
            s:DockMargin(0, 10, 5, 10)

            local lbl = vgui.Create("DLabel", line)
            lbl:SetText(tostring(name))
            lbl:SetTextColor(Color(40, 40, 40))
            lbl:SetFont("DermaDefaultBold")
            lbl:Dock(FILL)
            lbl:DockMargin(10, 0, 5, 0)
            lbl:SetContentAlignment(4)
        end
    end

    local function SafeAddAmmo(name)
        name = string.Trim(name)
        if name == "" or name == "none" then 
            surface.PlaySound("buttons/button10.wav")
            return 
        end
        if data[name] then
            Derma_Message("This type of ammo '" .. name .. "' already in list!", "Duplicate", "OK")
            surface.PlaySound("buttons/button5.wav")
            return
        end
        data[name] = 100
        RefreshList()
        surface.PlaySound("buttons/button14.wav")
    end

    local addBtn = vgui.Create("DButton", btnPanel)
    addBtn:SetText("Add")
    addBtn:Dock(LEFT)
    addBtn:SetWide(160)
    addBtn:DockMargin(5, 5, 5, 5)
    addBtn.DoClick = function()
        SafeAddAmmo(newName:GetValue())
        newName:SetText("")
    end

    local getBtn = vgui.Create("DButton", btnPanel)
    getBtn:SetText("Add for gun in hands")
    getBtn:Dock(FILL)
    getBtn:DockMargin(0, 5, 5, 5)
    getBtn.DoClick = function()
        local ply = LocalPlayer()
        local wep = IsValid(ply) and ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetPrimaryAmmoType() != -1 then
            SafeAddAmmo(game.GetAmmoName(wep:GetPrimaryAmmoType()))
        else
            Derma_Message("Pick gun with ammo!", "Error", "OK")
            surface.PlaySound("buttons/button5.wav")
        end
    end

    RefreshList()

    local save = vgui.Create("DButton", frame)
    save:SetText("Save changes")
    save:Dock(BOTTOM)
    save:SetHeight(40)
    save.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(50, 150, 50)) end
    save:SetTextColor(Color(255, 255, 255))
    save.DoClick = function()
        net.Start("AmmoCrate_Update")
        net.WriteTable(data)
        net.SendToServer()
        frame:Close()
    end
end

net.Receive("AmmoCrate_Sync", function()
    if not LocalPlayer():IsAdmin() then return end 
    
    local data = net.ReadTable()
    OpenAmmoEditor(data)
end)

concommand.Add("ammocrate_menu", function()
    if not LocalPlayer():IsAdmin() then 
        print("[Ammo Crate] You don't have permission!")
        surface.PlaySound("buttons/button5.wav")
        return 
    end

    net.Start("AmmoCrate_Sync")
    net.SendToServer()
end)