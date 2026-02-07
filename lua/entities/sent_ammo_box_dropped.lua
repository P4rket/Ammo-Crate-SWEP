AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dropped Ammo"
ENT.Spawnable = false

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/Items/BoxSRounds.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:Activate()
        self:SetModelScale(0.8, 0)
        self:SetColor(Color(255, 150, 0))
        
        SafeRemoveEntityDelayed(self, 60)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end

    local ammoLimits = {
        ["Pistol"]    = 150,
        ["357"]       = 18,
        ["SMG1"]      = 225,
        ["AR2"]       = 120,
        ["Buckshot"]  = 60,
        ["XBowBolt"]  = 30,
        ["Grenade"]   = 3,
        ["RPG_Round"] = 3,
        ["SMG1_Grenade"] = 3,
    }

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        
        local weapon = activator:GetActiveWeapon()
        if IsValid(weapon) and weapon:GetPrimaryAmmoType() != -1 then
            local ammoID = weapon:GetPrimaryAmmoType()
            local ammoName = game.GetAmmoName(ammoID)
            local currentAmmo = activator:GetAmmoCount(ammoID)

            local maxAllowed = ammoLimits[ammoName] or 120

            local amountToAdd = math.max(0, maxAllowed - currentAmmo)
            
            if amountToAdd > 0 then
                activator:GiveAmmo(amountToAdd, ammoID)
                activator:EmitSound("items/ammo_pickup.wav")
                self:Remove()
            else
                activator:ChatPrint("Max amount of this ammo type: " .. ammoName)
            end
        else
            activator:ChatPrint("Pick gun into hands!")
        end
    end
end