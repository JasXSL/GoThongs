#define LevelMethod$update 0		// Updates scripts from HUD
#define LevelMethod$loaded 1		// (int)HUD_loaded - 2 = Scripts from HUD loaded, 1 = Monsters, 0 = Assets Whenever the loader has finished
#define LevelMethod$died 2			// Add one to the death counter
#define LevelMethod$load 3			// (bool)edit_mode[, (str)group=JSON_INVALID] - Edit mode will let you move monsters and stuff around. JSON_INVALID = spawn at level start. Otherwise lets you spawn by group.
#define LevelMethod$setFinished 4	// (key)player||(int)-1[, (bool)evtOnFinished] - Set that this player has finished the level. Once all players have finished, the cell moves to the next unless evtOnFinished is set in which case it raises LevelEvt$levelCompleted. If using the latter. Send this command again with "" for user to finalize. If player is -1, then all players have finished
#define LevelMethod$spawn 5			// [!MOVED to got LevelAux, forwarded from got Level for legacy purposes]
#define LevelMethod$loadFinished 6	// void - Level has finished loading

#define LevelMethod$getScripts 7	// (int)remotePin, (arr)scripts - Gets monster scripts from the level
#define LevelMethod$interact 8		// (key)clicker, (key)asset - Raises an interaction event
#define LevelMethod$trigger 9		// (key)person, (key)asset, (str)data - Raises an interaction event
#define LevelMethod$idEvent 10		// (int)event, (str)id, (arr)data - Raises a LevelEvt$id* event
#define LevelMethod$cellData 11		// (var)questData - QuestData received from database 
#define LevelMethod$cellDesc 12		// (str)description - Cell Description received from database
#define LevelMethod$getObjectives 13// void - Updates the sender on quest progress
#define LevelMethod$bindToLevel 14	// void - Bind my HUD to any level
#define LevelMethod$getPlayers 15	// void - Forces a LevelEvt$players event to trigger
#define LevelMethod$potionUsed 16	// name - Potion with PotionsFlag$raise_event used

#define LevelMethod$despawn 0x71771E5	// Deletes a level

#define LevelStorage$main "got Level"				// Contains 
	#define LevelShared$P1_start "a"						// (vec)pos
	#define LevelShared$P2_start "b"						// (vec)pos
	#define LevelShared$questData "c"				// Data passed from database about the quest
	#define LevelShared$isSharp "d"					// Contains the rez param TRUE for sharp spawn

// These also exist in versions with _1 & _2 appended	
#define LevelStorage$points "got HUD_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)desc, (str)spawnRound]
#define LevelStorage$custom "got Custom_Assets"		// Contains an array of arrays - [(str)name, (vec)pos, (rot)rotation, (str)desc, (str)spawnRound]
#define Level$HUD_TABLES [LevelStorage$points,LevelStorage$points+"_1",LevelStorage$points+"_2"]
#define Level$CUSTOM_TABLES [LevelStorage$custom,LevelStorage$custom+"_1",LevelStorage$custom+"_2"]


#define LevelEvt$players 0			// (arr)players - List of players has been updated
#define LevelEvt$interact 1			// (key)player, (key)asset - When a player has attempted to interact with an item that needs to run a check with the server
#define LevelEvt$load 2				// (int)debug, (str)group - Loading monsters has begun. If group is JSON_INVALID it means the level has started loading main
#define LevelEvt$trigger 3			// (key)player, (key)asset, (str)data - A trigger has been hit. Asset may have been removed from the sim by the time this is raised, don't rely too much on it

// These require an ID to be set and got Status to be present. See https://github.com/JasXSL/GoThongs/wiki/LevelDev---Monster-Setting-Sheet
#define LevelEvt$idSpawned 4	// (key)monster, (str)id, (arr)vars - An item has spawned as live
#define LevelEvt$idDied 5		// (key)monster, (str)id, (arr)vars, (str)spawnround - An item has been killed

#define LevelEvt$loaded 6		// void - Level has finished loading
#define LevelEvt$questData 7	// (var)questdata - Questdata has been received
#define LevelEvt$levelCompleted 8	// Used when you feed setFinished with the evtOnFinish variable

#define LevelEvt$fetchObjectives 9	// [(key)clicker] - Try to fetch objectives if there are any
#define LevelEvt$potion 10			// [(key)agent, (str)name] Potion used

#define LevelEvt$playerDied 11		// [(key)hud] - Raised when a player dies


// Level description config: [[(int)task, (var)param1, (var)param2...]...]
#define LevelDesc$additionalScripts 0			// List of names of scripts to wait for evt$SCRIPT_INIT from




#define Level$loadDebug(group) runOmniMethod("got Level", LevelMethod$load, [1,group], TNN)
#define Level$loadSharp(group) runOmniMethod("got Level", LevelMethod$load, [0,group], TNN)
#define Level$targLoadSharp(targ, group) runMethod((str)targ, "got Level", LevelMethod$load, [0,group], TNN)

#define Level$intLoadSharp(group) runMethod((string)LINK_THIS, "got Level", LevelMethod$load, [0,group], TNN)

#define Level$loadFinished() runMethod((string)LINK_THIS, "got Level", LevelMethod$loadFinished, [], TNN)


#define Level$despawn() runOmniMethod("got Level", LevelMethod$despawn, [], TNN)
#define Level$getScripts(targ, pin, scripts) runMethod((str)targ, "got Level", LevelMethod$getScripts, [pin, scripts], TNN)
#define Level$trigger(user, data) runOmniMethod("got Level", LevelMethod$trigger, [user, data], TNN)
#define Level$idEvent(evt, id, data, spawnround) runOmniMethod("got Level", LevelMethod$idEvent, [evt, id, data, spawnround], TNN)
#define Level$loaded(targ, isHUD) runMethod((str)targ, "got Level", LevelMethod$loaded, [isHUD], TNN)
#define Level$loadPerc(targ, id, perc) runMethod(targ, "got Level", LevelMethod$loadPerc, [id, perc], TNN)

// These methods require an event listener and a global: if(script == "#ROOT" && evt == RootEvt$level){ROOT_LEVEL = j(data, 0);}
#define Level$died() runOnPlayers(targ, runOmniMethodOn(targ, "got Level", LevelMethod$died, [], TNN);)
#define Level$cellData(data) runMethod(ROOT_LEVEL, "got Level", LevelMethod$cellData, [data], TNN)
#define Level$cellDesc(desc) runMethod(ROOT_LEVEL, "got Level", LevelMethod$cellDesc, [desc], TNN)
#define Level$setFinished(player, overrideFinish) runMethod((string)LINK_THIS, "got Level", LevelMethod$setFinished, [player, overrideFinish], TNN)
#define Level$getObjectives() runMethod(ROOT_LEVEL, "got Level", LevelMethod$getObjectives, [], TNN)
#define Level$bind(player) runLimitMethod(player, "got Level", LevelMethod$bindToLevel, [], TNN, 100)
#define Level$getPlayers() runMethod((str)LINK_THIS, "got Level", LevelMethod$getPlayers, [], TNN)
#define Level$potionUsed(name) runMethod(ROOT_LEVEL, "got Level", LevelMethod$potionUsed, [name], TNN)

// Moved functions
#define Level$spawnAsset(asset) #error Level$spawn* has moved to LevelAux$spawn* You can just replace Level$ with LevelAux$
#define Level$spawnNPC(asset) Level$spawnAsset(a)
#define Level$spawnLive(asset, pos, rot) Level$spawnAsset(a)
#define Level$spawnLiveTarg(targ, asset, pos, rot) Level$spawnAsset(a)



// Level internal
#define _lSharp() ((integer)db3$get("got Level", [LevelShared$isSharp]))






