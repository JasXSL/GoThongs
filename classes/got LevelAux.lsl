#ifndef _gotLevelAux
#define _gotLevelAux

/* Table index for ALL level internal needs */
// Index for gotTable$meta
#define gotTable$meta$spawn0 db4$0		// (vector)player0_spawn_pos
#define gotTable$meta$spawn1 db4$1		// (vector)player1_spawn_pos (legacy)
#define gotTable$meta$levelData db4$2		// (var)levelData - Stores level data from site DB (like quest progress). Written to by got LevelData
#define gotTable$meta$levelSharp db4$3	// (bool)live - True when level was spawned through the HUD

#define LevelAuxConst$srcHud 0
#define LevelAuxConst$srcLocal 1

// Iterates over spawns
#define LevelAux$forSpawns( total, idx ) \
    integer total = db4$getIndex(gotTable$spawns); \
    integer idx; \
    for(; idx < total; ++idx )
        
// Gets the spawn data list
#define LevelAux$getSpawnData(idx) \
    llJson2List(db4$get(gotTable$spawns, idx))

/*
	Spawns are stored in gotTable$spawns. A DB4 indexed table with the following keys:
	0 : (int)spawn_repo. LevelAuxConst$srcHud = from HUD, LevelAuxConst$srcLocal = from local inventory
	1 : (str)obj_name
	2 : (vec)spawn_pos. Relative to level.
	3 : (rot)spawn_rot. Absolute.
	4 : (array)spawn_data. Custom data to be sent to the object on spawn.
	5 : (str)spawn_group. Lets you group or trigger spawns by name. Empty string are spawned on level load.
*/


// This script adds additional dev features

#define LevelAuxMethod$purge 1		// Purge the level data
#define LevelAuxMethod$save 2		// (str)group="" - Appends spawns to index
#define LevelAuxMethod$list 3		// (int)type, (str)search - Lists HUD or assets stored along with their IDs
#define LevelAuxMethod$stats 4		// void - Outputs stats
#define LevelAuxMethod$remove 5		// (int)ID - Removes an asset from the spawn list
#define LevelAuxMethod$testSpawn 10	// (int)storage_id, (int)live - Spawns an item by ID.
#define LevelAuxMethod$assetVar 11	// (int)ID, (int)index, (var)val - Sets item data.
#define LevelAuxMethod$getOffset 12 // (vec)global_pos - Returns local pos
#define LevelAuxMethod$spawn 13		// (str)prim, (vec)pos, (rot)rotation, (int)debug, (str)description
#define LevelAuxMethod$restoreFromBackup 14		// (str)api_key, (str)backup_token  - Overwrites spawner data with data from the server
#define LevelAuxMethod$ping 15					// void - Does nothing, but can callback
#define LevelAuxMethod$backup 16

#define LevelAux$ping(callback) runOmniMethod("got LevelAux", LevelAuxMethod$ping, [], callback)
#define LevelAux$save(group) runOmniMethod("got LevelAux", LevelAuxMethod$save, (list)(group), TNN)
#define LevelAux$purge() runOmniMethod("got LevelAux", LevelAuxMethod$purge, [], TNN)
#define LevelAux$stats() runOmniMethod("got LevelAux", LevelAuxMethod$stats, [], TNN)
#define LevelAux$setData(index, data) runOmniMethod("got LevelAux", LevelAuxMethod$setData, (list)index + data, TNN)
#define LevelAux$testSpawn(id, live) runOmniMethod("got LevelAux", LevelAuxMethod$testSpawn, (list)(id) + (live), TNN)
#define LevelAux$list(type, search) runOmniMethod("got LevelAux", LevelAuxMethod$list, (list)(type)+(search), TNN)
#define LevelAux$remove(id) runOmniMethod("got LevelAux", LevelAuxMethod$remove, (list)id, TNN)
#define LevelAux$assetVar(id, index, val) runOmniMethod("got LevelAux", LevelAuxMethod$assetVar, (list)(id) + (index) + (val), TNN)
#define LevelAux$getOffset(pos, cb) runOmniMethod("got LevelAux", LevelAuxMethod$getOffset, [pos], cb)
#define LevelAux$restoreFromBackup(targ, api_key, token) runMethod(targ, "got LevelAux", LevelAuxMethod$restoreFromBackup, (list)(api_key) + (token), TNN)
#define LevelAux$backup(targ, api_key, token) runMethod(targ, "got LevelAux", LevelAuxMethod$backup, [api_key, token], TNN)

#define LevelAux$spawnAsset(asset) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, (list)(asset) + (llGetRootPosition()+llRot2Fwd(llGetRot())) + 0 + TRUE, TNN)
#define LevelAux$spawnNPC(asset, rot) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, (list)(asset) + (llGetRootPosition()+llRot2Fwd(llGetRot())) + rot + TRUE, TNN)
#define LevelAux$spawnLive(asset, pos, rot) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, (list)(asset) + (pos) + (rot) + FALSE, TNN)
#define LevelAux$spawnLiveTarg(targ, asset, pos, rot) runMethod((string)(targ), "got LevelAux", LevelAuxMethod$spawn, (list)(asset) + (pos) + (rot) + FALSE, TNN)
// SAYs
#define LevelAux$spawn(prim, pos, rot, debug, description, group) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, (list)(prim) + (pos) + (rot) + (debug) + (description) + (group), TNN)
// Custom target
#define LevelAux$spawnTarg(targ, prim, pos, rot, debug, description, group) runMethod((str)targ, "got LevelAux", LevelAuxMethod$spawn, (list)(prim) + (pos) + (rot) + (debug) + (description) + (group), TNN)



#endif
