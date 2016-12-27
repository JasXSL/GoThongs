#define USE_EVENTS
#include "got/_core.lsl"

#ifndef CONCURRENCY
#define CONCURRENCY 5
#endif

integer BFL;
#define BFL_QUEUE 1
#define BFL_REZING 2

key ROOT_LEVEL;		// ID of level

list queue;			// [(str)name, (vec)pos, (rot)rot, (str)desc, (bool)debug, (bool)temp, (str)spawnround, (key)sender]
#define QUEUESTRIDE 8
list queue_rez;		// [(str)name, (str)desc, (str)spawnround, (key)sender]
integer processing;	// Number of objects currently rezed and in desc processing
list queue_desc;	// [(key)id, (str)name, (str)desc, (str)spawnround, (key)sender]
#define QUEUEDESCSTRIDE 5


next() {
	// Clear the completion timer
	multiTimer(["B"]);
	
	if(queue == [] || queue_rez != [] || BFL&BFL_REZING || (processing >= CONCURRENCY)){
		if(queue == []){
			multiTimer(["B", "", 2, FALSE]);
		}
		return;
	}
	
	// Object Name
	string asset = llList2String(queue, 0);
	
	if (asset == "CB"){
		if(processing > 0){
			return;
		}
		sendCallback(
			llList2String(queue, 1), 
			llList2String(queue, 2), 
			llList2Integer(queue, 3), 
			"", 
			llList2String(queue, 4)
		);
		queue = llDeleteSubList(queue, 0, 4);
		next();
		return;
	}
	
	if(llGetInventoryType(asset) != INVENTORY_OBJECT){
		qd("Error. Asset not found: "+mkarr(llList2List(queue, 0, QUEUESTRIDE-1))+". The level may work but you probably want to restart.");
		queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
		next();
		return;
	}
	
	BFL = BFL|BFL_REZING;
	
	// Set/reset clean up timer
	multiTimer(["FORCE_NEXT", 1, 30, FALSE]);
	
	// Spawn it
	_portal_spawn_std(asset, llList2Vector(queue, 1), llList2Rot(queue, 2), -<0,0,8>, llList2Integer(queue, 4), TRUE, llList2Integer(queue, 5));
	queue_rez = [asset, llList2String(queue, 3), llList2String(queue, 6), llList2String(queue, 7)];
	queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
}

// An item has been initialized, let's continue
done(key id){
	integer pos = llListFindList(queue_desc, [id]);
	if(~pos){
		queue_desc = llDeleteSubList(queue_desc, pos, pos+QUEUEDESCSTRIDE-1);
		if(queue_desc == []) multiTimer(["FORCE_NEXT"]);
		processing--;
		next();
	}
}

timerEvent(string id, string data){
	// B is sent once all objects have been spawned
	if(id == "B"){
		#ifdef IS_HUD
		Level$loaded(ROOT_LEVEL, TRUE);
		#else
		Level$loaded(LINK_ROOT, FALSE);
		#endif
	}
	// Something has gotten stuck
	else if(id == "FORCE_NEXT"){
		qd("Error. SL dropped spawn success on "+mkarr(queue_desc)+". The level may work but you probably want to restart.");
		// Clear post-rez processing queue, anything in it at this point has gotten stuck
		queue_desc = [];
		processing = 0;
		// Try next
		next();
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
	
	object_rez(key id){
		queue_desc += [id] + queue_rez;
		queue_rez = [];
		processing++;
		BFL = BFL&~BFL_REZING;
		if(processing < CONCURRENCY){
			next();
		}
	}
	
	// The script listens to it's own object key chan
	// SP is received when a portal is ready to receive a description
	// DN is received when a portal has received the description
	listen(integer chan, string name, key id, string message){
		if(llGetOwnerKey(id) != llGetOwner())return;
		if(message == "SP"){
			integer pos = llListFindList(queue_desc, [id]);
			if(~pos){
				Portal$iniData(id, llList2String(queue_desc, pos+2), llList2String(queue_desc, pos+3), llList2String(queue_desc, pos+4));
			}
			else {
				qd("Error. Got unexpected description request from object '"+llKey2Name(id)+"' "+(string)id+". The level may work but you probably want to restart.");
				// HAX: Send something to shut up the object
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
        if(METHOD == SpawnerMethod$spawnThese || METHOD == SpawnerMethod$spawn){
			key requester = id;
			if(requester == "")requester = llGetLinkKey(LINK_THIS);
			
			list data = PARAMS;
			if(METHOD == SpawnerMethod$spawn){
				data = [mkarr(PARAMS)];
			}
			
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

