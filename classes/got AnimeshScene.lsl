#define gotAnimeshSceneMethod$begin 1		// (obj)conf
	#define gotAnimeshScene$cSpeedMin "minSpeed"			// min time between thrusts
	#define gotAnimeshScene$cSpeedMax "maxSpeed"			// max time between thrusts
	#define gotAnimeshScene$cAnim "anim"					// (str)base. Animations are named base+"_"+t/a and thrusts are named base+"_"+n+"_"+t/a
	#define gotAnimeshScene$cPos "pos"						// (vec)pos. Where to put the player.
	#define gotAnimeshScene$cRot "rot"						// (rot)rotation. How to rotate the player
	#define gotAnimeshScene$cHeight "height"				// (float)height. Height above ground to put player
	#define gotAnimeshScene$cSound "sound"					// (arr)thrust_sounds (MUST be array). use [] for none, do not include to use default squish
	#define gotAnimeshScene$cSoundVolMin "volMin"			// (float)min squish vol
	#define gotAnimeshScene$cSoundVolMax "volMax"			// (float)max squish vol
	#define gotAnimeshScene$cFlags "flags"					// 
		#define gotAnimeshScene$cfParts 0x1						// Use particles
		
	
#define gotAnimeshSceneMethod$orient 2				// (vec)pos, (rot)rotation - Quickly update the pos and rot of any sitting player. Good for debug.
#define gotAnimeshSceneMethod$killByName 3				// (str)name - Kills by name
#define gotAnimeshSceneMethod$trigger 4				// int visuals - 1 = particles, 2 = sound - Trigger default particles or sounds (splat)


#define gotAnimeshSceneEvt$thrust 1					// void - Raised when a thrust starts


#define gotAnimeshScene$begin(CONF) runMethod((str)LINK_THIS, "got AnimeshScene", gotAnimeshSceneMethod$begin, (list)llList2Json(JSON_OBJECT, (list)CONF), TNN)
#define gotAnimeshScene$orient(pos, rot) runMethod((str)LINK_THIS, "got AnimeshScene", gotAnimeshSceneMethod$orient, (list)pos+rot, TNN)
#define gotAnimeshScene$killByName(name) runOmniMethod("got AnimeshScene", gotAnimeshSceneMethod$killByName, (list)name, TNN)
#define gotAnimeshScene$trigger(visuals) runMethod((str)LINK_THIS, "got AnimeshScene", gotAnimeshSceneMethod$trigger, (list)visuals, TNN)

