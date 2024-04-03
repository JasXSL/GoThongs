#ifndef _Trap
#define _Trap

#define TrapMethod$forceSit 1		// (key)victim, (float)duration[, (key)prim, (int)flags] - Will automatically send the forceSit quickrape to a player and sit them onto any "SEAT" named prim in the linkset. Prim can be a non key value instead of SEAT
	#define Trap$fsFlags$strip 0x1
	#define Trap$fsFlags$attackable 0x2	// Allows the victim to be attackable
	#define Trap$fsFlags$noAnims 0x4	// Do not animate
	
#define Trap$chanSensorSend 1857127 	// Channel that lets you send quick tasks to traps. Messages send JSON arrays [(int)task,(var)data...]
	#define Trap$chanSensorSend$get 1		// (float)dist - Runs Trap$chanSensorReply$get

#define Trap$chanSensorReply 1857128 	// Reply channel for traps.
	#define Trap$chanSensorReply$get 1		// void - Reply to Trap$chanSensorSend$get
	
#define TrapMethod$end 2			// void - Force end
#define TrapMethod$useQTE 3			// (int)numTaps/speed, preDelay, buttonDelay, flags - Use a quicktime event. 0 numTaps disables. See got Evts -> Evts$qFlags
#define TrapMethod$anim 4			// (str)anim, (bool)start - Start or stop an animation on the victim
#define TrapMethod$frame 5			// (str)data - Triggers a legacy MeshAnim$frame event on the trap

#define TrapEvent$triggered 1
#define TrapEvent$seated 2			// (key)ast
#define TrapEvent$unseated 3		// (key)sitter
#define TrapEvent$qteButton 4		// (bool)correct - A QTE button has been pushed
#define TrapEvent$reset 5			// Trap has come off cooldown



#define Trap$useQTE(numTaps) runMethod((str)LINK_THIS, "got Trap", TrapMethod$useQTE, [numTaps], TNN)
#define Trap$useConfQTE(numTaps, preDelay, buttonDelay, flags) runMethod((str)LINK_THIS, "got Trap", TrapMethod$useQTE, (list)(numTaps)+(preDelay)+(buttonDelay)+(flags), TNN)
#define Trap$useLeftRightQTE(speed, preDelay, buttonDelay) runMethod((str)LINK_THIS, "got Trap", TrapMethod$useQTE, (list)(speed)+(preDelay)+(buttonDelay)+Evts$qFlags$LR, TNN)
#define Trap$useLeftRightFailableQTE(speed, preDelay, buttonDelay) runMethod((str)LINK_THIS, "got Trap", TrapMethod$useQTE, (list)(speed)+(preDelay)+(buttonDelay)+(Evts$qFlags$LR|Evts$qFlags$LR_CAN_FAIL), TNN)


#define Trap$forceSit(victim, duration, prim, flags) runMethod((string)LINK_THIS, "got Trap", TrapMethod$forceSit, (list)(victim)+(duration)+(prim)+(flags), TNN)
#define Trap$end(targ) runMethod((str)targ, "got Trap", TrapMethod$end, [], TNN)
#define Trap$startAnim(targ, anim) runMethod((str)targ, "got Trap", TrapMethod$anim, [anim, TRUE], TNN)
#define Trap$stopAnim(targ, anim) runMethod((str)targ, "got Trap", TrapMethod$anim, [anim, FALSE], TNN)



// Index of the INI_DATA raised by localConf event
#define Trap$setIniData(triggerCd, finishCd, attachItems, baseAnim, animeshAnim) raiseEvent(LocalConfEvt$iniData, mkarr((list)(triggerCd) + (finishCd) + mkarr((list)attachItems) + (baseAnim) + (animeshAnim))) // note: MUST be raised by a script called got LocalConf
#define TrapConf$triggerCooldown 0		// (float) time between triggers
#define TrapConf$finishCooldown 1		// (float) cooldown after releasing a player
#define TrapConf$attach 2				// (arr) items to attach (uses the pink box in the hud)
#define TrapConf$baseAnim 3				// (str) anim to override baseanim. Default baseanim is the first animation matching the pattern "<anything>_<not_number>". Baseanim is triggered on the player. Use "_NONE_" for none
#define TrapConf$animeshAnim 4			// (str) baseAnim for the trap as an animesh object. Use "_NONE_" for none


#endif
