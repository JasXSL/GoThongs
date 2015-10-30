// This script adds additional dev features

#define LevelAuxMethod$purge 1		// Purge the level data
#define LevelAuxMethod$save 2		// (int)add - Saves current data. If add is set it will not purge before saving
#define LevelAuxMethod$list 3		// (int)HUD - Lists HUD or assets stored along with their IDs
#define LevelAuxMethod$stats 4		// void - Outputs stats
#define LevelAuxMethod$remove 5		// (int)HUD, (int)ID - Removes an asset from the spawn list
#define LevelAuxMethod$setData 6	// (str)table, (arr)index, (arr)value - Changes shared data manually
#define LevelAuxMethod$testSpawn 10	// (int)is_HUD, (int)storage_id, (int)live - Spawns an item by ID.

#define LevelAux$save(add) runOmniMethod("got LevelAux", LevelAuxMethod$save, [add], TNN)
#define LevelAux$purge() runOmniMethod("got LevelAux", LevelAuxMethod$purge, [], TNN)
#define LevelAux$stats() runOmniMethod("got LevelAux", LevelAuxMethod$stats, [], TNN)
#define LevelAux$setData(index, data) runOmniMethod("got LevelAux", LevelAuxMethod$setData, [index, data], TNN)
#define LevelAux$testSpawn(isHUD, id, live) runOmniMethod("got LevelAux", LevelAuxMethod$testSpawn, [isHUD, id, live], TNN)
#define LevelAux$list(isHUD) runOmniMethod("got LevelAux", LevelAuxMethod$list, [isHUD], TNN)
#define LevelAux$remove(isHUD, id) runOmniMethod("got LevelAux", LevelAuxMethod$remove, [isHUD, id], TNN)




