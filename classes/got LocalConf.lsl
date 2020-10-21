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
#define LocalConfMethod$grapple 8				// key targ - Used with template to start a grapple (needs to be compiled with grapples)

#define LocalConf$startSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$startSpell, [id], TNN)
#define LocalConf$interruptSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$interruptSpell, [id], TNN)
#define LocalConf$finishSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$finishSpell, [id], TNN)
#define LocalConf$ini() runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$ini, [], TNN)
#define LocalConf$checkCastSpell(id, targ, cb) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$checkCastSpell, [id, targ], cb)
#define LocalConf$stdInteract(targ, sender, data) runMethod(targ, "got LocalConf", LocalConfMethod$stdInteract, [sender]+data, TNN)
// Useful for monster scripts that aren't named LocalConf
#define LocalConf$stdInteractByScript(targ, script, sender, data) runMethod(targ, script, LocalConfMethod$stdInteract, [sender]+data, TNN)
#define LocalConf$generic(targ, params) runMethod((str)(targ), "got LocalConf", LocalConfMethod$generic, (list)params, TNN)


#define LocalConfEvt$iniData 1		// Separate from evt$SCRIPT_INIT in that this is raised on demand and contains script custom data
									// This data will vary based on the object the conf is in
									// For monster data see got Monster
#define LocalConfEvt$emulateAttack 2// Emulates an attack for monsters without mesh anims
#define LocalConfEvt$grappleStart 3	// (key)id Handled by template
#define LocalConfEvt$grappleEnd 4	// (key)id Handled by template
#define LocalConfEvt$grappleSuccess 3	// (key)id - LR Failable Grapple ended successfully
#define LocalConfEvt$grappleFail 4	// (key)id - LR Grapple check failed


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


#define LocalConf$grapple( targ ) runMethod((str)LINK_THIS, "got LocalConf", LocalConfMethod$grapple, (list)(targ), TNN)
 


#endif
