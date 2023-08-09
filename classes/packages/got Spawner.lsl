// Custom definitions
// #define onEvtCustom( script, evt, data)
#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

// If you need 
#ifndef TABLE
	#define TABLE gotTable$spawner
#endif

key ROOT_LEVEL;		// ID of level (used to send queue finish callbacks)


// gotTable$spawner is a sequential table containing JSON objects
/*
{
	i : (key)id				- Assigned when "SP" is received
	n : (str)obj_name		- Name of object we are spawning or "_CB_" if a callback
	p : (vec)pos 			- Object spawn pos
	r : (rot)rotation 		- Rotation of object
	d : (str)desc			- Object spawn desc / cb_data for _CB_
	t : (bool)debug_mode	- Spawn in debug/dummy mode
	g : (str)spawnround		- Spawn group
	s : (key)sender			- Sender that requested the spawn
	[Unused] f : (bool)temp_on_rez	- Should be temp on rez 
	_ : (float)time 		- llGetTime of when the spawn was requested
	c : (str)callbackScript - Script to send the callback to in _CB_ type
	m : (int)callbackMethod	- Method to callback to in _CB_ type
	! : (int)state 			- use ST_*
}
*/

#define ST_QUEUED 0			// Not rezzed yet
#define ST_REZZED 1			// We have called llRez on this
#define ST_DESC_SENT 2		// Awaiting ack from portal

#define CONCURRENCY 5
#define TIMEOUT 180			// 3 min

next(){

	// Loop through table
	int pre; int found; int rezzed; list rezzable; // Gets the oldest n CONCURRENCY indexes that are on ST_QUEUED
	db4$each(TABLE, i, data, 
		
		str name = j(data, "n");
		str desc = j(data, "d");
		
		if( name == "_CB_" ){
			
			// This queue is done. Send callback.
			if( pre == 0 ){
				
				sendCallback(
					j(data, "s"), 
					j(data, "c"), 
					(int)j(data, "m"), 
					"", 
					desc
				);
				db4$delete(TABLE, i);
				debugRare("[Queue] "+(str)i+". Sending queue callback for "+desc);
				
			}
				
			pre = 0;
			
		}
		else{
			++found; 	// This is a spawn in progress. Also needed on prune failed so callbacks do not get deleted.
			++pre;		// There is an unfinished spawn before the next callback
			
			int st = (int)j(data, "!");
			// Candidate for rezzing
			if( st == ST_QUEUED && count(rezzable) < CONCURRENCY )
				rezzable += i;
			// Items awaiting finalizing
			else if( st != ST_QUEUED )
				++rezzed;
				
			float spawned = (float)j(data, "_");
			if( 
				(st != ST_QUEUED && llGetTime()-spawned > TIMEOUT) || 	// Timeout hit after attempting to rez it
				(st == ST_DESC_SENT && llKey2Name(j(data, "i")) == "") 	// Object has been destroyed after sending desc
			){
				qd(
					"[ERROR] Failed to rez "+j(data, "n")+"\n"+
					"Timeout: "+(str)(llGetTime()-spawned > TIMEOUT) + " "+
					"Obj in region: "+llKey2Name(j(data, "i")) + "\n" +
					"Full data: "+data
				);
				db4$delete(TABLE, i);
			}
			
		}
		
	)
	
	// Queue is empty so we can reset LSD
	if( !found ){
	
		debugRare("Full queue is complete!");
		multiTimer(["PRUNE"]);
		db4$drop(TABLE);
		return;
		
	}
	
	debugUncommon("[Queue] Able to spawn "+(str)(CONCURRENCY-rezzed)+" items");
	// Rez items
	integer i;
	for(; i < count(rezzable) && i < CONCURRENCY-rezzed; ++i ){
	
		integer idx = l2i(rezzable, i);
		string data = db4$get(TABLE, idx);
		data = llJsonSetValue(data, (list)"!", (str)ST_REZZED);
		data = llJsonSetValue(data, (list)"_", (str)llGetTime()); // Give it more time
		db4$replace(TABLE, idx, data);
		
		debugUncommon("[Queue] Spawning "+j(data, "n"));
		// int id, string name, rotation rot, vector spawnOffset, integer debug
		_portal_spawn_new(
			idx,							// Index of spawn
			j(data, "n"),				// Object name 
			(rotation)j(data, "r"),		// Rotation 
			-<0,0,8>,					// Spawn below by default 
			(int)j(data, "t")			// Debug mode 
		);
		
	}
	
	// Unstucks if things do not rez
	multiTimer(["PRUNE", 0, 5, TRUE]);
	
}


timerEvent(string id, string data){
	
	if( id == "PRUNE" )
		next();
	
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

sendDesc( key id, integer idx ){

	string data = db4$get(TABLE, idx);
	if( data == "" ){
		
		debugRare("[Desc] Request sent to missing spawn idx: "+(str)idx);
		return;
		
	}
	data = llJsonSetValue(data, (list)"!", (str)ST_DESC_SENT); 	// Assign state
	data = llJsonSetValue(data, (list)"i", (str)id);			// Assign a UUID
	data = llJsonSetValue(data, (list)"_", (str)llGetTime());	// Give it more time
	db4$replace(TABLE, idx, data);
	
	// Portal$iniData(targ, data, spawnround, requester, pos)
	Portal$iniData(
		id, // target
		j(data, "d"), 	// Custom data 
		j(data, "g"), 	// Spawnround
		j(data, "s"), 	// Sender key
		j(data, "p")	// Spawn pos
	);
	debugCommon("[Desc] Sending to "+llKey2Name(id));

}

int pChan;

default{

	state_entry(){
	
		raiseEvent(evt$SCRIPT_INIT, "");
		// Listens to the prim playerChan, NOT owner
		pChan = playerChan(llGetKey());
		llListen(pChan, "", "", "");
		db4$drop(TABLE);
		#ifdef onStateEntry
		onStateEntry();
		#endif
		
	}
	
	// The script listens to its own object key chan
	// SP is received when a portal is ready to receive a description
	// DN is received when a portal has received the description
	listen( integer chan, string name, key id, string message ){
		idOwnerCheck
		
		#ifdef onListen
		onListen( chan, id, message );
		#endif
		/*
		// Sent from an object letting you know it was spawned, but not remoteloaded yet
		if( message == "PN" ){
			
		}
		*/
		
		if( chan != pChan )
			return;
		
		string start = llGetSubString(message, 0, 1);
		if( start != "SP" && start != "DN" )
			return;
		
		integer idx = (int)llGetSubString(message, 2, -1);
		if( llStringLength(message) == 2 ){
			
			debugRare("[ERROR] Received a legacy "+message+" from "+name);
			return;
			
		}
		
		// Send from a portal requesting a description
		if( start == "SP" ){
			
			sendDesc(id, idx);			
			next();
			
		}
		
		// Sent from a portal saying it's done
		if( start == "DN" ){
			
			// all done!
			debugCommon("[Desc] Finalized ID "+(str)(idx)+" :: "+name);
			db4$delete(TABLE, idx);
			next();
			
		}
		
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
	
    if(method$byOwner){
	
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
					//"f", l2i(dta, 5),					// Temp on rez
					"g", l2s(dta, 6),					// spawn group
					"s", requester							// sender
				]);
			
			else
				qd("Inventory missing: "+s);
			
			if( out ){
				
				out = llJsonSetValue(out, ["_"], (str)llGetTime());
				db4$insert(TABLE, out);
				
			}
			
		}
		
		next();
		
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

