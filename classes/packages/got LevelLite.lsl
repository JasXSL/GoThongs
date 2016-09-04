#define SCRIPT_ALIASES ["got Level"]
#define USE_SHARED ["*"]
#define USE_EVENTS
#include "got/_core.lsl"
integer slave;

// Load the level if portal is live
#define onEvt(script, evt, data) \
	if(script == "got Portal" && evt == evt$SCRIPT_INIT){\
		LevelLoader$load(FALSE, ""); \
	}\

default
{
	state_entry(){memLim(1.5); raiseEvent(evt$SCRIPT_INIT, "");}
	
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
	
	
    if(METHOD == LevelMethod$load && method$byOwner){
        integer debug = (integer)method_arg(0);
		string group = method_arg(1);
        raiseEvent(LevelEvt$load, mkarr(([debug, group])));
		LevelLoader$load(debug, group);
        return;
    }
	if(METHOD == LevelMethod$getScripts && method$byOwner){
        integer pin = (integer)method_arg(0);
        list scripts = llJson2List(method_arg(1));
        list_shift_each(scripts, v, 
            if(llGetInventoryType(v) == INVENTORY_SCRIPT){
                slave++;
                if(slave>9)slave=1;
                // Remote load
                llMessageLinked(LINK_THIS, slave, llList2Json(JSON_ARRAY, [id, v, pin, 2]), "rm_slave");
            }
            else if(llGetInventoryType(v) != INVENTORY_NONE) llGiveInventory(id, v);
			else qd(v+" could not be loaded onto "+llKey2Name(id)+" because it doesn't exist.");
        )
        
    }
    

    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

