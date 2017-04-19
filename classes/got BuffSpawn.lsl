/*
	Asset spawned from got BuffVis
*/

#define BuffSpawnMethod$purge 0 			// void - Removes ALL LTB spawns in the region

#define BuffSpawnConf$pos 0					// (vec)offset - Offsets from agent feet, multiplied by agent height & rotation
#define BuffSpawnConf$rot 1					// (rot)offset - Offsets from agent Z rotation
#define BuffSpawnConf$meta 2				// (var)any - Raises a BuffSpawnEvt$meta event

#define BuffSpawnChan(targ) playerChan(targ)+0x69

#define BuffSpawnEvt$meta 1					// (arr)metadata

#define BuffSpawn$purge() runOmniMethod("got BuffSpawn", BuffSpawnMethod$purge, [], TNN)
#define BuffSpawn$purgeTarg(targ) runMethod(targ, "got BuffSpawn", BuffSpawnMethod$purge, [], TNN)