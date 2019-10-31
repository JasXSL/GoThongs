#ifndef _NPCInt
#define _NPCInt

/*
	This script offloads got Status, handling the following:
	- Status textures
	- Player targeting
	
*/

#define NPCIntChan$targeting(user) (playerChan(user)+0x745)
#define NPCInt$setTargeting(targ, on) llRegionSayTo(targ, NPCIntChan$targeting(llGetOwnerKey(targ)), (string)on)
	#define NPCInt$targeting 0x1			// simple targeting
	#define NPCInt$focusing 0x2			// focusing as well
	
#define NPCIntMethod$stacksChanged 16	// NPC Only, use got Evts for PC. (int)PID, (int)added, (float)duration, (int)stacks - Sent when stacks have changed.
#define NPCIntMethod$addTextureDesc 9	// PC uses EvtMethod$addTextureDesc | pid, texture, desc, added, duration, stacks, casterSubstr(8), (int)flags - Adds a spell icon
#define NPCIntMethod$remTextureDesc 10	// PC uses EvtMethod$remTextureDesc | (key)texture						
#define NPCIntMethod$getTextureDesc 11	// (int)pos, (key)texture - Gets info about a spell by pos
#define NPCIntMethod$takehit 1		// void - Triggers monster take hit visual
#define NPCIntMethod$rapeMe 2			// void - Sent as omni from player upon death


#define NPCInt$addTextureDesc(pid, texture, desc, added, duration, stacks, casterKey, flags) runMethod((string)LINK_ROOT, "got NPCInt", NPCIntMethod$addTextureDesc, [pid, texture, desc, added, duration, stacks, llGetSubString(casterKey,0,7), flags], TNN)
#define NPCInt$remTextureDesc(pid) runMethod((string)LINK_ROOT, "got NPCInt", NPCIntMethod$remTextureDesc, [pid], TNN)
#define NPCInt$getTextureDesc(targ, pid) runMethod(targ, "got NPCInt", NPCIntMethod$getTextureDesc, [pid], TNN)
#define NPCInt$stacksChanged(pid, added, duration, stacks) runMethod((string)LINK_ROOT, "got NPCInt", NPCIntMethod$stacksChanged, [pid, added, duration, stacks], TNN)
#define NPCInt$hitfx(targ) runMethod(targ, "got NPCInt", NPCIntMethod$takehit, [], TNN)

#define NPCInt$rapeMe() runOnPlayers(k, runLimitMethod(k, "got NPCInt", NPCIntMethod$rapeMe, [], TNN, 10);)



#endif
