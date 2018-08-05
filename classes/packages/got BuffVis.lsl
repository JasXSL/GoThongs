#include "got/_core.lsl"

// Conf is a 2-strided array of (int)index, (var)data
// (key)follow_this_id, (int)spellID, (str)assetName, (arr)conf, (key)assetID
list VIS;
#define visFollow 0
#define visID 1
#define visAssetName 2
#define visConf 3
#define visAssetKey 4

#define VIS_STRIDE 5

#define getKeys(id) \
	llList2ListStrided(llDeleteSubList(VIS, 0,3), 0, -1, VIS_STRIDE)


integer CHAN;

default
{
    state_entry()
    {
        BuffSpawn$purge();
        CHAN = BuffSpawnChan(llGetOwner());
        llListen(CHAN, "", "", "");
    }
    
    object_rez(key id){
        
        integer i;
        string name = llKey2Name(id);
        
        for(i=0; i<count(VIS); i+=VIS_STRIDE){
            if(l2s(VIS, i+visAssetName) == name && l2s(VIS, i+visAssetKey) == ""){
                VIS = llListReplaceList(VIS, [id], i+visAssetKey, i+visAssetKey);
                return;
            }
        }
		
		llSetTimerEvent(10);
        
    }
	
	timer(){
		// purge deleted every 10 seconds
		int i;
		for(; i<count(VIS) && count(VIS); i+= VIS_STRIDE){
			
			if( llKey2Name(l2k(VIS, i+visAssetKey)) == "" ){
				
				VIS = llDeleteSubList(VIS, i, i+VIS_STRIDE-1);
				i -= VIS_STRIDE;
				
			}
			
		}
		
	}
    
    listen(integer chan, string name, key id, string message){
        idOwnerCheck
        
        if(message == "INI"){
            
            list keys = getKeys();
            
            integer pos = llListFindList(keys, [id]);
            if(~pos){
                pos*= VIS_STRIDE;
                
                // Send the conf
                list conf = llJson2List(l2s(VIS, pos+visConf));
				conf+= [-1,l2s(VIS, pos+visFollow)];
				
                llRegionSayTo(id, CHAN, mkarr(conf));
				// Free memory
                VIS = llListReplaceList(VIS, [""], pos+visConf, pos+visConf);
            }
            else{
                BuffSpawn$purgeTarg(id);
            }
            
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
        
        string visual = method_arg(1);
        if(llGetInventoryType(visual) != INVENTORY_OBJECT)
            return;
            
        VIS += [
			id,
            l2i(PARAMS, 0),
            visual,
            method_arg(2),
            ""
        ];
        
        vector pos = llGetPos()-<0,0,5>;
        _portal_spawn_std(visual, pos, ZERO_ROTATION, -<0,0,5>, FALSE, FALSE, FALSE);
		
    }
    else if(METHOD == BuffVisMethod$rem){
	
        integer n = l2i(PARAMS, 0);
        integer i;
        for(i=0; i<count(VIS) && VIS != []; i+= VIS_STRIDE){
            
            if(l2i(VIS, i+visID) == n && l2s(VIS, i+visFollow) == (str)id){
				
                // Remove
                key targ = l2k(VIS, i+visAssetKey);
                if(targ)
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
