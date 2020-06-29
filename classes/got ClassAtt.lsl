#ifndef _gotClassAtt
#define _gotClassAtt
/*
	
	Handles class attachments
	

*/

//#define gotClassAttMethod$spellStart 1			// (var)customData, (float)timeout
//#define gotClassAttMethod$spellEnd 2			// (var)customData, (int)success
//#define gotClassAttMethod$stance 3				// (str)stance | "" for reset
#define gotClassAttMethod$raiseEvent 4			// (int)event, (var)arg1, (var)arg2...

#define gotClassAttEvt$spellStart 1				// (var)customData | 
#define gotClassAttEvt$spellEnd 2				// (var)customData, (int)success | If success is -1 it timed out
#define gotClassAttEvt$stance 3					// (str)stance || "" for reset
#define gotClassAttEvt$dead 4					// (int)dead


#define gotClassAtt$raiseEvent(evt, args) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)evt+args, TNN)

#define gotClassAtt$spellStart(customData, timeout) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$spellStart+customData+timeout, TNN)
// CustomData is the array from dev tools spell visual ex ["A","A"]. spellVisData is an array of [(arr)targets]
#define gotClassAtt$spellEnd(customData, success, spellVisData) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$spellEnd+ (customData) + (success) + (spellVisData), TNN)
#define gotClassAtt$stance(stance) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$stance+stance, TNN)
#define gotClassAtt$dead(dead) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$dead+dead, TNN)





#endif
