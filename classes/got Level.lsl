#define LevelMethod$load 3		// (bool)edit_mode - Edit mode will let you move monsters and stuff around

#define LevelMethod$spawn 5		// (str)prim, (vec)pos, (rot)rotation, (int)debug

#define LevelMethod$getScripts 7	// (int)remotePin, (arr)scripts - Gets monster scripts from the level
#define LevelMethod$interact 8		// (key)clicker, (key)asset - Raises an interaction event
#define LevelMethod$trigger 9		// (key)person, (key)asset, (str)data - Raises an interaction event


#define LevelMethod$despawn 0x71771E5	// Deletes a level

#define LevelStorage$main "got Level"				// Contains 
	#define LevelShared$P1_start "a"						// (vec)pos
	#define LevelShared$P2_start "b"						// (vec)pos
	#define LevelShared$params "c"					// Data passed from database about the cell
	#define LevelShared$isSharp "d"					// Contains the rez param TRUE for sharp spawn
	
#define LevelStorage$points "got HUD_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)custom]
#define LevelStorage$custom "got Custom_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)custom]

#define LevelEvt$players 0			// (arr)players - List of players has been updated
#define LevelEvt$interact 1			// (key)player, (key)asset - When a player has attempted to interact with an item that needs to run a check with the server
#define LevelEvt$load 2				// (int)debug - Loading of the level has begun
#define LevelEvt$trigger 3			// (key)player, (key)asset, (str)data - A trigger has been hit. Asset may have been removed from the sim by the time this is raised, don't rely too much on it




#define Level$loadDebug() runOmniMethod("got Level", LevelMethod$load, [1], TNN)
#define Level$loadSharp() runOmniMethod("got Level", LevelMethod$load, [], TNN)


#define Level$despawn() runOmniMethod("got Level", LevelMethod$despawn, [], TNN)
#define Level$spawnAsset(asset) runOmniMethod("got Level", LevelMethod$spawn, [asset, llGetPos()+llRot2Fwd(llGetRot()), 0, TRUE], TNN)
#define Level$spawnNPC(asset) runOmniMethod("got Level", LevelMethod$spawn, [asset, llGetPos()+llRot2Fwd(llGetRot()), llEuler2Rot(<0,PI_BY_TWO,0>), TRUE], TNN)
#define Level$getScripts(pin, scripts) runOmniMethod("got Level", LevelMethod$getScripts, [pin, scripts], TNN)
#define Level$trigger(user, data) runOmniMethod("got Level", LevelMethod$trigger, [user, data], TNN)


#define _lSharp() ((integer)db2$get("got Level", [LevelShared$isSharp]))






