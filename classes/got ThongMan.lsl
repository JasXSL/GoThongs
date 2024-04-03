/*
	Update for materials:
	- Textures are now set into LSD by using ThongMan$setMaterial
	- You can use "LEGACY" on every state to make it not use PBR for that state
	- Prim names are not unique. You can set the same texture on many prims by naming them the same
	- JSON_NULL will be replaced by an invisible material
	
	Full example CustomThongScript:
	
	#include "got/_core.lsl"
	default{
		state_entry(){
			memLim(1.5);
			ThongMan$setMaterial(
				ThongManPreset$DEAD,
				"Main1",
				ALL_SIDES,
				JSON_NULL // JSON_NULL can be used to use default invisible texture
			);
			ThongMan$setMaterial(
				ThongManPreset$DEFAULT,                 // Preset
				"Main1",                                // Prim name
				ALL_SIDES,                              // Sides
				"..."  // Material UUID
			);
			ThongMan$setMaterial(
				ThongManPreset$WET,                     // Preset
				"Main1",                                // Prim name
				ALL_SIDES,                              // sides
				"..."  // Material UUID
			);
			ThongMan$setMaterial(
				ThongManPreset$OILY,                     // Preset
				"Main1",                                // Prim name
				ALL_SIDES,                              // sides
				"..."  // Material UUID
			);
			ThongMan$setMaterial(
				ThongManPreset$DIRTY,                     // Preset
				"Main1",                                // Prim name
				ALL_SIDES,                              // sides
				"..."  // Material UUID
			);
			ThongMan$setMaterial(
				ThongManPreset$FROZEN,                     // Preset
				"Main1",                                // Prim name
				ALL_SIDES,                              // sides
				"..."  // Material UUID
			);
			ThongMan$setMaterial(
				ThongManPreset$CUMSTAINS,                     // Preset
				"Main1",                                // Prim name
				ALL_SIDES,                              // sides
				"..."  // Material UUID
			);
		}
	}
		

*/
#ifndef _ThongMan
#define _ThongMan

#define ThongMan$table "gotTM" // preset is appended to it


#define ThongManPreset$DEAD 0		// defaults to "4f3fa15e-5a28-d8c5-64d7-ceded5644899" if set to JSON_NULL
#define ThongManPreset$DEFAULT 1	// you can use "LEGACY" to use it as a toggle that only adds or removes DEAD 
#define ThongManPreset$OILY 2
#define ThongManPreset$WET 3
#define ThongManPreset$DIRTY 4		// 
#define ThongManPreset$FROZEN 5		
#define ThongManPreset$CUMSTAINS 6	// 

#define ThongMan$setMaterial(preset, prim, side, material) llLinksetDataWrite(ThongMan$table+(str)(preset)+":"+mkarr((list)(prim) + (side)), (str)(material))


#define ThongManMethod$attached 1			// Removes any other thongs
#define ThongManMethod$reset 2				// (bool)output_debug - Resets thongMan
//#define ThongManMethod$get 3				// Gets the thong to send a refresh call to #ROOT
// DEPRECATED. USE PBR
// #define ThongManMethod$set 4				// (arr)[(vec)color, (float)glow, (arr)diffuse, (arr)bump, (arr)specular]
#define ThongManMethod$hit 5				// (vec)color
// Reworked for PBR
// #define ThongManMethod$fxVisual 6			// (vec)color, (float)glow, (arr)specular[texture,offsets,repeats,rot,color,gloss,world] - Color cannot be ZERO_VECTOR
#define ThongManMethod$fxVisual 6			// (vec)color, (float)glow, (str)preset, (int)dur - Dur is used with instant effects to have ThongMan manage the timeout. Do not use a nonzero timeout with a duration effect.
#define ThongManMethod$particles 7			// (float)timeout, (int)prim, (arr)particle_list
											// Class attachments handle particles now but this can be used for special visuals. generally prim 1 is for casting, and prim 2 for received spell effects
#define ThongManMethod$dead 8				// [(int)dead, (int)no_visual] - 
#define ThongManMethod$sound 9				// (key)sound, (float)vol, (int)loop - Or "" to stop sound
#define ThongManMethod$void 10				// Void function for getting callbacks
#define ThongManMethod$remTempVisuals 11	// void - Removes all visuals that use the ThongMan managed timers

#define ThongMan$attached() runOmniMethod("got ThongMan", ThongManMethod$attached, [], TNN)
//#define ThongMan$get() runMethod(llGetOwner(), "got ThongMan", ThongManMethod$get, [], TNN)
//#define ThongMan$set(targ, data) runMethod(targ, "got ThongMan", ThongManMethod$set, [data], TNN)
#define ThongMan$hit(targ, color) runMethod(targ, "got ThongMan", ThongManMethod$hit, (list)color, TNN)

#define ThongMan$remTempVisuals(targ) _tmOnTarg(targ, ThongManMethod$remTempVisuals, [])

// :: These are all synonyms ::
// Full default one
#define ThongMan$fxVisual(targ, color, glow, preset, dur) runMethod(targ, "got ThongMan", ThongManMethod$fxVisual, (list)(color) + (glow) + (preset) + (dur), TNN)
// Shorter one with no glow or color
#define ThongMan$fxPreset(targ, preset, dur) _tmOnTarg(targ, ThongManMethod$fxVisual, (list)"" + 0 + (preset) + (dur))
// Same as above but takes arguments as a raw list
#define ThongMan$fxVisualList(targ, data) runMethod(targ, "got ThongMan", ThongManMethod$fxVisual, data, TNN)

// Specific ones
#define ThongMan$fxVisOily(targ, color, dur) _tmOnTarg(targ, ThongManMethod$fxVisual, (list)color + 0 + (ThongManPreset$OILY) + (dur))
#define ThongMan$fxVisWet(targ, color, dur) _tmOnTarg(targ, ThongManMethod$fxVisual, (list)color + 0 + (ThongManPreset$WET) + (dur))
#define ThongMan$fxVisDirty(targ, color, dur) _tmOnTarg(targ, ThongManMethod$fxVisual, (list)color + 0 + (ThongManPreset$DIRTY) + (dur))
#define ThongMan$fxVisFrozen(targ, color, dur) _tmOnTarg(targ, ThongManMethod$fxVisual, (list)color + 0 + (ThongManPreset$FROZEN) + (dur))
#define ThongMan$fxVisCumstains(targ, color, dur) _tmOnTarg(targ, ThongManMethod$fxVisual, (list)color + 0 + (ThongManPreset$CUMSTAINS) + (dur))


#define ThongMan$particles(timeout, prim, particle_list) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$particles, [timeout, prim, particle_list], TNN)
#define ThongMan$dead(dead, no_visual) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$dead, [dead, no_visual], TNN)
#define ThongMan$sound(sound, vol, loop) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$sound, [sound, vol, loop], TNN)
#define ThongMan$reset(debug) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$reset, [debug], TNN)

#define ThongManEvt$hit 1					// [(vec)color]
#define ThongManEvt$ini 2					// []
// deprecated, build LSD in state_entry instead
//#define ThongManEvt$getVisuals 3			// void - Get visuals from helper of custom thong
#define ThongManEvt$death 4					// [(int)dead] - If the player lost their thong or not

_tmOnTarg( key t, int m, list d ){
	if( prAttachPoint(t) )
		t = llGetOwnerKey(t);
	runMethod(t, "got ThongMan", m, d, TNN);
}


#endif
 