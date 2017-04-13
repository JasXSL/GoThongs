#include "got/_core.lsl"

// Conf is a 2-strided array of (int)index, (var)data
// (int)spellID, (str)assetName, (arr)conf, (key)assetID
list VIS;
#define VIS_STRIDE 4

#define getKeys() llList2ListStrided(llDeleteSubList(VIS, 0,2), 0, -1, VIS_STRIDE)

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
            if(l2s(VIS, i+1) == name && l2s(VIS, i+3) == ""){
                VIS = llListReplaceList(VIS, [id], i+3, i+3);
                return;
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
                string conf = l2s(VIS, pos+2);
                llRegionSayTo(id, CHAN, conf);
                VIS = llListReplaceList(VIS, [""], pos+2, pos+2);
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
    
    if(id != "")
        return;
    
    if(METHOD == BuffVisMethod$add){
        
        string visual = method_arg(1);
        if(llGetInventoryType(visual) != INVENTORY_OBJECT)
            return;
            
        VIS += [
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
            
            if(l2i(VIS, i) == n){
                // Remove
                key targ = l2k(VIS, i+3);
                if(targ){
                    BuffSpawn$purgeTarg(targ);
                }
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
