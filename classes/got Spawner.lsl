#define SpawnerMethod$spawn 1				// (str)obj, (vec)pos, (rot)rotation, (str)desc
#define SpawnerMethod$debug 2				// void - Outputs the queue into chat if something gets stuck

#define Spawner$spawn(obj, pos, rot, desc, debug, temp) runMethod(llGetOwner(), "got Spawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp], TNN)
#define Spawner$spawnInt(obj, pos, rot, desc, debug, temp) runMethod((string)LINK_THIS, "got Spawner", SpawnerMethod$spawn, [obj, pos, rot, desc, debug, temp], TNN)
