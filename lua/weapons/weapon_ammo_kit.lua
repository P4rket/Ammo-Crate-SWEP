AddCSLuaFile()

SWEP.PrintName = "Ammo Supply"
SWEP.Category = "Other"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot    = 5
SWEP.SlotPos = 1
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/Items/BoxSRounds.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType("slam")
    self.RegenAccumulator = 0

    local timerName = "AmmoKitRegen_" .. self:EntIndex()

    timer.Create(timerName, 0.5, 0, function()
        if not IsValid(self) then 
            timer.Remove(timerName)
            return 
        end

        if SERVER then
            local curClip = self:Clip1()
            if curClip < 100 then
                self:SetClip1(math.min(100, curClip + 1))
            end
        end
    end)
end

function SWEP:OnRemove()
    timer.Remove("AmmoKitRegen_" .. self:EntIndex())
    
    if CLIENT then
        if IsValid(self.BoxModel) then self.BoxModel:Remove() end
        local owner = self:GetOwner()
        if IsValid(owner) then
            local vm = owner:GetViewModel()
            if IsValid(vm) then vm:SetMaterial("") end
        end
    end
end

function SWEP:Holster()
    if CLIENT then
        local owner = self:GetOwner()
        if IsValid(owner) then
            local vm = owner:GetViewModel()
            if IsValid(vm) then
                vm:SetMaterial("")
                for i = 0, vm:GetBoneCount() - 1 do
                    vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
                end
            end
        end
    end
    return true
end

if CLIENT then
    function SWEP:ViewModelDrawn(vm)
        if not IsValid(vm) then return end

        local fingerBones = {
            "ValveBiped.Bip01_R_Finger0",
            "ValveBiped.Bip01_R_Finger01",
            "ValveBiped.Bip01_R_Finger02"
        }
    
        for _, boneName in ipairs(fingerBones) do
            local bone = vm:LookupBone(boneName)
            if bone then
                vm:ManipulateBoneAngles(bone, Angle(-25, 0, 0)) 
            end
        end
    end

    function SWEP:PostDrawViewModel(vm, weapon, ply)
        if not IsValid(vm) then return end
        
        vm:SetMaterial("engine/occlusionproxy")

        if not IsValid(self.BoxModel) then
            self.BoxModel = ClientsideModel("models/Items/BoxSRounds.mdl")
            self.BoxModel:SetNoDraw(true)
        end

        local boneid = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end

        local matrix = vm:GetBoneMatrix(boneid)
        if not matrix then return end

        local pos = matrix:GetTranslation()
        local ang = matrix:GetAngles()

        ang:RotateAroundAxis(ang:Forward(), 180)
        ang:RotateAroundAxis(ang:Up(), 0)
        ang:RotateAroundAxis(ang:Right(), -10)

        pos = pos + ang:Forward() * 3.5 + ang:Up() * -3 + ang:Right() * -5

        local size = 0.55
        local mat = Matrix()
        mat:Scale(Vector(size, size, size))
        self.BoxModel:EnableMatrix("RenderMultiply", mat)

        self.BoxModel:SetPos(pos)
        self.BoxModel:SetAngles(ang)
        self.BoxModel:DrawModel()
    end

    function SWEP:OnRemove()
        local owner = self:GetOwner()
        if IsValid(owner) then
            local vm = owner:GetViewModel()
            if IsValid(vm) then
                local fingerBones = {
                    "ValveBiped.Bip01_R_Finger0",
                    "ValveBiped.Bip01_R_Finger01",
                    "ValveBiped.Bip01_R_Finger02"
                }
                for _, boneName in ipairs(fingerBones) do
                    local bone = vm:LookupBone(boneName)
                    if bone then
                        vm:ManipulateBoneAngles(bone, Angle(0, 0, 0))
                    end
                end
            end
        end

        if IsValid(self.BoxModel) then self.BoxModel:Remove() end
    end

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()

        if IsValid(owner) then
            local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end

            local matrix = owner:GetBoneMatrix(boneid)
            if not matrix then return end

            local pos = matrix:GetTranslation()
            local ang = matrix:GetAngles()

            local scale = 0.55

            ang:RotateAroundAxis(ang:Forward(), 200)
            ang:RotateAroundAxis(ang:Up(), 0)
            ang:RotateAroundAxis(ang:Right(), 0)

            pos = pos + ang:Forward() * 3 + ang:Up() * -5 + ang:Right() * -6

            self:SetModelScale(scale, 0)
            self:InvalidateBoneCache()

            self:SetRenderOrigin(pos)
            self:SetRenderAngles(ang)
        else
            self:SetRenderOrigin(nil)
            self:SetRenderAngles(nil)
            self:SetModelScale(1, 0)
        end

        self:DrawModel()
    end
end

function SWEP:PrimaryAttack()
    if self:Clip1() < 30 then
        self:SetNextPrimaryFire(CurTime() + 0.5)
        if SERVER then
            self:EmitSound("items/medshotno1.wav", 60, 100)
        end
        return 
    end

    self:SetNextPrimaryFire(CurTime() + 1.2)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    if SERVER then
        self:SetClip1(self:Clip1() - 30)
        
        local ent = ents.Create("sent_ammo_box_dropped")
        if IsValid(ent) then
            local ply = self:GetOwner()
            ent:SetPos(ply:GetShootPos() + ply:GetForward() * 20)
            ent:SetAngles(ply:GetAngles())
            ent:Spawn()
            
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:ApplyForceCenter(ply:GetForward() * 300 + Vector(0, 0, 100))
            end
        end
        self:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 60, 150)
    end
end

function SWEP:SecondaryAttack()
    return false
end