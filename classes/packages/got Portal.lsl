#define USE_EVENTS
#define ALLOW_USER_DEBUG 1
#include "../../_core.lsl"

list required;
list PLAYERS;

integer BFL;
#define BFL_SCRIPTS_INITIALIZED 1
#define BFL_GOT_PLAYERS 2
#define BFL_IS_DEBUG 4
#define BFL_HAS_DESC 8
#define BFL_INITIALIZED 0x10

#define BFL_INI 11
#define checkIni() if((BFL&BFL_INI) == BFL_INI && ~BFL&BFL_IS_DEBUG && ~BFL&BFL_INITIALIZED){llSleep(.2); BFL=BFL|BFL_INITIALIZED; raiseEvent(evt$SCRIPT_INIT, mkarr(PLAYERS)); debugUncommon("Portal initialized");}

string INI_DATA = "";

onEvt(string script, integer evt, string data){
    if(evt == evt$SCRIPT_INIT && required != []){
        integer pos = llListFindList(required, [script]);
        if(~pos)required = llDeleteSubList(required, pos, pos);
		debugUncommon("Waiting for "+mkarr(required));
        if(required == []){
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
			//qd(BFL);
			BFL = BFL|BFL_SCRIPTS_INITIALIZED;
			checkIni() 
			
        }
    }
}

/*
	On rez prim text gets set to integer mew
	Then it gets changed to [(vec)startPos, (int)debug, (var)start_data]
	Start data is set up by the prim's description when buliding the level

*/
#define getText() llList2String(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]), 0)
#define setText(data) llSetText(data, ZERO_VECTOR, 0)

integer pin;

default
{
    on_rez(integer mew){
        if(mew != 0){
			if(mew&BIT_TEMP){
				llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
			}
			integer p = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(p);
			setText((string)mew);
            multiTimer([]);
            Remoteloader$load(cls$name, p, 2);
			return;
        }
        llResetScript();
    }
    state_entry()
    {
	
		PLAYERS = [(string)llGetOwner()];
        initiateListen();
        pin = llCeil(llFrand(0xFFFFFFF));
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
            
					
			
			debugUncommon("Waiting for "+mkarr(required));
			
			integer mew = llList2Integer(llGetPrimitiveParams([PRIM_TEXT]), 0);
			
			
			vector p = llGetPos();
			vector pos = p-vecFloor(p)+int2vec(mew);
			
			if(mew == 1)pos = ZERO_VECTOR;

			if(mew&(BIT_DEBUG-1))llSetRegionPos(pos);
			if(mew&BIT_DEBUG){
				BFL = BFL|BFL_IS_DEBUG;
				llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
			}
			if(mew&BIT_GET_DESC){
				// Needs to fetch data from the spawner
				llSetObjectDesc("READY");
			}
			else BFL = BFL|BFL_HAS_DESC;
			setText(mkarr(([pos, ((BFL&BFL_IS_DEBUG)>0), ""])));
        } 
        if(required == []){
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
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
			
            integer p = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(p);
            integer nr = 2;
			if((integer)method_arg(0))nr = 3;	// Use a positive int to just update without initializing
			
			Remoteloader$load(cls$name, p, 3);
        }else if(METHOD == PortalMethod$remove){
            llDie();
        }
		else if(METHOD == PortalMethod$resetAll){
			qd("Resetting everything");
			resetAll();
		}
		else if(METHOD == PortalMethod$iniData){
			INI_DATA = method_arg(0);
			
			if(llJsonValueType(INI_DATA, []) == JSON_ARRAY){
				list ini = llJson2List(INI_DATA);
				integer i;
				for(i=0; i<llGetListLength(ini) && ini != []; i++){
					list v = llJson2List(llList2String(ini, i));
					if(llList2String(v, 0) == "SC"){
					
						v = llDeleteSubList(v, 0, 0);
						BFL=BFL&~BFL_SCRIPTS_INITIALIZED;
						required+=v;
						
						Level$getScripts(pin, mkarr(v));
						
						
						if(~BFL&BFL_IS_DEBUG){
							ini = llDeleteSubList(ini, i, i);
							i--;
						}
					}
				}
				INI_DATA = mkarr(ini);
			}
			
			if(BFL&BFL_IS_DEBUG)INI_DATA = "$"+INI_DATA;
			llSetObjectDesc(INI_DATA);
			BFL = BFL|BFL_HAS_DESC;
			string get = getText();
			get = llJsonSetValue(get, [2], INI_DATA);
			setText(get);
			
			raiseEvent(PortalEvt$desc_updated, "");
			
			checkIni()
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

