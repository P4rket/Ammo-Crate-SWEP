AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dropped Ammo"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/Items/BoxSRounds.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetColor(Color(255, 150, 0))
        SafeRemoveEntityDelayed(self, 60)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
    
    local weapon = activator:GetActiveWeapon()
    if not IsValid(weapon) then return end

    local ammoCheck = {
        weapon:GetPrimaryAmmoType(),
        weapon:GetSecondaryAmmoType()
    }

    local gaveAnyAmmo = false

    for _, ammoID in ipairs(ammoCheck) do
        if ammoID != -1 then
            local ammoName = game.GetAmmoName(ammoID)
            local maxAllowed = (AmmoCrate_Limits and AmmoCrate_Limits[ammoName]) or 120
            local currentAmmo = activator:GetAmmoCount(ammoName)

            if currentAmmo < maxAllowed then
                local need = maxAllowed - currentAmmo
                activator:GiveAmmo(need, ammoName)
                gaveAnyAmmo = true
            end
        end
    end

    if gaveAnyAmmo then
        activator:EmitSound("items/ammo_pickup.wav")
        self:Remove()
    else
        activator:ChatPrint("[Ammo Crate] Your ammunition is full!")
    end
end