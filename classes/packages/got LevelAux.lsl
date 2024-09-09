#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

list PLAYERS;
string group;
key fetchWindlights;

// (str)name, (vec)pos
list MONSTERS_KILLED;
list toSet;	// Windlights to set


#define onEvt(script, evt, data) \
	 \
	if(script == "got Level" && evt == LevelEvt$idDied){ \
		 \
		key id = l2s(data, 0); \
		parseMonsterFlags(id, mFlags) \
		if( ~mFlags&Monster$RF_MINOR ){ \
			vector pos = prPos(id); \
			list arr = [llKey2Name(id), "<"+roundTo(pos.x,2)+","+roundTo(pos.y,2)+","+roundTo(pos.z,2)+">"]; \
			MONSTERS_KILLED += [mkarr(arr)]; \
		}\
	} \
	else if(script == "got Level" && evt == LevelEvt$players) \
		PLAYERS = data; \


ptEvt( str id ){
	if( id == "KILLQUE" && MONSTERS_KILLED != [] ){
		runOnPlayers(targ,
			Bridge$monstersKilled(targ, MONSTERS_KILLED);
		)
		MONSTERS_KILLED = [];
	}	
}

list trimVecRot( list vec_or_rot, integer places, integer returnString ){
    integer type = llGetListEntryType(vec_or_rot, 0);
    if(type != TYPE_ROTATION && type != TYPE_VECTOR)
		return vec_or_rot;
    list expl = llCSV2List(llGetSubString(llList2String(vec_or_rot, 0), 1, -2));
    integer i;
    for(i=0; i<llGetListLength(expl); i++){
        string f = (string)
        (
            (float)(llRound(llList2Float(expl, i)*llPow(10, places)))
            /llPow(10, places)
        );
        while(llGetSubString(f, -1, -1) == "0")f = llDeleteSubString(f, -1, -1);
        if(llGetSubString(f, -1, -1) == ".")f = llDeleteSubString(f, -1, -1);
        if(llStringLength(f)>1 && llGetSubString(f, 0, 0) == "0")f = llDeleteSubString(f, 0, 0);
        expl = llListReplaceList(expl, [f], i, i);
    }
    string out = "<"+llDumpList2String(expl, ",")+">";
    if(returnString)return [out];
    if(type == TYPE_ROTATION)return [(rotation)out];
    return [(vector)out];
}

// Returns the spawn row (see header) or an empty list if not found
#define getAssetByIndex( index ) LevelAux$getSpawnData(index)

default{

    state_entry(){ 
	
		raiseEvent(evt$SCRIPT_INIT, ""); 
		ptSet("KILLQUE", 2, TRUE); 
		
	}
    
    timer(){ ptRefresh(); }
    
    #include "xobj_core/_LM.lsl"
    if( !method$byOwner )
		return;
	
	str listButtonA = "[secondlife:///app/chat/1/";
	str listButtonB = " (List)]";
	
    if( method$isCallback ){
	
		// Callback from portal telling you to save it
        if( CB == "SV" ){
		
            list data = llGetObjectDetails(id, [OBJECT_NAME, OBJECT_DESC, OBJECT_POS, OBJECT_ROT, OBJECT_ATTACHED_POINT]);
			// Ignore attachments
			if( l2i(data, 4) )
				return;
            
            string name = l2s(data, 0);
			integer localInv = llGetInventoryType(name) == INVENTORY_OBJECT;
            string pos = (string)trimVecRot([llList2Vector(data, 2)-llGetRootPosition()], 2, TRUE);
            string rot = "";
            if( (rotation)llList2String(data,3) != ZERO_ROTATION )
				rot = (string)trimVecRot([llList2Rot(data, 3)], 3, TRUE);
			
			// Build the table row
            list out = (list)localInv + name + pos + rot;
            string desc = llStringTrim(llList2String(data, 1), STRING_TRIM);
			// To save it must start with $ and not be $M$ which marks an object as a monster
            if( llGetSubString(desc, 0,0) != "$" || llGetSubString(desc, 0, 2) == "$M$" )
				desc = "";
            else 
				desc = llGetSubString(desc, 1, -1); // remove $
				
            out += desc;
            out += group;
			
			
			// This is a start point
            if( llGetSubString(name, 0, 12) == "_STARTPOINT_P" ){
                
				str idx = gotTable$meta$spawn0;
				if(name == "_STARTPOINT_P2")
					idx = gotTable$meta$spawn1;
				
				db4$freplace(gotTable$meta, idx, l2s(out, 2));
				llOwnerSay("-> Saved start point at "+l2s(out, 2));
				
            }
			// Otherwise it is a spawn
            else{
			
				// Todo: Check if we have any empty slots
				string o = mkarr(out); integer iid;
				LevelAux$forSpawns( tot, idx ){
					
					if( LevelAux$getSpawnData(idx) == [] ){
						
						// Empty slot found
						
						db4$replace(gotTable$spawns, idx, o);
						iid = idx;
						tot = -1;
						
					}
				
				}
				
				// Did not find an empty one
				if( ~tot )
					iid = db4$insert(gotTable$spawns, o);
				
				string url = "remSpawn "+(str)iid;
				llOwnerSay("Inserted "+(str)iid+" >>> " + o + " [secondlife:///app/chat/1/"+llEscapeURL(url)+" (Remove)]");

            }
			
        }
		
		// Callback end
        return;
		
    }
    
    // Purge all level data
    if( METHOD == LevelAuxMethod$purge ){
        
		llOwnerSay("Wiping all data");
		// 2 characters, starting with the table
        list spawns = llLinksetDataFindKeys("^"+gotTable$spawns+".$", 0, -1);
		integer i;
		for(; i < count(spawns); ++i )
			llLinksetDataDelete(l2s(spawns, i));
		
    }
	
	// Callback the position (arg0) relative to root position
	else if( METHOD == LevelAuxMethod$getOffset ){
		
		vector offs = (vector)method_arg(0);
		CB_DATA = [offs-llGetRootPosition()];
		
	}
    
	
    // Save level data
    else if( METHOD == LevelAuxMethod$save ){
        
		group = method_arg(0);
		llOwnerSay("Adding...");
		Portal$save();
		
    }
    
    else if(METHOD == LevelAuxMethod$stats){
	
        llOwnerSay("Stats:");
		llOwnerSay("-- P0 start point: "+db4$fget(gotTable$meta, gotTable$meta$spawn0));
		llOwnerSay("-- P1 start point: "+db4$fget(gotTable$meta, gotTable$meta$spawn1));
		llOwnerSay("-- Free LSD: "+(str)llLinksetDataAvailable());
		
    }
    
	// Spawn a new asset from either inventory by name. Usually used when placing new monsters into a level.
	else if( METHOD == LevelAuxMethod$spawn ){
	
		string asset = method_arg(0);
        vector pos = (vector)method_arg(1);
        rotation rot = (rotation)method_arg(2);
        integer debug = (integer)method_arg(3);
		string description = method_arg(4);
		string spawnround = method_arg(5);
		
		
        if( llGetInventoryType(asset) == INVENTORY_OBJECT ){
            
			if( debug )
				llOwnerSay("Spawning local asset: "+asset);
			Spawner$spawnInt(asset, pos, rot, description, debug, FALSE, spawnround, []);
			
        }else{
            
			if( debug )
				llOwnerSay("Item '"+asset+"' not found in level. Loading from HUD.");
            Spawner$spawn(asset, pos, rot, description, debug, FALSE, spawnround, []);
			
        }
		
	}

    // Spawns an item from HUD assets or level inventory as if it was live by ID
    else if( METHOD == LevelAuxMethod$testSpawn ){
	
        integer index = (integer)method_arg(0);
        integer live = (integer)method_arg(1);
        
		list asset = getAssetByIndex(index);
		if(asset == []){
			
			llOwnerSay("Not found: "+(str)index);
			return;
			
		}
		
		if( !l2i(asset, 0) ){
		
			llOwnerSay("From HUD: "+llList2String(asset, 1));
			Spawner$spawn(
				llList2String(asset, 1), 
				(vector)llList2String(asset, 2)+llGetRootPosition(), 
				llList2String(asset, 3), 
				llList2String(asset, 4), 
				!live, 
				false, 
				"",
				[]
			);
			
		}
		else{
		
			llOwnerSay("From INV: "+llList2String(asset, 1));
			Spawner$spawnInt(
				llList2String(asset, 1), 
				(vector)llList2String(asset,2)+llGetRootPosition(), 
				(rotation)llList2String(asset, 3), 
				llList2String(asset, 4), 
				!live, 
				false, 
				"",
				[]
			);
			
		}
    }
    
	// list all spawns
    else if( METHOD == LevelAuxMethod$list ){
		
		integer type = l2i(PARAMS, 0);
		string search = llToLower(method_arg(1));
		if( llGetSubString(search, 0,1) == "\\\"")
			search = llGetSubString(search, 1, -1);
			
		if( search )
			qd("Searching "+search);
		//llOwnerSay("Listing "+method_arg(0)+" ["+SENDER_SCRIPT+"]");
		LevelAux$forSpawns( total, idx ){
			
			list data = LevelAux$getSpawnData(idx);
			if( data ){
			
				string s = mkarr(data);
				integer fail = l2i(data, 0) != type;				
				if( search != "" && !fail )
					fail = llSubStringIndex(llToLower(s), search) == -1;
					
				if( !fail )
					llOwnerSay(
						"[secondlife:///app/chat/1/"+llEscapeURL("remSpawn "+(str)idx)+" DEL] "+
						"[secondlife:///app/chat/1/"+llEscapeURL("testSpawn "+(str)idx)+" DUM] "+
						"[secondlife:///app/chat/1/"+llEscapeURL("testSpawn "+(str)idx+" 1")+" LVE] "+
						"["+(str)idx+"] "+
						s
					);
				
			}
		}
		
    }
	
	// Set a property of a spawn
	else if( METHOD == LevelAuxMethod$assetVar ){
	
		integer globalIndex = l2i(PARAMS, 0);
		integer field = l2i(PARAMS,1);
		list newVal = llList2List(PARAMS, 2, 2);
		
		
		list asset = getAssetByIndex(globalIndex);
		string pre = mkarr(asset);
		integer total = db4$getIndex(gotTable$spawns);
		if( globalIndex >= total ){
			llOwnerSay("Error: Index too high.");
			return;
		}
		str oldVal = l2s(asset, field);
		// -1 field replaces whole entry
		if( field == -1 ){
			newVal = llJson2List(l2s(newVal, 0));
			if( count(newVal) < 4 ){
				llOwnerSay("Too few args for full replace.");
				return;
			}
			oldVal = mkarr(asset);
			asset = newVal;
		}
		else
			asset = llListReplaceList(asset, (list)newVal, field, field);
		
		db4$replace(gotTable$spawns, globalIndex, mkarr(asset));
		string url = "setSpawnVal "+(str)globalIndex+" "+(str)field+" "+oldVal;
		str aType = "listSpawns";
		if( l2i(asset, 0) )
			aType = "listAssets";
        llOwnerSay(
			"Updated #"+(str)globalIndex+"."+
			"\nOLD: "+pre + 
			"\nNEW: "+mkarr(asset)+
			"\n[secondlife:///app/chat/1/"+llEscapeURL(url)+" (Undo)] | "+listButtonA+aType+listButtonB
		);
		
	}
    
    else if(METHOD == LevelAuxMethod$remove){
	
		integer globalIndex = l2i(PARAMS, 0);
		
		list asset = getAssetByIndex(globalIndex);
		if( asset == [] ){
			llOwnerSay("Error: Item not found.");
			return;
		}
		
		db4$delete(gotTable$spawns, globalIndex);
		str as = mkarr(asset);
		string url = "setSpawnVal "+(str)globalIndex+" -1 "+as;
		str aType = "listSpawns";
		if( l2i(asset, 0) )
			aType = "listAssets";
		llOwnerSay("Removed asset: "+as+" [secondlife:///app/chat/1/"+llEscapeURL(url)+" (Undo)] | "+listButtonA+aType+listButtonB);
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}
