#define SCRIPT_ALIASES ["got Level"]
#define USE_SHARED ["*"]
#define USE_EVENTS
#include "got/_core.lsl"
integer slave;

integer BFL;
#define BFL_MONSTERS_LOADED 0x1
#define BFL_ASSETS_LOADED 0x2
#define BFL_SCRIPTS_LOADED 0x4
#define BFL_INI 0x8
#define BFL_LOAD_REQ (BFL_MONSTERS_LOADED|BFL_ASSETS_LOADED)

onEvt(string script, integer evt, list data){
	
	if(script == "got Portal" && evt == evt$SCRIPT_INIT){
		LevelLoader$load(FALSE, "");
	}
	
	if(script == "got LevelLoader"){
		// Returns true/false if assets/spawns exist
		if(evt == LevelLoaderEvt$defaultStatus){
			integer assets  = l2i(data, 0);
			integer spawns = l2i(data, 1);
					
			if(!assets){
				BFL = BFL|BFL_ASSETS_LOADED;
			}
			if(!spawns){
				BFL = BFL|BFL_MONSTERS_LOADED;
			}
			checkLoadFinish(FALSE);
			if(assets || spawns){
				multiTimer(["LOAD_FINISH", "", 60, FALSE]);
			}
		}
		else if(evt == LevelLoaderEvt$queueFinished){
			list d = llJson2List(l2s(data, 1));
			if(~llListFindList(d, [""])){
				if(l2s(data, 0) == "HUD")
					BFL = BFL|BFL_MONSTERS_LOADED;
				else
					BFL = BFL|BFL_ASSETS_LOADED;
				
				checkLoadFinish(FALSE);
			}
		}
	}
}

timerEvent(string id, string data){
	
	if(id == "LOAD_FINISH"){
		checkLoadFinish(TRUE);
	}

}

checkLoadFinish(integer force){
	if(BFL&BFL_INI)
		return;
	
	if(~BFL&(BFL_MONSTERS_LOADED|BFL_ASSETS_LOADED) && !force)
		return;
		
	BFL = BFL|BFL_INI;
	raiseEvent(LevelLiteEvt$loaded, "");

}

default
{
	state_entry(){
		memLim(1.5); 
		raiseEvent(evt$SCRIPT_INIT, "");
		if(llGetStartParameter() == 2){
			list tables = [
				LevelStorage$main,
				LevelStorage$points,
				LevelStorage$custom,
				LevelStorage$points+"_1",
				LevelStorage$custom+"_1",
				LevelStorage$points+"_2",
				LevelStorage$custom+"_2"
			];
			db3$addTables(tables);
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
	

	
    if(METHOD == LevelMethod$load && method$byOwner){
        integer debug = (integer)method_arg(0);
		string group = method_arg(1);
        raiseEvent(LevelLiteEvt$load, mkarr(([debug, group])));
		LevelLoader$load(debug, group);
        return;
    }
	/*
	// MOVED TO LEVELDATA
	if(METHOD == LevelMethod$getScripts && method$byOwner){
        integer pin = (integer)method_arg(0);
        list scripts = llJson2List(method_arg(1));
        list_shift_each(scripts, v, 
            if(llGetInventoryType(v) == INVENTORY_SCRIPT){
                slave++;
                if(slave>9)slave=1;
                // Remote load
                llMessageLinked(LINK_THIS, slave, llList2Json(JSON_ARRAY, [id, v, pin, 2]), "rm_slave");
            }
            else if(llGetInventoryType(v) != INVENTORY_NONE) llGiveInventory(id, v);
			else qd(xme(XLS(([
				XLS_EN, v+" could not be loaded onto "+llKey2Name(id)+" because it doesn't exist."
			]))));
        )
        
    }
	if(METHOD == LevelMethod$died){
		raiseEvent(LevelLiteEvt$playerDied, (str)id);
		return;
	}
	*/
	
	if( METHOD == LevelMethod$interact )
        raiseEvent(LevelLiteEvt$interact, mkarr(([llGetOwnerKey(id), method_arg(0), method_arg(1)]))); 
    
    else if( METHOD == LevelMethod$trigger )
        raiseEvent(LevelLiteEvt$trigger, mkarr(([method_arg(0), id, method_arg(1)])));   
    
    else if( METHOD == LevelMethod$idEvent ){
        
		list out = [id, method_arg(1), method_arg(2), method_arg(3)];
        integer evt = (integer)method_arg(0);
        return raiseEvent(evt, mkarr(out));
		
    }
	
	if( method$internal && METHOD == LevelMethod$raiseEvent )
		raiseEvent(l2i(PARAMS, 0), mkarr(llDeleteSubList(PARAMS, 0, 0)));
		
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

