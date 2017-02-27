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


// LevelLite supports the following level events

#define LevelLiteEvt$load LevelEvt$load					// (int)debug, (str)group - Loading monsters has begun. If group is JSON_INVALID it means the level has started loading main
#define LevelLiteEvt$loaded LevelEvt$loaded				// Cell has finished loading
#define LevelLiteEvt$interact LevelEvt$interact			// (key)player, (key)asset - When a player has attempted to interact with an item that needs to run a check with the server
#define LevelLiteEvt$trigger LevelEvt$trigger			// (key)player, (key)asset, (str)data - A trigger has been hit. Asset may have been removed from the sim by the time this is raised, don't rely too much on it
#define LevelLiteEvt$idSpawned LevelEvt$idSpawned 		// (key)monster, (str)id, (arr)vars - An item has spawned as live
#define LevelLiteEvt$idDied LevelEvt$idDied 			// (key)monster, (str)id, (arr)vars, (str)spawnround - An item has been killed
#define LevelLiteEvt$playerDied LevelEvt$playerDied



