#define SCRIPT_IS_ROOT
#define USE_EVENTS
#define ALLOW_USER_DEBUG 1
#define DB2_PRESERVE_ON_RESET
#include "got/_core.lsl"

integer slave;
list PLAYERS = [];
list PLAYERS_COMPLETED;
integer START_PARAM;

integer DEATHS;
integer MONSTERS_KILLED;

integer BFL;
#define BFL_MONSTERS_LOADED 0x1
#define BFL_ASSETS_LOADED 0x2
#define BFL_LOADING 0x4
#define BFL_SCRIPTS_LOADED 0x8
#define BFL_INI 0x10

#define BFL_LOAD_REQ (BFL_MONSTERS_LOADED|BFL_ASSETS_LOADED|BFL_SCRIPTS_LOADED)

list LOADQUEUE = REQUIRE;			// Required scripts to be remoteloaded
onEvt(string script, integer evt, string data){
	integer pos = llListFindList(LOADQUEUE, [script]);
	if(~pos && evt == evt$SCRIPT_INIT && ~BFL&BFL_INI){
		LOADQUEUE = llDeleteSubList(LOADQUEUE, pos, pos);
		if(LOADQUEUE == []){
			// Init
			raiseEvent(evt$SCRIPT_INIT, "");
			db2$set([LevelShared$isSharp], (string)START_PARAM);
			Alert$freetext(llGetOwner(), "Loading from HUD", FALSE, FALSE);
			llSetTimerEvent(3);
			Root$setLevel();
			BFL = BFL|BFL_INI;
			
		}
	}
}

#define runOnPlayers(pkey, code) {integer i; for(i=0; i<llGetListLength(PLAYERS); i++){key pkey = llList2Key(PLAYERS, i); code}}

integer pin;
default
{
    on_rez(integer mew){
        llSetText((string)mew, ZERO_VECTOR, 0);
        
        // Grab script update
		pin = llFloor(llFrand(0xFFFFFFF));
		llSetRemoteScriptAccessPin(pin);
        Remoteloader$load(cls$name, pin, 2);
    }
    
    state_entry()
    {
		resetAllOthers();
		PLAYERS = [(string)llGetOwner()];
		DB2$ini();
		initiateListen();
		START_PARAM = llList2Integer(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]), 0);
		
		if(llGetStartParameter() == 2){
			vector p = llGetPos();
			vector pos = p-vecFloor(p)+int2vec(START_PARAM);
			
			if(START_PARAM == 1)pos = ZERO_VECTOR;

			if(START_PARAM&(BIT_DEBUG-1))llSetRegionPos(pos);

		
			pin = llFloor(llFrand(0xFFFFFFF));
			llSetRemoteScriptAccessPin(pin);
			integer i;
			for(i=0; i<llGetListLength(LOADQUEUE); i++)
				Remoteloader$load(llList2String(LOADQUEUE, i), pin, 2);
        }
        else{
			llSetTimerEvent(5);
		}
    }
    
    timer(){
		if(~BFL&BFL_INI){
			qd("Level script could not update. If you are developing this level, wear the HUD and then reset the level script.");
			llSetTimerEvent(0);
		}else if(BFL&BFL_LOADING){
            Level$loadFinished();
            llSetTimerEvent(0);
        }
		else{
			Root$setLevel();
		}
    }
    
    changed(integer change){
        if(change&CHANGED_LINK)db2$ini();
    }
    
    #define LISTEN_LIMIT_FREETEXT if(llListFindList(PLAYERS, [(string)llGetOwnerKey(id)]) == -1){return;}
    #include "xobj_core/_LISTEN.lsl"
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    
    
    
    if(method$isCallback){
        if(!method$byOwner)return;
        if(CB == "LV" && SENDER_SCRIPT == "#ROOT" && llGetOwnerKey(id) == llGetOwner()){
            PLAYERS = llJson2List(PARAMS);
            raiseEvent(LevelEvt$players, PARAMS);
            llSetTimerEvent(0);
            Alert$freetext(llGetOwner(), "Players: "+(string)llGetListLength(PLAYERS), FALSE, FALSE);
            
            key p = llList2Key(PLAYERS, 0);
            if(p == llGetOwner())p = llList2Key(PLAYERS, 1);
            Root$setLevelOn(p);
            if(START_PARAM){
                runMethod((string)LINK_THIS, cls$name, LevelMethod$load, [FALSE], TNN);
            }
        }
        return;
    }
    
// PUBLIC HERE
    if(METHOD == LevelMethod$interact){
        raiseEvent(LevelEvt$interact, mkarr(([llGetOwnerKey(id), method_arg(0)])));   
    }
    else if(METHOD == LevelMethod$trigger){
        raiseEvent(LevelEvt$trigger, mkarr(([method_arg(0), id, method_arg(1)])));   
    }
    
    else if(METHOD == LevelMethod$idEvent){
        list out = [id, method_arg(1), method_arg(2)];
        integer evt = (integer)method_arg(0);
		if(evt == LevelEvt$idDied){
			MONSTERS_KILLED++;
		}
        raiseEvent(evt, mkarr(out));
    }
	else if(METHOD == LevelMethod$died){
		DEATHS++;
	}
	else if(METHOD == LevelMethod$getObjectives){
		raiseEvent(LevelEvt$fetchObjectives, mkarr([llGetOwnerKey(id)]));
	}
    
// OWNER ONLY BELOW THIS LINE
    if(!method$byOwner)return;
    
    if(METHOD == LevelMethod$setFinished){
        if(~llListFindList(PLAYERS_COMPLETED, [method_arg(0)]))return;
        if(method_arg(0) != "")PLAYERS_COMPLETED += [method_arg(0)];
		
        if(PLAYERS_COMPLETED == PLAYERS){
			if((integer)method_arg(1)){
				raiseEvent(LevelEvt$levelCompleted, "");
			}
            else if((integer)START_PARAM){
                runOnPlayers(pk, 
					integer continue = TRUE;
					if(pk != llGetOwner())continue = FALSE;
					Bridge$completeCell(pk, DEATHS, MONSTERS_KILLED, continue);
					Portal$killAll();
				)
            }else{
                llOwnerSay("Cell test completed!");
            }
			runOnPlayers(targ,
				GUI$toggleObjectives(targ, FALSE); // Clear objectives
			)
        }else{
			integer i;
			for(i=0; i<llGetListLength(PLAYERS); i++){
				string msg = "Someone has reached the level exit.";
				if(llListFindList(PLAYERS_COMPLETED, [llList2String(PLAYERS, i)]) == -1){
					msg += " Waiting for you to do the same.";
				}else{
					msg += " Waiting for coop player.";
				}
				Alert$freetext(llList2Key(PLAYERS, i), msg, TRUE, TRUE);
			}
		}
    }
    
    // Spawn the level
    else if(METHOD == LevelMethod$load){
        
        
        integer debug = (integer)method_arg(0);
		string group = method_arg(1);
        raiseEvent(LevelEvt$load, mkarr(([debug, group])));
        integer i; list data;
        
		// Things to run on level start
		if(group == JSON_INVALID){
			// For debugging, let's bind players again
			runOnPlayers(pk, 
				Root$setLevelOn(pk);
			)
			
			BFL = BFL&~BFL_MONSTERS_LOADED;
			BFL = BFL&~BFL_ASSETS_LOADED;
			BFL = BFL|BFL_LOADING;
			
			
			llSetTimerEvent(60);
			
			
			Bridge$getCellData();
			
			vector p1 = (vector)db2$get(cls$name, [LevelShared$P1_start]);
			vector p2 = (vector)db2$get(cls$name, [LevelShared$P2_start]); 
			if(debug){
				if(p1)
					Devtool$spawnAt("_STARTPOINT_P1", p1+llGetPos(), ZERO_ROTATION);
				if(p2)
					Devtool$spawnAt("_STARTPOINT_P2", p2+llGetPos(), ZERO_ROTATION);
			}else{
				// Send player to start
				Alert$freetext(llGetOwner(), "Loading Cell.. Please wait.", FALSE, FALSE);
				
				list tp = SupportcubeBuildTeleport(p1+llGetPos());
				RLV$cubeTaskOn(llList2String(PLAYERS, 0), tp);
				if(llGetListLength(PLAYERS)>1){
					vector two = p2;
					if(two == ZERO_VECTOR)two = p1;
					tp = SupportcubeBuildTeleport(two+llGetPos());
					RLV$cubeTaskOn(llList2String(PLAYERS, 1), tp);
				}
			}
			
			runOnPlayers(pk, 
				if(!debug)Status$loading(pk, TRUE);
				GUI$toggleSpinner(pk, TRUE, "");
			)
        }
		
		// These will be run even when loading a custom group
		
        // Spawn from HUD
        data = llJson2List(db2$get(LevelStorage$points, []));
        if(data == [])BFL = BFL|BFL_MONSTERS_LOADED;
        list_shift_each(data, val,
			if(j(val, 4) == group){
				Spawner$spawn(j(val, 0), (vector)j(val, 1)+llGetPos(), j(val, 2), j(val, 3), debug, FALSE);
			}
        )
        
        // Spawn from Me
        data = llJson2List(db2$get(LevelStorage$custom, []));
        if(data == [])BFL = BFL|BFL_ASSETS_LOADED;
        list_shift_each(data, val,
			if(j(val, 4) == group){
				string desc = llStringTrim(j(val, 3), STRING_TRIM);  // This needs to be cached somehow
				Spawner$spawnInt(j(val, 0), (vector)j(val,1)+llGetPos(), (rotation)j(val, 2), desc, debug, FALSE);
			}
            //Spawner$spawn(llList2String(parse, 0), (vector)llList2String(parse, 1)+llGetPos(), llList2String(parse, 2), llList2String(parse, 3));
        )
        
        
        
        integer needed = BFL_ASSETS_LOADED|BFL_MONSTERS_LOADED;
        if(BFL&needed == needed)
            Level$loadFinished();
    }
    
    else if(METHOD == LevelMethod$loaded && BFL&BFL_LOADING){
        integer isHUD = (integer)method_arg(0);
        if(isHUD == 2)BFL = BFL|BFL_SCRIPTS_LOADED;
        else if(isHUD)BFL = BFL|BFL_MONSTERS_LOADED;
        else BFL = BFL|BFL_ASSETS_LOADED;
        
        
        if(BFL&BFL_LOAD_REQ == BFL_LOAD_REQ){
            Level$loadFinished();
        }
    }
	
	else if(METHOD == LevelMethod$cellData){
		string dta = method_arg(0);
		db2$set([LevelShared$questData], dta);
		raiseEvent(LevelEvt$questData, dta);
	}
	else if(METHOD == LevelMethod$cellDesc){
		string txt = method_arg(0);
		if(~BFL&BFL_LOAD_REQ && isset(txt)){	// One of the items required for load is not set
			runOnPlayers(pk,
				GUI$toggleSpinner(pk, TRUE, txt);
			)
		}
	}

	
    
    else if(METHOD == LevelMethod$loadFinished){
        llSetTimerEvent(0);
        BFL = BFL&~BFL_LOADING;
        raiseEvent(LevelEvt$loaded, "");
		
		runOnPlayers(pk, 
			Status$loading(pk, FALSE);
            GUI$toggleSpinner(pk, FALSE, "");
		)

    }

    else if(METHOD == LevelMethod$despawn){
        llDie();
    }
	else if(METHOD == LevelMethod$update){
		// Grab script update
		pin = llFloor(llFrand(0xFFFFFFF));
		llSetRemoteScriptAccessPin(pin);
        Remoteloader$load(cls$name, pin, 2);
	}
    
    else if(METHOD == LevelMethod$spawn){
        string asset = method_arg(0);
        vector pos = (vector)method_arg(1);
        rotation rot = (rotation)method_arg(2);
        integer debug = (integer)method_arg(3);
        
        if(llGetInventoryType(asset) == INVENTORY_OBJECT){
            if(debug)llOwnerSay("Spawning local asset: "+asset);
            _portal_spawn_std(asset, pos, rot, <0,0,-8>, debug, FALSE, FALSE);
        }else{
            llOwnerSay("Item '"+asset+"' not found in level. Loading from HUD.");
            Spawner$spawn(asset, pos, rot, "", debug, FALSE);
        }
        
    }
    
    
    

    else if(METHOD == LevelMethod$getScripts){
        integer pin = (integer)method_arg(0);
        list scripts = llJson2List(method_arg(1));
        list_shift_each(scripts, v, 
            if(llGetInventoryType(v) == INVENTORY_NONE){
                llOwnerSay("ERROR: Custom Script '"+v+"' not found!");
            }
            else if(llGetInventoryType(v) == INVENTORY_SCRIPT){
                slave++;
                if(slave>9)slave=1;
                // Remote load
                llMessageLinked(LINK_THIS, slave, llList2Json(JSON_ARRAY, [id, v, pin, 2]), "rm_slave");
            }
            else llGiveInventory(id, v);
            
        )
        
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

