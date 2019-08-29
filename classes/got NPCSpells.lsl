#define NPCSpellsMethod$setSpells 1			// Array of spell objects, see below
#define NPCSpellsMethod$interrupt 2			// (int)force
#define NPCSpellsMethod$startCast 3			// (int)id - Returns true/false
#define NPCSpellsMethod$wipeCooldown 4		// (int)id - -1 is all
#define NPCSpellsMethod$setOutputStatusTo 5	// Sets players that are currently targeting this monster
#define NPCSpellsMethod$setConf 6			// (float)max_spells_per_sec
#define NPCSpellsMethod$silence 7		// (int)silence - Silence
#define NPCSpellsMethod$customCast 8		// (int)flags, (float)casttime, (str)name, (key)targ - Casts a custom spell. The index will be -1
#define NPCSpellsMethod$disableSpells 9		// (int)spell1, (int)spell2...

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
	#define NPCS$FLAG_IGNORE_TANK 0x800			// Ignores the currently aggroed target
	#define NPCS$FLAG_IGNORE_HASTE 0x1000		// Ignores haste modifier
	
	#define NPCS$STUN (NPCS$FLAG_ROOT|NPCS$FLAG_PACIFY|NPCS$FLAG_NOROT)
	
#define NPCS$SPELL_CASTTIME 1		// 0 = instant cast
#define NPCS$SPELL_RECASTTIME 2		// 0 = only reset timer on event
#define NPCS$SPELL_RANGE 3			// 0 = Unlimited range
#define NPCS$SPELL_NAME 4			// Not needed for instant cast
#define NPCS$SPELL_MIN_RANGE 5		// Minimum range of target 
#define NPCS$SPELL_TARG_SEX 6		// Sex flags needed on target, 0 ignores 

#define NPCS$buildSpell(flags, casttime, recast, range, name, minrange, targSex) llList2Json(JSON_ARRAY, [flags, casttime, recast, range, name, minrange, targSex])

// Spell is the spell index, targ is the target (converted to owner key if attached), real is either same as targ or the HUD itself
#define NPCSpellsEvt$SPELL_CAST_START 1				// (int)spell, (key)targ, (key)real, (str)spellName
#define NPCSpellsEvt$SPELL_CAST_FINISH 2			// (int)spell, (key)targ, (key)real, (str)spellName
#define NPCSpellsEvt$SPELL_CAST_INTERRUPT 3			// (int)spell, (key)targ, (key)real, (str)spellName
#define NPCSpellsEvt$SPELLS_SET 4					// (str)script - Raises an event when setSpells has been ran, script is the name of the script that set spells


#define NPCSpells$setSpells(data) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$setSpells, data, TNN)
#define NPCSpells$setConf(conf)	runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$setConf, conf, TNN)
#define NPCSpells$interrupt( force ) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$interrupt, (list)(force), TNN)
#define NPCSpells$startCast(id) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$startCast, [id], TNN)
#define NPCSpells$wipeCooldown(id) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$wipeCooldown, [id], TNN)
#define NPCSpells$setOutputStatusTo(targs) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$setOutputStatusTo, targs, TNN)
#define NPCSpells$silence(silenced) runMethod((string)LINK_THIS, "got NPCSpells", NPCSpellsMethod$silence, [silenced], TNN)
#define NPCSpells$customCast(flags, casttime, name, targ) runMethod((str)LINK_THIS, "got NPCSpells", NPCSpellsMethod$customCast, [flags, casttime, name, targ], TNN)
#define NPCSpells$disableSpells(targ, spells) runMethod((str)targ, "got NPCSpells", NPCSpellsMethod$disableSpells, spells, TNN)


