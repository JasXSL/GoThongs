#define WeaponLoaderMethod$toggleSheathe 1			// (int)sheathed - Use -1 to toggle
#define WeaponLoaderMethod$anim 2					// Trigger an animation based on the current weapon. Also unsheathes.
#define WeaponLoaderMethod$storeOffset 3			// (vector)pos, (rotation)rot
#define WeaponLoaderMethod$storeScale 4				// (float)scaleFactor
#define WeaponLoaderMethod$remInventory 5			// (arr)assets - Removes assets from this link

#define WeaponLoaderEvt$attackAnim 1				// void | Attack animation started

#define WeaponLoader$toggleSheathe(targ, sheathe) runMethod((str)targ, "got WeaponLoader", WeaponLoaderMethod$toggleSheathe, [sheathe], TNN)  
#define WeaponLoader$anim() runMethod((str)LINK_ALL_OTHERS, "got WeaponLoader", WeaponLoaderMethod$anim, [], TNN)

#define WeaponLoader$storeOffset(pos, rot) runMethod((str)llGetOwner(), "got WeaponLoader", WeaponLoaderMethod$storeOffset, [pos,rot], TNN)  
#define WeaponLoader$storeScale(scale) runMethod((str)llGetOwner(), "got WeaponLoader", WeaponLoaderMethod$storeScale, [scale], TNN)  
#define WeaponLoader$remInventory(data) runMethod((str)LINK_SET, "got WeaponLoader", WeaponLoaderMethod$remInventory, data, TNN)
