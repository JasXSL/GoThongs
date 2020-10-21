#ifndef _SpellAux
#define _SpellAux

//#define SpellAuxMethod$cache 1			// void
//#define SpellAuxMethod$finishCast 2		// (int)spell, (arr)targets, (int)wipe_cooldown
//#define SpellAuxMethod$startCast 3		// (int)spell
//#define SpellAuxMethod$spellEnd 4		// null

//#define SpellAuxMethod$toggle 5			// (bool)on - Shows/hides buttons
//#define SpellAuxMethod$setCastedAbility 6	// (int)spell, (float)casttime : -1 = rest
//#define SpellAuxMethod$setGlobalCooldowns 7	// f2i((float)cd), (int)spell0, (int)spell1... FALSE = disregard, TRUE = set, -1 = remove
//#define SpellAuxMethod$setCooldown 8		// (int)spell, (float)sec : -1 = rest
//#define SpellAuxMethod$stopCast 9			// (int)spell - Removes both cast and cooldown
//REPLACED BY FXCEvt$spellMultipliers #define SpellAuxMethod$spellModifiers 10	// (arr)modifiers - Modifiers are [(float)rest_mod, (float)abil1mod...]
//#define SpellAuxMethod$setQueue 10			// (int)index - Sets this spell as queued

#define SpellAuxMethod$tunnel 1				// (str)wrapper, (arr)targets, (float)range, (bool)tunnelFlags
	#define SpellAux$tfAllowCrit 0x1			// Allow crits


#define SpellAuxEvt$crit 1					// (int)index - A critical hit has been scored

#define SpellAux$tunnel( wrapper, targets, range, tunnelFlags ) runMethod((str)LINK_ROOT, "got SpellAux", SpellAuxMethod$tunnel, (list)wrapper + mkarr(targets) + range + tunnelFlags, TNN)


#define SpellAux$difficultyDamageDoneModifier( DIF ) llPow(0.9, DIF)

#endif
