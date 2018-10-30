// Player interaction spawner

#define gotPISpawner$spawn(obj, pos, rot, desc, debug, temp, spawnround) runMethod(llGetOwner(), "got PISpawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp, spawnround], TNN)
#define gotPISpawner$spawnInt(obj, pos, rot, desc, debug, temp, spawnround) runMethod((string)LINK_SET, "got PISpawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp, spawnround], TNN)
#define gotPISpawner$remInventory(assets) runMethod((string)LINK_SET, "got PISpawner", SpawnerMethod$remInventory, [mkarr(assets)], TNN)
#define gotPISpawner$spawnThese(targ, data) runMethod((string)targ, "got PISpawner", SpawnerMethod$spawnThese, data, TNN)
#define gotPISpawner$getAsset(item) runMethod(llGetOwner(), "got PISpawner", SpawnerMethod$getAsset, [item], TNN)

