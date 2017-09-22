#define SpellVisMethod$toggle 5				// (bool)on - Shows/hides buttons
#define SpellVisMethod$setCooldowns 8		// (float)startTime1, (float)duration1[,...](float)time - 2-strided, start and end
#define SpellVisMethod$setQueue 10			// (int)index - Sets this spell as queued


#define SpellVis$setCooldowns(cooldowns, time) runMethod((string)LINK_ROOT, "got SpellVis", SpellVisMethod$setCooldowns, cooldowns+time, TNN)
#define SpellVis$statusCache(mana) runMethod((string)LINK_ROOT, "got SpellVis", SpellVisMethod$statusCache, [mana], TNN)
#define SpellVis$setQueue(index) runMethod((str)LINK_THIS, "got SpellVis", SpellVisMethod$setQueue, [index], TNN)
#define SpellVis$toggle(on) runMethod((str)LINK_THIS, "got SpellVis", SpellVisMethod$toggle, [on], TNN)

