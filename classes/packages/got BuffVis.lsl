#define USE_DB4
#include "got/_core.lsl"

// Conf is a 2-strided array of (int)index, (var)data
// (key)follow_this_id, (int)spellID, (str)assetName, (arr)conf, (key)assetID
list VIS;
#define visFollow 0		// Needs to be stored because player huds handle visuals on their monsters, allowing PID overlaps from got FX.
#define visID 1			// spellID
#define visAssetKey 2	// Needed for deletions
#define visTimestamp 3	// llGetTime(), prevents race conditions

#define VIS_STRIDE 4

integer CHAN;

default{

    state_entry(){
	
        BuffSpawn$purge();
        CHAN = BuffSpawnChan(llGetOwner());
        llListen(CHAN, "", "", "");
		llSetTimerEvent(10);
		
    }
    

	timer(){
		// purge deleted every 10 seconds
		int i;
		for(; i<count(VIS) && count(VIS); i+= VIS_STRIDE){
			
			float ts = l2f(VIS, i+visTimestamp);
			if( llKey2Name(l2k(VIS, i+visAssetKey)) == "" && llGetTime()-ts > 10 ){
				
				VIS = llDeleteSubList(VIS, i, i+VIS_STRIDE-1);
				i -= VIS_STRIDE;
				
			}
			
		}
		
	}
    
    listen(integer chan, string name, key id, string message){
        idOwnerCheck

		// FX may have been removed before the object spawned. then we need to remove it
        if( message == "INI" ){
		
            integer pos = llListFindStrided(VIS, [id], 0, -1, visAssetKey);
            if( pos == -1 )
                BuffSpawn$purgeTarg(id);

        }
		
    }
    
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl"  
    
    if(method$isCallback){
        return;
    }
    
    if(!method$byOwner)
        return;
    
    if(METHOD == BuffVisMethod$add){
        
		int pid = l2i(PARAMS, 0);
        string visual = method_arg(1);
        if(llGetInventoryType(visual) != INVENTORY_OBJECT)
            return;

        
        vector pos = llGetRootPosition()-<0,0,5>;
        key obj = _portal_spawn_v3(
			visual, 
			pos, 
			ZERO_ROTATION, 
			-<0,0,5>, 
			FALSE, 
			"_LTB", 
			id,
			method_arg(2), // Config
			[]
		);
		VIS += [
			id, pid, obj, llGetTime()
		];
		
    }
    else if( METHOD == BuffVisMethod$rem ){
	
        integer n = l2i(PARAMS, 0);
        integer i;
        for( ; i < count(VIS) && VIS != []; i+= VIS_STRIDE){
            
            if( 
				l2i(VIS, i+visID) == n && 			// Effect PID
				l2s(VIS, i+visFollow) == (str)id	// Vis target
			){
				
                // Remove
                key targ = l2k(VIS, i+visAssetKey);
                if( targ )
                    BuffSpawn$purgeTarg(targ);
                
                VIS = llDeleteSubList(VIS, i, i+VIS_STRIDE-1);
                
                i-= VIS_STRIDE;
				
            }
            
        }
		
        
    }
	else if(METHOD == BuffVisMethod$remInventory){
		
		list_shift_each(PARAMS, name,
			if(llGetInventoryType(name) == INVENTORY_OBJECT)
				llRemoveInventory(name);
		)
		
	}
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
