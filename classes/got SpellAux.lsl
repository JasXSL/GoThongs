#define SpellAuxMethod$cache 1			// void
#define SpellAuxMethod$finishCast 2		// (int)spell, (arr)targets, (int)wipe_cooldown
#define SpellAuxMethod$startCast 3		// (int)spell
#define SpellAuxMethod$spellEnd 4		// null

#define SpellAuxMethod$toggle 5			// (bool)on - Shows/hides buttons
//#define SpellAuxMethod$setCastedAbility 6	// (int)spell, (float)casttime : -1 = rest
#define SpellAuxMethod$setGlobalCooldowns 7	// f2i((float)cd), (int)spell0, (int)spell1... FALSE = disregard, TRUE = set, -1 = remove
#define SpellAuxMethod$setCooldown 8		// (int)spell, (float)sec : -1 = rest
#define SpellAuxMethod$stopCast 9			// (int)spell - Removes both cast and cooldown
//REPLACED BY FXCEvt$spellMultipliers #define SpellAuxMethod$spellModifiers 10	// (arr)modifiers - Modifiers are [(float)rest_mod, (float)abil1mod...]
#define SpellAuxMethod$setQueue 10			// (int)index - Sets this spell as queued


#define SpellAux$cache() runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$cache, [], TNN)
#define SpellAux$finishCast(spell, targets, nocd) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$finishCast, [spell, targets, nocd], TNN)
#define SpellAux$startCast(spell, casttime) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$startCast, [spell, casttime], TNN)
#define SpellAux$spellEnd() runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$spellEnd, [], TNN)
#define SpellAux$setCooldown(buttonMinusOne, sec) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$setCooldown, [buttonMinusOne, sec], TNN)
//#define SpellAux$setCastedAbility(buttonMinusOne, sec) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$setCastedAbility, [buttonMinusOne, sec], TNN)
#define SpellAux$stopCast(buttonMinusOne) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$stopCast, [buttonMinusOne], TNN)

// Auto converts to int
#define SpellAux$setGlobalCooldowns(time, spells) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$setGlobalCooldowns, [f2i(time), spells], TNN)

#define SpellAux$statusCache(mana) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$statusCache, [mana], TNN)
#define SpellAux$overrideRest(icon, mana_cost, visual, data) runMethod((str)LINK_THIS, "got SpellAux", SpellAuxMethod$overrideRest, [icon, mana_cost, visual, data], TNN)
//#define SpellAux$spellModifiers(modifiers) runMethod((str)LINK_THIS, "got SpellAux", SpellAuxMethod$spellModifiers, [mkarr(modifiers)], TNN)
#define SpellAux$setQueue(index) runMethod((str)LINK_THIS, "got SpellAux", SpellAuxMethod$setQueue, [index], TNN)
#define SpellAux$toggle(on) runMethod((str)LINK_THIS, "got SpellAux", SpellAuxMethod$toggle, [on], TNN)
