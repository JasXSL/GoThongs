#define LevelSpawnerMethod$spawnLevel 1			// (str)level


#define LevelSpawner$spawnLevel(level) runMethod((string)LINK_ALL_OTHERS, "got LevelSpawner", LevelSpawnerMethod$spawnLevel, [level], TNN)
