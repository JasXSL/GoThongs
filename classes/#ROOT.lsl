#ifndef _ROOT
#define _ROOT


// DB table row definitions
// Root table
#define gotTable$root$targ db4$0			// UUID of current target
#define gotTable$root$focus db4$1			// UUID of focus target
#define gotTable$root$level db4$2			// UUID of level
#define gotTable$root$levelIsChallenge db4$3	// 0/1 level is challenge dungeon
#define gotTable$root$levelIsLive db4$4			// 0/1 level is live
#define gotTable$root$supportCube db4$5			// uuid of support cube

#define hud$root$targ() db4$fget(gotTable$root, gotTable$root$targ)
#define hud$root$focus() db4$fget(gotTable$root, gotTable$root$focus)
#define hud$root$level() db4$fget(gotTable$root, gotTable$root$level)
#define hud$root$levelIsChallenge() ((int)db4$fget(gotTable$root, gotTable$root$levelIsChallenge))
#define hud$root$levelIsLive() ((int)db4$fget(gotTable$root, gotTable$root$levelIsLive))
#define hud$root$supportCube() db4$fget(gotTable$root, gotTable$root$supportCube)

#define hud$root$numPlayers() db4$getIndex(gotTable$rootPlayers)
#define hud$root$numHuds() db4$getIndex(gotTable$rootHuds)

#define RootConst$chanQuickControl 717713		// When an edge event control happens and if we are sitting on something it will send a message on this channel containing (int)pressed$(int)released


#define RootMethod$reset 0						// Reset script
#define RootMethod$statusControls 1				// (int)controls - Additional controls for root to take
#define RootMethod$debugHuds 2					// void - Owner-says a JSON array of the coop HUDs
//#define RootMethod$setThongIni 3				// (int)has_thong		- Initialize thong
#define RootMethod$setTarget 4					// (key)target, (key)texture, (int)force_override|(key)pre_targ, (int)team - If pre_targ is a key, it only clears if that is the current target
#define RootMethod$getPlayers 5					// (int)channel=0 - callbacks [(arr)players, (arr)huds] - If channel is specified, it instead sends a JSON array to the sender on that channel. Useful if you want to make non-xobj ways of fetching players.
#define RootMethod$setParty 6					// (key)coop_player, (key)players2... - 
#define RootMethod$setLevel 7					// void - Returns players
#define RootMethod$manageAdditionalPlayer 8		// (key)player, (int)rem - Adds or removes a player to be able to interact with the HUD and any monsters you spawn
#define RootMethod$attached 9					// Sent as omni com on HUD attach - Also used to get the coop player's HUD
#define RootMethod$refreshTarget 10				// (key)id, Force a target refresh command if id is "" or we are currently targeting ID
#define RootMethod$getTarget 11					// void - Callbacks the key of your current target
#define RootMethod$refreshPlayers 69			// void - Sends the players and coop_hud event. Good for debugging.
#define RootMethod$targetCoop 12				// (key)hud_id - Tries to target a coop player by HUD ID
#define RootMethod$blockControls 13				// (bool)block - Blocks or unblocks controls. Tied to the prim that sends this command.
#define RootMethod$raiseLevelEvent 14			// void - Owner only. Forces the HUD to raise a level changed event. Used for addons to instantly get level data.


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
#define Root$getPlayersFast(chan) runMethod(llGetOwner(), "#ROOT", RootMethod$getPlayers, [chan], TNN)

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
#define Root$getTarget(targ, cb) runMethod(targ, "#ROOT", RootMethod$getTarget, [], cb)
#define Root$targetCoop(targ, hud) runMethod((str)targ, "#ROOT", RootMethod$targetCoop, (list)hud, TNN)
#define Root$blockControls(targ, block, cb) runMethod((str)targ, "#ROOT", RootMethod$blockControls, (list)block, cb)
#define Root$raiseLevelEvent() runMethod(llGetOwner(), "#ROOT", RootMethod$raiseLevelEvent, [], TNN)



// This is a custom call that bypasses XOBJ. Send it on AOE_CHAN and it sends back "GHD"+json_array(HUDs) on the same channel
#define Root$getHUDSLight(targ) llRegionSayTo(targ, AOE_CHAN, "GHD")

#endif
