#define RootMethod$reset 0						// Reset script
#define RootMethod$statusControls 1				// (int)controls - Additional controls for root to take
#define RootMethod$debugHuds 2					// void - Owner-says a JSON array of the coop HUDs
//#define RootMethod$setThongIni 3				// (int)has_thong		- Initialize thong
#define RootMethod$setTarget 4					// (key)target, (key)texture, (int)force_override|(key)pre_targ, (int)team - If pre_targ is a key, it only clears if that is the current target
#define RootMethod$getPlayers 5					// callbacks [(arr)players, (arr)huds]
#define RootMethod$setParty 6					// (key)coop_player, (key)players2... - 
#define RootMethod$setLevel 7					// void - Returns players
#define RootMethod$manageAdditionalPlayer 8		// (key)player, (int)rem - Adds or removes a player to be able to interact with the HUD and any monsters you spawn
#define RootMethod$attached 9					// Sent as omni com on HUD attach - Also used to get the coop player's HUD
#define RootMethod$refreshTarget 10				// (key)id, Force a target refresh command if id is "" or we are currently targeting ID
#define RootMethod$refreshPlayers 69			// void - Sends the players and coop_hud event. Good for debugging.

//#define RootEvt$thongKey 1						// Thong key has changed
#define RootEvt$flags 2							// (int)flags - Flags changed
#define RootEvt$targ 3							// [(key)targ, (key)icon, (int)team]
#define RootEvt$players 4						// (arr)players
#define RootEvt$level 5							// [(key)id, (bool)isChallenge] - Whenever a new cell has been ressed
#define RootEvt$coop_hud 6						// ["", (key)player1, (key)player2...] - Id of coop HUDs. Used by GUI
#define RootEvt$focus 7							// (int)index of player


//#define Root$refreshThong(targ) runMethod(targ, "#ROOT", RootMethod$refreshThong, [], TNN)
//#define Root$setThongIni(on) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setThongIni, [on], TNN)
#define Root$getPlayers(cb) runMethod(llGetOwner(), "#ROOT", RootMethod$getPlayers, [], cb)
#define Root$statusControls(conts) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$statusControls, [conts], TNN)
// Targets the sender
#define Root$targetMe(targ, texture, force, team) runMethod(targ, "#ROOT", RootMethod$setTarget, [llGetKey(), texture, force, team], TNN)
// Targets t
#define Root$targetT(targ, t, texture, force, team) runMethod(targ, "#ROOT", RootMethod$setTarget, [t, texture, force, team], TNN)

#define Root$targetThis(targ, texture, force, team) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setTarget, [targ, texture, force, team], TNN)
#define Root$aggro(targ) runMethod(targ, "#ROOT", RootMethod$aggro, [], TNN)
#define Root$setParty(uuids) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setParty, uuids, TNN)
#define Root$clearTargetOn(targ) runMethod(targ, "#ROOT", RootMethod$setTarget, ["", "", TRUE], TNN)
#define Root$clearTargetIfIs(targ, uuid) runMethod((str)targ, "#ROOT", RootMethod$setTarget, ["", "", uuid], TNN)
#define Root$setLevel() runMethod(llGetOwner(), "#ROOT", RootMethod$setLevel, [], "LV")
#define Root$setLevelOn(targ) runMethod(targ, "#ROOT", RootMethod$setLevel, [], TNN)
#define Root$addPlayer(player) runMethod(llGetOwner(), "#ROOT", RootMethod$manageAdditionalPlayer, [player], TNN)
#define Root$remPlayer(player) runMethod(llGetOwner(), "#ROOT", RootMethod$manageAdditionalPlayer, [player, TRUE], TNN)
#define Root$attached() llRegionSay(AOE_CHAN, (string)RUN_METHOD+":#ROOT"+llList2Json(JSON_ARRAY, [RootMethod$attached, "", llGetScriptName(), "ATTACHED"]))
#define Root$forceRefresh(targ, id) runMethod(targ, "#ROOT", RootMethod$refreshTarget, [id], TNN)
