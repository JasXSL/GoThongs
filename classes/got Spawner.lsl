#ifndef _Spawner
#define _Spawner

#define SpawnerMethod$spawn 1				// (str)obj, (vec)pos, (rot)rotation, (str)desc, N/A(legacy), (str)spawnround, (arr)rezParams - Spawnround is a label that you can remove by
#define SpawnerMethod$debug 2				// void - Outputs the queue into chat if something gets stuck
#define SpawnerMethod$remInventory 3		// [(arr)items] - Removes inventory items
#define SpawnerMethod$spawnThese 4			// (arr)items - Items should be sub-arrays containing SpawnerMethod$spawn values
#define SpawnerMethod$getAsset 5			// (str)item - Has the spawner give the object to the sender

#define SpawnerConst$ACK_CHAN 919238371		// Used to receive ack messages by portals. Portals receive their ack by this channel+1

#define Spawner$spawn(obj, pos, rot, desc, debug, _na, spawnround, rezParams) \
	runMethod(llGetOwner(), "got Spawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, 0, spawnround, mkarr((list)rezParams)], TNN)
#define Spawner$spawnTarg(targ, obj, pos, rot, desc, debug, _na, spawnround, rezParams) \
	runMethod((str)targ, "got Spawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, 0, spawnround, mkarr((list)rezParams)], TNN)
#define Spawner$spawnInt(obj, pos, rot, desc, debug, _na, spawnround, rezParams) \
	runMethod((string)LINK_SET, "got Spawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, 0, spawnround, mkarr((list)rezParams)], TNN)
#define Spawner$remInventory(assets) runMethod((string)LINK_SET, "got Spawner", SpawnerMethod$remInventory, [mkarr(assets)], TNN)
#define Spawner$spawnThese(targ, data) \
	runMethod((string)targ, "got Spawner", SpawnerMethod$spawnThese, data, TNN)
#define Spawner$getAsset(item) runMethod(llGetOwner(), "got Spawner", SpawnerMethod$getAsset, [item], TNN)


#endif
