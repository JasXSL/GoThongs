/*
	
	Script resides in the cyan library box
	
*/
#define RootAuxMethod$prepareManifest 1			// (arr)manifest - Loads a mod manifest
#define RootAuxMethod$playSound 2				// (key)sound, (float)vol

#define RootAux$prepareManifest(manifest) runMethod(llGetOwner(), "got RootAux", RootAuxMethod$prepareManifest, [mkarr(manifest)], TNN)
#define RootAux$playSound(targ, sound, vol) runMethod((str)targ, "got RootAux", RootAuxMethod$playSound, [sound, vol], TNN)



