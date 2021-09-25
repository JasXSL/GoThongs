#ifndef _PISpawner
#define _PISpawner

// Player interaction spawner

// Has custom methods above 100
#define gotPiSpawnerMethod$generateInteraction 100	// (list)players/huds, (float)duration, (vec)pos=auto, (rot)rotation=auto, (bool)no_instigator
#define gotPiSpawnerMethod$callback 101				// Callback received from above request
#define gotPiSpawnerMethod$testInteraction 102		// (int)id, (float)duration, (key)player1, (key)player2...

#define gotPISpawner$spawn(obj, pos, rot, desc, debug, temp, spawnround) runMethod(llGetOwner(), "got PISpawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp, spawnround], TNN)
#define gotPISpawner$spawnInt(obj, pos, rot, desc, debug, temp, spawnround) runMethod((string)LINK_SET, "got PISpawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp, spawnround], TNN)
#define gotPISpawner$spawnTarg(targ, obj, pos, rot, desc, debug, temp, spawnround) runMethod((str)targ, "got PISpawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp, spawnround], TNN)
#define gotPISpawner$remInventory(assets) runMethod((string)LINK_SET, "got PISpawner", SpawnerMethod$remInventory, [mkarr(assets)], TNN)
#define gotPISpawner$spawnThese(targ, data) runMethod((string)targ, "got PISpawner", SpawnerMethod$spawnThese, data, TNN)
#define gotPISpawner$getAsset(item) runMethod(llGetOwner(), "got PISpawner", SpawnerMethod$getAsset, [item], TNN)

#define gotPISpawner$testInteraction(interaction, duration, players) \
	runMethod(llGetOwner(), "got PISpawner", gotPiSpawnerMethod$testInteraction, (list)interaction + duration + players, TNN)

#define gotPISpawner$generateInteraction(players, duration, pos, rot, no_instigator) \
	runMethod(llGetOwner(), "got PISpawner", gotPiSpawnerMethod$generateInteraction, (list)mkarr((list)players)+duration+pos+rot+no_instigator, TNN)
#define gotPISpawner$generateInteractionOn(target, players, duration, pos, rot, no_instigator) runMethod((str)target, "got PISpawner", gotPiSpawnerMethod$generateInteraction, (list)mkarr((list)players)+duration+pos+rot+no_instigator, TNN)

#define gotPISpawner$callback(targ, raw_data) runMethod((str)targ, "got PISpawner", gotPiSpawnerMethod$callback, (list)raw_data, TNN)

#endif

