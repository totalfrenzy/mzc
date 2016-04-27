
DEBUG_SPEW = 1

function CustomGameMode:InitGameMode()

	-- Get Rid of Shop button - Change the UI Layout if you want a shop button
	GameRules:GetGameModeEntity():SetHUDVisible(6, false)
	GameRules:GetGameModeEntity():SetCameraDistanceOverride(1300)
	GameRules:SetGoldPerTick(0)
	GameRules:SetStartingGold(5)


	-- DebugPrint
	Convars:RegisterConvar('debug_spew', tostring(DEBUG_SPEW), 'Set to 1 to start spewing debug info. Set to 0 to disable.', 0)
	
	-- Event Hooks
	ListenToGameEvent('entity_killed', Dynamic_Wrap(CustomGameMode, 'OnEntityKilled'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(CustomGameMode, 'OnPlayerPickHero'), self)
	--ListenToGameEvent('npc_spawned', Dynamic_Wrap(CustomGameMode, 'OnUnitSpawned'), self)

	-- Filters
    GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( CustomGameMode, "FilterExecuteOrder" ), self )

    -- Register Listener
    CustomGameEventManager:RegisterListener( "update_selected_entities", Dynamic_Wrap(CustomGameMode, 'OnPlayerSelectedEntities'))
   	CustomGameEventManager:RegisterListener( "repair_order", Dynamic_Wrap(CustomGameMode, "RepairOrder"))  	
    CustomGameEventManager:RegisterListener( "building_helper_build_command", Dynamic_Wrap(BuildingHelper, "BuildCommand"))
	CustomGameEventManager:RegisterListener( "building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "CancelCommand"))
	
	-- Full units file to get the custom values
	GameRules.AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  	GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
  	GameRules.ItemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  	GameRules.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")

    GameRules:SetHeroRespawnEnabled(false)
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetPostGameTime(100)
    GameRules:SetPreGameTime(0)
    GameRules:SetHeroSelectionTime(0)
    GameRules:SetGoldPerTick(0)
    GameRules:GetGameModeEntity():SetGoldSoundDisabled(true)
    GameRules:GetGameModeEntity():SetAnnouncerDisabled(true)
    GameRules:GetGameModeEntity():SetHUDVisible(DOTA_HUD_VISIBILITY_TOP_SCOREBOARD, false)

	base_game_mode:SetCustomGameForceHero("npc_Dota_hero_kunkka")
  	
  	-- Store and update selected units of each pID
	GameRules.SELECTED_UNITS = {}

	-- Keeps the blighted gridnav positions
	GameRules.Blight = {}
end

-- A player picked a hero
function CustomGameMode:OnUnitSpawned(keys)
	local unit = EntIndexToHScript(keys.entindex)

    if unit:IsRealHero() then
        local hero = unit
        local playerID = hero:GetPlayerID()

        CustomGameMode:OnHeroInGame(hero)

    else
        local unitName = unit:GetUnitName()
        if unitName and unitName ~= "" and not NPC_UNITS_CUSTOM[unitName] then
            Log:warn("A non-custom unit was spawned! "..unitName)
            unit:RemoveSelf()
        end
    end
end

function CustomGameMode:OnHeroInGame(hero)
    local playerID = hero:GetPlayerID()

    --if playerID == -1 then return end
    --if GetPlayerData(playerID) then --Don't create playerdata twice
     --   CustomGameMode:InitializeHero(playerID, hero) --INITIALIZE HERO
     --   return
    --end

    local playerData = CreateDataForPlayer(playerID)
    playerData.name = PlayerResource:GetPlayerName(playerID)

    if playerData.name == "" then -- This normally happens in dev tools
        playerData.name = 'Developer'
    end

    local teamID = PlayerResource:GetTeam(playerID)
    --if COOP_MAP then
        -- Player based colors
    --    PlayerResource:SetCustomPlayerColor(playerID, PlayerColors[playerID][1], PlayerColors[playerID][2], PlayerColors[playerID][3])
    --else
        -- Team location based colors
    --    PlayerResource:SetCustomPlayerColor(playerID, m_TeamColors[teamID][1], m_TeamColors[teamID][2], m_TeamColors[teamID][3])
    --end

    --playerData.sector = TEAM_TO_SECTOR[hero:GetTeamNumber()]

    self:InitializeHero(playerID, hero)
    self.playerSpawnIndexes[playerID] = playerData.sector + 1
    self.availableSpawnIndex = self.availableSpawnIndex + 1

    -- we must create the Elemental Summoner for this player
    --local sector = playerData.sector + 1
    --local summoner = CreateUnitByName("elemental_summoner", ElementalSummonerLocations[sector], false, nil, nil, hero:GetTeamNumber()) 
    --summoner:SetOwner(hero)
    --summoner:SetControllableByPlayer(playerID, true)
    --summoner:SetAngles(0, 270, 0)
    --summoner:AddItem(CreateItem("item_buy_pure_essence_disabled", nil, nil))
    --summoner.icon = CreateUnitByName("elemental_summoner_icon", ElementalSummonerLocations[sector], false, nil, nil, hero:GetTeamNumber())
    --playerData.summoner = summoner

    hero:SetBaseMaxHealth(playerData.health)
    hero:SetHealth(playerData.health)

    hero:ModifyGold(0)
    ModifyLumber(playerID, 0)  -- updates summoner spells

end

function GetPlayerData(playerID)
	return PlayerData[playerID]
end

function CustomGameMode:InitializeHero(playerID, hero)
    Log:info("InitializeHero "..playerID..":"..hero:GetUnitName())
    hero:AddNewModifier(nil, nil, "modifier_disarmed", {})
    hero:AddNewModifier(nil, nil, "modifier_attack_immune", {})
    hero:AddNewModifier(hero, nil, "modifier_max_ms", {ms=GameSettings:GetMapSetting("BuilderMoveSpeed")})
    --hero:AddNewModifier(hero, nil, "modifier_client_convars", {})
    local playerData = hero:GetPlayerID()
    --local playerData = GetPlayerData(playerID)

    --Timers(0.03, function() 
    --    hero:SetAbilityPoints(playerData.lumber or 0)
    --    SetCustomGold(playerID, playerData.gold)
    --end)

    -- Give building items
    hero:AddItem(CreateItem("item_build_arrow_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_cannon_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_periodic_tower_disabled", hero, hero))
    hero:AddAbility("tower")
    hero:AddAbility("dragon_tower")

    if not playerData.toggle_grid_item then
        playerData.toggle_grid_item = hero:AddItem(CreateItem("item_toggle_grid", hero, hero))
        playerData.toggle_grid_item.particles = setmetatable({}, {
            __index = (function(tab, index)
                tab[index] = {}
                return tab[index]
            end)
        })
    elseif IsValidEntity(playerData.toggle_grid_item) and playerData.toggle_grid_item_old then
        Timers(0.03, function()
            local item = hero:AddItem(playerData.toggle_grid_item_old)
            item:SetPurchaser(hero)
        end)
    end
    
    Timers:CreateTimer(0.1, function() hero:SwapItems(3, 5) end)

    -- Additional Heroes UI
    heroUI = hero:FindAbilityByName("hero_ui")
    if heroUI then
        heroUI:SetLevel(1)
    end

    UpdatePlayerSpells(playerID)
    UpdateScoreboard(playerID)
end

function CustomGameMode:OnPlayerPickHero(keys) --keys

	local hero = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
	local playerID = hero:GetPlayerID()

	-- Initialize Variables for Tracking
	player.units = {} -- This keeps the handle of all the units of the player, to iterate for unlocking upgrades
	player.structures = {} -- This keeps the handle of the constructed units, to iterate for unlocking upgrades
	player.buildings = {} -- This keeps the name and quantity of each building
	player.upgrades = {} -- This kees the name of all the upgrades researched
	player.lumber = 10 -- Secondary resource of the player

    -- Create city center in front of the hero
    --local position = hero:GetAbsOrigin() + hero:GetForwardVector() * 300
    --local city_center_name = "city_center"
	--local building = BuildingHelper:PlaceBuilding(player, city_center_name, position, true, 5) 

	-- Set health to test repair
	--building:SetHealth(building:GetMaxHealth()/3)

	-- These are required for repair to know how many resources the building takes
	--building.GoldCost = 100
	--building.LumberCost = 100
	--building.BuildTime = 15

	-- Add the building to the player structures list
	--player.buildings[city_center_name] = 1
	--table.insert(player.structures, building)

	CheckAbilityRequirements( hero, player )
	CheckAbilityRequirements( building, player )

	-- Add the hero to the player units list
	table.insert(player.units, hero)
	hero.state = "idle" --Builder state

	-- Spawn some peasants around the hero
	--local position = hero:GetAbsOrigin()
	--local numBuilders = 5
	--local angle = 360/numBuilders
	--for i=1,5 do
		--local rotate_pos = position + Vector(1,0,0) * 100
		--local builder_pos = RotatePosition(position, QAngle(0, angle*i, 0), rotate_pos)
--
		--local builder = CreateUnitByName("peasant", builder_pos, true, hero, hero, hero:GetTeamNumber())
		--builder:SetOwner(hero)
		--builder:SetControllableByPlayer(playerID, true)
		--table.insert(player.units, builder)
		--builder.state = "idle"
--
		---- Go through the abilities and upgrade
		--CheckAbilityRequirements( builder, player )
	--end

	-- Give Initial Resources
	

	hero:SetGold(10, false)
	ModifyLumber(player, 10)

	--GameMode:SetFogOfWarDisabled(true) 


	-- Lumber tick
	--Timers:CreateTimer(1, function()
	--	ModifyLumber(player, 10)
	--	return 10
	--end)

	-- Give a building ability
	--local item = CreateItem("item_build_wall", hero, hero)
	--hero:AddItem(item)

	-- Learn all abilities (this isn't necessary on creatures)
	for i=0,15 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then ability:SetLevel(ability:GetMaxLevel()) end
	end
	hero:SetAbilityPoints(0)

end

-- An entity died
function CustomGameMode:OnEntityKilled( event )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript(event.entindex_killed)
	-- The Killing entity
	local killerEntity
	if event.entindex_attacker then
		killerEntity = EntIndexToHScript(event.entindex_attacker)
	end

	-- Player owner of the unit
	local player = killedUnit:GetPlayerOwner()

	-- Building Killed
	if IsCustomBuilding(killedUnit) then

		 -- Building Helper grid cleanup
		BuildingHelper:RemoveBuilding(killedUnit, true)

		-- Check units for downgrades
		local building_name = killedUnit:GetUnitName()
				
		-- Substract 1 to the player building tracking table for that name
		if player.buildings[building_name] then
			player.buildings[building_name] = player.buildings[building_name] - 1
		end

		-- possible unit downgrades
		for k,units in pairs(player.units) do
		    CheckAbilityRequirements( units, player )
		end

		-- possible structure downgrades
		for k,structure in pairs(player.structures) do
			CheckAbilityRequirements( structure, player )
		end
	end

	-- Cancel queue of a builder when killed
	if IsBuilder(killedUnit) then
		BuildingHelper:ClearQueue(killedUnit)
	end

	-- Table cleanup
	if player then
		-- Remake the tables
		local table_structures = {}
		for _,building in pairs(player.structures) do
			if building and IsValidEntity(building) and building:IsAlive() then
				--print("Valid building: "..building:GetUnitName())
				table.insert(table_structures, building)
			end
		end
		player.structures = table_structures
		
		local table_units = {}
		for _,unit in pairs(player.units) do
			if unit and IsValidEntity(unit) then
				table.insert(table_units, unit)
			end
		end
		player.units = table_units		
	end
end

-- Called whenever a player changes its current selection, it keeps a list of entity indexes
function CustomGameMode:OnPlayerSelectedEntities( event )
	local pID = event.pID

	GameRules.SELECTED_UNITS[pID] = event.selected_entities

	-- This is for Building Helper to know which is the currently active builder
	local mainSelected = GetMainSelectedEntity(pID)
	if IsValidEntity(mainSelected) and IsBuilder(mainSelected) then
		local player = PlayerResource:GetPlayer(pID)
		player.activeBuilder = mainSelected
	end
end
