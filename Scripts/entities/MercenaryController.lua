MercenaryState = {
    OnFoot = 0,
    OnHorse = 1,
    AttemptingMount = 2,
    AttemptingDismount = 3,
    Waiting = 4
}

MercenaryHorsePresets = {
    "a21e7c6c-d161-4500-a55a-89962a33c3c3",
    "db63a282-a663-42ed-8ceb-610be4839aa0",
    "4e925a7f-9621-4d52-898a-e53fedcaacff",
    "65e9eed3-e34e-41ec-bbda-fbd09f81c285",
    "4d279fc4-8b8f-450a-b310-2208bb8a76ae",
    "479642ad-7b2d-4d2b-a80c-e43e431d70be",
    --"d0c3d3cf-7190-4493-a700-86de03f4a2b5",
}

MercenaryHorseCaparisonGuids = {
    "40024d27-b1c4-6ef7-3ca0-98025de43f9e",
    "402c55d2-ae62-bf47-823f-8a5760eab7bd",
    "407c5a00-2e73-f2dc-6a0b-8244c78e5da7",
    "40a5de5a-d3a5-c4c3-f5f1-71ab661d55b4",
    "40e576c7-74e8-216e-a4f0-a3aa6bd35387",
    "411f568d-9e62-417c-38a1-ae108bb233ba",
    "41c05047-74e5-f23d-1fe8-b0a8db360087",
    "421ff758-4be3-cc11-1946-39ceb56aecb1",
    "42e8c6bf-a457-4ad9-48c8-445fea1507ae",
    "466c49e3-6cbc-e962-2571-c44183da449d",
    "468a36a5-1aa9-e1c8-1d01-2c778ef84ea9",
    "46ee8c8f-2c9a-3002-a31e-8623e2da529d",
    "470d9803-e4cb-c9ae-da72-3466cf117cbb",
    "473709c6-2b26-5d05-57cf-50e4d6fceaa7",
    "47c3342a-3be4-8fe6-696e-436555714b8f",
    "4849903a-5dd2-e0b8-bfd0-2e599509c68e",
    "48a1ea8c-c52a-9b35-fda6-8df247fc18a2",
    "49b83945-99a1-50ba-9107-c3d9846875b1",
    "4a346515-2839-801d-3172-826486b9ee9d",
    "4af5fe3b-3e23-1a10-4ff6-b2d53d4d7187",
    "4b609a17-9266-0e3e-75dc-d4d709533dba",
    "4cc06ca7-46bf-609c-93de-3ce43481a28c",
    "4f3d678e-553c-f810-86fe-5534db2e1ea9"
}


MercenaryController = {
    useHorse = true, -- self explanitory
    preventSavingOnHorse = true, -- self explanitory
    attemptReequipPolearm = true, -- This flag should be disabled if you have a mod that reassigns polearms to shields
    
    --internal stuff
    saveLockName="FollowerSaveLock",
    useNormalBrain = true,
    needReload = false, -- loading function
    signalFlag = false, -- hack
    Follower = nil,
    FollowerHorse = nil,
    MaxFollowDistSq = 800,
    MaxFollowDistSqWaiting = 4000,
    reorderInterval = 10000, -- every 10 seconds, resend follow order
    oversizeWeap = nil, -- only used if attemptReequipPolearm is enabled
    
    currentState = MercenaryState.OnFoot,
    
    currentHorsePresetKey = nil,
    currentHorsePreset = nil
    
}

function MercenaryController:OnSpawn()
    -- needed for OnUpdate callback
    self:Activate(1)
end

function MercenaryController:OnDestroy()
    self:Kill()
    self.KillHorse(self)
end

-- easier than messing with xmls
function MercenaryController:SetStats()
    self.Follower.soul:AdvanceToStatLevel("str",15)
    self.Follower.soul:AdvanceToStatLevel("agi",15)
    self.Follower.soul:AdvanceToStatLevel("vit",18)
    self.Follower.soul:AdvanceToSkillLevel("defense",14)
    --self.Follower.soul:AdvanceToSkillLevel("fencing",14)
    self.Follower.soul:AdvanceToSkillLevel("weapon_large",14)
    self.Follower.soul:AdvanceToSkillLevel("weapon_sword",12)
    self.Follower.soul:AdvanceToSkillLevel("weapon_mace",12)
    self.Follower.soul:AdvanceToSkillLevel("weapon_axe",12)
    self.Follower.soul:AddPerk(string.upper("d2da2217-d46d-4cdb-accb-4ff860a3d83e")) -- perfect block
    self.Follower.soul:AddPerk(string.upper("ec4c5274-50e3-4bbf-9220-823b080647c4")) -- riposte
    self.Follower.soul:AddPerk(string.upper("3e87c467-681d-48b5-9a8c-485443adcd42")) -- pommel strike
    self.Follower.soul:AddPerk(string.upper("7d124502-f7ac-42ad-bb27-cba085fb69be")) -- LS combo 4
    --self.Follower.soul:AddPerk(string.upper("2cd86a68-776f-4d9b-ae3f-a0273dfff1f6")) -- last gasp
    self.Follower.soul:AddPerk(string.upper("8f1af639-7e7f-49e3-ae25-e3cfefa2a054")) -- close shave
    self.Follower.soul:AddPerk(string.upper("caf7c415-2b83-44a3-b79b-2ddc3437f58e")) -- halfsword
end

function MercenaryController:OnSave(table)
    if self.Follower == nil then
        System.LogAlways("$5 Tried to save but follower is nil!!")
        return
    end
    table.Follower = self.Follower:GetGUID()
    --table.currentState = self.currentState
    if self.FollowerHorse ~= nil then
        table.FollowerHorse = self.FollowerHorse:GetGUID()
    end
    if self.oversizeWeap ~= nil then
        local weap = ItemManager.GetItem(self.oversizeWeap)
        table.oversizeWeapClass = weap.class
    else
        table.oversizeWeapClass = nil
    end
    table.currentHorsePreset = self.currentHorsePreset
end

function MercenaryController:OnLoad(table)
    System.LogAlways("$5 OnLoad")
    self.Follower = System.GetEntityByGUID(table.Follower)
    self.FollowerHorse = System.GetEntityByGUID(table.FollowerHorse)
    if table.oversizeWeapClass ~= nil then
        --System.LogAlways(table.oversizeWeapClass)
        --temporary use of this as a class
        self.oversizeWeap = table.oversizeWeapClass
    end
    if self.Follower == nil then
        System.LogAlways("$5 Load Failed")
    end
    --self.currentState = table.currentState
    self.currentHorsePreset = table.currentHorsePreset
    self.needReload=true
end

function MercenaryController:AssignActions()
    self.Follower.Properties.controller = self
    self.Follower.GetActions = function (self,firstFast)
        output = {}
        AddInteractorAction( output, firstFast, Action():hint("Manage Follower"):action("use"):func(self.Manage):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Give/Take Items"):action("mount_horse"):func(self.GiveItems):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Retire Follower"):action("mount_horse"):hintType( AHT_HOLD ):func(self.Retire):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Heal"):action("use"):hintType( AHT_HOLD ):func(self.Heal):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Stay Here/Follow Me"):action("block"):hintType( AHT_HOLD ):func(self.StayOrFollow):interaction(inr_talk))
        return output
    end
    self.Follower.Manage = function (self, user)
        self.actor:OpenInventory(user.id, E_IM_Player, INVALID_WUID, "")
        --user.actor:OpenInventory(user.id, E_IM_StoreReadOnly, entity.inventory:GetId(), "") 
    end
    self.Follower.GiveItems = function (self, user)
        user.actor:OpenInventory(user.id, E_IM_Loot, self.inventory:GetId(), "") 
    end
    self.Follower.Retire = function (self, user)
        self.soul:SetState("health", 0)
        self:Hide(1)
        --self:DeleteThis()
        System.RemoveEntity(self.id)
        Game.SendInfoText("Follower has left your service.",false,nil,5)
    end
    self.Follower.Heal = function (self, user)
        self.soul:SetState( "health", 100 )
        --self.soul:SetState( "stamina", 100 );
        self.soul:SetState( "exhaust", 100 )
        self.soul:SetState( "hunger", 100 )
        self.soul:HealBleeding(1, 1)
        self.soul:HealBleeding(1, 2)
        self.soul:HealBleeding(1, 3)
        self.soul:HealBleeding(1, 4)
        self.soul:HealBleeding(1, 5)
        self.soul:HealBleeding(1, 6)
        if self.human:IsInDialog() then
            --System.LogAlways("in dialog")
        else
            --System.LogAlways("not in dialog")
        end
        local cleanVal = 0.95
        self.actor:WashDirtAndBlood(cleanVal)
        self.actor:WashItems(cleanVal)
        self.human:InterruptDialog()
        self.Properties.controller:InitOrder()
        self.Properties.controller:OrderStop()
        local weapon = self.human:GetItemInHand(0)
        local isOversized = ItemManager.IsItemOversized(weapon)
        
        if self.human:IsWeaponDrawn() ~= true and isOversized ~= true then
            self.human:DrawWeapon()
        end
        
        
        Game.SendInfoText("I'm all healed up.",false,nil,5)
    end
    self.Follower.StayOrFollow = function (self, user)
        if self.Properties.controller.currentState == MercenaryState.Waiting then
            self.Properties.controller:ResetOrder()
            self.Properties.controller.currentState = MercenaryState.OnFoot
            Game.SendInfoText("I will follow you now.",false,nil,5)
        elseif self.Properties.controller.currentState == MercenaryState.OnFoot then
            self.Properties.controller:HoldGround()
            self.Properties.controller.currentState = MercenaryState.Waiting
            Game.SendInfoText("I will wait here.",false,nil,5)
        else
            Game.SendInfoText("Don't tell me to do that right now.",false,nil,5)
        end
    end
end


function MercenaryController:Spawn()
    System.LogAlways("$5 Attempting to Spawn follower")
    self:Kill()
    
    local position = player:GetWorldPos()
    local spawnParams = {}
    spawnParams.class = "NPC"
    spawnParams.radius = 5
    spawnParams.name = "chaser"
    --spawnParams.position = {x=52.073,y=43.119,z=33.56}
    spawnParams.position=position
    spawnParams.properties = {}
    -- While he is used as a follower, the brain behavior has been modified so you can use for any sort of specific thing
    -- This is good because now you can use a script to order enemies and NPCs around without a lot of setup
    spawnParams.properties.sharedSoulGuid = "4eafa794-d75f-4ba1-daa6-1e91819f1cba"
    spawnParams.properties.bWH_PerceptibleObject = 1
    local entity = System.SpawnEntity(spawnParams)
    --entity.soul.factionId = player.soul:GetFactionID()
    self.Follower = entity

    self:AssignActions()
    self:ResetOrder()
    
    self.ResendOrder(self)
    self:SetStats()
end

function MercenaryController:SpawnHorse()
    System.LogAlways("$5 Attempting to Spawn horse")
    self.KillHorse(self)
    
    local position = self.Follower:GetWorldPos()
    local spawnParams = {}
    spawnParams.class = "Horse"
    spawnParams.radius = 5
    spawnParams.name = "chaser"
    --spawnParams.position = {x=52.073,y=43.119,z=33.56}
    spawnParams.position=position
    spawnParams.properties = {}
    spawnParams.properties.sharedSoulGuid = "490b0faa-1114-9cbb-f3a8-68e242922abc"
    spawnParams.properties.bWH_PerceptibleObject = 1
    local entity = System.SpawnEntity(spawnParams)
    if self.currentHorsePreset ~= nil then
        --entity.actor:EquipClothingPreset(self.currentHorsePreset)
    end
    
    for key, value in pairs(MercenaryHorseCaparisonGuids) do
        local caparison = self.Follower.inventory:FindItem(value)
        if caparison ~= nil then
            entity.inventory:CreateItem(value, 100, 1)
            local transferredItem = entity.inventory:FindItem(value)
            entity.actor:EquipInventoryItem(transferredItem)
        end
    end
    entity.AI.invulnerable = true
    self.FollowerHorse = entity
    
    self:Mount()
end

function MercenaryController:NextHorsePreset()
    if self.currentHorsePresetKey ~= nil then
        local key, v = next(MercenaryHorsePresets, self.currentHorsePresetKey)
        self.currentHorsePresetKey = key
    else
        local key = next(MercenaryHorsePresets)
        self.currentHorsePresetKey = key
    end

end

function MercenaryController:SetHorsePreset(guid)
    self.currentHorsePreset = guid
    Dump(self.currentHorsePreset)
end

function MercenaryController:HoldGround()
    local initmsg2 = Utils.makeTable('skirmish:command',{type="holdGround", clearQueue=true, immediate=true})
    XGenAIModule.SendMessageToEntityData(self.Follower.this.id,'skirmish:command',initmsg2);
end

function MercenaryController:UnstealItems()
    for key, item in pairs (self.Follower.inventory:GetInventoryTable()) do
        ItemManager.SetItemOwner(item, player.id, false)
    end
end

function MercenaryController:Mount()
    System.LogAlways("$5 attempting mount!")
    self.currentState = MercenaryState.AttemptingMount
    self.Follower.human:Mount(self.FollowerHorse.id)
    --local initmsg3 = Utils.makeTable('skirmish:command',{type="mountHorse",target=self.FollowerHorse.id, randomRadius=0.5, immediate=true, clearQueue=true})
    --XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:command',initmsg3);
    
    -- polearms are dropped automatically due to AI reset after dismount
    -- so we unequip it then re equip it
    local weapon = self.Follower.human:GetItemInHand(0)
    local isOversized = ItemManager.IsItemOversized(weapon)
    if isOversized and self.attemptReequipPolearm then
        self.Follower.inventory:AddItem(weapon)
        self.Follower.actor:UnequipInventoryItem(weapon)
        self.oversizeWeap = weapon
    end
    
    if self.preventSavingOnHorse then
        Utils.DisableSave(self.saveLockName,enum_disableSaveReason.script)
    end
end

function MercenaryController:Dismount()
    if self.FollowerHorse ~= nil then
        self.Follower.human:Dismount()
        self.currentState = MercenaryState.AttemptingDismount
    end
end

function MercenaryController:OrderAttack(entity)
    local initmsg2 = Utils.makeTable('skirmish:command',{type="attack",target=entity.this.id})
    XGenAIModule.SendMessageToEntityData(self.Follower.this.id,'skirmish:command',initmsg2);
end

function MercenaryController:OrderStop()
    local initmsg2 = Utils.makeTable('skirmish:command',{type="stopFighting", clearQueue=true, immediate=true})
    XGenAIModule.SendMessageToEntityData(self.Follower.this.id,'skirmish:command',initmsg2);
    local initmsg3 = Utils.makeTable('skirmish:command',{type="attackFollowPlayer",target=player.this.id, randomRadius=0.5 })
    XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:command',initmsg3);
end


function MercenaryController:ResetOrder()
    self:InitOrder()
    self:FollowOrder(true)
end

function MercenaryController:FollowOrder(force)
    force = force or false
    local initmsg3 = Utils.makeTable('skirmish:command',{type="attackFollowPlayer",target=player.this.id, randomRadius=1.5, clearQueue=true, immediate = force })
    XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:command',initmsg3);
end

-- resend order every so often if not on horse
function MercenaryController.ResendOrder(self)
    if self.FollowerHorse == nil and self.currentState == MercenaryState.OnFoot then
        self:FollowOrder()
        self.Follower.human:InterruptDialog()
    end
    Script.SetTimer(self.reorderInterval, self.ResendOrder, self)
end

function MercenaryController:InitOrder()
    local initmsg = Utils.makeTable('skirmish:init',{controller=self.Follower.soul:GetId(),isEnemy=false,oponentsNode=self.Follower.soul:GetId(),useQuickTargeting=false,targetingDistance=5.0, useMassBrain=self.useNormalBrain })
    XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:init',initmsg);
    local initmsg3 = Utils.makeTable('skirmish:barkSetup',{ metarole="UDELEJ_TO_NENASILNE", cooldown="30s", once=false, command="*", forceSubtitles = false})
    --local initmsg3 = Utils.makeTable('skirmish:barkSetup',{ metarole="COMBAT_CHARGE", cooldown="5s", once=false, command="*", forceSubtitles = true})
    XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:barkSetup',initmsg3);
end

function MercenaryController:IsPlayerOnHorse()
    local horseWuid = player.human:GetHorse()
    return horseWuid ~= INVALID_WUID
end

function MercenaryController:ControlledInitialized()
    System.LogAlways("$5 got a callback")
end

function MercenaryController.getrandomposnear(position, radius)
    -- deep copy
    local ret = {}
    ret.x = position.x
    ret.y = position.y
    ret.z = position.z
    ret.x = position.x + (math.random() * 2) - (math.random() * 2) + math.random(0, radius) - math.random(0, radius)
    ret.y = position.y + (math.random() * 2) - (math.random() * 2) + math.random(0, radius) - math.random(0, radius)
    return ret
end

function MercenaryController:TeleportToPlayer()
    if self:IsPlayerOnHorse() then
        local horse = XGenAIModule.GetEntityByWUID(player.human:GetHorse())
        local position = MercenaryController.getrandomposnear(horse:GetWorldPos(), 4)
        self.Follower:SetWorldPos(position)
        self:ResetOrder()
    else
        local position = MercenaryController.getrandomposnear(player:GetWorldPos(), 1)
        self.Follower:SetWorldPos(position)
        self:ResetOrder()
    end
end

function MercenaryController:TeleportHorseToPlayer()
    if self:IsPlayerOnHorse() then
        local horse = XGenAIModule.GetEntityByWUID(player.human:GetHorse())
        local position = MercenaryController.getrandomposnear(horse:GetWorldPos(), 4)
        self.FollowerHorse:SetWorldPos(position)
    else
        local position = MercenaryController.getrandomposnear(player:GetWorldPos(), 1)
        self.FollowerHorse:SetWorldPos(position)
    end
end

function MercenaryController:Kill()
    if self.Follower ~= nil then
        self.Follower.soul:SetState("health", 0)
        self.Follower:Hide(1)
        System.RemoveEntity(self.Follower.id)
        --self.Follower:DeleteThis()
        self.Follower = nil
    end 
end

function MercenaryController.KillHorse(self)
    if self.FollowerHorse ~= nil then
        self.FollowerHorse.soul:SetState("health", 0)
        Dump(self.FollowerHorse.actor:GetCurrentAnimationState())
        self.FollowerHorse:ResetAnimation(0,-1)
        Dump(self.FollowerHorse.actor:GetCurrentAnimationState())
        --self.FollowerHorse:Hide(1)
        --self.FollowerHorse:DeleteThis()
        System.RemoveEntity(self.FollowerHorse.id)
        self.FollowerHorse = nil
    end 
end

function MercenaryController.ResetAfterDismount(self)
    self:ResetOrder()
    if self.oversizeWeap ~= nil and self.attemptReequipPolearm then
        self.Follower.actor:EquipInventoryItem(self.oversizeWeap)
        self.Follower.human:DrawFromInventory(self.oversizeWeap, 0, false)
        self.oversizeWeap = nil
    end

    -- it breaks the horse as well if the horse animation state is dismount
    -- no way to fix that at the moment though
    if self.Follower.actor:GetCurrentAnimationState() ~= "Dismount" then
        self.KillHorse(self)
    else
        System.LogAlways("Something really bad happened. Attempted to delete horse in the middle of dismounting")
    end
    
    self.currentState = MercenaryState.OnFoot
    if self.preventSavingOnHorse then
        Game.RemoveSaveLock(self.saveLockName)
    end
end

function MercenaryController.WaitForReloadedMount(self)
    self.needReload = false
    self.ResendOrder(self)
end

function MercenaryController:MainLoop()
    if self.Follower ~= nil then
        if self.Follower.soul:GetState("health") < 1 then
            System.LogAlways("$5 Follower has died!")
            Game.ShowNotification("Your follower has died!")
            -- hopefully no memory leak if we don't call destroy entity (assuming that engine cleans up for us for corpse/ragdoll purposes)
            -- System.RemoveEntity(self.Follower.id)
            self.Follower = nil
            -- delete me for now
            System.RemoveEntity(self.id)
        else
            if self.currentState ~= MercenaryState.Waiting then
                -- only use state machine on horse
                if self.useHorse then
                    if self.currentState == MercenaryState.OnFoot then
                        if self.FollowerHorse ~= nil then
                            self:KillHorse()
                        end
                        if self:IsPlayerOnHorse() and self.FollowerHorse == nil then
                            self.currentState = MercenaryState.AttemptingMount
                            self:SpawnHorse()
                        end
                        

                    end
                    if self.currentState == MercenaryState.AttemptingMount then
                        if self.Follower.actor:GetCurrentAnimationState() == "MotionIdle" then
                            self.currentState = MercenaryState.OnHorse
                        end
                    end
                    if self.currentState == MercenaryState.AttemptingDismount then
                        if self.Follower.actor:GetCurrentAnimationState() == "MotionIdle" then
                            --Script.SetTimer(500, self.ResetAfterDismount, self)
                            self.ResetAfterDismount(self)
                            self.currentState = MercenaryState.OnFoot
                        end
                    end
                    if self.currentState == MercenaryState.OnHorse then
                         -- somehow got seperated from horse
                        if self:IsPlayerOnHorse() and self.FollowerHorse ~= nil then
                            local horseWuid = self.Follower.human:GetHorse()
                            -- not on a horse but follower horse still exists, basically a glitched state
                            if horseWuid == INVALID_WUID then
                                self.currentState = MercenaryState.OnFoot
                                self.KillHorse(self)
                            end
                        end
                        -- needs to execute this at the end due to state updates
                        if (not self:IsPlayerOnHorse() or player.actor:GetCurrentAnimationState() == "Dismount") and self.FollowerHorse ~= nil then
                            self:Dismount()
                            self.currentState = MercenaryState.AttemptingDismount
                        end
                    end
                end
                local playerPosition = player:GetWorldPos()
                if self.FollowerHorse == nil and self.currentState == MercenaryState.OnFoot then
                    local dist = DistanceSqVectors(self.Follower:GetWorldPos(), playerPosition)
                    if dist > self.MaxFollowDistSq then
                        self:TeleportToPlayer()
                    end
                else
                    local dist = DistanceSqVectors(self.FollowerHorse:GetWorldPos(), playerPosition)
                    if dist > self.MaxFollowDistSq then
                        self:TeleportHorseToPlayer()
                    end
                end
            else
                -- if waiting
                local dist = DistanceSqVectors(self.Follower:GetWorldPos(), playerPosition)
                if dist > self.MaxFollowDistSqWaiting then
                    self:TeleportToPlayer()
                end
            end
        end
    else
        -- dangling controller
        System.RemoveEntity(this.id)
    end
end

function MercenaryController:HandleReload()
    -- something really bad happened
    if self.Follower == nil then
        System.LogAlways("FollowerMod: Something really bad happened. A controller was saved without a follower. This controller will be deleted")
        System.RemoveEntity(this.id)
        return
    end
    -- this is all one big gigantic hack to give the game enough time
    -- signalling to a script doesn't work
    if self.signalFlag == false then
        System.LogAlways("Reloaded Follower")
        --Dump(self.Follower)
        
        self.Follower:SetViewDistUnlimited()
        self:AssignActions()
        if self.FollowerHorse~=nil or self.currentState == MercenaryState.OnHorse then
            System.LogAlways("Has Horse")
            if self.oversizeWeap ~= nil and self.attemptReequipPolearm then
                local class = self.oversizeWeap
                self.oversizeWeap = self.Follower.inventory:FindItem(class)
                self.Follower.actor:EquipInventoryItem(self.oversizeWeap)
                self.Follower.human:DrawFromInventory(self.oversizeWeap, 0, false)
                self.oversizeWeap = nil
            end
            -- the AI needs some time to process all the initialization
            -- forcing it to mount immediately interrupts everything and fucks it up for good
            self.KillHorse(self)
            -- hacky way of 'waiting' until everything is loaded because on level loaded doesn't work
            -- we don't get anything from the game to guarantee this
            -- the 'right' way is to do everythign in MBT because they have mailboxes for events
            -- but fuck MBT
            Script.SetTimer(5000, self.WaitForReloadedMount, self)
        else
            if self.currentState == MercenaryState.OnFoot then
                self:ResetOrder()
            end
            self.ResendOrder(self)
            --if we don't have a horse then we can start processing immediately
            self.needReload = false
        end
        self.signalFlag = true
    end
end

function MercenaryController:OnUpdate(delta)
    --System.LogAlways("$5 onupdate.")
    if self.needReload == true then
        self:HandleReload()
    else
        self:MainLoop()
    end
end