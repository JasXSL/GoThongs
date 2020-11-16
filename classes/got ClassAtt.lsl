#ifndef _gotClassAtt
#define _gotClassAtt
/*
	
	Handles class attachments
	

*/

//#define gotClassAttMethod$spellStart 1			// (var)customData, (float)timeout
//#define gotClassAttMethod$spellEnd 2			// (var)customData, (int)success
//#define gotClassAttMethod$stance 3				// (str)stance | "" for reset
#define gotClassAttMethod$raiseEvent 4			// (int)event, (var)arg1, (var)arg2...

#define gotClassAttEvt$spellStart 1				// (var)customData, (float)casttime, (key)target
#define gotClassAttEvt$spellEnd 2				// (var)customData, (int)success, (key)target | If success is -1 it timed out
#define gotClassAttEvt$stance 3					// (str)stance || "" for reset
#define gotClassAttEvt$dead 4					// (int)dead
#define gotClassAttEvt$spec 5					// (int)spec index


#define gotClassAtt$raiseEvent(evt, args) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)evt+args, TNN)

// CustomData from spellVis is the ID from spell data such as A B C
// Timeout is casttime+1
// 
#define gotClassAtt$spellStart(customData, timeout, target) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$spellStart + customData + timeout + target, TNN)
// CustomData is the array from dev tools spell visual ex ["A","A"]. 
// spellVisData is an array of [(arr)targets]
#define gotClassAtt$spellEnd(customData, success, spellVisData) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$spellEnd+ (customData) + (success) + (spellVisData), TNN)
#define gotClassAtt$stance(stance) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$stance+stance, TNN)
#define gotClassAtt$dead(dead) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$dead+dead, TNN)
#define gotClassAtt$spec(spec) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$raiseEvent, (list)gotClassAttEvt$spec+spec, TNN)





#endif
