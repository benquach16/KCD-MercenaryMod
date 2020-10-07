Follower_Mod = {
    cUniqueIdName="uniqueIdMercenaryMerchant",
    cost = 1000,
    controllers = {},
    horse = nil,
    test = nil,
    doorName = "AnimDoor_4c1cc10b-8f58-23e9-075f-b7301d156880"
}

function Follower_Mod.AssignActions(entity)
    entity.GetActions = function (user,firstFast)
        output = {}
        AddInteractorAction( output, firstFast, Action():hint("Hire Mercenary (800 Groschen)"):action("use"):hintType( AHT_HOLD ):func(entity.OnUsed):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Hire Expensive Mercenary (3200 Groschen)"):action("mount_horse"):hintType( AHT_HOLD ):func(entity.OnUsed2):interaction(inr_talk))
        AddInteractorAction( output, firstFast, Action():hint("Change Horse Caparison"):action("block"):hintType( AHT_HOLD ):func(entity.Horse):interaction(inr_talk))
        return output
    end
    entity.OnUsed = function (self, user)
        --System.LogAlways("interacted")
        if player.inventory:GetMoney() < 800 then
            Game.SendInfoText("You need 800 Groschen",false,nil,5)
        else
            Game.SendInfoText("You paid 800 Groschen for a follower",false,nil,5)
            --entity:DeleteThis()
            player.inventory:RemoveMoney(800)
            local entity = Follower_Mod.create()
            entity.actor:EquipClothingPreset("46136347-ff79-f5c0-217e-31f235a34b9c")
        end
    end
    entity.OnUsed2 = function (self, user)
        --System.LogAlways("interacted")
        if player.inventory:GetMoney() < 3200 then
            Game.SendInfoText("You need 3200 Groschen",false,nil,5)
        else
            Game.SendInfoText("You paid 3200 Groschen for a follower",false,nil,5)
            --entity:DeleteThis()
            player.inventory:RemoveMoney(3200)
            local entity = Follower_Mod.create()
        end
    end
    entity.Horse = function (self, user)
        Game.SendInfoText("Changed",false,nil,5)
        for k, value in pairs (Follower_Mod.controllers) do
            Follower_Mod.controllers[k]:NextHorsePreset()
        end
    end
end

-- HACK
-- this function exists for a horrendously stupid edge case
-- where the follower might lock the door to your room because the game logic is shit
function Follower_Mod.Unlock()
    
    --local door = System.GetEntityByName(Follower_Mod.doorName)
    local center = { x = 2552.936, y = 460.0597, z = 68.0108 }
    local ents = System.GetEntitiesInSphere(center, 1.0)
    local door = nil
    for key,value in pairs(ents) do
        --System.LogAlways("found something")
        door = value
    end
    if door == nil then
        System.LogAlways("could not find door")
    end
    door.Properties.Lock.bNeverLock = 1
    door:SetNeverLock(true)
    door.shouldLockOverride_onEnter = false
    door.shouldLockOverride_onExit = false
    door:SetLockpickLegal(true)
    door.Properties.Lock.bLockInside = 0
    door.Properties.Lock.bLockOutside = 0
    door.Properties.fLockDifficulty = 0
    -- We don't need this as it correctly follows the unlock quest
    -- but this is for safety
    -- door:Unlock()
    System.LogAlways("force unlocked door")
end

function Follower_Mod.FG_Init()
    local entity = System.GetEntityByName(Follower_Mod.cUniqueIdName) 
    if entity == nil then
        Follower_Mod.shop()
    else
        System.LogAlways("$5 Merchant already found")
        local allcontrollers = System.GetEntitiesByClass("MercenaryController")
        for k, value in pairs (allcontrollers) do
            table.insert(Follower_Mod.controllers, value)
        end
        entity:SetViewDistUnlimited()
        Follower_Mod.AssignActions(entity)
    end
    Follower_Mod.Unlock()
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
    spawnParams.properties.sharedSoulGuid = "4957c994-1489-f528-130c-a00b9838a4a5"
    spawnParams.properties.bWH_PerceptibleObject = 1
    local entity = System.SpawnEntity(spawnParams)
    Follower_Mod.test = entity
end

function Follower_Mod.unsteal()
    for k, value in pairs (Follower_Mod.controllers) do
        Follower_Mod.controllers[k]:UnstealItems()
    end
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
    spawnParams.position=vec
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
    table.insert(Follower_Mod.controllers, entity)
    
    return entity.Follower
end

function Follower_Mod.uninstall()
    local entities = System.GetEntitiesByClass("MercenaryController")
    for key, value in pairs(entities) do
        System.RemoveEntity(value.id)
    end
    for k, value in pairs (Follower_Mod.controllers) do
        Follower_Mod.controllers[k] = nil
    end
    local entity = System.GetEntityByName(Follower_Mod.cUniqueIdName) 
    if entity ~= nil then
        entity.soul:SetState("health", 0)
        entity:Hide(1)
        System.RemoveEntity(entity.id)
    end
end

System.AddCCommand("follower_unlock", "Follower_Mod.Unlock()", "[Debug] test follower")
System.AddCCommand("add_cuman", "Follower_Mod.SpawnTestHostile()", "[Debug] test follower")
System.AddCCommand("follower_uninstall", "Follower_Mod.uninstall()", "[Debug] test follower")
System.AddCCommand("follower_make_shop", "Follower_Mod.shop()", "[Debug] test follower")
System.AddCCommand("follower_unsteal", "Follower_Mod.unsteal()", "[Debug] test follower")
System.AddCCommand("follower_init", "Follower_Mod.create()", "[Debug] test follower")
