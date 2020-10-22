#include "got/_core.lsl"

integer BFL;
#define BFL_QUEUE 0x1

list queue; // [name, targ, time]
purge(){
    integer i;
    for(i=0; i<llGetListLength(queue) && queue != []; i+=3){
        if(llGetTime()-llList2Integer(queue, i+2)>10){
            queue = llDeleteSubList(queue, i, i+2);
            i-=3;
        }
    }
}

list quickQn;	// Holds names of spawned objects with custom data
list quickQd;	// time, data		// Holds time of spawn and data for above. Use above index multiplied by 2

removeFromQuickQ( integer index ){
	
	quickQn = llDeleteSubList(quickQn, index, index);
	quickQd = llDeleteSubList(quickQn, index*2, index*2+1);

}

default{

    state_entry(){
	
		llListen(SpellFX$customDataChan, "", "", "");
		llSetTimerEvent(30);	// Checks for quickQ timeout
		
    }
	
	listen( integer ch, string n, key id, string msg ){
		idOwnerCheck
		
		// GET data for the name of the sender
		if( msg == "G" ){
			
			// returns E if no data found
			string out = "E";
			integer pos = llListFindList(quickQn, (list)n);
			if( ~pos ){
				out = l2s(quickQd, pos*2+1);
				removeFromQuickQ(pos);
			}
			llRegionSayTo(id, ch, out);
			
		}
	
	}

	
	timer(){
		
		integer i;
		for(; i < count(quickQn) && count(quickQn); ++i ){
			
			float timeout = l2f(quickQd, i*2);
			if( llGetTime()-timeout > 30 ){
				
				removeFromQuickQ(i);			
				--i;
				
			}
		
		}
		
	}

    
    #include "xobj_core/_LM.lsl" 

    if(method$isCallback){
        return;
    }
    
    if(method$internal){
        if(METHOD == SpellFXMethod$spawn){

			string item = method_arg(0);
            key targ = method_arg(1);
			purge();
            
            if(!isset(item) || !isset(targ))return;
            queue+=[item, targ, llGetTime()];
			
			vector r = llRot2Euler(prRot(llGetOwner()));
            llRezAtRoot(item, llGetRootPosition()-<0,0,3>, ZERO_VECTOR, llEuler2Rot(<0,0,r.z>), 1);
			
        }
		else if(METHOD == SpellFXMethod$remInventory){
			list assets = llJson2List(method_arg(0));
			list_shift_each(assets, val,
				if(llGetInventoryType(val) == INVENTORY_OBJECT){
					llRemoveInventory(val);
				}
			)
		}
	}
    
    if(method$byOwner){
	
        if(METHOD == SpellFXMethod$getTarg){
            string n = llKey2Name(id);
            integer pos = llListFindList(llList2ListStrided(queue, 0, -1, 3), [n]);
            if(~pos){
                CB_DATA = [llList2String(queue, pos*3+1)];
                queue = llDeleteSubList(queue, pos, pos+2);
            }
            else CB_DATA = [0];
        }
        
        else if(METHOD == SpellFXMethod$sound){
            key sound = method_arg(0);
            if(sound){
                llStopSound();
                float vol = (float)method_arg(1);
                integer loop = (integer)method_arg(2);
                if(loop)llLoopSound(sound, vol);
                else llPlaySound(sound, vol);
            }
            else llStopSound();
        }
        else if( METHOD == SpellFXMethod$spawnInstant ){
		
            list data = llJson2List(method_arg(0));
            string name = llList2String(data, 0);
            vector pos_offset = (vector)llList2String(data, 1);
            rotation rot_offset = (rotation)llList2String(data, 2);
			integer flags = llList2Integer(data, 3);
			integer startParam = l2i(data, 4);
			string quickQ = l2s(data, 5);
			
			if(startParam == 0)
				startParam = 1;
			
            key targ = method_arg(1);
			key t = targ;
			if( flags & SpellFXFlag$SPI_SPAWN_FROM_CASTER )
				t = llGetOwner();
            
			
			float zOffset = pos_offset.z;
			pos_offset.z = 0;
			
			float b;	// Bounds height. 0 = ignore
			if( flags&SpellFXFlag$SPI_IGNORE_HEIGHT )
				zOffset = 0;
				
				
			vector vrot = llRot2Euler(prRot(t));
			if( ~flags & SpellFXFlag$SPI_FULL_ROT )
				vrot = <0,0,vrot.z>;
			
			if( flags & SpellFXFlag$SPI_TARG_IN_REZ )
				startParam = (int)("0x"+llGetSubString(targ,0,7));
			
			rotation rot = llEuler2Rot(vrot);

			
			vector to = getTargetPosOffset(t, zOffset+0.5)+pos_offset*rot;
						
			if( isset(quickQ) ){
				
				quickQn += name;
				quickQd += (list)llGetTime() + quickQ;
				
			}
						
            llRezAtRoot(name, to, ZERO_VECTOR, llEuler2Rot(vrot)*rot_offset, startParam);

        }
		else if(METHOD == SpellFXMethod$fetchInventory){
			list items = llJson2List(method_arg(0));
			list_shift_each(items, item,
				if(llGetInventoryType(item) == INVENTORY_OBJECT)
					llGiveInventory(id, item);
			)
		}
		
    }


    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}

