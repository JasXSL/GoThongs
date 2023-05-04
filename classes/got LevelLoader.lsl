#ifndef _gotLevelLoader
#define _gotLevelLoader

#define LevelLoaderMethod$load 1			// (bool)debug, (var)group(s) | Group can be either a group name or a JSON array of multiple groups. 

#define LevelLoaderEvt$levelLoaded 1		// When loading the "" group, it will wait until all queues started within 5 sec have loaded.
#define LevelLoaderEvt$queueFinished 2		// (str)"HUD"/"CUSTOM", (arr)groups - A queue has finished loading

#define LevelLoader$load(debug, group) runMethod((str)LINK_ROOT, "got LevelLoader", LevelLoaderMethod$load, [debug, group], TNN)



#endif
