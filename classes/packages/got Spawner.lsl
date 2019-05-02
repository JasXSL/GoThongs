// Custom definitions
// #define onEvtCustom( script, evt, data)

#define USE_EVENTS
#include "got/_core.lsl"

// Defines how many objects can await description at a time
#ifndef CONCURRENCY
#define CONCURRENCY 5
#endif

key ROOT_LEVEL;		// ID of level (used to send queue finish callbacks)

string CURRENT_ASSET;
 
// Inputs:
// 1. Items to spawn are added into the queue
list queue;			// [(str)objectName, (vec)objectRezPos, (rot)objectRezRot, (str)objectDesc, (bool)debug, (bool)temp_on_rez, (str)spawnround, (key)sender]
// If objectName is "_CB_", a callback is sent, and these are the vars used instead of above:
// ["_CB_", (str)customCallback]
#define QUEUESTRIDE 8

// 2. Before an object is rezzed, it is added to a rez queue
list queue_rez;		// [(str)desc, (str)spawnround, (key)sender]

// 3. Upon rezzing, the object gets added to a description que. This can hold up to CONCURRENCY assets
// Number of objects rezzed and currently awaiting descriptions.
#define processing (count(queue_desc)/QUEUEDESCSTRIDE)	
list queue_desc;	// [(key)idOfObject, (str)desc, (str)spawnround, (key)sender]
#define QUEUEDESCSTRIDE 4

// Timestamp when the last spawn took place
float SPAWN_START;

next() {
	// Clear the completion timer
	multiTimer(["B"]);
	
	if(
		// No items left to spawn
		queue == [] || 
		// An item is in the process of being spawned
		queue_rez != [] || 
		// To many description load requests. This should prevent the event queue from being full
		processing >= CONCURRENCY
	){
		// Queue done, Give it 5 sec before telling the level the load queue is finished. Used in case a mod adds additional spawns.
		if(queue == []){
			float timeout = 10;
			// If we have been spawning for more than 10 sec we are allowed to end this earlier
			if(SPAWN_START+10 < llGetTime())
				timeout = 2;
			multiTimer(["B", "", timeout, FALSE]);
			multiTimer(["FORCE_NEXT"]);
		}
		return;
	}
	
	if( SPAWN_START == 0 )
		SPAWN_START = llGetTime();
	
	// Object Name
	string asset = llList2String(queue, 0);
	
	// If object name is _CB_, send a callback
	if(asset == "_CB_"){
	
		// Waits for queue to finish before loading more. This works because done() triggers next()
		if(processing > 1){	// 1 is because the "_CB_" call counts as processing
			return;
		}
	
		
		sendCallback(
			llList2String(queue, 1), 
			llList2String(queue, 2), 
			llList2Integer(queue, 3), 
			"", 
			llList2String(queue, 4)
		);
		queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
		next();
		return;
		
	}
	
	// Asset not foudn in inventory, skip it
	if(llGetInventoryType(asset) != INVENTORY_OBJECT){
	
		qd("Error. Asset not found: "+mkarr(llList2List(queue, 0, QUEUESTRIDE-1))+". The level may work but you probably want to restart.");
		queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
		next();
		return;
		
	}
	
	// Set/reset clean up timer
	multiTimer(["FORCE_NEXT", 1, 30, FALSE]);
	
	CURRENT_ASSET = asset;
	// Spawn it
	_portal_spawn_std(asset, llList2Vector(queue, 1), llList2Rot(queue, 2), -<0,0,8>, llList2Integer(queue, 4), TRUE, llList2Integer(queue, 5));
	
	// Store the data in a separate array which is also used to check if we're currently rezzing
	queue_rez = [
		llList2String(queue, 3), // Desc
		llList2String(queue, 6), // Spawnround
		llList2String(queue, 7)  // Sender
	];
	
	// Remove from the main queue
	queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
	
}

// An item has received description, continue rezzing
done(key id){

	// Find the ID in the description queue
	integer pos = llListFindList(queue_desc, [id]);
	if( ~pos ){
	
		// Remove it from desc queue
		queue_desc = llDeleteSubList(queue_desc, pos, pos+QUEUEDESCSTRIDE-1);
		// Spawn another asset if possible
		next();
		
	}
	else
		qd("done() was run on an unknown UUID: "+(str)id+"\nqueue_desc was: "+mkarr(queue_desc));
	
}

timerEvent(string id, string data){

	// B is sent once all objects have been spawned
	if( id == "B" ){
	
		SPAWN_START = 0;
		// If this spawner is inside the HUD, send to ROOT_LEVEL
		#ifdef IS_HUD
		Level$loaded(ROOT_LEVEL, TRUE);
		#else
		// Otherwise it's in the level itself, so it can send to self
		Level$loaded(LINK_ROOT, FALSE);
		#endif
		
	}
	// Something has gotten stuck
	else if( id == "FORCE_NEXT" ){
	
		qd("Error! An item didn't spawn in a timely fashion. This is usually caused by high lag in the region. Debug:");
		qd("Main queue: "+mkarr(queue));
		qd("Flushing assets awaiting desc: "+mkarr(queue_desc));
		qd("Asset being spawned: "+mkarr(queue_rez));
		// Clear post-rez processing queue, anything in it at this point has gotten stuck
		queue_desc = [];
		// Try next
		next();
		
	}
	
}

onEvt(string script, integer evt, list data){

	#ifdef onEvtCustom
		onEvtCustom( script, evt, data);
	#endif
	// Gets the key of the level.
	if(script == "#ROOT" && evt == RootEvt$level){
		ROOT_LEVEL = llList2String(data, 0);
	}
}

default
{
	state_entry(){
		raiseEvent(evt$SCRIPT_INIT, "");
		// Listens to the prim playerChan, NOT owner
		llListen(playerChan(llGetKey()), "", "", "");
	}
	
	// An item was spawned
	object_rez(key id){
		// Memory leak here when not spawning with standard
		if(llKey2Name(id) != CURRENT_ASSET)
			return;
		
		// move it from queue_rez to queue_desc
		queue_desc += [id] + queue_rez;
		queue_rez = [];
		next(); // Spawn the next if possible
	}
	
	// The script listens to it's own object key chan
	// SP is received when a portal is ready to receive a description
	// DN is received when a portal has received the description
	listen(integer chan, string name, key id, string message){
		idOwnerCheck
		
		if( message == "SP" ){
		
			integer pos = llListFindList(queue_desc, [id]);
			
			// Send the ini data
			if(~pos){
				Portal$iniData(id, llList2String(queue_desc, pos+1), llList2String(queue_desc, pos+2), llList2String(queue_desc, pos+3));
			}
			// HAX: Send something to shut up the object
			else{
				qd("Error. Got unexpected description request from object '"+llKey2Name(id)+"' "+(string)id+".");
				Portal$iniData(id, "", "", llGetKey());
			}
			
		}
		else if(message == "DN"){
			done(id);
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
		// Used primarily for mods to overwrite installed content when installed multiple times
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
		
        if( METHOD == SpawnerMethod$spawnThese || METHOD == SpawnerMethod$spawn ){
			
			key requester = id;
			if( requester == "" )
				requester = llGetLinkKey(LINK_THIS);
			
			list data = PARAMS;
			if( METHOD == SpawnerMethod$spawn )
				data = [mkarr(PARAMS)];
			
			
			integer i;
			for( i=0; i<llGetListLength(data); i++ ){
			
				string s = llList2String(data, i);
				if( llJsonValueType(s, []) == JSON_ARRAY ){
					
					list dta = llJson2List(s);
					string asset = llList2String(dta,0);
					if( asset == "_CB_" )
						queue += [
							asset,
							id,
							SENDER_SCRIPT,
							METHOD,
							llList2String(dta, 1),
							0,
							0,
							0
						];
					
					else if( llGetInventoryType(asset) == INVENTORY_OBJECT )
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
					
					else 
						qd("Inventory missing: '"+llList2String(dta, 0)+"'\n"+mkarr(PARAMS));
				}
			}
			
			next();
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
			if(llGetInventoryType(asset) == INVENTORY_NONE) {
				qd("Unable to give asset '"+asset+"', not found in inventory!");
				return;
			}
			llGiveInventory(id, asset);
		}
		
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

