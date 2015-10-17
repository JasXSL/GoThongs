#define USE_EVENTS
#define ALLOW_USER_DEBUG 1
#include "../../_core.lsl"

list required;
list PLAYERS;

integer BFL;
#define BFL_SCRIPTS_INITIALIZED 1
#define BFL_GOT_PLAYERS 2

#define BFL_INI 3
#define checkIni() if((BFL&BFL_INI) == BFL_INI){llSleep(.2); raiseEvent(evt$SCRIPT_INIT, mkarr(PLAYERS));}

onEvt(string script, integer evt, string data){
    if(evt == evt$SCRIPT_INIT && required != []){
        integer pos = llListFindList(required, [script]);
        if(~pos)required = llDeleteSubList(required, pos, pos);
		debugUncommon("Waiting for "+mkarr(required));
        if(required == []){
            BFL = BFL|BFL_SCRIPTS_INITIALIZED;
            checkIni() 
        }
    }
}
 
timerEvent(string id, string data){
	
}


default
{
    on_rez(integer mew){
        if(mew){
            integer pin = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(pin);
            
			
            vector p = llGetPos();
            vector pos = p-vecFloor(p)+int2vec(mew);			
			if(mew == 1)pos = ZERO_VECTOR;
			llSetText((string)pos, ZERO_VECTOR, 0);
			
            
            multiTimer([]);
            Remoteloader$load(cls$name, pin, 2);
			return;
        }
        llResetScript();
    }
    state_entry()
    {
		PLAYERS = [(string)llGetOwner()];
        initiateListen();
        integer pin = llCeil(llFrand(0xFFFFFFF));
        llSetRemoteScriptAccessPin(pin);
            
        if(!llGetStartParameter())return;
        if(llGetStartParameter() == 2){
            // Request
            list check = PORTAL_SEARCH_SCRIPTS;
            list_shift_each(check, val,
                if(llGetInventoryType(val) == INVENTORY_SCRIPT){
                    required+=val;
                }
            )
			integer i;
			for(i=0; i<llGetListLength(required); i++)
				Remoteloader$load(llList2String(required, i), pin, 2);
            
            vector pos = (vector)llList2String(llGetPrimitiveParams([PRIM_TEXT]), 0);
			if(pos != ZERO_VECTOR)llSetRegionPos(pos);
			
        } 
        if(required == []){
            BFL = BFL|BFL_SCRIPTS_INITIALIZED;
            checkIni()
        }
        Root$getPlayers("INI");
        llSetTimerEvent(5);
        memLim(1.5);
    }
    
    timer(){
        Root$getPlayers("INI");
    }
    
	#define LISTEN_LIMIT_FREETEXT if(llListFindList(PLAYERS, [(string)llGetOwnerKey(id)]) == -1)return;
    #include "xobj_core/_LISTEN.lsl"
    
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters   
        CB - The callback you specified when you sent a task
    */ 
    if(method$isCallback){
        if(!method$byOwner)return;
        
        if(SENDER_SCRIPT == "#ROOT" && METHOD == RootMethod$getPlayers && CB == "INI"){
            PLAYERS = llJson2List(method_arg(0));
            BFL = BFL|BFL_GOT_PLAYERS;
            llSetTimerEvent(0);
            checkIni()
        } 
        return;
    }
    
    if(method$byOwner){
        if(METHOD == PortalMethod$reinit){
            qd("Reinitializing");
            integer pin = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(pin);
            Remoteloader$load(cls$name, pin, 2);
        }else if(METHOD == PortalMethod$remove){
            llDie();
        }
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

