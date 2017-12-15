#define USE_EVENTS
#include "got/_core.lsl"

vector startPos;

quit(){
    startPos = ZERO_VECTOR;
}

onEvt(string script, integer evt, list data){
    if(script == "got RootAux" && evt == RootAuxEvt$cleanup){
		integer manual = l2i(data, 0);
        if(manual)
			startPos = ZERO_VECTOR;
    }
}

default
{
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    
    if(method$isCallback)return;
    
    
    if(METHOD == LevelSpawnerMethod$spawnLevel && method$byOwner){
	
		string level = method_arg(0);
		
		if(llGetInventoryType(level) != INVENTORY_OBJECT){
			qd(level+" not found in the HUD. You may be missing a mod install. Remember that you have to install mods each time you update your HUD!");
			quit();
            return;
        }
		
        if(startPos == ZERO_VECTOR || llVecDist(startPos, llGetPos())>300){
			startPos = llGetPos()+<0,0,8>;
		}
            
        // Clear old
        Portal$killAll();
        Level$despawn();
        _portal_spawn_std(level, startPos, ZERO_ROTATION, <0,0,8>, FALSE, FALSE, FALSE);
		
		
    }
 
	if(METHOD == LevelSpawnerMethod$remInventory && method$internal){
        list assets = llJson2List(method_arg(0));
        list_shift_each(assets, val,
            if(llGetInventoryType(val) == INVENTORY_OBJECT){
                llRemoveInventory(val);
            }
        )
    }
    
    
    
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}

