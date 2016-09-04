/*
	
	This is a lite implementation of the level script used for sublevels. It should be put in the sublevel root prim.
	Dependencies:
	- got LevelAux
	- got LevelLoader
	- got Portal
	- DB0 prim
	
	You can interchange LevelMethod$ with LevelLiteMethod$ and use the following ones:
	
*/
#define LevelLiteMethod$load LevelMethod$load			// (bool)edit_mode[, (str)group=JSON_INVALID] - Edit mode will let you move monsters and stuff around. JSON_INVALID = spawn at level start. Otherwise lets you spawn by group.

/*
Use same as got Level
#define LevelStorage$main "got Level"				// Contains 
	#define LevelShared$P1_start "a"						// (vec)pos
	#define LevelShared$P2_start "b"						// (vec)pos
	#define LevelShared$questData "c"				// Data passed from database about the quest
	#define LevelShared$isSharp "d"					// Contains the rez param TRUE for sharp spawn
#define LevelStorage$points "got HUD_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)desc, (str)spawnRound]
#define LevelStorage$custom "got Custom_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)desc, (str)spawnRound]
*/

#define LevelLiteEvt$load LevelEvt$load				// (int)debug, (str)group - Loading monsters has begun. If group is JSON_INVALID it means the level has started loading main

/*
You can use these because LevelLite is aliased for got Level
#define Level$loadDebug(group) runOmniMethod("got Level", LevelMethod$load, [1,group], TNN)
#define Level$loadSharp(group) runOmniMethod("got Level", LevelMethod$load, [0,group], TNN)
#define Level$intLoadSharp(group) runMethod((string)LINK_THIS, "got Level", LevelMethod$load, [0,group], TNN)
#define Level$spawnLive(asset, pos, rot) runOmniMethod("got Level", LevelMethod$spawn, [asset, pos, rot, FALSE], TNN)
#define Level$spawnLiveTarg(targ, asset, pos, rot) runMethod(targ, "got Level", LevelMethod$spawn, [asset, pos, rot, FALSE], TNN)
*/


