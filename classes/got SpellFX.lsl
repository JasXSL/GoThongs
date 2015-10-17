#define SpellFXMethod$spawn 1		// [(str)obj, (key)targ]
#define SpellFXMethod$getTarg 2		// NULL - Returns targ for obj name
#define SpellFXMethod$sound 3		// (key)sound, (float)vol, (int)loop - If sound is "", stop sound
#define SpellFXMethod$spawnInstant 4	// [(arr)data, (key)targ]

#define SpellFX$spawn(obj, targ) runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$spawn, [obj, targ], TNN)
#define SpellFX$getTarg(cb) runMethod(llGetOwner(), "got SpellFX", SpellFXMethod$getTarg, [], cb)
#define SpellFX$startSound(sound, vol, loop) runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$sound, [sound, vol, loop], TNN)
#define SpellFX$stopSound()  runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$sound, [""], TNN)
#define SpellFX$spawnInstant(obj, targ) runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$spawnInstant, [obj, targ], TNN)

