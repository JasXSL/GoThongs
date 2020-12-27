#define USE_EVENTS
#include "got/_core.lsl"

list PLAYERS;

string group = "";
integer assets_saved;
integer points_saved;
integer custom_saved;
key backup_restore;
key backup;
key fetchWindlights;

#define HUD_TABLES Level$HUD_TABLES
#define CUSTOM_TABLES Level$CUSTOM_TABLES

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


ptEvt(str id){
    if(id == "SAVE")
        llOwnerSay((string)assets_saved+" HUD\n"+(string)points_saved+" spawns\n"+(string)custom_saved+" assets saved");
    else if(id == "S"){
        // Start save
        Portal$save();
        ptSet("SAVE", 10, FALSE);
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

// Returns [(str)table, (int)internal_index, (str)data] or [] if not found
list getAssetByIndex(integer customAsset, integer globalIndex){
	if(globalIndex<0){
		llOwnerSay("Negative indexes are no longer allowed");
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

default{

    state_entry(){ 
	
		raiseEvent(evt$SCRIPT_INIT, ""); 
		ptSet("KILLQUE", 2, TRUE); 
		
		integer N;
        // fetchWindlights((list)"[TOR] Night - Anwar" + "Nacon's Natural Sunset: C");
        links_each( nr, name,
            
            string desc = l2s(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0);
            if( ~llSubStringIndex(desc, "WL$") ){
                
                list spl = explode("$$", desc);
                integer i;
                for(; i < count(spl); ++i ){
                    
                    list sub = explode("$", l2s(spl, i));
                    if( l2s(sub, 0) == "WL" ){
                        
                        string wl = llToLower(l2s(sub, 1));
						
						// Windlight is already a key
						if( (key)wl ){}
						else{
						
							integer pos = llListFindList(toSet, (list)wl);
							if( ~pos )
								toSet = llListReplaceList(toSet, [
									implode(",", explode(",", l2s(toSet, pos+1)) + nr )
								], pos+1, pos+1);
							else
								toSet += (list)wl + nr;

						}
						i = count(spl);
						
                    }
                    
                }
                
            }
            ++N;
        
        )
		
        fetchWindlights = llHTTPRequest(
			"https://jasx.org/api/windlight/?SKY="+
				llEscapeURL(implode(",", llList2ListStrided(toSet, 0, -1, 2))),
			[],
			""
		);
		
	}
    
    timer(){ ptRefresh(); }
    
	
	http_response(key id, integer status, list meat, string body){
		
		if( id == backup )
			llOwnerSay(body);
		
		if( id == fetchWindlights ){
			
			integer i;
			body = j(body, "SKY");
			if( !isset(body) )
				return;
				
			for(; i < count(toSet); i += 2 ){
				
				key uuid = j(body, l2s(toSet, i));
				if( uuid ){
					
					list prims = explode(",", l2s(toSet, i+1));
					integer pid;
					for(; pid < count(prims); ++pid ){
						
						integer prim = l2i(prims, pid);
						list desc = explode(
							"$$", 
							l2s(
								llGetLinkPrimitiveParams(prim, (list)PRIM_DESC),
								0
							)
						);
						
						integer d;
						for( ; d < count(desc); ++d ){
							
							list spl = explode("$", l2s(desc, d));
							if( l2s(spl, 0) == "WL" ){
								
								spl = llListReplaceList(spl, (list)uuid, 1, 1);
								desc = llListReplaceList(desc, (list)implode("$", spl), d, d);
								
							}    
							
						}
						
						string out = implode("$$", desc);
						if( llStringLength(out) > 127 )
							llOwnerSay("ERROR: Prim desc too long: '"+out+"' Please report this here: https://github.com/JasXSL/GoThongs/issues/343");
						else
							llSetLinkPrimitiveParamsFast(prim, (list)PRIM_DESC + out);
						
					}
					
					
				}
				else
					llOwnerSay("MISSING WINDLIGHT: "+l2s(toSet, i));
				
				
			}
			toSet = [];
					
		}
		
		if( id != backup_restore )
			return;
		
		if(llJsonValueType(body, []) != JSON_OBJECT ){
			llOwnerSay(body);
			return;
		}
		
		if(llJsonValueType(body, ["jsonapi", 0, "errors"]) != JSON_INVALID){
			llOwnerSay(llJsonGetValue(body, ["jsonapi", 0, "errors", 0, "title"]));
			return;
		}
		if(llJsonValueType(body, ["jsonapi", 0, "data"]) == JSON_INVALID){
			llOwnerSay("Load failed, data was invalid: ("+(str)llStringLength(body)+"):");
			integer n;
			while(n<llStringLength(body)){
				llOwnerSay(llGetSubString(body, n, n+999));
				n += 1000;
			}
			return;
		}
		body = llJsonGetValue(body, ["jsonapi", 0, "data"]);
		llOwnerSay("Wiping existing tables");
		list all = Level$ALL_TABLES;
		list_shift_each(all, val,
			db3$setOther(val, [], "[]");
		)
		list split = llJson2List(body);
		body = "";
		integer i;
		for(i=0; i<count(split); i = i+2){
			llOwnerSay("Restoring "+l2s(split, i));
			db3$setOther(l2s(split, i), [], l2s(split, i+1));
		}
		llOwnerSay("Backup load complete");
		
	}
	
    #include "xobj_core/_LM.lsl"
    if(!method$byOwner)return;
    if(method$isCallback){
	
        if(CB == "SV"){
		
            ptSet("SAVE", 5, FALSE);
            
            
            list data = llGetObjectDetails(id, [OBJECT_NAME, OBJECT_DESC, OBJECT_POS, OBJECT_ROT, OBJECT_ATTACHED_POINT]);
			if( l2i(data, 4) )
				return;
            
            string name = llList2String(data, 0);
            string pos = (string)trimVecRot([llList2Vector(data, 2)-llGetRootPosition()], 2, TRUE);
            string rot = "";
            if( (rotation)llList2String(data,3) != ZERO_ROTATION )
				rot = (string)trimVecRot([llList2Rot(data, 3)], 3, TRUE);
				
            list out = [name, pos, rot];
            string desc = llStringTrim(llList2String(data, 1), STRING_TRIM);
            if( llGetSubString(desc, 0,0) != "$" || llGetSubString(desc, 0, 2) == "$M$" )
				desc = "";
            else 
				desc = llGetSubString(desc, 1, -1);
				
            out+=desc;
            out+=group;
			
			integer i;
			
			// Saved data is [name, pos, rot, desc, group]
            
            // This object is in my inventory
            if(llGetInventoryType(name) == INVENTORY_OBJECT){
				
				for( i=0; i < count(CUSTOM_TABLES); ++i ){
				
					if( db3$setOther(l2s(CUSTOM_TABLES, i), [-1], mkarr(out)) != "0" ){
						++custom_saved;
						return;
					}
					
				}
			
            }
            // This is a start point
            else if(llGetSubString(name, 0, 12) == "_STARTPOINT_P"){
                if(name == "_STARTPOINT_P1")
					db3$setOther("got Level", [LevelShared$P1_start], llList2String(out, 1));
                else if(name == "_STARTPOINT_P2")
					db3$setOther("got Level", [LevelShared$P2_start], llList2String(out, 1));
                points_saved++;
            }
            // This is probably in the HUD then
            else{
			
                // Spawn from HUD
                list names = HUD_TABLES;
				for(i=0; i<3; ++i){
					if( db3$setOther(l2s(names, i), [-1], mkarr(out)) != "0" ){
						++assets_saved;
						return;
					}
				}
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

        ptSet("S", 3, FALSE);
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
		if(asset == []){
			llOwnerSay("Not found: "+(str)index);
			return;
		}
		list parse = llJson2List(l2s(asset, 2));
		if(HUD){
			llOwnerSay("From HUD: "+llList2String(parse, 0));
			Spawner$spawn(llList2String(parse, 0), (vector)llList2String(parse, 1)+llGetRootPosition(), llList2String(parse, 2), llList2String(parse, 3), !live, false, "");
		}else{
			llOwnerSay("From INV: "+llList2String(parse, 0));
			Spawner$spawnInt(llList2String(parse, 0), (vector)llList2String(parse,1)+llGetRootPosition(), (rotation)llList2String(parse, 2), llList2String(parse, 3), !live, false, "");
		}
    }
    
    else if(METHOD == LevelAuxMethod$list){
		//llOwnerSay("Listing "+method_arg(0)+" ["+SENDER_SCRIPT+"]");
        list data = [];
        if((integer)method_arg(0))
			data = HUD_TABLES;
        else 
			data = CUSTOM_TABLES;
        
        integer i; integer n;
        for(i=0; i<llGetListLength(data); i++){
			string s = db3$get(l2s(data, i), []);
			list spawns = llJson2List(s);
			list_shift_each(spawns, val,
				llOwnerSay("["+(string)n+"] "+val);
				++n;
			)
        }
        
    }
	
	else if( METHOD == LevelAuxMethod$restoreFromBackup ){
		
		string api_key = method_arg(0);
		string save_token = trim(method_arg(1));
		if( save_token == "" )
			save_token = "backup";
		backup_restore = llHTTPRequest(
			"https://jasx.org/lsl/got/app/mod_api/", 
			[HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded", HTTP_CUSTOM_HEADER, "Got-Mod-Token", api_key, HTTP_BODY_MAXLENGTH, 16384],
			"tasks="+llEscapeURL(llList2Json(JSON_ARRAY, [
				llList2Json(JSON_OBJECT, [
					"type", "GetBackup",
					"target", llGetObjectName(),
					"data", llList2Json(JSON_OBJECT, [
						"backup_token", save_token
					])
				])
			]))
		);
		
	}
	
	else if( METHOD == LevelAuxMethod$backup ){
		
		string api_key = method_arg(0);
		string save_token = method_arg(1);
		
		integer dbPrim;
		links_each(nr, name,
			if( name == "DB0" ){
				dbPrim = nr;
			}
		)
		

		llOwnerSay("Beginning dump");
		list out = [];
		integer i;
		for(i=0; i<llGetLinkNumberOfSides(dbPrim); ++i){
				
			list tables = llGetLinkMedia(dbPrim, i, [
				PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL, PRIM_MEDIA_WHITELIST
			]);
			string text;
			list_shift_each(tables, val,
				int pos = llSubStringIndex(val, "://");
				text += llDeleteSubString(val, 0, pos+2);
			)
			
			integer pos = llSubStringIndex(text, "|");
			string a = llGetSubString(text, 0, pos-1);
			if(
				llStringLength(text) && 
				llGetListLength(
					llJson2List(llGetSubString(text, pos+1, -1))
				) &&
				llListFindList(out, (list)a) == -1
			){
				text = llGetSubString(text, pos+1, -1);
				
				if(llStringLength(text) > 2034)
					llOwnerSay("WARNING! Table "+a+" is too big to fit on the new prim DB. Can splice it in MYSQL.");
				out += [
					a, text
				];
			}
			
		}
		
		llOwnerSay("Backing up "+llGetObjectName());
		backup = llHTTPRequest(
			"https://jasx.org/lsl/got/app/mod_api/", 
			[HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded", HTTP_CUSTOM_HEADER, "Got-Mod-Token", api_key, HTTP_BODY_MAXLENGTH, 16384],
			"tasks="+llEscapeURL(llList2Json(JSON_ARRAY, [
				llList2Json(JSON_OBJECT, [
					"type", "BackupCell",
					"target", llGetObjectName(),
					"data", llList2Json(JSON_OBJECT, [
						"backup_token", save_token,
						"data", llList2Json(JSON_OBJECT, out)
					])
				])
			]))
		);
		
	}
        
		
	
	
	// Set a property of a spawn
	else if(METHOD == LevelAuxMethod$assetVar){
		integer HUD = l2i(PARAMS, 0);
		integer globalIndex = l2i(PARAMS, 1);
		integer field = l2i(PARAMS,2);
		string newVal = method_arg(3);
		
		
		list asset = getAssetByIndex(!HUD, globalIndex);
		if(asset == []){
			llOwnerSay("Error: Item not found.");
			return;
		}
		list data = llJson2List(l2s(asset, 2));
		
		data = llListReplaceList(data, [newVal], field, field);

        db3$setOther(l2s(asset, 0), [l2i(asset, 1)], mkarr(data));
        llOwnerSay("Item updated. Say 'listAssets' or 'listSpawns' for updated index");
		
	}
    
    else if(METHOD == LevelAuxMethod$remove){
        integer HUD = l2i(PARAMS, 0);
		integer globalIndex = l2i(PARAMS, 1);
		
		list asset = getAssetByIndex(!HUD, globalIndex);
		if(asset == []){
			llOwnerSay("Error: Item not found.");
			return;
		}
		string table = l2s(asset, 0);
		integer localIndex = l2i(asset, 1);
		list out = llJson2List(db3$get(table, []));
		out = llDeleteSubList(out, localIndex, localIndex);
		db3$setOther(table, [], mkarr(out));
        llOwnerSay("Removed. Index list changed.");
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}
