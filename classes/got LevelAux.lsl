// This script adds additional dev features

#define LevelAuxMethod$purge 1		// Purge the level data
#define LevelAuxMethod$save 2		// (int)deprecated, (str)group=NULL - Appends spawns to index
#define LevelAuxMethod$list 3		// (int)HUD - Lists HUD or assets stored along with their IDs
#define LevelAuxMethod$stats 4		// void - Outputs stats
#define LevelAuxMethod$remove 5		// (int)HUD, (int)ID - Removes an asset from the spawn list
#define LevelAuxMethod$testSpawn 10	// (int)is_HUD, (int)storage_id, (int)live - Spawns an item by ID.
#define LevelAuxMethod$assetVar 11	// (int)is_HUD, (int)ID, (int)index, (var)val - Sets item data.
#define LevelAuxMethod$getOffset 12 // (vec)global_pos - Returns local pos
#define LevelAuxMethod$spawn 13		// (str)prim, (vec)pos, (rot)rotation, (int)debug, (str)description
#define LevelAuxMethod$restoreFromBackup 14		// (str)api_key, (str)backup_token  - Overwrites spawner data with data from the server
#define LevelAuxMethod$ping 15					// void - Does nothing, but can callback

#define LevelAux$ping(callback) runOmniMethod("got LevelAux", LevelAuxMethod$ping, [], callback)
#define LevelAux$save(group) runOmniMethod("got LevelAux", LevelAuxMethod$save, [TRUE, group], TNN)
#define LevelAux$purge() runOmniMethod("got LevelAux", LevelAuxMethod$purge, [], TNN)
#define LevelAux$stats() runOmniMethod("got LevelAux", LevelAuxMethod$stats, [], TNN)
#define LevelAux$setData(index, data) runOmniMethod("got LevelAux", LevelAuxMethod$setData, [index, data], TNN)
#define LevelAux$testSpawn(isHUD, id, live) runOmniMethod("got LevelAux", LevelAuxMethod$testSpawn, [isHUD, id, live], TNN)
#define LevelAux$list(isHUD) runOmniMethod("got LevelAux", LevelAuxMethod$list, [isHUD], TNN)
#define LevelAux$remove(isHUD, id) runOmniMethod("got LevelAux", LevelAuxMethod$remove, [isHUD, id], TNN)
#define LevelAux$assetVar(isHUD, id, index, val) runOmniMethod("got LevelAux", LevelAuxMethod$assetVar, [isHUD, id, index, val], TNN)
#define LevelAux$getOffset(pos, cb) runOmniMethod("got LevelAux", LevelAuxMethod$getOffset, [pos], cb)
#define LevelAux$restoreFromBackup(targ, api_key, token) runMethod(targ, "got LevelAux", LevelAuxMethod$restoreFromBackup, [api_key, token], TNN)


#define LevelAux$spawnAsset(asset) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, [asset, llGetRootPosition()+llRot2Fwd(llGetRot()), 0, TRUE], TNN)
#define LevelAux$spawnNPC(asset) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, [asset, llGetRootPosition()+llRot2Fwd(llGetRot()), llEuler2Rot(<0,PI_BY_TWO,0>), TRUE], TNN)
#define LevelAux$spawnLive(asset, pos, rot) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, [asset, pos, rot, FALSE], TNN)
#define LevelAux$spawnLiveTarg(targ, asset, pos, rot) runMethod((string)(targ), "got LevelAux", LevelAuxMethod$spawn, [asset, pos, rot, FALSE], TNN)
// SAYs
#define LevelAux$spawn(prim, pos, rot, debug, description, group) runOmniMethod("got LevelAux", LevelAuxMethod$spawn, [prim, pos, rot, debug, description, group], TNN)
// Custom target
#define LevelAux$spawnTarg(targ, prim, pos, rot, debug, description, group) runMethod((str)targ, "got LevelAux", LevelAuxMethod$spawn, [prim, pos, rot, debug, description, group], TNN)


