Follower_Mod = {
	cUniqueIdName="uniqueIdMercenaryMerchant",
	cost = 1000,
	currController = nil,
	horse = nil
}

function Follower_Mod.AssignActions(entity)
	entity.GetActions = function (user,firstFast)
		output = {}
		AddInteractorAction( output, firstFast, Action():hint("Hire Mercenary (1000 Groschen)"):action("use"):hintType( AHT_HOLD ):func(entity.OnUsed):interaction(inr_talk))
		return output
	end
	entity.OnUsed = function (self, user)
		--System.LogAlways("interacted")
		if player.inventory:GetMoney() < Follower_Mod.cost then
			Game.SendInfoText("You need 1000 Groschen",false,nil,5)
		else
			Game.SendInfoText("You paid 1000 Groschen for a follower",false,nil,5)
			--entity:DeleteThis()
			player.inventory:RemoveMoney(Follower_Mod.cost)
			Follower_Mod.create()
		end
	end
end

function Follower_Mod.FG_Init()
	local entity = System.GetEntityByName(Follower_Mod.cUniqueIdName) 
	if entity == nil then
		Follower_Mod.shop()
	else
		System.LogAlways("$5 Merchant already found")
		allcontrollers = System.GetEntitiesByClass("MercenaryController")
		local key, value = next(allcontrollers)
		Follower_Mod.currController = value
		entity:SetViewDistUnlimited()
		Follower_Mod.AssignActions(entity)
	end
	System.LogAlways("$5 Started mercenarymod")
end

function Follower_Mod.SpawnTestHostile()
	local position = player:GetWorldPos()
	System.LogAlways("$5 attempting to spawn test.")
	
	local vec = { x=2775.926, y=682.817, z=101.530 }
    local spawnParams = {}
    spawnParams.class = "NPC"
	spawnParams.radius = 5
    spawnParams.name = "chaser"
	spawnParams.position=position
    spawnParams.properties = {}	
	spawnParams.properties.sharedSoulGuid = "555f5566-eb38-4c64-bb66-4874ed68816c"
	spawnParams.properties.bWH_PerceptibleObject = 1
	local entity = System.SpawnEntity(spawnParams)
end

function Follower_Mod.horse()
	Follower_Mod.currController:SpawnHorse()
end
function Follower_Mod.horse2()
	Follower_Mod.currController:Dismount()
end


function Follower_Mod.teleport()
	Follower_Mod.currController:TeleportToPlayer()
end

function Follower_Mod.hardreset()
	Follower_Mod.currController:ResetOrder()
end

function Follower_Mod.shop()
	--create a guy to get stuff from
	local position = player:GetWorldPos()
	local spawnParams = {}
	spawnParams.class = "NPC"
	spawnParams.radius = 5
	spawnParams.name = Follower_Mod.cUniqueIdName
	local vec = { x=2775.926, y=682.817, z=101.530 }
	--spawnParams.position = {x=52.073,y=43.119,z=33.56}
	spawnParams.position=position
	spawnParams.properties = {}
	spawnParams.properties.sharedSoulGuid = "4eafa794-d75f-4ba1-daa6-1e91819f1cba"
	spawnParams.properties.bWH_PerceptibleObject = 1
	
	local entity = System.SpawnEntity(spawnParams)
	
	Follower_Mod.AssignActions(entity)
end

function Follower_Mod.create()
    local spawnParams = {}

    spawnParams.class = "MercenaryController"
    spawnParams.orientation = { x = 0, y = 0, z = 1 }
    spawnParams.properties = {}
    spawnParams.name = "merccontroller"
    local entity = System.SpawnEntity(spawnParams)
    entity:Spawn()
    System.LogAlways("$5 [MercenaryController] has been successfully created.")
    Follower_Mod.currController = entity
end

function Follower_Mod.uninstall()
	local entities = System.GetEntitiesByClass("MercenaryController")
	for key, value in pairs(entities) do
		System.RemoveEntity(value.id)
	end
	if Follower_Mod.currController ~= nil then
		--should have been removed in the code before
		--System.RemoveEntity(Follower_Mod.currController)
		Follower_Mod.currController = nil
	end
	local entity = System.GetEntityByName(Follower_Mod.cUniqueIdName) 
	if entity ~= nil then
		entity.soul:SetState("health", 0)
		entity:Hide(1)
		System.RemoveEntity(entity.id)
	end
end

System.AddCCommand("makehorse", "Follower_Mod.horse()", "[Debug] test follower")
System.AddCCommand("makehorse2", "Follower_Mod.horse2()", "[Debug] test follower")
System.AddCCommand("add_cuman", "Follower_Mod.SpawnTestHostile()", "[Debug] test follower")
System.AddCCommand("follower_teleport", "Follower_Mod.teleport()", "[Debug] test follower")
System.AddCCommand("follower_uninstall", "Follower_Mod.uninstall()", "[Debug] test follower")
System.AddCCommand("follower_make_shop", "Follower_Mod.shop()", "[Debug] test follower")
System.AddCCommand("follower_hard_reset", "Follower_Mod.hardreset()", "[Debug] test follower")
System.AddCCommand("follower_init", "Follower_Mod.create()", "[Debug] test follower")
