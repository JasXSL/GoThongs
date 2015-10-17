#define SpawnerMethod$spawn 1				// (str)obj, (vec)pos, (rot)rotation

#define Spawner$spawn(obj, pos, rot) runMethod(llGetOwner(), "got Spawner", SpawnerMethod$spawn, [obj, pos, rot], TNN)
