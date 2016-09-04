/*
	
	Script resides in the cyan library box
	
*/
#define RootAuxMethod$prepareManifest 1			// (str)pubkey - Loads a mod manifest
#define RootAuxMethod$playSound 2				// (key)sound, (float)vol

#define RootAux$prepareManifest(pubkey) runMethod(llGetOwner(), "got RootAux", RootAuxMethod$prepareManifest, [pubkey], TNN)
#define RootAux$playSound(targ, sound, vol) runMethod((str)targ, "got RootAux", RootAuxMethod$playSound, [sound, vol], TNN)

#define RootAuxEvt$cleanup 1					// void - Sent when the user hits the cleanup button


