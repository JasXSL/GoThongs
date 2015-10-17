//#define USE_EVENTS
//#define USE_SHARED ["#ROOT", "got Bridge"]
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define tArg(idx) llList2String(data, idx)

default
{
	state_entry(){memLim(1.5);}
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback)
        return;
    
    if(METHOD == InteractMethod$interactWithMe){
        list data = llGetObjectDetails(id, [OBJECT_DESC, OBJECT_POS]);
        
        list split = llParseString2List(llList2String(data, 0), ["$$"], []);
        float range = llList2Float(split, 0);
        if(range<=0)range = 3;
        
        if(llVecDist(llGetPos(), llList2Vector(data, 1)) > range)return;
        
        list_shift_each(split, val,
            data = llParseString2List(val, ["$"], []);
            string task = llToLower(llList2String(data, 0));
            data = llDeleteSubList(data, 0, 0);
            
            if(task == "book")
                SharedMedia$setBook(tArg(0));
            
        )
        
    }
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}


