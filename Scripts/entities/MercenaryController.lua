MercenaryController = {
	useHorse = true,
	attemptReequipPolearm = true,
	useNormalBrain = true,
	needReload = false,
	attemptingDismount = false,
	attemptingMount = false,
	onHorse = false,
	Follower = nil,
	FollowerHorse = nil,
	MaxFollowDistSq = 900,
	MaxFollowDistSqHorse = 1800,
	oversizeWeap = nil
}

function MercenaryController:OnSpawn()
	-- needed for OnUpdate callback
	self:Activate(1)
end

function MercenaryController:OnDestroy()
	self:Kill()
	self.KillHorse(self)
end

-- doing this inside of the NPC behaviors was horrendous and impossible to test
-- this is the option we take when we need control of the AI
function MercenaryController:SearchForHostiles()
    local playerPos = player:GetWorldPos() 
    local safeRadius = 2.5
    local ents = System.GetEntitiesInSphere(self.Follower:GetWorldPos(), safeRadius)
    if ents and #ents > 0 then
        for i,e in pairs(ents) do
			if e.class == "NPC" and e.this.id ~= self.Follower.this.id and e.this.id ~= player.this.id then
				local pos = e:GetWorldPos()
				System.LogAlways("$5 found a man")
				local dist = DistanceSqVectors(self.Follower:GetWorldPos(), pos)
				if dist < 5 and dist > 0.01 then
					self:OrderAttack(e)
				end
				System.LogAlways(tostring(dist))
			end
		end
	end		
end

function MercenaryController:SetStats()
	self.Follower.soul:AdvanceToStatLevel("str",15)
	self.Follower.soul:AdvanceToStatLevel("agi",15)
	self.Follower.soul:AdvanceToStatLevel("vit",15)
	self.Follower.soul:AdvanceToSkillLevel("defense",12)
	self.Follower.soul:AdvanceToSkillLevel("weapon_large",12)
	self.Follower.soul:AdvanceToSkillLevel("weapon_sword",12)
	self.Follower.soul:AddPerk(string.upper("d2da2217-d46d-4cdb-accb-4ff860a3d83e")) -- perfect block
	self.Follower.soul:AddPerk(string.upper("ec4c5274-50e3-4bbf-9220-823b080647c4")) -- riposte
	self.Follower.soul:AddPerk(string.upper("3e87c467-681d-48b5-9a8c-485443adcd42")) -- pommel strike
end


function MercenaryController:OnSave(table)
	if self.Follower == nil then
		System.LogAlways("$5 Tried to save but follower is nil!!")
	end
	table.Follower = self.Follower:GetGUID()
	table.FollowerHorse = self.FollowerHorse:GetGUID()
end

function MercenaryController:OnLoad(table)
	System.LogAlways("$5 OnLoad")
	self.Follower = System.GetEntityByGUID(table.Follower)
	self.FollowerHorse = System.GetEntityByGUID(table.FollowerHorse)
	if self.Follower == nil then
		System.LogAlways("$5 Load Failed")
	end
	self.Follower:SetViewDistUnlimited()
	self.needReload=true
end

function MercenaryController:AssignActions()
	self.Follower.GetActions = function (self,firstFast)
		output = {}
		AddInteractorAction( output, firstFast, Action():hint("Manage Follower"):action("use"):func(self.Manage):interaction(inr_talk))
		AddInteractorAction( output, firstFast, Action():hint("Give/Take Items"):action("mount_horse"):func(self.GiveItems):interaction(inr_talk))
		AddInteractorAction( output, firstFast, Action():hint("Retire Follower"):action("mount_horse"):hintType( AHT_HOLD ):func(self.Retire):interaction(inr_talk))
		AddInteractorAction( output, firstFast, Action():hint("Heal"):action("use"):hintType( AHT_HOLD ):func(self.Heal):interaction(inr_talk))
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
		System.RemoveEntity(self.id)
		Game.SendInfoText("Follower has left your service.",false,nil,5)
	end
	self.Follower.Heal = function (self, user)
		self.soul:SetState( "health", 100 )
		--self.soul:SetState( "stamina", 100 );
		self.soul:SetState( "exhaust", 50 )
		self.soul:SetState( "hunger", 100 )
		-- HACKY CODE DUPLICATION
		-- references are too much work here so just copy the code in
		local initmsg3 = Utils.makeTable('skirmish:command',{type="attackFollowPlayer",target=player.this.id, randomRadius=0.5, clearQueue=true, immediate=true})
		XGenAIModule.SendMessageToEntityData(self.soul:GetId(),'skirmish:command',initmsg3);
		
		Game.SendInfoText("I'm all healed up.",false,nil,5)
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
	self:InitOrder()
	self:AssignActions()
	self:FollowOrder()
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
	self.FollowerHorse = entity
	self.attemptingMount = true
	self.Follower.human:Mount(entity.id)
	
	-- polearms are dropped automatically due to AI reset after dismount
	-- so we unequip it then re equip it
	local weapon = self.Follower.human:GetItemInHand(0)
	local isOversized = ItemManager.IsItemOversized(weapon)
	if isOversized then
		self.Follower.inventory:AddItem(weapon)
		self.Follower.actor:UnequipInventoryItem(weapon)
		self.oversizeWeap = weapon
	end
end

function MercenaryController:Dismount()
	if self.FollowerHorse ~= nil then
		self.Follower.human:Dismount()
		self.attemptingDismount = true
	end
end

function MercenaryController:OrderAttack(entity)
	local initmsg2 = Utils.makeTable('skirmish:command',{type="attack",target=entity.this.id})
	XGenAIModule.SendMessageToEntityData(self.Follower.this.id,'skirmish:command',initmsg2);
end


function MercenaryController:ResetOrder()
	self:InitOrder()
	self:FollowOrder()
end

function MercenaryController:FollowOrder()
	--only capable of following player for now
	System.LogAlways("$5 Sending follow order")
	local initmsg3 = Utils.makeTable('skirmish:command',{type="attackFollowPlayer",target=player.this.id, randomRadius=0.5, clearQueue=true, immediate=true})
	XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:command',initmsg3);
	-- attack move command is buggy right now due to perception targetting changes
	--local initmsg2 = Utils.makeTable('skirmish:command',{type="attackMove",target=player.this.id})
	--XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:command',initmsg2);
end

function MercenaryController:InitOrder()
	local initmsg = Utils.makeTable('skirmish:init',{controller=player.this.id,isEnemy=false,oponentsNode=player.this.id,useQuickTargeting=false,targetingDistance=10.0, useMassBrain=self.useAggressiveBrain })
	XGenAIModule.SendMessageToEntityData(self.Follower.soul:GetId(),'skirmish:init',initmsg);
end

function MercenaryController:IsPlayerOnHorse()
	local horseWuid = player.human:GetHorse()
	return horseWuid ~= INVALID_WUID
end

function MercenaryController.getrandomposnear(position)
	-- deep copy
	local ret = {}
	ret.x = position.x
	ret.y = position.y
	ret.z = position.z
	ret.x = position.x + math.random() - math.random()
	ret.y = position.y + math.random() - math.random()
	return ret
end

function MercenaryController:TeleportToPlayer()
	
	if self:IsPlayerOnHorse() then
		local horse = XGenAIModule.GetEntityByWUID(horseWuid)
		local position = MercenaryController.getrandomposnear(horse:GetWorldPos())
		self.Follower:SetWorldPos(horse)
	else
		local position = MercenaryController.getrandomposnear(player:GetWorldPos())
		self.Follower:SetWorldPos(position)
	end
end

function MercenaryController:Kill()
	if self.Follower ~= nil then
		self.Follower.soul:SetState("health", 0)
		self.Follower:Hide(1)
		System.RemoveEntity(self.Follower.id)
		self.Follower = nil
	end	
end

function MercenaryController.KillHorse(self)
	if self.FollowerHorse ~= nil then
		self.FollowerHorse.soul:SetState("health", 0)
		self.FollowerHorse:Hide(1)
		System.RemoveEntity(self.FollowerHorse.id)
		self.FollowerHorse = nil
	end	
end

function MercenaryController.ResetAfterDismount(self)
	
	if self.oversizeWeap ~= nil and self.attemptReequipPolearm then
		self.Follower.actor:EquipInventoryItem(self.oversizeWeap)
		self.Follower.human:DrawFromInventory(self.oversizeWeap, 0, false)
		self.oversizeWeap = nil
	end
	self.onHorse = false
	--self.KillHorse(self)
	self:ResetOrder()
end

function MercenaryController:OnUpdate(delta)
	--System.LogAlways("$5 onupdate.")
	if self.needReload == true then
		--Dump(self.Follower)
		self:InitOrder()
		self:FollowOrder()
		self:AssignActions()
		self.needReload = false
	end
	if self.Follower ~= nil then
		if self.Follower.soul:GetState("health") < 1 then
			System.LogAlways("$5 Has died!")
			-- hopefully no memory leak if we don't call destroy entity (assuming that engine cleans up for us for corpse/ragdoll purposes)
			self.Follower = nil
			-- delete me for now
			System.RemoveEntity(self.id)
		else
			if self:IsPlayerOnHorse() and self.FollowerHorse == nil and self.onHorse == false and self.onHorse == false then
				self:SpawnHorse()
			end
			if not self:IsPlayerOnHorse() and self.FollowerHorse ~= nil and self.attemptingDismount == false then
				self:Dismount()
			end
			
			if self.attemptingMount and self.Follower.actor:GetCurrentAnimationState() == "MotionIdle" then
				self.attemptingMount = false
				self.onHorse = true
			end
			if self.attemptingDismount and self.Follower.actor:GetCurrentAnimationState() == "MotionIdle" then
			System.LogAlways("should only print once")	
				Script.SetTimer(1000, self.ResetAfterDismount, self)
				self.attemptingDismount = false
			end
			local playerPosition = player:GetWorldPos()
			local dist = DistanceSqVectors(self.Follower:GetWorldPos(), playerPosition)
			if dist > self.MaxFollowDistSq and self.FollowerHorse == nil then
				self:TeleportToPlayer()
			end
		end
	end
end