#define USE_EVENTS
#define SCRIPT_IS_ROOT
#define ALLOW_USER_DEBUG 1
#include "../../_core.lsl"

#define RQSTRIDE 2
list required;				// [(bool)fromHUD, (str)script]
list PLAYERS;
list PLAYER_HUDS;

key spawner;				// Key of prim that spawned me
key requester;				// Key of priom that requested this spawn. Can be "" if internal from the HUD, and can be same as spawner. Defaults to spawner

integer BFL;
#define BFL_SCRIPTS_INITIALIZED 1
#define BFL_GOT_PLAYERS 2
#define BFL_IS_DEBUG 4
#define BFL_HAS_DESC 8
#define BFL_INITIALIZED 0x10
#define BFL_PERSISTENT 0x20

#define BFL_INI 11
#define checkIni() if((BFL&BFL_INI) == BFL_INI && ~BFL&BFL_IS_DEBUG && ~BFL&BFL_INITIALIZED){BFL=BFL|BFL_INITIALIZED; raiseEvent(evt$SCRIPT_INIT, mkarr(PLAYERS)); raiseEvent(PortalEvt$spawner, (str)requester); raiseEvent(PortalEvt$desc_updated, INI_DATA); raiseEvent(PortalEvt$playerHUDs, mkarr(PLAYER_HUDS)); }

// Fetches desc from spawner
#define fetchDesc() llRegionSayTo(spawner, playerChan(spawner), "SP")

string INI_DATA = "";
string SPAWNROUND;
integer REZ_PARAM;

onEvt( string script, integer evt, list data ){

    if( evt == evt$SCRIPT_INIT && required != [] ){
	
        integer pos = llListFindList(required, [script]);
        if( ~pos )
			required = llDeleteSubList(required, pos-1, pos);
		
		debugUncommon("Waiting for "+mkarr(required));
        if( required == [] ){
		
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
			//qd(BFL);
			BFL = BFL|BFL_SCRIPTS_INITIALIZED;
			checkIni() 
			
        }
		
    }
	
}

/*
	On rez prim text gets set to integer mew
	Then it gets changed to [(vec)startPos, (int)debug, (var)start_data]
	Start data is set up by the prim's description when buliding the level

*/
#define getText() llList2String(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]), 0)
#define setText(data) llSetText(data, ZERO_VECTOR, 0)

integer pin;

timerEvent( string id, string data ){

	if( id == "INI" )
		Root$getPlayers("INI");
		
	else if( id == "POSTQUERY" ){
	
		if( ~BFL&BFL_INITIALIZED ){
		
			// We have failed
			checkIni();
			
			qd("Portal failed to initialize. BFL was: "+(string)BFL+" & non-initialized was "+mkarr(required));
			// Description is gone for good because simulator fuckery
			if( ~BFL&BFL_HAS_DESC )
				return qd("Fatal error: Description has gone missing in the vast abyss of the simulator.");
			// Players can be refetched
			if( ~BFL&BFL_GOT_PLAYERS )
				Root$getPlayers("INI");
			// Scripts can be refetched
			if( ~BFL&BFL_SCRIPTS_INITIALIZED ){
				
				integer i; list fromHUD; list fromLevel;
				for(i=0; i<llGetListLength(required); i+=2){
					if(llList2Integer(required, i))fromHUD+= llList2String(required, i+1);
					else fromLevel+= llList2String(required, i+1);
				}
				
				if(fromHUD)
					Remoteloader$load(mkarr(fromHUD), pin, 2);
				if(fromLevel){
					gotLevelData$getScripts(requester, pin, mkarr(fromLevel));
				}
			}
			multiTimer([id, "", 60, FALSE]);
			
		}
		
	}
	
	else if( id == "A" )
		fetchDesc();
	
}

// Removes this and anything spawned by this if this was a sub level
remove(){
	// Sub levels should also remove their spawned content
	if(llGetInventoryType("got LevelLite") != INVENTORY_NONE){
		Portal$removeSpawnedByThis();
		llSleep(3);
	}
    llDie();
}

default
{
    on_rez(integer mew){
        if(mew != 0){
			integer p = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(p);
			setText((string)mew);
            multiTimer([]);
            Remoteloader$load(cls$name, p, 2);
			return;
        }
        llResetScript();
    }
    state_entry()
    {
	
		requester = mySpawner();
		PLAYERS = [(string)llGetOwner()];
        initiateListen();
		llListen(AOE_CHAN, "", "", "");
        pin = llCeil(llFrand(0xFFFFFFF));
        llSetRemoteScriptAccessPin(pin);
		spawner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);

        if(!llGetStartParameter())return;
		
		
        if( llGetStartParameter() == 2 ){
		
			list refresh = PORTAL_SEARCH_OBJECTS;
			list get_objects;
			while(llGetListLength(refresh)){
				string val = llList2String(refresh,0); 
				refresh = llDeleteSubList(refresh,0,0);  
				if(llGetInventoryType(val) != INVENTORY_NONE){ 
					llRemoveInventory(val); 
					get_objects += val;
				} 
			}
		
            // Request
            list check = PORTAL_SEARCH_SCRIPTS;
            list_shift_each(check, val,
			
                if(llGetInventoryType(val) == INVENTORY_SCRIPT)
                    required+=([1, val]);
                
            )
			
			// Required together
			if( llGetInventoryType("got LevelLite") == INVENTORY_SCRIPT )
				required+= [1, "got LevelData"];
			
			check = PORTAL_SEARCH_OBJECTS;
			list_shift_each(check, val,
				if(llGetInventoryType(val) != INVENTORY_NONE){
					llRemoveInventory(val);
				}
			)
			
			Remoteloader$load(mkarr(llList2ListStrided(llDeleteSubList(required, 0, 0), 0, -1, 2)), pin, 2);
			debugUncommon("Waiting for "+mkarr(required));
			
			
			
			integer mew = llList2Integer(llGetPrimitiveParams([PRIM_TEXT]), 0)&~BIT_TEMP;
			REZ_PARAM = mew;
			
			vector p = llGetPos();
			vector pos;
			
			
			// I can't remember what 1 is for but if it's 0 then it's not a region position
			if(mew > 1)
				pos = p-vecFloor(p)+int2vec(mew);
			// If no position is set then we regard it as debug (got LevelLite relies on this behavior)
			else 
				mew = mew|BIT_DEBUG;
			
			// Checks if pos is actually received
			if( mew&(BIT_DEBUG-1) )
				llSetRegionPos(pos);
			
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
			
			if( mew&BIT_DEBUG )
				BFL = BFL|BFL_IS_DEBUG;
			else
				multiTimer(["POSTQUERY", "", 30, FALSE]);
				
			if(mew&BIT_GET_DESC){
				// Needs to fetch data from the spawner
				fetchDesc();
				multiTimer(["A", "", 2, TRUE]);
			}
			else 
				BFL = BFL|BFL_HAS_DESC;
			
			// Build the first config
			list text = [
				pos, 						// Spawn pos
				((BFL&BFL_IS_DEBUG)>0), 	// Is live
				"", 						// Custom desc data
				""							// Spawnround
			];
			setText(mkarr(text));
			
			// Putting it below will cause trouble with double inits
			Root$getPlayers("INI");
			multiTimer(["INI", "", 5, TRUE]);
			
			list_shift_each(get_objects, val,
				Spawner$getAsset(val);
			)
        } 
        if(required == []){
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
            BFL = BFL|BFL_SCRIPTS_INITIALIZED;
            checkIni()
        }
		
		
        memLim(1.5);
    }
    
    timer(){
		multiTimer([]);
    }
    
	#define LISTEN_LIMIT_FREETEXT \
	if( \
		llListFindList(PLAYERS, [(string)llGetOwnerKey(id)]) == -1 && \
		llList2String(PLAYERS, 0) != "*" && \
		llGetOwnerKey(id) != llGetOwner() \
	){ \
		return; \
	}
	
    #include "xobj_core/_LISTEN.lsl"
    
    //#define LM_PRE qd("Got string: "+s);
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
        
        if(SENDER_SCRIPT == "#ROOT" && METHOD == RootMethod$getPlayers && CB == "INI" && llGetStartParameter() == 2){
            PLAYERS = llJson2List(method_arg(0));
			//qd("PLAYERS from root: "+mkarr(PLAYERS));
			multiTimer(["INI"]);
			BFL = BFL|BFL_GOT_PLAYERS;
			PLAYER_HUDS = llJson2List(method_arg(1));
			checkIni()
        } 
        return;
    }
    
    if(method$byOwner){
	
	
        if( METHOD == PortalMethod$reinit ){
		
            qd("Reinitializing");
			
            integer p = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(p);
            integer nr = 2;
			if( (integer)method_arg(0) )
				nr = 3;	// Use a positive int to just update without initializing
			
			Remoteloader$load(cls$name, p, nr);
			
        }
		else if( METHOD == PortalMethod$sendPlayers ){
			
			raiseEvent(PortalEvt$playerHUDs, mkarr(PLAYER_HUDS));
			raiseEvent(PortalEvt$players, mkarr(PLAYERS));
			
		}
		else if(METHOD == PortalMethod$remove && 
			(
				(	
					(
						llGetInventoryType("got LevelLite") == INVENTORY_NONE || 
						REZ_PARAM
					) && 
					~BFL&BFL_PERSISTENT
				) || 
				l2i(PARAMS, 0)
			)
		){
			remove();
        }
		else if(METHOD == PortalMethod$resetAll){
			qd(xme(XLS(([
				XLS_EN, "Resetting everything"
			]))));
			resetAll();
		}
		else if(METHOD == PortalMethod$removeBySpawner){
			if(method_arg(0) == requester){
				llDie();
			}
		}
		else if(METHOD == PortalMethod$persistence){
			if(l2i(PARAMS, 0))
				BFL = BFL|BFL_PERSISTENT;
			else
				BFL = BFL&~BFL_PERSISTENT;
		}			
		else if(METHOD == gotMethod$setHuds){
			
			PLAYER_HUDS = PARAMS;
			PLAYERS = [];
			runOnHUDs(targ,
				PLAYERS += (str)llGetOwnerKey(targ);
			)
			
			Portal$sendPlayers();
			
		}
		
		// Forces the portal to load as if it was live
		else if(METHOD == PortalMethod$forceLiveInitiate){
			qd(xme(XLS(([
				XLS_EN, "Updating and setting live"
			]))));
			vector g = llGetPos();
			integer in = vec2int(g);
			integer p = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(p);
			setText((string)in);
            multiTimer([]);
            Remoteloader$load(cls$name, p, 2);
		}
		
		else if(METHOD == PortalMethod$iniData && ~BFL&BFL_HAS_DESC && llGetStartParameter() == 2){
			INI_DATA = method_arg(0);
			SPAWNROUND = method_arg(1);
			requester = method_arg(2);
			
			// Tell the spawner to continue
			llRegionSayTo(spawner, playerChan(spawner), "DN");
			// Stop asking for description
			multiTimer(["A"]);
			
			string desc = INI_DATA;
			if(desc != ""){
				if(BFL&BFL_IS_DEBUG)desc = "$"+desc;
				llSetObjectDesc(desc);
				if(llJsonValueType(INI_DATA, []) == JSON_ARRAY){
					list ini = llJson2List(INI_DATA);
					integer i;
					for(i=0; i<llGetListLength(ini) && ini != []; i++){
						list v = llJson2List(llList2String(ini, i));
						string task = llList2String(v, 0);
						if( task == "SC" || task == "PR" || task == "HSC" ){
							v = llDeleteSubList(v, 0, 0);
							// Make sure there's actually an asset
							if(v != []){
								// Only add to required ini if it's scripts
								if(task == "SC" || task == "HSC"){
									BFL=BFL&~BFL_SCRIPTS_INITIALIZED;
									integer i;
									for(i=0; i<llGetListLength(v); i++){
										string val = llList2String(v, i);
										if(llListFindList(required, [val]) == -1)
											required+=[
												task == "HSC",		// From HUD
												val					// Name
											];
									}
								}
								
								if(task == "HSC"){
									Remoteloader$load(mkarr(v), pin, 2);
								}
								else
									gotLevelData$getScripts(requester, pin, mkarr(v));
							}
							// Remove this from data that is sent out, since we only need to send monster/status specific stuff
							ini = llDeleteSubList(ini, i, i);
							i--;
						}
					}
					INI_DATA = mkarr(ini);
				}
			}
			BFL = BFL|BFL_HAS_DESC;
			list get = llJson2List(getText());
			get = llListReplaceList(get, [INI_DATA], 2, 2);
			get = llListReplaceList(get, [SPAWNROUND], 3, 3);
			setText(mkarr(get));
			
			
			checkIni()
		}
		else if(METHOD == PortalMethod$debugPlayers){
			qd(mkarr(PLAYERS));
		}
		else if(METHOD == PortalMethod$removeBySpawnround && method_arg(0) == SPAWNROUND){
			remove();
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

