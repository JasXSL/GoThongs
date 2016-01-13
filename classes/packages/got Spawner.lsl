#define USE_SHARED ["#ROOT"]
#include "got/_core.lsl"


list queue;			// [name, pos, rot, desc, debug, temp]
#define QUEUESTRIDE 6
integer BFL;
#define BFL_QUEUE 1
// If the object description has been sent
#define BFL_READY 2

integer rDesc; // Req desc of this item
string asset;
key current;
integer attempts;

// Spawns the next asset
next(integer forceRetry){
	// Queue is empty or already going
	if(queue == [] || (BFL&BFL_QUEUE && !forceRetry)){
		if(queue == []){  
			multiTimer(["FORCE_NEXT"]);
			multiTimer(["B", "", 2, FALSE]);
		}
		return;
	}
	// Clear the completion timer
	multiTimer(["B"]);
	
	// Globals
	// If a description is needed
	rDesc = llList2String(queue, 3) != "";
	// Name
	asset = llList2String(queue, 0);
	
	// Description has not been sent
	BFL = BFL&~BFL_READY;
	
	
	
	
	// Spawn it
	_portal_spawn_std(asset, llList2Vector(queue,1), llList2Rot(queue,2), -<0,0,8>, llList2Integer(queue, 4), rDesc, llList2Integer(queue,5));
	
	// Wait for it to finish
	BFL = BFL|BFL_QUEUE;
	
	// Sets a timer to force retry this one if it didn't spawn
	multiTimer(["FORCE_NEXT", "", 30, FALSE]);
}

// An item has been initialized, let's continue
done(){
	queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
	BFL = BFL&~BFL_QUEUE;
	next(FALSE);
}

timerEvent(string id, string data){
	// A checks if the asset is ready for description input, provided the asset does have a description
	if(id == "A"){
		string desc = prDesc(current);
		// Send the description since the object is now ready
		if(desc == "READY"){
			BFL = BFL|BFL_READY;
			Portal$iniData(current, llList2String(queue, 3));
			attempts++;
			if(attempts == 50){
				qd("Portal is not responding: "+llKey2Name(current));
			}
		}
		// Keep sending until the description is no longer "READY"
		else if(BFL&BFL_READY){
			multiTimer(["A"]);
			done();
		}
	}
	// B is sent once all objects have been spawned
	else if(id == "B"){
		#ifdef IS_HUD
		Level$loaded(db2$get("#ROOT", [RootShared$level]), TRUE);
		#else
		Level$loaded((string)LINK_ROOT, FALSE);
		#endif
	}
	// If SL didn't rez in a timely fashion, retry
	else if(id == "FORCE_NEXT"){
		qd("Error. SL dropped spawn success on "+mkarr(llList2List(queue, 0, QUEUESTRIDE-1))+" retrying. If this message repeats a lot, say 'debug got Spawner' in chat and restart the level.");
		next(TRUE);
	}
	
}

default
{
	state_entry(){db2$ini(); raiseEvent(evt$SCRIPT_INIT, "");}
	object_rez(key id){
		if(llKey2Name(id) != asset)return;
		if(!rDesc){
			done();
		}else{
			attempts = 0;
			current = id; // Cache the current ID
			multiTimer(["A", "", .2, TRUE]);
		}
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
    if(method$isCallback){
        return;
    }
    
	if(method$internal){
		if(METHOD == SpawnerMethod$remInventory){
			list assets = llJson2List(method_arg(0));
			list_shift_each(assets, val,
				if(llGetInventoryType(val) == INVENTORY_OBJECT){
					llRemoveInventory(val);
				}
			)
		}
	}
	
    if(method$byOwner){
		if(METHOD == 0){
			llResetScript();
		}
        if(METHOD == SpawnerMethod$spawn){
            string object = method_arg(0);
            if(llGetInventoryType(object) != INVENTORY_OBJECT){qd("Missing asset: "+object);return;}
            vector pos = (vector)method_arg(1);
            rotation rot = (rotation)method_arg(2);
			string desc = (string)method_arg(3);		// DO something with this
			integer debug = (integer)method_arg(4);		
			integer temp = (integer)method_arg(5);
			queue+= [object, pos, rot, desc, debug, temp];
			next(FALSE);
        }else if(METHOD == SpawnerMethod$debug){
			qd("Dumping queue");
			integer i;
			for(i=0; i<llGetListLength(queue); i+= QUEUESTRIDE){
				qd(mkarr(llList2List(queue, i, i+QUEUESTRIDE-1)));
			}
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

