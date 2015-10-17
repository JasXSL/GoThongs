#define SpellAuxMethod$cache 1			// void
#define SpellAuxMethod$finishCast 2		// (int)spell, (arr)targets
#define SpellAuxMethod$startCast 3		// (int)spell
#define SpellAuxMethod$spellEnd 4		// null

#define SpellAux$cache() runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$cache, [], TNN)
#define SpellAux$finishCast(spell, targets) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$finishCast, [spell, targets], TNN)
#define SpellAux$startCast(spell) runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$startCast, [spell], TNN)
#define SpellAux$spellEnd() runMethod((string)LINK_ROOT, "got SpellAux", SpellAuxMethod$spellEnd, [], TNN)
 