#include "got/_core.lsl"

#define TIMER_FADE "a"

list ALERTS;
integer P_ALERT;

setText(float alpha){
    llSetLinkPrimitiveParamsFast(P_ALERT, [PRIM_TEXT, llDumpList2String(ALERTS, "\n"), <1,.25, .25>, alpha]);
}

timerEvent(string id, string data){
    if(id == TIMER_FADE){
        float alpha = (float)data-.025;
        setText(alpha);
        if(alpha <=0){
            ALERTS = [];
            return;
        }
        multiTimer([id, alpha, .05, FALSE]);
    }
}

default
{
    state_entry()
    {
        memLim(1.5);
        links_each(nr, name,
            if(name == "ALERT")P_ALERT = nr;
        )
    }
    
    timer(){
        multiTimer([]);
    }
    
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
    if(method$isCallback){
        return;
    }
    
    // Internal means the method was sent from within the linkset
    if(method$internal){
        if(METHOD == AlertMethod$alert || METHOD == AlertMethod$freetext){
            string text = method_arg(0);
            if(METHOD == AlertMethod$alert){
                integer id = (integer)text;
                
                if(SENDER_SCRIPT == "got SpellMan")text = llList2String(ASpellMan, id);
                else if(SENDER_SCRIPT == "#ROOT")text = llList2String(ARoot, id);
                else if(SENDER_SCRIPT == "got Bridge")text = llList2String(ABridge, id);
                
                
                if(text == ""){
                    qd("Text missing for "+SENDER_SCRIPT+" : "+(string)id);
                    return;
                }
            }
            if((integer)method_arg(1))llOwnerSay(text);
            if((integer)method_arg(2))llPlaySound("09ba0e73-fcf6-ed22-e1a3-7fc600237711", .25);
            
            ALERTS+=text;
            if(llGetListLength(ALERTS)>3)
                ALERTS = llDeleteSubList(ALERTS, 0, 0);
            
            
            setText(1);
            
            multiTimer([TIMER_FADE, 1, llStringLength(text)*.02+2, FALSE]);
        }
        
    }
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

