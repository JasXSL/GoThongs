#define USE_EVENTS
#include "got/_core.lsl"


list queue;			// [(str)name, (vec)pos, (rot)rot, (str)desc, (bool)debug, (bool)temp, (str)spawnround, (key)sender]
#define QUEUESTRIDE 8
integer BFL;
#define BFL_QUEUE 1
// If the object description has been sent
#define BFL_READY 2

integer rDesc; // Req desc of this item
string asset;
key current;
integer attempts;
integer num_spawned;

key ROOT_LEVEL;		// ID of level

// Spawns the next asset
next(integer forceRetry){
	// Clear the completion timer
	multiTimer(["B"]);
	
	// Queue is empty or already going
	if(queue == [] || (BFL&BFL_QUEUE && !forceRetry)){
		if(queue == []){  
			multiTimer(["FORCE_NEXT"]);	
			multiTimer(["B", "", 2, FALSE]);
		}
		return;
	}
	

	// Globals
	
	// Name
	asset = llList2String(queue, 0);
	
	if (asset == "CB"){
		sendCallback(
			llList2String(queue, 1), 
			llList2String(queue, 2), 
			llList2Integer(queue, 3), 
			"", 
			llList2String(queue, 4)
		);
		queue = llDeleteSubList(queue, 0, 4);
		next(FALSE);
		return;
	}
	
	// Description has not been sent
	BFL = BFL&~BFL_READY;
	// Spawn it
	_portal_spawn_std(asset, llList2Vector(queue,1), llList2Rot(queue,2), -<0,0,8>, llList2Integer(queue, 4), TRUE, llList2Integer(queue,5));
	
	
	// Wait for it to finish
	BFL = BFL|BFL_QUEUE;
	
	// let's wait for the object
	multiTimer(["FORCE_NEXT", 1, 30, FALSE]);

}

// An item has been initialized, let's continue
done(){
	queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
	BFL = BFL&~BFL_QUEUE;
	next(FALSE);
	num_spawned++;
}

timerEvent(string id, string data){
	// Just move to the next
	if(id == "A"){
		done();
	}
	// B is sent once all objects have been spawned
	else if(id == "B"){
		#ifdef IS_HUD
		Level$loaded(ROOT_LEVEL, TRUE);
		#else
		Level$loaded(LINK_ROOT, FALSE);
		#endif
		num_spawned = 0;
	}
	// If SL didn't rez in a timely fashion, retry
	else if(id == "FORCE_NEXT"){
		qd("Error. SL dropped spawn success on "+mkarr(llList2List(queue, 0, QUEUESTRIDE-1))+". The level may work but you probably want to restart.");
		done();
	}
	
}

onEvt(string script, integer evt, list data){
	if(script == "#ROOT" && evt == RootEvt$level){
		ROOT_LEVEL = llList2String(data, 0);
	}
}

default
{
	state_entry(){
		raiseEvent(evt$SCRIPT_INIT, "");
		llListen(playerChan(llGetKey()), "", "", "");
	}
	
	// The script listens to it's own object key chan
	// SP is received when a portal is ready to receive a description
	// DN is received when a portal has received the description
	listen(integer chan, string name, key id, string message){
		if(llGetOwnerKey(id) != llGetOwner())return;
		// An object wants to fetch data
		if(message == "SP")Portal$iniData(id, llList2String(queue, 3), llList2String(queue, 6), llList2String(queue,7));  
		else if(message == "DN"){
			done();
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
			if(id == "")id = llGetLinkKey(LINK_THIS);
		
            string object = method_arg(0);
            if(llGetInventoryType(object) != INVENTORY_OBJECT){qd("Missing asset: "+object);return;}
            vector pos = (vector)method_arg(1);
            rotation rot = (rotation)method_arg(2);
			string desc = method_arg(3);		// DO something with this
			integer debug = (integer)method_arg(4);		
			integer temp = (integer)method_arg(5);
			string spawnround = method_arg(6);
			queue+= [object, pos, rot, desc, debug, temp, spawnround, id];
			next(FALSE);
        }
		else if(METHOD == SpawnerMethod$spawnThese){
			key requester = id;
			if(requester == "")requester = llGetLinkKey(LINK_THIS);
			
			list data = PARAMS;
			integer i;
			for(i=0; i<llGetListLength(data); i++){
				string s = llList2String(data, i);
				if(llJsonValueType(s, []) == JSON_ARRAY){
					list dta = llJson2List(s);
					string asset = llList2String(dta,0);
					if(asset == "CB"){
						queue += [
							"CB",
							id,
							SENDER_SCRIPT,
							METHOD,
							llList2String(dta, 1)
						];
					}
					else if(llGetInventoryType(asset) == INVENTORY_OBJECT){
						queue += [
							asset,								// Obj name
							(vector)llList2String(dta, 1),		// Position
							(rotation)llList2String(dta, 2),	// Rotation
							llList2String(dta, 3),				// Description
							llList2Integer(dta, 4),				// Debug
							llList2Integer(dta, 5),				// Temp
							llList2String(dta, 6),				// spawnround
							requester							// sender
						];
					}
					else qd("Inventory missing: "+llList2String(dta, 0));
				}
			}
			
			next(FALSE);
		}
		else if(METHOD == SpawnerMethod$debug){
			qd("Dumping queue");
			integer i;
			for(i=0; i<llGetListLength(queue); i+= QUEUESTRIDE){
				qd(mkarr(llList2List(queue, i, i+QUEUESTRIDE-1)));
			}
		}
		
		else if(METHOD == SpawnerMethod$getAsset){
			string asset = method_arg(0);
			if(llGetInventoryType(asset) == INVENTORY_NONE)return qd("Unable to give asset '"+asset+"', not found in inventory!");
			llGiveInventory(id, asset);
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

