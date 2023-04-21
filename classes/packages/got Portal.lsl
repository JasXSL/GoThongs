#define USE_DB4
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

list INJ_REQS;				// (key)script, (int)nrScripts - Scripts that are allowed to inject scripts into us using the quick API.

integer BFL;
#define BFL_SCRIPTS_INITIALIZED 1
#define BFL_GOT_PLAYERS 2
#define BFL_IS_DEBUG 4
#define BFL_HAS_DESC 8
#define BFL_INITIALIZED 0x10
#define BFL_PERSISTENT 0x20
#define BFL_INJECTING 0x40		// An active inject request is open

#define BFL_INI 11
//~BFL&BFL_IS_DEBUG && 
#define checkIni() \
	if((BFL&BFL_INI) == BFL_INI && ~BFL&BFL_INITIALIZED){ \
		BFL=BFL|BFL_INITIALIZED; \
		sendPlayers(); \
		raiseEvent(evt$SCRIPT_INIT, mkarr(PLAYERS)); \
		debugUncommon("Raising script init"); \
		raiseEvent(PortalEvt$spawner, (str)requester); \
		raiseEvent(PortalEvt$desc_updated, INI_DATA); \
		llListen(evtChan, "", "", ""); \
		llRegionSay(evtChan, Portal$gEvt$ini); \
	}

// Fetches desc from spawner
#define fetchDesc() llRegionSayTo(spawner, playerChan(spawner), "SP")

string INI_DATA = "";
string SPAWNROUND;
integer REZ_PARAM;
int evtChan;

onEvt( string script, integer evt, list data ){

    if( evt == evt$SCRIPT_INIT && required != [] ){
	
        integer pos = llListFindList(required, [script]);
        if( ~pos )
			required = llDeleteSubList(required, pos-1, pos);
		
		debugUncommon("Waiting for "+mkarr(required));
        if( required == [] ){
		
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
			//qd(BFL);
			debugUncommon("All scripts acquired");
			BFL = BFL|BFL_SCRIPTS_INITIALIZED;
			
			debugUncommon(BFL);
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


handleInjectReq(){
	// Inject is active
	if( BFL&BFL_INJECTING || INJ_REQS == [] )
		return;
	
	key id = l2k(INJ_REQS, 0);
	int cd = l2i(INJ_REQS, 1)*3+3;
	INJ_REQS = llDeleteSubList(INJ_REQS, 0, 1);
	multiTimer(["INJ", 0, cd, FALSE]);
	pin = llFloor(llFrand(0xFFFFFFF));
	llSetRemoteScriptAccessPin(pin);
	BFL = BFL|BFL_INJECTING;
	llRegionSayTo(id, evtChan, Portal$gEvt$inject+(str)pin);
	
}

// Clears access pin and continues the queue
injectDone(){
	BFL = BFL&~BFL_INJECTING;
	llSetRemoteScriptAccessPin(0);
	handleInjectReq();
}


integer pin;

timerEvent( string id, string data ){

	if( id == "INI" )
		Root$getPlayers("INI");
		
	else if( id == "INJ" )
		injectDone();
		
		
	else if( id == "POSTQUERY" ){
	
		if( ~BFL&BFL_INITIALIZED ){
		
			// We have failed
			checkIni();
			
			qd("Portal failed to initialize. BFL was: "+(string)BFL+" & non-initialized was "+mkarr(required));
			// Description is gone for good because simulator fuckery
			if( ~BFL&BFL_HAS_DESC ){
				qd("Fatal error: Description has gone missing in the vast abyss of the simulator.");
				return;
			}
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

sendPlayers(){
	
	string huds = mkarr(PLAYER_HUDS);
	string players = mkarr(PLAYERS);
	
	db4$freplace(portalTable$portal, portalRow$players, players);
	db4$freplace(portalTable$portal, portalRow$huds, players);
	raiseEvent(PortalEvt$playerHUDs, huds);
	raiseEvent(PortalEvt$players, players);
	
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




default{

    on_rez(integer mew){
	
	
		// Let the spawner know it can rez next
		llRegionSayTo(mySpawner(), playerChan(mySpawner()), "PN");
        if( mew ){
		
			integer p = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(p);
            multiTimer([]);
			setText((str)mew);
            Remoteloader$load(cls$name, p, 2);
			return;
			
        }
		setText("");
		
    }
    state_entry(){
	
		evtChan = Portal$evtChan(llGetOwner());
		requester = spawner = mySpawner();
		// Let the spawner know it can rez next
		llRegionSayTo(requester, playerChan(requester), "PN");
		
		
		PLAYERS = [(string)llGetOwner()];
		db4$freplace(portalTable$portal, portalRow$players, mkarr(PLAYERS));
		db4$freplace(portalTable$portal, portalRow$huds, "[]");
		
        initiateListen();
		llListen(AOE_CHAN, "", "", "");
        pin = llCeil(llFrand(0xFFFFFFF));
        llSetRemoteScriptAccessPin(pin);
		Root$getPlayers("INI");
				
        memLim(1.5);
		
        if(!llGetStartParameter())
			return;
		
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
			// Status needs NPCInt which offloads it
			if( llGetInventoryType("got Status") == INVENTORY_SCRIPT )
				required+= [1, "got NPCInt"];
			
			
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
			
			vector p = llGetRootPosition();
			vector pos;
			
			
			// I can't remember what 1 is for but if it's 0 then it's not a region position
			if( mew > 1 )
				pos = p-vecFloor(p)+int2vec(mew);
			// If no position is set then we regard it as debug (got LevelLite relies on this behavior)
			else 
				mew = mew|BIT_DEBUG;
			
			
			llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, FALSE]);
			

			// Checks if pos is actually received
			if( mew&(BIT_DEBUG-1) && pos != ZERO_VECTOR ){

				int att = llSetRegionPos(pos);
				if( !att && !llGetAttached() )
					llOwnerSay("!SIM ERROR! Unable to position asset. Check build and object entry at "+(str)pos);
				
			}
			
			
			debugUncommon("Start params "+(str)mew);
			if( mew&BIT_DEBUG )
				BFL = BFL|BFL_IS_DEBUG;
			else
				multiTimer(["POSTQUERY", "", 30, FALSE]);
				
			if( mew&BIT_GET_DESC ){
			
				// Needs to fetch data from the spawner
				fetchDesc();
				multiTimer(["A", "", 10, TRUE]);	// re-fetching too much might cause problems
				
			}
			else 
				BFL = BFL|BFL_HAS_DESC;
			
			// Build the first config
			list text = [
				pos, 						// Spawn pos
				((~BFL&BFL_IS_DEBUG)>0), 	// Is live
				"", 						// Custom desc data
				""							// Spawnround
			];
			setText(mkarr(text));
			
			// Putting it below will cause trouble with double inits
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
	} \
	if( chan == evtChan ){ \
		if( message == Portal$gTask$get ){ \
			llRegionSayTo(id, evtChan, Portal$gEvt$ini); \
		} \
		/* Owner only tasks */ \
		if( llGetOwnerKey(id) == llGetOwner() ){ \
			/* Post-ini script injections. Useful for HUD mods etc. */ \
			if( llGetSubString(message, 0, 2) == Portal$gTask$inject ){ \
				int nrScripts = (int)llGetSubString(message, 3, -1); \
				if( nrScripts < 1 ) \
					nrScripts = 1; \
				INJ_REQS += (list)id + nrScripts; \
				handleInjectReq(); \
			} \
			else if( message == Portal$gTask$injectDone && id == l2k(INJ_REQS, 0) ){ \
				injectDone(); \
			} \
		} \
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
        
        if( SENDER_SCRIPT == "#ROOT" && METHOD == RootMethod$getPlayers && CB == "INI" ){
		
			
            PLAYERS = llJson2List(method_arg(0));
			PLAYER_HUDS = llJson2List(method_arg(1));
			debugUncommon("Got players "+mkarr(PLAYERS));
			debugUncommon("Got HUDS "+mkarr(PLAYER_HUDS));
			

			sendPlayers();
			if( llGetStartParameter() != 2 )
				return;
				
			//qd("PLAYERS from root: "+mkarr(PLAYERS));
			multiTimer(["INI"]);
			BFL = BFL|BFL_GOT_PLAYERS;
			debugUncommon(BFL);
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
			
			sendPlayers();
			
		}
		else if(METHOD == PortalMethod$remove && 
			(
				(	
					(
						llGetInventoryType("got LevelLite") == INVENTORY_NONE || 
						REZ_PARAM
					) && 
					~BFL&BFL_PERSISTENT &&
					(
						llAvatarOnSitTarget() == NULL_KEY ||
						llGetInventoryType("got AnimeshScene") == INVENTORY_NONE
					)
				) || 
				l2i(PARAMS, 0)
			)
		){
			remove();
        }
		
		else if(METHOD == PortalMethod$resetAll){
		
			qd("Resetting everything");
			setText("");
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
			qd("Updating and setting live");
			vector g = llGetRootPosition();
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
			if( desc != "" ){
			
				if( BFL&BFL_IS_DEBUG )
					desc = "$"+desc;
				
				llSetObjectDesc(desc);
				if( llJsonValueType(INI_DATA, []) == JSON_ARRAY ){
				
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
			
			Root$getPlayers("INI");
			qd(mkarr(PLAYERS));			
			
		}
		else if(METHOD == PortalMethod$removeBySpawnround && method_arg(0) == SPAWNROUND){
			remove();
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

