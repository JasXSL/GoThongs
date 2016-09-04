#define SpellManMethod$hotkey 1			// (str)text
#define SpellManMethod$interrupt 2		// NULL
#define SpellManMethod$rebuildCache 3	// void - rebuilds from shared: BridgeSpells$name
#define SpellManMethod$spellComplete 4	// NULL - Internal
#define SpellManMethod$purgeCache 5		// NULL - purges the cache
#define SpellManMethod$resetCooldowns 6	// (int)bitfield, where 0x1=rest, 0x2=button1, 0x4=button2 etc
#define SpellManMethod$replace 7		// (int)index, (arr)data - Replaces a spell on the fly. Index of rest is -1, then 0,1,2,3 for the spells from left to right. See got Bridge BridgeSpells$name for data.

#define SpellManShared$cooldowns 1		// (arr)cooldowns


#define SpellManEvt$interrupted 1	// NULL - NULL
#define SpellManEvt$cast 2			// f2i((float)casttime), (key)target - Cast started - Not raised on instant cast
#define SpellManEvt$complete 3 		// (int)spell_index, (key)target - Spell finished casting. Index goes from 0 (rest) to 4 (last)


#define SpellMan$NO_GCD 0x80
#define SpellMan$NO_CRITS 0x100
#define SpellMan$NO_SWIM 0x200

#define SpellMan$hotkey(text) runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$hotkey, [text], TNN)
#define SpellMan$interrupt() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$interrupt, [], TNN)
#define SpellMan$rebuildCache() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$rebuildCache, [], TNN)
#define SpellMan$spellComplete() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$spellComplete, [], TNN)
#define SpellMan$purgeCache() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$purgeCache, [], TNN)
#define SpellMan$resetCooldowns(bitfield) runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$resetCooldowns, [bitfield], TNN)
#define SpellMan$replace(targ, index, data) runMethod((str)targ, "got SpellMan", SpellManMethod$replace, [index, data], TNN)



