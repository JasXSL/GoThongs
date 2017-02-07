#define EvtsMethod$cycleEnemy 1				// void - Get a nearby enemy
#define EvtsMethod$startQuicktimeEvent 2	// (int)numButtons, (float)preDelay, (str)callback - Starts a quick time event where you have to push numButtons random buttons. Sends a callback with the first arg being one of the below tasks and the CB specified. preDelay lets you delay before the event starts, useful when forcing avatars to sit on targets as that seems to raise a keypress event without pushing a key
	// Callback tasks [(int)task, (var)arg1...]
	#define EvtsEvt$QTE$APPLY 0					// (int)success - QTE task was executed
	#define EvtsEvt$QTE$BUTTON 1				// (int)success - QTE button was hit. Success = proper button was hit
	#define EvtsEvt$QTE$END 2					// (int)success - QTE has ended. Success = all buttons were hit
	
#define EvtsEvt$QTE 1						// (int)numButtons - Quick time event, 0 for off

	
	

#define Evts$cycleEnemy() runMethod((string)LINK_SET, "got Evts", EvtsMethod$cycleEnemy, [], TNN)
#define Evt$startQuicktimeEvent(targ, numButtons, preDelay, callback) runMethod((str)targ, "got Evts", EvtsMethod$startQuicktimeEvent, [numButtons, preDelay], callback)

