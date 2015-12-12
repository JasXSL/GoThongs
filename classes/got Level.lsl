#define LevelMethod$update 0		// Updates scripts from HUD
#define LevelMethod$loaded 1		// (int)HUD_loaded - Whenever the loader has finished
#define LevelMethod$died 2			// Add one to the death counter
#define LevelMethod$load 3			// (bool)edit_mode[, (str)group=JSON_INVALID] - Edit mode will let you move monsters and stuff around. JSON_INVALID = spawn at level start. Otherwise lets you spawn by group.
#define LevelMethod$setFinished 4	// (key)player[, (bool)evtOnFinished] - Set that this player has finished the level. Once all players have finished, the cell moves to the next unless evtOnFinished is set in which case it raises LevelEvt$levelCompleted. If using the latter. Send this command again with "" for user to finalize
#define LevelMethod$spawn 5			// (str)prim, (vec)pos, (rot)rotation, (int)debug
#define LevelMethod$loadFinished 6	// void - Level has finished loading

#define LevelMethod$getScripts 7	// (int)remotePin, (arr)scripts - Gets monster scripts from the level
#define LevelMethod$interact 8		// (key)clicker, (key)asset - Raises an interaction event
#define LevelMethod$trigger 9		// (key)person, (key)asset, (str)data - Raises an interaction event
#define LevelMethod$idEvent 10		// (int)event, (str)id, (arr)data - Raises a LevelEvt$id* event
#define LevelMethod$cellData 11		// (var)questData - QuestData received from database 
#define LevelMethod$cellDesc 12		// (str)description - Cell Description received from database
#define LevelMethod$getObjectives 13// void - Updates the sender on quest progress


#define LevelMethod$despawn 0x71771E5	// Deletes a level

#define LevelStorage$main "got Level"				// Contains 
	#define LevelShared$P1_start "a"						// (vec)pos
	#define LevelShared$P2_start "b"						// (vec)pos
	#define LevelShared$questData "c"				// Data passed from database about the quest
	#define LevelShared$isSharp "d"					// Contains the rez param TRUE for sharp spawn
	
#define LevelStorage$points "got HUD_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)custom]
#define LevelStorage$custom "got Custom_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)custom]

#define LevelEvt$players 0			// (arr)players - List of players has been updated
#define LevelEvt$interact 1			// (key)player, (key)asset - When a player has attempted to interact with an item that needs to run a check with the server
#define LevelEvt$load 2				// (int)debug, (str)group - Loading monsters has begun. If group is JSON_INVALID it means the level has started loading main
#define LevelEvt$trigger 3			// (key)player, (key)asset, (str)data - A trigger has been hit. Asset may have been removed from the sim by the time this is raised, don't rely too much on it

// These require an ID to be set and got Status to be present. See https://github.com/JasXSL/GoThongs/wiki/LevelDev---Monster-Setting-Sheet
#define LevelEvt$idSpawned 4	// (key)monster, (str)id, (arr)vars - An item has spawned as live
#define LevelEvt$idDied 5		// (key)monster, (str)id, (arr)vars - An item has been killed

#define LevelEvt$loaded 6		// void - Level has finished loading
#define LevelEvt$questData 7	// (var)questdata - Questdata has been received
#define LevelEvt$levelCompleted 8	// Used when you feed setFinished with the evtOnFinish variable

#define LevelEvt$fetchObjectives 9	// (key)clicker - Try to fetch objectives if there are any


#define Level$loadDebug(group) runOmniMethod("got Level", LevelMethod$load, [1,group], TNN)
#define Level$loadSharp(group) runOmniMethod("got Level", LevelMethod$load, [0,group], TNN)
#define Level$intLoadSharp(group) runMethod((string)LINK_THIS, "got Level", LevelMethod$load, [0,group], TNN)

#define Level$loadFinished() runMethod((string)LINK_THIS, "got Level", LevelMethod$loadFinished, [], TNN)


#define Level$despawn() runOmniMethod("got Level", LevelMethod$despawn, [], TNN)
#define Level$spawnAsset(asset) runOmniMethod("got Level", LevelMethod$spawn, [asset, llGetPos()+llRot2Fwd(llGetRot()), 0, TRUE], TNN)
#define Level$spawnNPC(asset) runOmniMethod("got Level", LevelMethod$spawn, [asset, llGetPos()+llRot2Fwd(llGetRot()), llEuler2Rot(<0,PI_BY_TWO,0>), TRUE], TNN)
#define Level$getScripts(pin, scripts) runOmniMethod("got Level", LevelMethod$getScripts, [pin, scripts], TNN)
#define Level$trigger(user, data) runOmniMethod("got Level", LevelMethod$trigger, [user, data], TNN)
#define Level$idEvent(evt, id, data) runOmniMethod("got Level", LevelMethod$idEvent, [evt, id, data], TNN)
#define Level$loaded(targ, isHUD) runMethod(targ, "got Level", LevelMethod$loaded, [isHUD], TNN)
#define Level$loadPerc(targ, id, perc) runMethod(targ, "got Level", LevelMethod$loadPerc, [id, perc], TNN)
#define Level$died() runMethod(db2$get("#ROOT", [RootShared$level]), "got Level", LevelMethod$died, [], TNN)
#define Level$cellData(data) runMethod(db2$get("#ROOT", [RootShared$level]), "got Level", LevelMethod$cellData, [data], TNN)
#define Level$cellDesc(desc) runMethod(db2$get("#ROOT", [RootShared$level]), "got Level", LevelMethod$cellDesc, [desc], TNN)
#define Level$setFinished(player, overrideFinish) runMethod((string)LINK_THIS, "got Level", LevelMethod$setFinished, [player, overrideFinish], TNN)
#define Level$getObjectives() runMethod(db2$get("#ROOT", [RootShared$level]), "got Level", LevelMethod$getObjectives, [], TNN)
#define Level$spawnLive(asset, pos, rot) runOmniMethod("got Level", LevelMethod$spawn, [asset, pos, rot, FALSE], TNN)


#define _lSharp() ((integer)db2$get("got Level", [LevelShared$isSharp]))






