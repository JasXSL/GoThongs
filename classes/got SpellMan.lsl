#ifndef _SpellMan
#define _SpellMan

#define SpellManMethod$hotkey 1			// (str)text
#define SpellManMethod$interrupt 2		// NULL
#define SpellManMethod$rebuildCache 3	// void - rebuilds from shared: BridgeSpells$name
#define SpellManMethod$spellComplete 4	// NULL - Internal
#define SpellManMethod$purgeCache 5		// NULL - purges the cache
#define SpellManMethod$resetCooldowns 6	// (int)bitfield, where 0x1=rest, 0x2=button1, 0x4=button2 etc, (int)num_charges=1
#define SpellManMethod$replace 7		// (int)index, (arr)data, (int)update - Replaces a spell on the fly. Index of rest is -1, then 0,1,2,3 for the spells from left to right. See got Bridge BridgeSpells$name for data. Only updates if update is TRUE. Only set update on the last spell you send to the target. Use [] data to reset
#define SpellManMethod$reduceCD 8		// (int)spells, (float)seconds - spells is bitwise combination of (hotkeys) 1=5, 2=1, 4=2...

#define SpellManShared$cooldowns 1		// (arr)cooldowns


#define SpellManEvt$interrupted 1	// (int)index, f2i(casttime) - Spell has been interrupted
#define SpellManEvt$cast 2			// f2i((float)casttime), (key)target, (int)spellIndex, (int)spellFlags - Cast started - Not raised on instant cast
#define SpellManEvt$complete 3 		// (int)spell_index, (key)target, (bool)detrimental, (arr)all_targs, (bool)noWipe, (f2i)casttime - Spell finished casting. Index goes from 0 (rest) to 4 (last)
#define SpellManEvt$recache 4		// void - Triggers a recache of spell data
#define SpellManEvt$charges 5		// (int)charges - Spell charges have changed. 4 bit int of charges remaining


#define SpellMan$CASTER 0x1
#define SpellMan$ENEMIES 0x8
#define SpellMan$AOE 0x40
#define SpellMan$NO_GCD 0x80
#define SpellMan$NO_CRITS 0x100
#define SpellMan$NO_SWIM 0x200
#define SpellMan$HIDE 0x400
#define SpellMan$CASTABLE_WHILE_MOVING 0x800
#define SpellMan$DRAW_WEAPON 0x1000

#define SpellMan$hotkey(text) runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$hotkey, [text], TNN)
#define SpellMan$interrupt(force) runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$interrupt, [force], TNN)
#define SpellMan$rebuildCache() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$rebuildCache, [], TNN)
#define SpellMan$spellComplete() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$spellComplete, [], TNN)
#define SpellMan$purgeCache() runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$purgeCache, [], TNN)
#define SpellMan$resetCooldowns(bitfield, charges) runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$resetCooldowns, [bitfield, charges], TNN)
#define SpellMan$replace(targ, index, data, update) runMethod((str)targ, "got SpellMan", SpellManMethod$replace, [index, mkarr(data), update], TNN)
// Same as above but accepts a JSON string instead of a list
#define SpellMan$replaceString(targ, index, json, update) runMethod((str)targ, "got SpellMan", SpellManMethod$replace, [index, json, update], TNN)
#define SpellMan$reduceCD(data) runMethod((string)LINK_ROOT, "got SpellMan", SpellManMethod$reduceCD, data, TNN)



#endif

