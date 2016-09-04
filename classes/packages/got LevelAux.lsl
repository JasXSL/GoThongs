#include "got/_core.lsl"

string group = "";
integer assets_saved;
integer points_saved;
integer custom_saved;

timerEvent(string id, string data){
    if(id == "SAVE"){
        qd("Save: \n"+(string)assets_saved+" HUD assets\n"+(string)points_saved+" spawnpoints\n"+(string)custom_saved+" custom assets");
    }
    else if(id == "S"){
        // Start save
        Portal$save();
        multiTimer(["SAVE", "", 10, FALSE]);
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


default
{
    state_entry()
    {
		raiseEvent(evt$SCRIPT_INIT, "");
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
            
            if(llVecDist(llList2Vector(data, 2), llGetPos())>150){
                llOwnerSay("Warning! Out of bounds object: "+llList2String(data, 0)+" could not be added!");
                return;
            }
            
            
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
                db3$setOther(LevelStorage$points, [-1], mkarr(out)); 
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
        if(!(integer)method_arg(0)){
			// Clear current
            llOwnerSay("Saving...");
			list points = llJson2List(db3$get(LevelStorage$points, [])); list out;
			list_shift_each(points, val,
				if(j(val, 4) != group)out+=val;
			)
            db3$setOther(LevelStorage$points, [], mkarr(out));
			
			points = llJson2List(db3$get(LevelStorage$custom, [])); out = [];
			list_shift_each(points, val,
				if(j(val, 4) != group)out+=val;
			)
            db3$setOther(LevelStorage$custom, [], mkarr(out));
			
        }else llOwnerSay("Adding...");
		
		
		
        multiTimer(["S", "", 3, FALSE]);
    }
    
    else if(METHOD == LevelAuxMethod$stats){
        llOwnerSay("Stats:");
        integer hud = llGetListLength(llJson2List(db3$get(LevelStorage$points, [])));
        integer custom = llGetListLength(llJson2List(db3$get(LevelStorage$custom, [])));
        
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
		integer perc = llRound((1-((float)llStringLength(db3$get(LevelStorage$points, []))/(1024*3)))*100);
		llOwnerSay("Free Spawner Memory: "+(string)perc+"%");
        perc = llRound((1-((float)llStringLength(db3$get(LevelStorage$custom, []))/(1024*3)))*100);
		llOwnerSay("Free Assets Memory: "+(string)perc+"%");
    }
    
	else if(METHOD == LevelAuxMethod$spawn){
		string asset = method_arg(0);
        vector pos = (vector)method_arg(1);
        rotation rot = (rotation)method_arg(2);
        integer debug = (integer)method_arg(3);
		string description = method_arg(4);

        if(llGetInventoryType(asset) == INVENTORY_OBJECT){
            if(debug)llOwnerSay("Spawning local asset: "+asset);
			Spawner$spawnInt(asset, pos, rot, description, debug, FALSE, "");
        }else{
            if(debug)llOwnerSay("Item '"+asset+"' not found in level. Loading from HUD.");
            Spawner$spawn(asset, pos, rot, description, debug, FALSE, "");
        }
	}

    // Spawns an item from HUD assets or level inventory as if it was live by ID
    else if(METHOD == LevelAuxMethod$testSpawn){
        integer HUD = (integer)method_arg(0);
        integer i = (integer)method_arg(1);
        integer live = (integer)method_arg(2);
        
        if(HUD){
            list parse = llJson2List(llList2String(llJson2List(db3$get(LevelStorage$points, [])), i));
            if(llList2String(parse, 0) == "")return;
			llOwnerSay("Spawning from HUD: "+llList2String(parse, 0));
            Spawner$spawn(llList2String(parse, 0), (vector)llList2String(parse, 1)+llGetPos(), llList2String(parse, 2), llList2String(parse, 3), !live, false, "");
        }else{
            list parse = llJson2List(llList2String(llJson2List(db3$get(LevelStorage$custom, [])), i));
            if(llList2String(parse, 0) == "")return;
			llOwnerSay("Spawning from INV: "+llList2String(parse, 0));
			Spawner$spawnInt(llList2String(parse, 0), (vector)llList2String(parse,1)+llGetPos(), (rotation)llList2String(parse, 2), llList2String(parse, 3), !live, false, "");
        }
    }
    
    else if(METHOD == LevelAuxMethod$list){
        list data = [];
        if((integer)method_arg(0))data = llJson2List(db3$get(LevelStorage$points, []));
        else data = llJson2List(db3$get(LevelStorage$custom, []));
        
        integer i;
        for(i=0; i<llGetListLength(data); i++){
            llOwnerSay("["+(string)i+"] "+llList2String(data, i));
        }
        
    }
	
	// Set a property of a spawn
	else if(METHOD == LevelAuxMethod$assetVar){
		list data = [];
        if((integer)method_arg(0))data = llJson2List(db3$get(LevelStorage$points, []));
        else data = llJson2List(db3$get(LevelStorage$custom, []));
        integer pos = (integer)method_arg(1);
		integer field = (integer)method_arg(2);
		string newVal = method_arg(3);
		string asset = llList2String(data, pos);
		asset = llJsonSetValue(asset, [field], newVal);
        data = llListReplaceList(data, [asset], pos, pos);
        
        if((integer)method_arg(0))db3$setOther(LevelStorage$points, [], mkarr(data));
        else db3$setOther(LevelStorage$custom, [], mkarr(data));
        llOwnerSay("Item updated. Say 'listAssets' or 'listSpawns' for updated index");
	}
    
    else if(METHOD == LevelAuxMethod$remove){
        list data = [];
        if((integer)method_arg(0))data = llJson2List(db3$get(LevelStorage$points, []));
        else data = llJson2List(db3$get(LevelStorage$custom, []));
        integer pos = (integer)method_arg(1);
        data = llDeleteSubList(data, pos, pos);
        
        if((integer)method_arg(0))db3$setOther(LevelStorage$points, [], mkarr(data));
        else db3$setOther(LevelStorage$custom, [], mkarr(data));
        llOwnerSay("Asset removed. Say 'listAssets' or 'listSpawns' for updated index");
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}
