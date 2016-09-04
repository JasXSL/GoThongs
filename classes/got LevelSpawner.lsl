/*

	This script loads the levels from the HUD

*/
#define LevelSpawnerMethod$spawnLevel 1			// (str)level
#define LevelSpawnerMethod$remInventory 2		// [(arr)objects]

#define LevelSpawner$spawnLevel(level) runMethod((string)LINK_ALL_OTHERS, "got LevelSpawner", LevelSpawnerMethod$spawnLevel, [level], TNN)
#define LevelSpawner$spawnLevelOwner(level) runMethod((string)llGetOwner(), "got LevelSpawner", LevelSpawnerMethod$spawnLevel, [level], TNN)
#define LevelSpawner$remInventory(assets) runMethod((string)LINK_ALL_OTHERS, "got LevelSpawner", LevelSpawnerMethod$remInventory, [mkarr(assets)], TNN)

