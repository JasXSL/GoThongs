// Monsters
#define LocalConfMethod$ini 0					// Sends out the LocalConfEvt$iniData event

#define LocalConfMethod$startSpell 1			// (int)id
#define LocalConfMethod$interruptSpell 2		// (int)id
#define LocalConfMethod$finishSpell 3			// (int)id
#define LocalConfMethod$testIdle 4				// null - Debug command only. Tests the monsters's idle animation
#define LocalConfMethod$checkCastSpell 5		// (int)id, (key)targ, expects callback true on success
#define LocalConfMethod$stdInteract 6			// (key)sender, (var)data - A player has interacted with the object. You can input anything you want as variables

#define LocalConf$startSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$startSpell, [id], TNN)
#define LocalConf$interruptSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$interruptSpell, [id], TNN)
#define LocalConf$finishSpell(id) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$finishSpell, [id], TNN)
#define LocalConf$ini() runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$ini, [], TNN)
#define LocalConf$checkCastSpell(id, targ, cb) runMethod((string)LINK_THIS, "got LocalConf", LocalConfMethod$checkCastSpell, [id, targ], cb)
#define LocalConf$stdInteract(targ, sender, data) runMethod(targ, "got LocalConf", LocalConfMethod$stdInteract, [sender]+data, TNN)

#define LocalConfEvt$iniData 1		// Separate from evt$SCRIPT_INIT in that this is raised on demand and contains script custom data
									// This data will vary based on the object the conf is in
									// For monster data see got Monster
#define LocalConfEvt$emulateAttack 2// Emulates an attack for monsters without mesh anims


// These can be used in monsters if you want									
list localConfAnims;
string localConfIdle;					
#define localConfCacheAnims() integer i; for(i=0; i<llGetInventoryNumber(INVENTORY_ANIMATION); i++){string n = llGetInventoryName(INVENTORY_ANIMATION, i); if(localConfIdle){if(n != localConfIdle && llGetSubString(n, 0, llStringLength(localConfIdle)-1) == localConfIdle){localConfAnims+=n;}}else if(llGetSubString(n, -2, -1) == "_1"){localConfIdle = llGetSubString(n, 0, -3); i=0;}}
									
									