#ifndef _gotLevelSpawner
#define _gotLevelSpawner

/*

	This script loads the levels from the HUD

*/
#define LevelSpawnerMethod$spawnLevel 1			// (str)level
#define LevelSpawnerMethod$remInventory 2		// [(arr)objects]
#define LevelSpawnerMethod$setLoading 3			// void | Sets loading screen on a player

#define LevelSpawner$spawnLevel(level) runMethod((string)LINK_ALL_OTHERS, "got LevelSpawner", LevelSpawnerMethod$spawnLevel, [level], TNN)
#define LevelSpawner$spawnLevelOwner(level) runMethod((string)llGetOwner(), "got LevelSpawner", LevelSpawnerMethod$spawnLevel, [level], TNN)
#define LevelSpawner$remInventory(assets) runMethod((string)LINK_ALL_OTHERS, "got LevelSpawner", LevelSpawnerMethod$remInventory, [mkarr(assets)], TNN)
#define LevelSpawner$setLoading(targ) runMethod((string)targ, "got LevelSpawner", LevelSpawnerMethod$setLoading, [], TNN)

#endif
