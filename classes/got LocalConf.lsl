#ifndef _LocalConf
#define _LocalConf

// Monsters
#define LocalConfMethod$ini 0					// Sends out the LocalConfEvt$iniData event


#define LocalConfMethod$startSpell 1			// (int)id
#define LocalConfMethod$interruptSpell 2		// (int)id
#define LocalConfMethod$finishSpell 3			// (int)id
#define LocalConfMethod$testIdle 4				// null - Debug command only. Tests the monsters's idle animation
#define LocalConfMethod$checkCastSpell 5		// (int)id, (key)targ, expects callback true on success
#define LocalConfMethod$stdInteract 6			// (key)sender, (key)object, (var)data - A player has interacted with the object. You can input anything you want as variables
#define LocalConfMethod$generic 7 				// Generic method, put any data you want in it. Effect will vary between implementations
#define LocalConfMethod$grapple 8				// key targ - Used with NPC template to start a grapple (needs to be compiled with grapples). Deprecated. Call methods at got MonsterGrapple instead
#define LocalConfMethod$grappleEnable 9			// (bool)on - Used with NPC template to enable/disable grapple code.Deprecated. Call methods at got MonsterGrapple instead
#define LocalConfMethod$canHookup 10			// (arr)gotTable$monsterGrappleHup_indexes - Sent from got MonsterGrapple to check conditions for a hookup. Indexes map to gotTable$monsterGrappleHup and are poses that are valid.


#define LocalConf$startSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$startSpell, [id], TNN)
#define LocalConf$interruptSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$interruptSpell, [id], TNN)
#define LocalConf$finishSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$finishSpell, [id], TNN)
#define LocalConf$ini() runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$ini, [], TNN)
#define LocalConf$checkCastSpell(id, targ, cb) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$checkCastSpell, [id, targ], cb)
#define LocalConf$stdInteract(targ, sender, data) runMethod(targ, "got LocalConf", LocalConfMethod$stdInteract, [sender]+data, TNN)
// Useful for monster scripts that aren't named LocalConf
#define LocalConf$stdInteractByScript(targ, script, sender, data) runMethod(targ, script, LocalConfMethod$stdInteract, [sender]+data, TNN)
#define LocalConf$generic(targ, params) runMethod((str)(targ), "got LocalConf", LocalConfMethod$generic, (list)params, TNN)
#define LocalConf$grappleEnable(targ, on) #error "Method LocalConf$grappleEnable is deprecated, check got MonsterGrapple instead"
//runMethod((str)(targ), "got LocalConf", LocalConfMethod$grappleEnable, (list)(on), TNN)
#define LocalConf$canHookup(hupClientIndexes) runMethod((str)LINK_THIS, "got LocalConf", LocalConfMethod$canHookup, (list)mkarr(hupClientIndexes), TNN)


// note: these are hardcoded. not all NPCs will raise these events
#define LocalConfEvt$iniData 1		// Separate from evt$SCRIPT_INIT in that this is raised on demand and contains script custom data
									// This data will vary based on the object the conf is in
									// For monster data see got Monster
#define LocalConfEvt$emulateAttack 2// Emulates an attack for monsters without mesh anims

#define LocalConfEvt$meta 9				// (str)action, ... - Can be raised by NPCs to let monsterscript & mods have more information. For an example: The portal imp hump spell. These should be noted at the top of the script.

// These can be used in monsters if you want									
list localConfAnims;
string localConfIdle;					
#define localConfCacheAnims() integer i; for(i=0; i<llGetInventoryNumber(INVENTORY_ANIMATION); i++){string n = llGetInventoryName(INVENTORY_ANIMATION, i); if(localConfIdle){if(n != localConfIdle && llGetSubString(n, 0, llStringLength(localConfIdle)-1) == localConfIdle){localConfAnims+=n;}}else if(llGetSubString(n, -2, -1) == "_1"){localConfIdle = llGetSubString(n, 0, -3); i=0;}}

/*
	Flags: Defined in got NPCSpells NPCS$FLAG_*
	Casttime: Float in seconds
	Recast: Recast time, float, seconds
	Range: Float range in meters
	Name: str name of spell
	Minrange: min range float in meters. Meaning player must be further than this range to be targeted.
	TargSex: Sex flags that ALL must be present on target (see _core.lsl)
	TargFX: FX flags that ALL must be present on the target (see got FX.lsl)
	StatusFlags: Status flags that ALL must be present on the target (see got Status.lsl)
	Radius: Float radius the player must be within. Use negative for inverse. PI_BY_TWO = Player must be in front. -PI_BY_TWO = Player must be behind
*/
#define LocalConf$npc$addSpell(flags, casttime, recast, range, name, minrange, targSex, targFX, statusFlags, viableRoles, radius) \
	SPELLS += NPCS$buildSpell(flags, casttime, recast, range, name, minrange, targSex, targFX, statusFlags, viableRoles, radius)

 
// Keepalive is built into got LocalConf NPC and handles temp on rez effect prims, spawning them automatically when they fade, and letting them auto expire when their rezzer dies.
// Send a message to all keepalive prims. Params will get converted to a JSON array and can use + notation
#define LocalConf$sendKeepalive( params ) llRegionSay(KEEPALIVE_CHAN, mkarr((list)params))
#define LocalConf$killMyKeepalives() llRegionSay(KEEPALIVE_CHAN, "KILL")



#endif
