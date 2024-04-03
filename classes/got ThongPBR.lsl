/*
	Minified alt version of got ThongMan for PBR. Uses a subset of commands
*/
#ifndef _ThongPBR
#define _ThongPBR

#define ThongManMethod$attached 1			// Removes any other thongs
#define ThongManMethod$reset 2				// (bool)output_debug - Resets thongMan
//#define ThongManMethod$get 3				// Gets the thong to send a refresh call to #ROOT
#define ThongManMethod$set 4				// (arr)[(vec)color, (float)glow, (arr)diffuse, (arr)bump, (arr)specular]
#define ThongManMethod$hit 5				// (vec)color
#define ThongManMethod$fxVisual 6			// (vec)color, (float)glow, (arr)specular[texture,offsets,repeats,rot,color,gloss,world] - Color cannot be ZERO_VECTOR
#define ThongManMethod$particles 7			// (float)timeout, (int)prim, (arr)particle_list
											// generally prim 1 is for casting, and prim 2 for received spell effects
#define ThongManMethod$dead 8				// [(int)dead, (int)no_visual] - 
#define ThongManMethod$sound 9			// (key)sound, (float)vol, (int)loop - Or "" to stop sound
#define ThongManMethod$void 10				// Void function for getting callbacks

#define ThongMan$attached() runOmniMethod("got ThongMan", ThongManMethod$attached, [], TNN)
#define ThongMan$get() runMethod(llGetOwner(), "got ThongMan", ThongManMethod$get, [], TNN)
#define ThongMan$set(targ, data) runMethod(targ, "got ThongMan", ThongManMethod$set, [data], TNN)
#define ThongMan$hit(color) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$hit, [color], TNN)
#define ThongMan$fxVisual(params) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$fxVisual, params, TNN)
#define ThongMan$particles(timeout, prim, particle_list) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$particles, [timeout, prim, particle_list], TNN)
#define ThongMan$dead(dead, no_visual) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$dead, [dead, no_visual], TNN)
#define ThongMan$sound(sound, vol, loop) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$sound, [sound, vol, loop], TNN)
#define ThongMan$reset(debug) runMethod(llGetOwner(), "got ThongMan", ThongManMethod$reset, [debug], TNN)

#define ThongManEvt$hit 1					// [(vec)color]
#define ThongManEvt$ini 2					// []
#define ThongManEvt$getVisuals 3			// void - Get visuals from helper of custom thong
#define ThongManEvt$death 4					// [(int)dead] - If the player lost their thong or not

#endif
 