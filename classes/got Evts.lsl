#define EvtsMethod$cycleEnemy 1				// void - Get a nearby enemy
#define EvtsMethod$startQuicktimeEvent 2	// (int)numButtons, (str)callback - Starts a quick time event where you have to push numButtons random buttons
	// Callback tasks [(int)task, (var)arg1...]
	#define EvtsEvt$QTE$APPLY 0					// (int)success - QTE task was executed
	#define EvtsEvt$QTE$BUTTON 1				// (int)success - QTE button was hit. Success = proper button was hit
	#define EvtsEvt$QTE$END 2					// void - QTE has ended
	
#define EvtsEvt$QTE 1						// (int)numButtons - Quick time event, 0 for off

	
	

#define Evts$cycleEnemy() runMethod((string)LINK_SET, "got Evts", EvtsMethod$cycleEnemy, [], TNN)
#define Evt$startQuicktimeEvent(targ, numButtons, callback) runMethod((str)targ, "got Evts", EvtsMethod$startQuicktimeEvent, [numButtons], callback)

