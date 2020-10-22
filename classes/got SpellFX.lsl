#ifndef _SpellFX
#define _SpellFX

#define SpellFXMethod$spawn 1		// [(str)obj, (key)targ]
#define SpellFXMethod$getTarg 2		// NULL - Returns targ for obj name
#define SpellFXMethod$sound 3		// (key)sound, (float)vol, (int)loop - If sound is "", stop sound
#define SpellFXMethod$spawnInstant 4	// [(arr)data, (key)targ]
										// Data is: [(str)obj, (vec)pos_offset, (rot)rot_offset, (int)flags[, (int)startParam=1]]
										// startParam cannot be 0
#define SpellFXMethod$remInventory 5	// [(arr)assets]
#define SpellFXMethod$fetchInventory 6	// (arr)assets || (str)asset - Owner only, attempts an inventory give

#define SpellFXFlag$SPI_FULL_ROT 0x1			// Don't limit rotation to Z
#define SpellFXFlag$SPI_TARG_IN_REZ 0x2			// (PC only) Compiles the hex value of the first 8 characters of target's character key as the rez value. Used in hunter arrows.
#define SpellFXFlag$SPI_SPAWN_FROM_CASTER 0x4	// (PC only) Use the caster for offsets, not target
#define SpellFXFlag$SPI_IGNORE_HEIGHT 0x8		// Use the given Z coordinate instead of multiplying it by the user


// Channel that can be used to remove custom data
#define SpellFX$customDataChan (playerChan(llGetOwner())+80085)

#define SpellFX$getCustomData() llRegionSayTo(mySpawner(), SpellFx$customDataChan, "G")



#define SpellFX$spawn(obj, targ) runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$spawn, [obj, targ], TNN)
#define SpellFX$getTarg(cb) runMethod(llGetOwner(), "got SpellFX", SpellFXMethod$getTarg, [], cb)
#define SpellFX$startSound(sound, vol, loop) runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$sound, [sound, vol, loop], TNN)
#define SpellFX$stopSound()  runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$sound, [""], TNN)
#define SpellFX$spawnInstant(data, targ) runMethod((string)LINK_ALL_OTHERS, "got SpellFX", SpellFXMethod$spawnInstant, [data, targ], TNN)
#define SpellFX$remInventory(assets) runMethod((string)LINK_SET, "got SpellFX", SpellFXMethod$remInventory, [mkarr(assets)], TNN)
#define SpellFX$fetchInventory(assets) runMethod(llGetOwner(), "got SpellFX", SpellFXMethod$fetchInventory, [assets], TNN)
#define SpellFX$spawnInstantTarg(t, data, targ) runMethod((string)t, "got SpellFX", SpellFXMethod$spawnInstant, [data, targ], TNN)




#endif 
