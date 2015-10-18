#define RootMethod$reset 0						// Reset script
#define RootMethod$statusControls 1				// (int)controls - Additional controls for root to take
#define RootMethod$refreshThong 2				// (int)phys_id - Update thong
#define RootMethod$setThongIni 3				// (int)has_thong		- Initialize thong
#define RootMethod$setTarget 4					// (key)target, (key)texture, (int)force_override
#define RootMethod$getPlayers 5					// NULL - Returns an array of players
#define RootMethod$setParty 6					// (key)coop_player - 

#define RootShared$thongUUID "a"				// UUID of last attached thong
#define RootShared$flags "b"
	#define RootFlag$ini 1							// UUID fetched
	#define RootFlag$game_started 2					// 
#define RootShared$players "c"					// [(key)self, (key)coop_player]
#define RootShared$targ "d"						// (key)selected_target


#define RootEvt$thongKey 1						// Thong key has changed
#define RootEvt$flags 2							// (int)flags - Flags changed
#define RootEvt$targ 3							// [(key)targ, (key)icon]
#define RootEvt$players 4						// (arr)players
#define RootEvt$monsterTarg 5					// [(key)targ, (key)icon] - ROOT has a monster target that stays in the background while cycling

#define Root$refreshThong(phys) runMethod(llGetOwner(), "#ROOT", RootMethod$refreshThong, [phys], TNN)
#define Root$setThongIni(on) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setThongIni, [on], TNN)
#define Root$getPlayers(cb) runMethod(llGetOwner(), "#ROOT", RootMethod$getPlayers, [], cb)
#define Root$statusControls(conts) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$statusControls, [conts], TNN)
// Targets the sender
#define Root$targetMe(targ, texture, force) runMethod(targ, "#ROOT", RootMethod$setTarget, [llGetKey(), texture, force], TNN)
// Targets a key (internal)
#define Root$targetThis(targ, texture, force) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setTarget, [targ, texture, force], TNN)
#define Root$aggro(targ) runMethod(targ, "#ROOT", RootMethod$aggro, [], TNN)
#define Root$setParty(uuid) runMethod((string)LINK_ROOT, "#ROOT", RootMethod$setParty, [uuid], TNN)
#define Root$clearTargetOn(targ) runMethod(targ, "#ROOT", RootMethod$setTarget, ["", "", TRUE], TNN)

#define THONG_KEY ((key)db2$get("#ROOT", [RootShared$thongUUID]))

#define _getPlayers() llJson2List(db2$get("#ROOT", [RootShared$players]))
#define _getTarg() (key)db2$get("#ROOT", ([RootShared$targ, 0]))


