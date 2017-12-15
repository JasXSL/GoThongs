#define SCRIPT_IS_ROOT
#define USE_EVENTS
#define ALLOW_USER_DEBUG 1
#include "got/_core.lsl"


list PLAYERS = [];
list PLAYERS_COMPLETED;
list PLAYERS_HUDS;	 // Should match PLAYERS

integer START_PARAM;

//#define sqd(text) qd(text)
#define sqd(text) 

// These are generally only relevant in challenge mode
integer DIFFICULTY;  			
integer CHALLENGE;

integer pin;
integer DEATHS;

integer BFL;
#define BFL_MONSTERS_LOADED 0x1
#define BFL_ASSETS_LOADED 0x2
#define BFL_LOADING 0x4
#define BFL_SCRIPTS_LOADED 0x8
#define BFL_INI 0x10
#define BFL_LOAD_REQ (BFL_MONSTERS_LOADED|BFL_ASSETS_LOADED)
// Prevents auto load from running multiple times when the level is rezzed live
#define BFL_AUTOLOADED 0x40

#define BFL_WIPE_TRACKER 0x80 // enables the wipe tracker
#define BFL_WIPED 0x100		// Unable to finish the quest

// Required additional spawn groups before completing
list SPAWNS_REQ = [];

list LOADQUEUE = REQUIRE;			// Required scripts to be remoteloaded
list LOAD_ADDITIONAL = [];			// Scripts from description we need to wait for

#define onEvt(script, evt, data) \
	if(evt == evt$SCRIPT_INIT && ~BFL&BFL_INI){ \
		integer pos = llListFindList(LOADQUEUE, [script]); \
		if(~pos){ \
			LOADQUEUE = llDeleteSubList(LOADQUEUE, pos, pos); \
			if(LOADQUEUE == []){ /* These are base scripts that get fetched first */ \
				db3$set([LevelShared$isSharp], (string)START_PARAM); \
				raiseEvent(evt$SCRIPT_INIT, (str)pin);			  \
				sqd("INI raised");\
			}  \
		} \
		pos = llListFindList(LOAD_ADDITIONAL, [script]); \
		if(~pos){ \
			LOAD_ADDITIONAL = llDeleteSubList(LOAD_ADDITIONAL, pos, pos); \
		} \
		if(LOADQUEUE+LOAD_ADDITIONAL == [] && ~BFL&BFL_INI){ \
			/* All scripts have been initialized, fetch players and begin loading */ \
			sqd(">> All scripts are now initialized <<"); \
			Alert$freetext(llGetOwner(), "Loading from HUD", FALSE, FALSE); \
			Root$setLevel(); \
			BFL = BFL|BFL_INI; \
		} \
	} \
	 \
	if(script == "got LevelLoader" && evt == LevelLoaderEvt$defaultStatus){ \
		integer assets = l2i(data, 0); \
		integer spawns = l2i(data, 1); \
		if(!assets){ \
			Level$loaded(LINK_THIS, 0); \
		} \
		if(!spawns){ \
			Level$loaded(LINK_THIS, 1); \
		} \
		if(assets || spawns){ \
			multiTimer(["LOAD_FINISH", "", 60, FALSE]); \
		} \
	}
	
	


timerEvent(string id, string data){

	if(id == "INI"){
		if(~BFL&BFL_INI){
			qd("ERROR: Could not update. Make sure you are wearing the GoT HUD.");
		}
		Root$setLevel();
	}
	
	else if(id == "LOAD_FINISH"){
		Level$loadFinished();
		Root$setLevel();
	}
	
	else if(id == "WIPE"){
	
		BFL = BFL&~BFL_WIPED;
		DEATHS = 0;
		Portal$killAll();
		multiTimer(["RESTART", "", 2, FALSE]);
		runOnPlayers(targ,
			Status$fullregenTarget(targ);
		)
	}
	
	else if( id == "RESTART" )
		runMethod((string)LINK_THIS, cls$name, LevelMethod$load, [FALSE], TNN);
	

}


default
{

    on_rez(integer mew){
	
        llSetText((string)mew, ZERO_VECTOR, 0);
		pin = floor(llFrand(0xFFFFFFF));
		llSetRemoteScriptAccessPin(pin);
        Remoteloader$load(cls$name, pin, 2);
		llResetScript();
		
    }
    
    state_entry(){
		
		// resetAllOthers();
		
		initiateListen();
		PLAYERS = [(string)llGetOwner()];
		
		// Rez param
		START_PARAM = llList2Integer(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]), 0);
		
		// On remoteload
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
			
			vector p = llGetPos();
			vector pos = p-vecFloor(p)+int2vec(START_PARAM);
			
			if(START_PARAM == 1)pos = ZERO_VECTOR;

			if(START_PARAM&(BIT_DEBUG-1))llSetRegionPos(pos);
			
			list refresh = ["Trigger", "TriggerSensor"];
			while(llGetListLength(refresh)){
			
				string val = llList2String(refresh,0); 
				refresh = llDeleteSubList(refresh,0,0);  
				if(llGetInventoryType(val) != INVENTORY_NONE){ 
					llRemoveInventory(val); 
					llSleep(.1); 
				} 
				Spawner$getAsset(val);
				
			}
			
			pin = floor(llFrand(0xFFFFFFF));
			llSetRemoteScriptAccessPin(pin);
			
			Remoteloader$load(mkarr(LOADQUEUE), pin, 2);
			
			// Add custom scripts that need to init
			if(llJsonValueType(llGetObjectDesc(), []) == JSON_ARRAY){
				list d = llJson2List(llGetObjectDesc());
				list_shift_each(d, val,
					list v = llJson2List(val);
					integer type = l2i(v, 0);
					v = llDeleteSubList(v, 0,0);
					
					// Custom scripts
					if(type == LevelDesc$additionalScripts){
						list_shift_each(v, script,
							if(llListFindList(LOAD_ADDITIONAL, [script]) == -1){
								LOAD_ADDITIONAL += script;
							}
						)
					}
					
				)
			}
			
			return;
        }
		multiTimer(["INI", "", 5, FALSE]);
		
    }
    
    timer(){
		multiTimer([]);
    }

    #define LISTEN_LIMIT_FREETEXT \
	if( \
		llListFindList(PLAYERS, [(string)llGetOwnerKey(id)]) == -1 && \
		llGetOwnerKey(id) != llGetOwner() \
	){ \
		return; \
	} \

    #include "xobj_core/_LISTEN.lsl"
    
	
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
	// Spawn the level, this goes first as it's fucking memory intensive
    if(METHOD == LevelMethod$load && method$byOwner){
	
		integer debug = (integer)method_arg(0);
		string group = method_arg(1);
		
        raiseEvent(LevelEvt$load, mkarr(([debug, group])));

		// Things to run on level start
		if(group == ""){
		
			BFL = BFL&~BFL_MONSTERS_LOADED;
			BFL = BFL&~BFL_ASSETS_LOADED;
			BFL = BFL|BFL_LOADING;
			
			multiTimer(["LOAD_FINISH", "", 20, FALSE]);
			
			Bridge$getCellData();
			
			vector p1 = (vector)db3$get(cls$name, [LevelShared$P1_start]);
			vector p2 = (vector)db3$get(cls$name, [LevelShared$P2_start]); 
			if(debug){
				if(p1)
					Devtool$spawnAt("_STARTPOINT_P1", p1+llGetPos(), ZERO_ROTATION);
				if(p2)
					Devtool$spawnAt("_STARTPOINT_P2", p2+llGetPos(), ZERO_ROTATION);
			}else{
				// Send player to start
				Alert$freetext(llGetOwner(), "Loading Cell.. Please wait.", FALSE, FALSE);
				
				list positions = [
					p1,
					p2
				];
				
				integer i;
				runOnPlayers(targ,
					vector pos = l2v(positions, i);
					if(pos == ZERO_VECTOR)
						pos = l2v(positions, 0)+(<llCos(PI/4*i), llSin(PI/4*i),0>*.5);
					list tp = ([
						SupportcubeBuildTask(Supportcube$tSetPos, [prPos(targ)]), 
						SupportcubeBuildTask(Supportcube$tDelay, [.1]), 
						SupportcubeBuildTask(Supportcube$tForceSit, ([FALSE, TRUE])), 
						SupportcubeBuildTask(Supportcube$tSetPos, [pos+llGetPos()]), 
						SupportcubeBuildTask(Supportcube$tDelay, [6]), 
						SupportcubeBuildTask(Supportcube$tForceUnsit, [])
					]);
					RLV$cubeTaskOn(targ, tp);
				)
			}
			
			runOnPlayers(pk, 
			
				Root$setLevelOn(pk);
				if(!debug)
					Status$loading(pk, TRUE);
					
			)
			
        }
		
		// These will be run even when loading a custom group
		
		LevelLoader$load(debug, group);
        return;
    }
	
	
	
    if(method$isCallback){
	
		// Players grabbed
        if(
			CB == "LV" && 
			SENDER_SCRIPT == "#ROOT" && 
			llGetOwnerKey(id) == llGetOwner() && 
			llGetStartParameter() == 2 && 
			method$byOwner
		){
            
			PLAYERS = PARAMS;
			if(llList2Key(PLAYERS, 0)){
				// prevents recursion
				if(BFL&BFL_AUTOLOADED)
					return;
					
				BFL = BFL|BFL_AUTOLOADED;
				
				list pnames = [];
				raiseEvent(LevelEvt$players, mkarr(PARAMS));
				
				runOnPlayers(targ,
					
					string n = llGetDisplayName(targ);
					if( n == "" )
						n = "???";
					pnames += n;
					GUI$toggleBoss(targ, "", FALSE);
					Rape$setTemplates(targ, []);
					Root$setLevelOn(targ);
			
				)
				
				multiTimer(["INI"]);
				Alert$freetext(llGetOwner(), "Players: "+implode(", ", pnames), FALSE, FALSE);
				if(START_PARAM){
					runMethod((string)LINK_THIS, cls$name, LevelMethod$load, [FALSE], TNN);
				}
			}
			
        }
        return;
		
    }
	
	

	if( method$internal && METHOD == LevelMethod$raiseEvent )
		raiseEvent(l2i(PARAMS, 0), mkarr(llDeleteSubList(PARAMS, 0, 0)));
	
    
// PUBLIC HERE
    if(METHOD == LevelMethod$interact)
        return raiseEvent(LevelEvt$interact, mkarr(([llGetOwnerKey(id), method_arg(0), method_arg(1)]))); 
    
    if(METHOD == LevelMethod$trigger)
        return raiseEvent(LevelEvt$trigger, mkarr(([method_arg(0), id, method_arg(1)])));   
    
    if(METHOD == LevelMethod$idEvent)
        return raiseEvent(method_arg(0), mkarr(([id, method_arg(1), method_arg(2), method_arg(3)])));
    
	if( METHOD == LevelMethod$getObjectives )
		return raiseEvent(LevelEvt$fetchObjectives, mkarr([llGetOwnerKey(id)]));
	
	if( METHOD == LevelMethod$bindToLevel )
		return Root$setLevelOn(llGetOwnerKey(id));
	
	if( METHOD == LevelMethod$spawn )
		return runMethod((str)LINK_THIS, "got LevelAux", LevelAuxMethod$spawn, PARAMS, TNN);
    
	if(METHOD == LevelMethod$playerInteract)
		return raiseEvent(LevelEvt$playerInteract, mkarr(([llGetOwnerKey(id), method_arg(0)])));
	
	
// OWNER ONLY
	if( method$byOwner && METHOD == gotMethod$setHuds ){
	
		PLAYERS = [];
		integer i;
		for( i=0; i<count(PARAMS); ++i )
			PLAYERS += (str)llGetOwnerKey(l2k(PARAMS, i));
		
		raiseEvent(LevelEvt$playerHUDs, mkarr(PARAMS));
		raiseEvent(LevelEvt$players, mkarr(PLAYERS));
		
	}

	if (METHOD == LevelMethod$getPlayers )
		raiseEvent(LevelEvt$players, mkarr(PLAYERS));
   
    
    if(METHOD == LevelMethod$loaded && BFL&BFL_LOADING && method$byOwner){
	
        integer isHUD = (integer)method_arg(0);
		
        //if(isHUD == 2)BFL = BFL|BFL_SCRIPTS_LOADED;
        if(isHUD)BFL = BFL|BFL_MONSTERS_LOADED;
        else BFL = BFL|BFL_ASSETS_LOADED;
				
        if((BFL&BFL_LOAD_REQ) == BFL_LOAD_REQ){
            Level$loadFinished();
        }
		
    }
	
	if(METHOD == LevelMethod$potionUsed)
		raiseEvent(LevelEvt$potion, mkarr(([llGetOwnerKey(id), method_arg(0)])));
	
	if(METHOD == LevelMethod$potionDropped)
		raiseEvent(LevelEvt$potionDropped, mkarr(([id, method_arg(0)])));
	

    if(METHOD == LevelMethod$loadFinished && BFL&BFL_LOADING && method$byOwner){
		
		multiTimer(["LOAD_FINISH"]);
        BFL = BFL&~BFL_LOADING;
        raiseEvent(LevelEvt$loaded, "");
		
		runOnPlayers(pk, 
			Status$loading(pk, FALSE);
            GUI$toggleSpinner(pk, FALSE, "");
		)

    }

    if(METHOD == LevelMethod$despawn && method$byOwner && START_PARAM != 0)
        llDie();
    
	if(METHOD == LevelMethod$update && method$byOwner){
	
		// Grab script update
		pin = floor(llFrand(0xFFFFFFF));
		llSetRemoteScriptAccessPin(pin);
        Remoteloader$load(cls$name, pin, 2);
		qd("Updating level code...");
		
	}

	// input_method, output_method
    list PROXY_LOADER = [
		LevelMethod$setFinished, gotLevelDataMethod$setFinished,
		LevelMethod$enableWipeTracker, gotLevelDataMethod$enableWipeTracker
	];
	integer pos = llListFindList(llList2ListStrided(PROXY_LOADER, 0, -1, 2), [METHOD]);
	if( method$byOwner && ~pos )
		runMethod((string)LINK_THIS, "got LevelData", l2i(PROXY_LOADER, pos*2+1), PARAMS, TNN);

	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

