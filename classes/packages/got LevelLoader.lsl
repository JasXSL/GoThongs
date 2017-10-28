#include "got/_core.lsl"

// Used for "" loading and reporting
integer BFL;
#define BFL_HAS_ASSETS 0x1
#define BFL_HAS_SPAWNS 0x2

timerEvent(string id, string data){
	if(id == "INI"){
		list d = [BFL&BFL_HAS_ASSETS, BFL&BFL_HAS_SPAWNS];
		raiseEvent(LevelLoaderEvt$defaultStatus, mkarr(d));
	}
}

default
{
    state_entry()
    {
		if(llGetStartParameter() == 2){
			raiseEvent(evt$SCRIPT_INIT, "");
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
		if(SENDER_SCRIPT == "got Spawner" && (METHOD == SpawnerMethod$spawnThese || METHOD == SpawnerMethod$spawn)){
			list parse = llJson2List(CB);
			//if(l2s(parse, 0) == "HUD" || l2s(parse, 0) == "CUSTOM"){
			raiseEvent(LevelLoaderEvt$queueFinished, CB);
			//}
		}
		return;
	}
	

// Spawn the level, this goes first as it's fucking memory intensive
    if(METHOD == LevelLoaderMethod$load && method$internal){
        integer debug = (integer)method_arg(0);
		
		list groups = [method_arg(1)];
		if(llJsonValueType(method_arg(1), []) == JSON_ARRAY)
			groups = llJson2List(method_arg(1));
		
		if(l2s(groups, 0) == ""){
			BFL = BFL&~BFL_HAS_ASSETS;
			BFL = BFL&~BFL_HAS_SPAWNS;
			multiTimer(["INI", "", 10, FALSE]);
		}
				
		list out;					// Data to push to spawners
		list data;					// Asset data
		integer spawned;			// Nr spawned
		
        // Spawn from HUD
		list HUD = Level$HUD_TABLES;
		list_shift_each(HUD, table,
			data = llJson2List(db3$get(table, []));
			
			
			list_shift_each(data, v,
				list val = llJson2List(v);
				
				list l = llList2List(val, 4, 4);
				if(l == [])l = [""];
				integer pos = llListFindList(groups, l);
				string group = llList2String(groups, pos);
				
				if(~pos){ 
					spawned++;
					string chunk = llList2Json(JSON_ARRAY, [
						llList2String(val, 0), 
						(vector)llList2String(val, 1)+llGetPos(), 
						llList2String(val, 2), 
						llList2String(val, 3), 
						debug, 
						FALSE, 
						group
					]);
					if(llStringLength(mkarr(out)+chunk)>900){
						// Send out
						Spawner$spawnThese(llGetOwner(), out);
						out = [];
					}
					// Add the chunk
					out+= chunk;
				}
			)
		)
		

		// Send out
		if(out)
			Spawner$spawnThese(llGetOwner(), out);
			
		
		out = [llList2Json(JSON_ARRAY, [
			"_CB_", "[\"HUD\","+mkarr(groups)+"]"
		])];
		Spawner$spawnThese(llGetOwner(), out);
		
		
		BFL = BFL|BFL_HAS_SPAWNS;
		

			
		//qd("Spawned "+(str)spawned+" monsters");
        spawned = 0;
		
        // Spawn from Me
		out = [];
        
		list CUSTOM = Level$CUSTOM_TABLES;
		list_shift_each(CUSTOM, table,
			data = llJson2List(db3$get(table, []));
			list_shift_each(data, v,
				list val = llJson2List(v);
				
				list l = llList2List(val, 4, 4);
				if(l == [])l = [""];
				integer pos = llListFindList(groups, l);
				string group = llList2String(groups, pos);
				
				if(~pos){
					spawned++;
					// No limit on link messages, just send all of the things
					string add = llList2Json(JSON_ARRAY, [
						llList2String(val, 0), 
						(vector)llList2String(val,1)+llGetPos(), 
						llList2String(val, 2), 
						llStringTrim(llList2String(val, 3), STRING_TRIM), 
						debug, 
						FALSE, 
						group
					]);
					
					if(llStringLength(mkarr(out))+llStringLength(add) > 1024){
						Spawner$spawnThese(LINK_THIS, out);
						out = [];
					}
					out += add;
				}
			)
		)
		
		if(out)
			Spawner$spawnThese(LINK_THIS, out);
			
		out = [llList2Json(JSON_ARRAY, [
			"_CB_", "[\"CUSTOM\","+mkarr(groups)+"]"
		])];
		Spawner$spawnThese(LINK_THIS, out);

		BFL = BFL|BFL_HAS_ASSETS;
		
		

		out = [];
    }
	
	
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

