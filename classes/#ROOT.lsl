#define RootMethod$reset 0						// Reset script
#define RootMethod$statusControls 1				// (int)controls - Additional controls for root to take
//#define RootMethod$refreshThong 2				// (int)phys_id - Update thong
//#define RootMethod$setThongIni 3				// (int)has_thong		- Initialize thong
#define RootMethod$setTarget 4					// (key)target, (key)texture, (int)force_override, (int)team
#define RootMethod$getPlayers 5					// NULL - Returns an array of players
#define RootMethod$setParty 6					// (key)coop_player - 
#define RootMethod$setLevel 7					// void - Returns players
#define RootMethod$manageAdditionalPlayer 8		// (key)player, (int)rem - Adds or removes a player to be able to interact with the HUD and any monsters you spawn
#define RootMethod$attached 9					// Sent as omni com on HUD attach - Also used to get the coop player's HUD

//#define RootEvt$thongKey 1						// Thong key has changed
#define RootEvt$flags 2							// (int)flags - Flags changed
#define RootEvt$targ 3							// [(key)targ, (key)icon, (int)team]
#define RootEvt$players 4						// (arr)players
#define RootEvt$level 5							// [(key)id] - Whenever a new cell has been ressed
#define RootEvt$coop_hud 6						// (key)id - Id of coop HUD. Used by GUI

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
#define Root$setParty(uuid) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setParty, [uuid], TNN)
#define Root$clearTargetOn(targ) runMethod(targ, "#ROOT", RootMethod$setTarget, ["", "", TRUE], TNN)
#define Root$setLevel() runMethod(llGetOwner(), "#ROOT", RootMethod$setLevel, [], "LV")
#define Root$setLevelOn(targ) runMethod(targ, "#ROOT", RootMethod$setLevel, [], TNN)
#define Root$addPlayer(player) runMethod(llGetOwner(), "#ROOT", RootMethod$manageAdditionalPlayer, [player], TNN)
#define Root$remPlayer(player) runMethod(llGetOwner(), "#ROOT", RootMethod$manageAdditionalPlayer, [player, TRUE], TNN)
#define Root$attached() llRegionSay(AOE_CHAN, (string)RUN_METHOD+":#ROOT"+llList2Json(JSON_ARRAY, [RootMethod$attached, "", llGetScriptName(), "ATTACHED"]))

