#define LevelLoaderMethod$load 1	// (bool)debug, (var)group(s) | Group can be either a group name or a JSON array of multiple groups. 

#define LevelLoaderEvt$defaultStatus 1		// (bool)has_assets, (bool)has_spawns - Raised 10 sec after a "" spawn request hase been received

#define LevelLoader$load(debug, group) runMethod((str)LINK_ROOT, "got LevelLoader", LevelLoaderMethod$load, [debug, group], TNN)



