#define NPCSpellsMethod$setSpells 1			// Array of spell objects, see below
#define NPCSpellsMethod$interrupt 2			
#define NPCSpellsMethod$startCast 3			// (int)id - Returns true/false
#define NPCSpellsMethod$wipeCooldown 4		// (int)id - -1 is all
#define NPCSpellsMethod$setOutputStatusTo 5	// Sets players that are currently targeting this monster
#define NPCSpellsMethod$setConf 6			// (float)max_spells_per_sec


// For the spells array
#define NPCS$SPELL_FLAGS 0			// 
	#define NPCS$FLAG_ROOT 1					// Monster is rooted while casting
	#define NPCS$FLAG_PACIFY 2					// monster cannot attack while casting
	#define NPCS$FLAG_NOROT 4					// Monster doesn't look at the target
	#define NPCS$FLAG_NO_INTERRUPT 0x10			// Spell cannot be interrupted
	#define NPCS$FLAG_DISABLED_ON_START 0x20	// Enable with NPCSpells$wipeCooldown(id)
	#define NPCS$FLAG_REQUEST_CASTSTART 0x40	// Will attempt to get a callback before casting by using LocalConfMethod$checkCastSpell
	#define NPCS$FLAG_RESET_CD_ON_INTERRUPT 0x80// Resets cooldown if interrupted
	#define NPCS$FLAG_CAST_AT_RANDOM 0x100		// Tries to cast at a random visible target
	#define NPCS$FLAG_LOOK_OVERRIDE 0x200		// Forces the monster to look at the victim even if it's not the target
	#define NPCS$ALLOW_MULTIPLE_CHECKS 0x400	// Use with FLAG_CAST_AT_RNADOM - Even if a player matches, it will still query all
	
	#define NPCS$STUN (NPCS$FLAG_ROOT|NPCS$FLAG_PACIFY|NPCS$FLAG_NOROT)
	
#define NPCS$SPELL_CASTTIME 1		// 0 = instant cast
#define NPCS$SPELL_RECASTTIME 2		// 0 = only reset timer on event
#define NPCS$SPELL_RANGE 3			// 0 = Unlimited range
#define NPCS$SPELL_NAME 4			// Not needed for instant cast
#define NPCS$SPELL_MIN_RANGE 5		// Minimum range of target

#define NPCS$buildSpell(flags, casttime, recast, range, name, minrange) llList2Json(JSON_ARRAY, [flags, casttime, recast, range, name, minrange])

#define NPCSpellsEvt$SPELL_CAST_START 1				// (int)spell, (key)targ
#define NPCSpellsEvt$SPELL_CAST_FINISH 2			// (int)spell, (key)targ
#define NPCSpellsEvt$SPELL_CAST_INTERRUPT 3			// (int)spell, (key)targ



#define NPCSpells$setSpells(data) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$setSpells, data, TNN)
#define NPCSPells$setConf(conf)	runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$setConf, conf, TNN)
#define NPCSpells$interrupt() runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$interrupt, [], TNN)
#define NPCSpells$startCast(id) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$startCast, [id], TNN)
#define NPCSpells$wipeCooldown(id) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$wipeCooldown, [id], TNN)
#define NPCSpells$setOutputStatusTo(targs) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$setOutputStatusTo, targs, TNN)



