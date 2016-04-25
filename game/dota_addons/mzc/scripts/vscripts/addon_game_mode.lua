---------------------------------------------------------------------------
if CustomGameMode == nil then
	_G.CustomGameMode = class({})
end

require('gamemode')
require('utilities')
require('upgrades')
require('mechanics')
require('orders')
require('builder')
require('buildinghelper')

require('libraries/timers')
require('libraries/popups')
require('libraries/notifications')

function Precache( context )

	-- Model ghost and grid particles
	PrecacheResource("particle_folder", "particles/buildinghelper", context)
	PrecacheResource("particle_folder", "particles/econ/items/earthshaker/earthshaker_gravelmaw/", context)

	-- Resources used
	PrecacheUnitByNameSync("peasant", context)
	PrecacheUnitByNameSync("tower", context)
	PrecacheUnitByNameSync("tower_tier2", context)
	PrecacheUnitByNameSync("city_center", context)
	PrecacheUnitByNameSync("city_center_tier2", context)
	PrecacheUnitByNameSync("tech_center", context)
	PrecacheUnitByNameSync("dragon_tower", context)
	PrecacheUnitByNameSync("dark_tower", context)
	PrecacheUnitByNameSync("wall", context)

	PrecacheItemByNameSync("item_apply_modifiers", context)

end

-- Create our game mode and initialize it
function Activate()
	CustomGameMode:InitGameMode()
end

---------------------------------------------------------------------------




--[[
	OUT OF VECTOR IS CAUSING ISSUES? CNetworkOriginCellCoordQuantizedVector m_cellZ cell 155 is outside of cell bounds (0->128) @(-15714.285156 -15714.285156 23405.712891)
	NEED TO ADD ABILITY_BUILDING AND QUEUE MANUALLY, NECESSARY?
	COLLISION SIZE?
]]--