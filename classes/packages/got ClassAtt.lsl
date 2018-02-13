#define USE_EVENTS
#include "got/_core.lsl"

list PLAYERS;

onEvt(string script, integer evt, list data){
    
    if( Portal$isPlayerListIfStatement )
        PLAYERS = data;
    
}

timerEvent( string id, string data ){
    
    if( startsWith(id, "P_") )
		raiseEvent(gotClassAttEvt$spellEnd, llGetSubString(id, 2, -1));
    
}

default{
    
    on_rez(integer mew){llResetScript();}
    
    state_entry(){
        
        PLAYERS = [(string)llGetOwner()];
        memLim(1.5);
        
    }
        
    timer(){multiTimer([]);}
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters   
        CB - The callback you specified when you sent a task
    */ 
    if( method$isCallback || !method$byOwner )
        return;
        
    if( METHOD == gotClassAttMethod$spellStart ){
        
		float timeout = l2f(PARAMS, 1);
		if( timeout <= 0 )
			timeout = 1;
			
		raiseEvent(gotClassAttEvt$spellStart, mkarr([method_arg(0)]));
        multiTimer(["P_"+method_arg(0), "", timeout, FALSE]);
        
    }
    
    else if( METHOD == gotClassAttMethod$spellEnd ){
        
		multiTimer(["P_"+method_arg(0)]);
		raiseEvent(gotClassAttEvt$spellEnd, mkarr(PARAMS));
		
    }
	else if( METHOD == gotClassAttMethod$stance )
		raiseEvent(gotClassAttEvt$stance, mkarr(PARAMS));
	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
