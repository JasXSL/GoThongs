#define USE_EVENTS
#include "got/_core.lsl"

list PLAYERS;

string group = "";
integer assets_saved;
integer points_saved;
integer custom_saved;

#define HUD_TABLES Level$HUD_TABLES
#define CUSTOM_TABLES Level$CUSTOM_TABLES

// (str)name, (vec)pos
list MONSTERS_KILLED;


onEvt(string script, integer evt, list data){
	
	if(script == "got Level" && evt == LevelEvt$idDied){
		
		key id = l2s(data, 0);
		vector pos = prPos(id);
		list arr = [llKey2Name(id), "<"+roundTo(pos.x,2)+","+roundTo(pos.y,2)+","+roundTo(pos.z,2)+">"];
		MONSTERS_KILLED += [mkarr(arr)];
		
	}
	else if(script == "got Level" && evt == LevelEvt$players)
		PLAYERS = data;

}

timerEvent(string id, string data){
    if(id == "SAVE"){
        qd(xme(XLS(([
			XLS_EN, "Save: \n"+(string)assets_saved+" HUD assets\n"+(string)points_saved+" spawnpoints\n"+(string)custom_saved+" custom assets"
		]))));
    }
    else if(id == "S"){
        // Start save
        Portal$save();
        multiTimer(["SAVE", "", 10, FALSE]);
    }
	else if(id == "KILLQUE" && MONSTERS_KILLED != []){
		runOnPlayers(targ,
			Bridge$monstersKilled(targ, MONSTERS_KILLED);
		)
		MONSTERS_KILLED = [];
	}
	
}

list trimVecRot(list vec_or_rot, integer places, integer returnString){
    integer type = llGetListEntryType(vec_or_rot, 0);
    if(type != TYPE_ROTATION && type != TYPE_VECTOR)return vec_or_rot;
    
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

// Returns [(str)table, (int)internal_index, (str)data] or [] if not found
list getAssetByIndex(integer customAsset, integer globalIndex){
	if(globalIndex<0){
		qd(xme(XLS(([
			XLS_EN, "Negative indexes are no longer allowed"
		]))));
		return [];
	}
	// Tables
	list tables = HUD_TABLES;
	if(customAsset)
		tables = CUSTOM_TABLES;
		
	// Global index
	integer n;
	
	list out = [];
	// Interate over tables
	integer i;
	for(i=0; i<count(tables); ++i){
		list parse = llJson2List(db3$get(l2s(tables, i), []));
		if(globalIndex>=n+count(parse)){
			n+= count(parse);
		}
		else{
			return [
				l2s(tables, i),
				globalIndex-n,
				llList2String(parse, globalIndex-n)
			];
		}
	}
	return [];
}


default
{
    state_entry()
    {
		raiseEvent(evt$SCRIPT_INIT, "");
		multiTimer(["KILLQUE", "", 2, TRUE]);
    }
    
    timer(){
        multiTimer([]);
    }
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    
    if(!method$byOwner)return;
    if(method$isCallback){
        if(CB == "SV"){
            multiTimer(["SAVE", "", 5, FALSE]);
            
            
            list data = llGetObjectDetails(id, [OBJECT_NAME, OBJECT_DESC, OBJECT_POS, OBJECT_ROT]);
            /*
            if(llVecDist(llList2Vector(data, 2), llGetPos())>150){
                llOwnerSay("Warning! Out of bounds object: "+llList2String(data, 0)+" could not be added!");
                return;
            }
            */
            
            string name = llList2String(data, 0);
            string pos = (string)trimVecRot([llList2Vector(data, 2)-llGetPos()], 2, TRUE);
            string rot = "";
            if((rotation)llList2String(data,3) != ZERO_ROTATION)rot = (string)trimVecRot([llList2Rot(data, 3)], 3, TRUE);
            list out = [name, pos, rot];
            string desc = llStringTrim(llList2String(data, 1), STRING_TRIM);
            if(llGetSubString(desc, 0,0) != "$" || llGetSubString(desc, 0, 2) == "$M$")desc = "";
            else desc = llGetSubString(desc, 1, -1);
            out+=desc;
            out+=group;
			
			integer i;
			
			// Saved data is [name, pos, rot, desc, group]
            
            // This object is in my inventory
            if(llGetInventoryType(name) == INVENTORY_OBJECT){
                db3$setOther(LevelStorage$custom, [-1], mkarr(out));
                custom_saved++;
            }
            // This is a start point
            else if(llGetSubString(name, 0, 12) == "_STARTPOINT_P"){
                if(name == "_STARTPOINT_P1")db3$setOther("got Level", [LevelShared$P1_start], llList2String(out, 1));
                else if(name == "_STARTPOINT_P2")db3$setOther("got Level", [LevelShared$P2_start], llList2String(out, 1));
                points_saved++;
            }
            // This is probably in the HUD then
            else{
                // Spawn from HUD
                list names = HUD_TABLES;
				for(i=0; i<3 && db3$setOther(l2s(names, i), [-1], mkarr(out)) == "0"; ++i){}
                assets_saved++;
            }
        }
        return;
    }
    
    // Purge all level data
    if(METHOD == LevelAuxMethod$purge){
        llOwnerSay("Wiping all data");
        clearDB3()
    }
	else if(METHOD == LevelAuxMethod$getOffset){
		vector offs = (vector)method_arg(0);
		CB_DATA = [offs-llGetRootPosition()];
	}
    
	
    // Save level data
    else if(METHOD == LevelAuxMethod$save){
        
		group = method_arg(1);
        assets_saved = 0;
        points_saved = 0;
        custom_saved = 0;
		
		llOwnerSay("Adding...");

        multiTimer(["S", "", 3, FALSE]);
    }
    
    else if(METHOD == LevelAuxMethod$stats){
        llOwnerSay("Stats:");
		list h = HUD_TABLES;
		integer hud;
		integer hlen;
		list_shift_each(h, val,
			val = db3$get(val, []);
			hud = llGetListLength(llJson2List(val));
			hlen += llStringLength(val);
		)
		list c = CUSTOM_TABLES;
		integer custom;
		integer clen;
		list_shift_each(c, val,
			val = db3$get(val, []);
			custom = llGetListLength(llJson2List(val));
			clen += llStringLength(val);
        )
		
        vector p1 = (vector)db3$get("got Level", [LevelShared$P1_start]);
        vector p2 = (vector)db3$get("got Level", [LevelShared$P2_start]);
        
        if(p1 == ZERO_VECTOR){
            llOwnerSay("WARNING. Required P1 spawn point missing.");
        }
        else llOwnerSay("P1: "+(string)p1);
        
        if(p2){
            llOwnerSay("P2: "+(string)p2);
        }
        else llOwnerSay("P2 Not set.");
        

        
        llOwnerSay("HUD Spawned: "+(string)hud);
        llOwnerSay("Custom assets: "+(string)custom);
		integer perc = llRound(100-((float)hlen/(db3$tableMaxlength*3)*100));
		llOwnerSay("Free Spawner Memory: "+(string)perc+"%");
        perc = llRound(100-((float)clen/(db3$tableMaxlength*3))*100);
		llOwnerSay("Free Assets Memory: "+(string)perc+"%");
    }
    
	else if(METHOD == LevelAuxMethod$spawn){
		string asset = method_arg(0);
        vector pos = (vector)method_arg(1);
        rotation rot = (rotation)method_arg(2);
        integer debug = (integer)method_arg(3);
		string description = method_arg(4);
		string spawnround = method_arg(5);
		
		
        if(llGetInventoryType(asset) == INVENTORY_OBJECT){
            if(debug)llOwnerSay("Spawning local asset: "+asset);
			Spawner$spawnInt(asset, pos, rot, description, debug, FALSE, spawnround);
        }else{
            if(debug)llOwnerSay("Item '"+asset+"' not found in level. Loading from HUD.");
            Spawner$spawn(asset, pos, rot, description, debug, FALSE, spawnround);
        }
	}

    // Spawns an item from HUD assets or level inventory as if it was live by ID
    else if(METHOD == LevelAuxMethod$testSpawn){
        integer HUD = (integer)method_arg(0);
        integer index = (integer)method_arg(1);
        integer live = (integer)method_arg(2);
        
		list asset = getAssetByIndex(!HUD, index);
		if(asset == [])
			return qd(xme(XLS(([
				XLS_EN, "Item not found: "+(str)index
			]))));
		
		list parse = llJson2List(l2s(asset, 2));
		if(HUD){
			qd(xme(XLS(([
				XLS_EN, "Spawning from HUD: "+llList2String(parse, 0)]
			))));
			Spawner$spawn(llList2String(parse, 0), (vector)llList2String(parse, 1)+llGetPos(), llList2String(parse, 2), llList2String(parse, 3), !live, false, "");
		}else{
			qd(xme(XLS(([
				XLS_EN, "Spawning from INV: "+llList2String(parse, 0)
			]))));
			Spawner$spawnInt(llList2String(parse, 0), (vector)llList2String(parse,1)+llGetPos(), (rotation)llList2String(parse, 2), llList2String(parse, 3), !live, false, "");
		}
    }
    
    else if(METHOD == LevelAuxMethod$list){
        list data = [];
        if((integer)method_arg(0))data = HUD_TABLES;
        else data = CUSTOM_TABLES;
        
        integer i; integer n;
        for(i=0; i<llGetListLength(data); i++){
			list spawns = llJson2List(db3$get(l2s(data, i), []));
			list_shift_each(spawns, val,
				qd("["+(string)n+"] "+val);
				++n;
			)
        }
        
    }
	
	// Set a property of a spawn
	else if(METHOD == LevelAuxMethod$assetVar){
		integer HUD = l2i(PARAMS, 0);
		integer globalIndex = l2i(PARAMS, 1);
		integer field = l2i(PARAMS,2);
		string newVal = method_arg(3);
		
		
		list asset = getAssetByIndex(!HUD, globalIndex);
		if(asset == [])
			return qd(xme(XLS(([
				XLS_EN, "Error: Item not found."
			]))));
		
		list data = llJson2List(l2s(asset, 2));
		
		data = llListReplaceList(data, [newVal], field, field);

        db3$setOther(l2s(asset, 0), [l2i(asset, 1)], mkarr(data));
        llOwnerSay(xme(XLS(([
			XLS_EN, "Item updated. Say 'listAssets' or 'listSpawns' for updated index"
		]))));
		
	}
    
    else if(METHOD == LevelAuxMethod$remove){
        integer HUD = l2i(PARAMS, 0);
		integer globalIndex = l2i(PARAMS, 1);
		
		list asset = getAssetByIndex(!HUD, globalIndex);
		if(asset == [])
			return qd(xme(XLS(([
				XLS_EN, "Error: Item not found."
			]))));
		string table = l2s(asset, 0);
		integer localIndex = l2i(asset, 1);
		
		list out = llJson2List(db3$get(table, []));
		out = llDeleteSubList(out, localIndex, localIndex);
		db3$setOther(table, [], mkarr(out));
        qd(xme(XLS(([
			XLS_EN, "Asset removed. Say 'listAssets' or 'listSpawns' for updated index"
		]))));
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}
