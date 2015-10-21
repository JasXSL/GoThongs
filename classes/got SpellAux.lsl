#define SpellAuxMethod$cache 1			// void
#define SpellAuxMethod$finishCast 2		// (int)spell, (arr)targets, (int)wipe_cooldown
#define SpellAuxMethod$startCast 3		// (int)spell
#define SpellAuxMethod$spellEnd 4		// null

#define SpellAuxMethod$statusCache 5		// (float)mana
//#define SpellAuxMethod$setCastedAbility 6	// (int)spell, (float)casttime : -1 = rest
#define SpellAuxMethod$setGlobalCooldowns 7	// (float)cd, (int)spell0, (int)spell1... FALSE = disregard, TRUE = set, -1 = remove
#define SpellAuxMethod$setCooldown 8		// (int)spell, (float)sec : -1 = rest
#define SpellAuxMethod$stopCast 9			// (int)spell - Removes both cast and cooldown



#define SpellAux$cache() runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$cache, [], TNN)
#define SpellAux$finishCast(spell, targets, nocd) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$finishCast, [spell, targets, nocd], TNN)
#define SpellAux$startCast(spell, casttime) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$startCast, [spell, casttime], TNN)
#define SpellAux$spellEnd() runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$spellEnd, [], TNN)
#define SpellAux$setCooldown(buttonMinusOne, sec) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$setCooldown, [buttonMinusOne, sec], TNN)
//#define SpellAux$setCastedAbility(buttonMinusOne, sec) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$setCastedAbility, [buttonMinusOne, sec], TNN)
#define SpellAux$stopCast(buttonMinusOne) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$stopCast, [buttonMinusOne], TNN)
#define SpellAux$setGlobalCooldowns(time, spells) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$setGlobalCooldowns, [time, spells], TNN)
#define SpellAux$statusCache(mana) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$statusCache, [mana], TNN)

