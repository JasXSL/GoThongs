#ifndef _gotEvts
#define _gotEvts

#define EvtsMethod$cycleEnemy 1				// void - Get a nearby enemy
#define EvtsMethod$startQuicktimeEvent 2	/* Starts a quick time event. Sends a callback with the first arg being one of the below tasks and the CB specified.
	(int)numButtons, 		- Nr butttons needed to be pressed. In LR_CAN_FAIL mode this sets the speed of the bar growing, default 30% per second
	(float)preDelay, 		- Time to wait before showing the buttons.
	(float)buttonDelay=0,  	- How long to wait after a successful press to draw the next part. Useful for monster that trigger an animation on success.
	(int)flags				- See below
*/
#define Evts$qFlags$LR 0x1				// Instead of having to press 4 buttons, you have to press left right repeatedly to fill a bar
#define Evts$qFlags$LR_CAN_FAIL 0x2		// When used with above, the bar starts at 50% and starts fading. Fade rate can be inversely affected by fxMod

	// Callback tasks [(int)task, (var)arg1...]
	#define EvtsEvt$QTE$APPLY 0					// void - QTE task was executed
	#define EvtsEvt$QTE$BUTTON 1				// (int)success - QTE button was hit. Success = proper button was hit
	#define EvtsEvt$QTE$END 2					// (int)success - QTE has ended. Success = all buttons were hit
	
#define EvtsMethod$addTextureDesc 3	// pid, texture, desc, added, duration, stacks, pflags - Adds a spell icon
#define EvtsMethod$remTextureDesc 4	// (key)texture						
#define EvtsMethod$getTextureDesc 5	// (int)pid, (key)player - Gets info about a spell by pos
#define EvtsMethod$stacksChanged 6	// (int)PID, (int)added, (float)duration, (int)stacks - Sent when stacks have changed.
	
#define EvtsEvt$QTE 1						// (int)numButtons - Quick time event, 0 for off

	
	

#define Evts$cycleEnemy() runMethod((string)LINK_SET, "got Evts", EvtsMethod$cycleEnemy, [], TNN)
#define Evt$startQuicktimeEvent(targ, numButtons, preDelay, callback, buttonDelay, flags) runMethod((str)targ, "got Evts", EvtsMethod$startQuicktimeEvent, [numButtons, preDelay, buttonDelay, flags], callback)
#define Evts$startQuicktimeEvent(targ, numButtons, preDelay, callback, buttonDelay, flags) Evt$startQuicktimeEvent(targ, numButtons, preDelay, callback, buttonDelay, flags)
#define Evts$stopQicktimeEvent(targ) runMethod((str)targ, "got Evts", EvtsMethod$startQuicktimeEvent, [-1], TNN);

#define Evts$addTextureDesc(pid, texture, desc, added, duration, stacks, pflags) runMethod((string)LINK_ROOT, "got Evts", EvtsMethod$addTextureDesc, [pid, texture, desc, added, duration, stacks, pflags], TNN)
#define Evts$remTextureDesc(pid) runMethod((string)LINK_ROOT, "got Evts", EvtsMethod$remTextureDesc, [pid], TNN)
#define Evts$getTextureDesc(player, pid) runMethod((str)player, "got Evts", EvtsMethod$getTextureDesc, (list)pid, TNN)
#define Evts$stacksChanged(pid, added, duration, stacks) runMethod((string)LINK_ROOT, "got Evts", EvtsMethod$stacksChanged, [pid, added, duration, stacks], TNN)

string evtsStringitizeDesc( string desc, int stacks ){
	
	list out = llParseString2List(desc, [], ["<|", "|>"]);
	integer i;
	for( ;i<count(out); ++i ){
	
		string s = l2s(out, i);
		if( s == "<|" ){
			
			s = l2s(out, i+1);
			if( llGetSubString(s, 0,0) == "s" )
				s = (string)llRound((float)llGetSubString(s, 1, -1)*stacks);
				
			out = llListReplaceList(out, (list)s, i, i+2);
		
		}
	
	}
	return (string)out;

}


#endif
