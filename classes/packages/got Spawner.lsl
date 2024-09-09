// Custom definitions
// #define onEvtCustom( script, evt, data)
#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

// If you need 
#ifndef TABLE
	#define TABLE gotTable$spawner
#endif

// gotTable$spawner is a sequential table containing JSON objects
/*
{
	n : (str)obj_name		- Name of object we are spawning or "_CB_" if a callback
	p : (vec)pos 			- Object spawn pos
	r : (rot)rotation 		- Rotation of object
	d : (str)desc			- Object spawn desc / cb_data for _CB_
	t : (bool)debug_mode	- Spawn in debug/dummy mode
	g : (str)spawnround		- Spawn group
	s : (key)sender			- Sender that requested the spawn
	q : (arr)rez_params		- List of params that is passed to llRezObjectWithParams. You can use everything except REZ_POS, REZ_ROT, REZ_PARAM_STRING 
	c : (str)callbackScript - Script to send the callback to in _CB_ type
	m : (int)callbackMethod	- Method to callback to in _CB_ type
}
*/

// Used only when REMOTELOADER_METATABLE is undefined (so from non-HUD)
// Try to get remoteloader prim from owner. We use that prim to stagger rezzing.
/*
key getRemoteloader(){

	// Fetch HUDs from level
	key hud = l2k(LevelDb$getHuds(), 0);
	integer num = llList2Integer(llGetObjectDetails(spawner, (list)OBJECT_PRIM_COUNT), 0);
	integer i = 1;
	for(; i <= num; ++i ){
		
		key k = llGetObjectLinkKey(spawner, i);
		string name = llKey2Name(k);
		if( name == "Remote" )
			return k;
		
	}
	return "";
	
}
*/


#define ST_QUEUED 0			// Not rezzed yet
#define ST_REZZED 1			// We have called llRez on this
#define ST_DESC_SENT 2		// Awaiting ack from portal

#define CONCURRENCY 2
#define TIMEOUT 180			// 3 min

key wAck; // waiting for ack
float ackStart;
string spawnData;
integer fails;


spawn(){
	
	str name = j(spawnData, "n");
	str desc = j(spawnData, "d");
	ackStart = llGetTime();
	wAck = "";
	
	if( name == "_CB_" ){
		
		// This queue is done. Send callback.
		sendCallback(
			j(spawnData, "s"), 
			j(spawnData, "c"), 
			(int)j(spawnData, "m"), 
			"", 
			desc
		);
		
		debugRare("[Queue] Sending queue callback for "+desc);
		
	}
	else{
		
		debugUncommon("[Queue] Spawning "+j(spawnData, "n"));
		wAck = _portal_spawn_v3(
			name,				// Object name 
			(vector)j(spawnData, "p"),		// Position
			(rotation)j(spawnData, "r"),		// Rotation 
			-<0,0,8>,					// Spawn below by default 
			(((int)j(spawnData, "t")>0)|PortalRezFlag$ack),			// Debug mode / need ack
			j(spawnData, "g"),				// spawn group
			j(spawnData, "s"),				// sender
			desc,						// desc
			llJson2List(j(spawnData, "q")) 	// Custom rezparams
		);
		
	}
	
	
}

next(){
	
	
	// This only works for HUDs. And makes sure that we stop if remoteloader gets full.
	#ifdef REMOTELOADER_METATABLE
	int rlMeta = Remoteloader$getMetaStatus(REMOTELOADER_METATABLE);
	if( rlMeta != remoteloaderStatus$NO_QUEUE ){
		
		debugUncommon("Waiting for remoteloader");
		multiTimer(["CONT",0,.25,FALSE]);
		return;
		
	}
	#endif
	
	// We should wait for an ack from the rezzed objects before continuing.
	if( wAck ){
	
		if( llGetTime()-ackStart > 30 ){
			qd(llKey2Name(wAck) + " failed to spawn in a timely fashion, trying again. SpawnData: "+spawnData);
			//llDerezObject(wAck); // Todo: Enable when implemented. Remove old object just in case
			if( ++fails == 4 ){
				qd("Too many failed attempt, dropping this spawn");
				wAck = "";
			}
			else
				spawn();
		}
		multiTimer(["CONT",0,.25,FALSE]);
		return;
		
	}

	int found;
	// Loop through table
	db4$each(TABLE, i, data, 
		
		++found;
		db4$delete(TABLE, i);
		spawnData = data;
		spawn();
		if( wAck )
			jump _found; // we tried to spawn something

	)
	
	@_found;
	
	// Queue is empty so we can reset LSD
	if( !found ){
	
		debugRare("Full queue is complete!");
		dropQueue();
		return;
		
	}
	
	
	multiTimer(["CONT",0,.1,FALSE]); // Prevents blocking and allows things to catch up
	
}

dropQueue(){
	
	spawnData = "";
	multiTimer(["CONT"]);
	db4$drop(TABLE);
	
}

timerEvent(string id, string data){
	
	if( id == "CONT" )
		next();
	
}

onEvt(string script, integer evt, list data){

	#ifdef onEvtCustom
		onEvtCustom( script, evt, data);
	#endif
	
	if( script == "got RootAux" && evt == RootAuxEvt$cleanup && spawnData != "" ){
		
		llOwnerSay("Note: Cleanup received. Ending active spawn cycle.");
		dropQueue();
		
	}
		
}

default{

	state_entry(){
	
		raiseEvent(evt$SCRIPT_INIT, "");
		// Listens to the prim playerChan, NOT owner
		db4$drop(TABLE);
		#ifdef onStateEntry
		onStateEntry();
		#endif
		
		llListen(SpawnerConst$ACK_CHAN, "", "", "ACK");
		
	}
	
	// Handles ack from portal
	listen( integer ch, string name, key id, string message ){
	
		if( id == wAck ){
			
			debugUncommon("[Queue] Got ack from "+name);
			wAck = spawnData = "";
			fails = 0;
			next(); // continue immediately
			
		}
		else{
			debugUncommon("[Queue] Got ack from unknown prim "+name);
		}
		
		llRegionSayTo(id, ch+1, message);
		
		
	}
	
	
	
		
	timer(){multiTimer([]);}
	
	
    #include "xobj_core/_LM.lsl"
    /*
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters   
        CB - The callback you specified when you sent a task
    */ 
    if(method$isCallback){
        return;
    }
    
	if( method$internal ){
	
		// Used primarily for mods to overwrite installed content when installed multiple times
		if( METHOD == SpawnerMethod$remInventory ){
			
			list assets = llJson2List(method_arg(0));
			list_shift_each(assets, val,
			
				if(llGetInventoryType(val) == INVENTORY_OBJECT)
					llRemoveInventory(val);
				
			)
			
		}
		
	}
	
    if( method$byOwner ){
	
		if( METHOD == 0 )
			llResetScript();
		
		
        else if( METHOD == SpawnerMethod$debug ){
			
			qd("== Spawn queue ==");
			db4$each(TABLE, i, data, 
				llOwnerSay((str)i+". "+data);
			)
			
		}
		
		else if( METHOD == SpawnerMethod$getAsset ){
		
			string asset = method_arg(0);
			if( llGetInventoryType(asset) == INVENTORY_NONE ){
				qd("Unable to give asset '"+asset+"', not found in inventory!");
				return;
			}
			llGiveInventory(id, asset);
			
		}
		
		#ifdef onOwnerMethod
			onOwnerMethod(METHOD, id, PARAMS);
		#endif
		
    }
	
	if( METHOD == SpawnerMethod$spawnThese || METHOD == SpawnerMethod$spawn ){
		
		key requester = id;
		if( requester == "" )
			requester = llGetLinkKey(LINK_THIS);
		
		list data = PARAMS;
		if( METHOD == SpawnerMethod$spawn )
			data = (list)mkarr(PARAMS);
		
		
		integer i;
		for( ; i < count(data); ++i ){
		
			list dta = llJson2List(l2s(data, i));
			string asset = llList2String(dta,0);
			string out;
			if( asset == "_CB_" )
				out = llList2Json(JSON_OBJECT, [
					"n", asset,		// Name
					"s", id,		// Sender
					"c", SENDER_SCRIPT,	// Callback script
					"m", METHOD,		// Callback method
					"d", l2s(dta, 1)
				]);
			
			// Have asset in inventory
			else if( llGetInventoryType(asset) == INVENTORY_OBJECT )
				out = llList2Json(JSON_OBJECT, [
					"n", asset,							// Obj name
					"p", l2s(dta, 1),					// Position
					"r", l2s(dta, 2),					// Rotation
					"d", l2s(dta, 3),					// Description
					"t", l2i(dta, 4),					// Debug
					"g", l2s(dta, 6),					// spawn group
					"q", l2s(dta, 7),					// Array to pass to llRezObjectWithParams
					"s", requester						// sender
				]);
			
			else
				qd("Inventory missing: "+s);
			
			if( out ){
				
				db4$insert(TABLE, out);
				
			}
			
		}
		
		next();
		
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

