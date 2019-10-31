#ifndef _RootAux
#define _RootAux
/*
	
	Script resides in the cyan library box
	
*/
#define RootAuxMethod$prepareManifest 1			// (str)pubkey - Loads a mod manifest
#define RootAuxMethod$playSound 2				// (key)sound, (float)vol
#define RootAuxMethod$cleanup 3					// (int)manual - Same as hitting the cleanup button. Manual should be TRUE if it was initiated by a user click

#define RootAux$prepareManifest(pubkey) runMethod(llGetOwner(), "got RootAux", RootAuxMethod$prepareManifest, [pubkey], TNN)
#define RootAux$playSound(targ, sound, vol) runMethod((str)targ, "got RootAux", RootAuxMethod$playSound, [sound, vol], TNN)
#define RootAux$cleanup(targ, manual) runMethod((str)targ, "got RootAux", RootAuxMethod$cleanup, [manual], TNN)

#define RootAuxEvt$cleanup 1					// (bool)manual - Sent when the user hits the cleanup button. Manual means cleanup was triggered by the user. Non manual was triggered by a script


#endif
