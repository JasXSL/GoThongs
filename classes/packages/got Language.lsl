#define USE_SHARED ["got Bridge"]
#define USE_EVENTS
#include "got/_core.lsl"

integer SPOKEN;

onEvt(string script, integer evt, string data){
    if(script == "got Bridge" && evt == BridgeEvt$userDataChanged){
        SPOKEN = (integer)j(data, BSUD$LANG);
    }
}



default
{
    state_entry()
    {
        memLim(1.5);
        llSetTimerEvent(1);
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
    if(method$isCallback){
        
        return;
    }
    
    if(METHOD == LanguageMethod$text){
        integer lang = (integer)method_arg(0);
        integer field = 1;
        if(~SPOKEN&lang && lang)field = 2;
        string text = method_arg(field);
        key sound = (key)method_arg(3);
        float vol = (float)method_arg(4);
        if(sound){
            if(vol <= 0)vol = 1;
            llPlaySound(sound, vol);
        }
        AM$(text);
        
    }
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
