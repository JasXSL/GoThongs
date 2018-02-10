/*
	
	Handles class attachments
	

*/

#define gotClassAttMethod$spellStart 1			// (var)customData, (float)timeout
#define gotClassAttMethod$spellEnd 2			// (var)customData, (int)success

#define gotClassAttEvt$spellStart 1				// (var)customData | 
#define gotClassAttEvt$spellEnd 2				// (var)customData, (int)success | If success is -1 it timed out

#define gotClassAtt$spellStart(customData, timeout) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$spellStart, [customData, timeout], TNN)
#define gotClassAtt$spellEnd(customData, success) runMethod(llGetOwner(), "got ClassAtt", gotClassAttMethod$spellEnd, [customData, success], TNN)

