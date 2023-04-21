#ifndef _gotLevel
#define _gotLevel

#define LevelMethod$update 0		// Updates scripts from HUD
#define LevelMethod$loaded 1		// (int)HUD_loaded - 2 = Scripts from HUD loaded, 1 = Monsters, 0 = Assets Whenever the loader has finished
//#define LevelMethod$died 2			// MOVED to got LevelData
#define LevelMethod$load 3			// (bool)edit_mode[, (str)group=JSON_INVALID] - Edit mode will let you move monsters and stuff around. JSON_INVALID = spawn at level start. Otherwise lets you spawn by group.
#define LevelMethod$setFinished 4	// [PROXY for got LevelData]
#define LevelMethod$spawn 5			// [!MOVED to got LevelAux, forwarded from got Level for legacy purposes]
#define LevelMethod$loadFinished 6	// void - Level has finished loading
//#define LevelMethod$getScripts 7	// MOVED TO got LevelData 
#define LevelMethod$interact 8		// (key)clicker, (key)asset - Raises an interaction event
#define LevelMethod$trigger 9		// (key)person, (key)asset, (str)data - Raises an interaction event
#define LevelMethod$idEvent 10		// (int)event, (str)id, (arr)data - Raises a LevelEvt$id* event
//#define LevelMethod$cellData 11		// MOVED to got LevelData
//#define LevelMethod$cellDesc 12		// MOVED to got LevelData
#define LevelMethod$getObjectives 13// void - Updates the sender on quest progress
#define LevelMethod$bindToLevel 14	// void - Bind my HUD to any level
#define LevelMethod$getPlayers 15	// void - Forces a LevelEvt$players event to trigger
#define LevelMethod$potionUsed 16	// name - Potion with PotionsFlag$raise_event used
//#define LevelMethod$difficulty 17	// MOVED TO got LevelData
#define LevelMethod$enableWipeTracker 18	// [PROXY FOR got LevelData]
#define LevelMethod$playerInteract 19		// (key)interactee - Sent from the interactor
#define LevelMethod$potionDropped 20		// (str)name - Potion with PotionsFlag$raise_drop_event has been dropped

#define LevelMethod$raiseEvent 21			// (int)event, (var)param1, (var)param2... - Internal only
#define LevelMethod$playerSceneDone 22		// (str)sceneName, (bool)success, (arr)players



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

#define Level$ALL_TABLES Level$HUD_TABLES+Level$CUSTOM_TABLES+LevelStorage$main

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

#define LevelEvt$playerDied 11		// [(key)hud, (key)killer] - Raised when a player dies
#define LevelEvt$difficulty 12		// (int)difficulty, (bool)challenge - This is only raised when a quest starts. Mostly useful for challenge mode since you can't change difficulty.

#define LevelEvt$wipe 13			// All players dead (wipe tracker enabled)
#define LevelEvt$playerHUDs 14		// (arr)HUDs - Raised when party changes
#define LevelEvt$playerInteract 15	// (key)interactor, (key)interactee - Sent from the interactor 
#define LevelEvt$potionDropped 16	// (key)HUD, (str)potion - Raised when a player drops a potion with PotionsFlag$raise_drop_event
#define LevelEvt$playerSceneDone 17	// (str)pose_name, (bool)success, (arr)HUDs - Raised when a PlayerPose scene finished

// Level description config: [[(int)task, (var)param1, (var)param2...]...]
#define LevelDesc$additionalScripts 0			// List of names of scripts to wait for evt$SCRIPT_INIT from
#define LevelDesc$difficulty 1					// (int)difficulty, (int)isChallenge
#define LevelDesc$live 2						// void - Present when level is live


#define Level$loadDebug(group) runOmniMethod("got Level", LevelMethod$load, (list)1 + (group), TNN)
#define Level$loadSharp(group) runOmniMethod("got Level", LevelMethod$load, (list)0 + (group), TNN)
#define Level$targLoadSharp(targ, group) runMethod((str)targ, "got Level", LevelMethod$load, [0,group], TNN)
#define Level$intLoadSharp(group) runMethod((string)LINK_THIS, "got Level", LevelMethod$load, [0,group], TNN)
#define Level$loadFinished() runMethod((string)LINK_THIS, "got Level", LevelMethod$loadFinished, [], TNN)
#define Level$despawn() runOmniMethod("got Level", LevelMethod$despawn, [], TNN)
#define Level$trigger(user, data) runOmniMethod("got Level", LevelMethod$trigger, (list)user + data, TNN)
#define Level$idEvent(evt, id, data, spawnround) runOmniMethod("got Level", LevelMethod$idEvent, (list)(evt) + (id) + (data) + (spawnround), TNN)
#define Level$loaded(targ, isHUD) runMethod((str)targ, "got Level", LevelMethod$loaded, [isHUD], TNN)
#define Level$loadPerc(targ, id, perc) runMethod(targ, "got Level", LevelMethod$loadPerc, [id, perc], TNN)
// ??? These methods require an event listener and a global: if(script == "#ROOT" && evt == RootEvt$level){ROOT_LEVEL = j(data, 0);}
#define Level$getObjectives() runMethod(ROOT_LEVEL, "got Level", LevelMethod$getObjectives, [], TNN)
#define Level$bind(player) runOmniMethodOn(player, "got Level", LevelMethod$bindToLevel, [], TNN)
#define Level$getPlayers() runMethod((str)LINK_THIS, "got Level", LevelMethod$getPlayers, [], TNN)
#define Level$potionUsed(name) runMethod(ROOT_LEVEL, "got Level", LevelMethod$potionUsed, [name], TNN)
#define Level$potionDropped(name) runMethod(ROOT_LEVEL, "got Level", LevelMethod$potionDropped, [name], TNN)
#define Level$playerHUDs(huds) runOmniMethod("got Level", LevelMethod$playerHUDs, huds, TNN)
#define Level$playerInteract(level, victim) runMethod(level, "got Level", LevelMethod$playerInteract, [victim], TNN)
// Moved functions
#define Level$spawnAsset(asset) #error Level$spawn* has moved to LevelAux$spawn* You can just replace Level$ with LevelAux$
#define Level$spawnNPC(asset) Level$spawnAsset(a)
#define Level$spawnLive(asset, pos, rot) Level$spawnAsset(a)
#define Level$spawnLiveTarg(targ, asset, pos, rot) Level$spawnAsset(a)
#define Level$raiseEvent(evt, args) runMethod((str)LINK_THIS, "got Level", LevelMethod$raiseEvent, [evt]+args, TNN)
#define Level$playerSceneDone(host, success, players) runOmniMethodOn(host, "got Level", LevelMethod$playerSceneDone, (list)success + players, TNN)



// Level internal
#define _lSharp() ((integer)db3$get("got Level", (list)LevelShared$isSharp))


#endif



