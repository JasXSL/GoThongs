#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

list PLAYERS;

onEvt(string script, integer evt, list data){
    
    if( Portal$isPlayerListIfStatement )
        PLAYERS = data;
    
}

timerEvent( string id, string data ){
    
    if( llGetSubString(id, 0,2) == "P_" )
		raiseEvent(gotClassAttEvt$spellEnd, llGetSubString(id, 2, -1));
    
}

ini(){
	key id = prRoot(mySpawner());
	if( id )
		llSetObjectDesc("TAG$gothud_"+(string)id);
}

default{
    
    on_rez(integer mew){llResetScript();}
    
    state_entry(){
        
        PLAYERS = [(string)llGetOwner()];
        memLim(1.5);
        raiseEvent(evt$SCRIPT_INIT, "");
		ini();
		
    }
    
	attach(key id ){
		if( id )
			ini();
	}
	
    timer(){multiTimer([]);}
    
    #include "xobj_core/_LM.lsl"
    if( method$isCallback || !method$byOwner )
        return;
    
	if( METHOD == gotClassAttMethod$raiseEvent ){
		
		int evt = l2i(PARAMS, 0);
		list data = llDeleteSubList(PARAMS, 0, 0);
		raiseEvent(evt, mkarr(data));
		
		if( evt == gotClassAttEvt$spellStart ){
		
			float timeout = l2f(data, 1);
			if( timeout <= 0 )
				timeout = 1;
			multiTimer(["P_"+l2s(data, 0), "", timeout, FALSE]);
			
		}
		
		else if( evt == gotClassAttEvt$spellEnd ){
			
			multiTimer(["P_"+l2s(data, 0)]);
			
		}
		
		
	}
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}


