#define USE_DB4
#define USE_EVENTS
#define SCRIPT_IS_ROOT
#define ALLOW_USER_DEBUG 1
#include "../../_core.lsl"

#define RQSTRIDE 2
list remoted;				// List of scripts that we have remoteloaded
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

#define BFL_INITIALIZED 0x10
#define BFL_PERSISTENT 0x20
#define BFL_INJECTING 0x40		// An active inject request is open

#define BFL_NEED_ACK 0x100		// We need to send an ack to our rezzer

#define BFL_INI (BFL_SCRIPTS_INITIALIZED|BFL_GOT_PLAYERS)
//~BFL&BFL_IS_DEBUG && 
checkIni(){

	if( (BFL&BFL_INI) == BFL_INI && ~BFL&BFL_INITIALIZED ){
	
		BFL=BFL|BFL_INITIALIZED;
		sendPlayers(); 
		raiseEvent(evt$SCRIPT_INIT, mkarr(PLAYERS)); 
		debugUncommon("Raising script init"); 
		raiseEvent(PortalEvt$spawner, (str)requester);
		raiseEvent(PortalEvt$desc_updated, INI_DATA); 
		llListen(evtChan, "", "", ""); 
		llRegionSay(evtChan, Portal$gEvt$ini); 
		Remoteloader$portalInit( remoted ); 
		multiTimer(["POSTQUERY"]);
		
	}
	
}

	
#define shortUUID() \
	llGetSubString((str)llGetKey(), 0, 3)

string INI_DATA = "";
string SPAWNROUND;
int evtChan;
int NO_REMOTE;

onEvt( string script, integer evt, list data ){


    if( evt == evt$SCRIPT_INIT && required != [] ){
	
        integer pos = llListFindList(required, (list)script);
        if( ~pos ){
			
			required = llDeleteSubList(required, pos-1, pos);
			remoted += script;
			
		}
		debugUncommon("[Ini "+shortUUID()+"] Waiting for "+mkarr(required));
        if( required == [] ){
		
			//qd(BFL);
			debugUncommon("[Ini "+shortUUID()+"] All scripts acquired");
			BFL = BFL|BFL_SCRIPTS_INITIALIZED;
			sendAck();
			debugUncommon(BFL);
			checkIni();
			
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

// Ack is sent to our spawner when we have loaded all scripts
sendAck(){
	
	if( ~BFL&BFL_NEED_ACK )
		return;
	
	if( !ackListen )
		ackListen = llListen(SpawnerConst$ACK_CHAN+1, "", mySpawner(), "ACK");
	llRegionSayTo(mySpawner(), SpawnerConst$ACK_CHAN, "ACK");
	multiTimer(["ACK", 0, 1, FALSE]);

}


integer pin;
int pqAttempts;

timerEvent( string id, string data ){

	if( id == "INI" )
		Root$getPlayers("INI");
		
	else if( id == "INJ" )
		injectDone();
		
	// Tries to make sure that we have been initialized
	else if( id == "POSTQUERY" ){
	
		checkIni();
		
		// We have failed
		if( ~BFL&BFL_INITIALIZED ){
		
			++pqAttempts;
			if( pqAttempts == 6 ){ // Give it 1 minute
				
				qd("Item failed to initialize in a timely fashion. If you get this message a lot you may want to try a sim restart.");
				qd("BFL was: "+(string)BFL+" & non-initialized was "+mkarr(required));
				
			}
			
			// Players can be refetched
			if( ~BFL&BFL_GOT_PLAYERS )
				Root$getPlayers("INI");
				
			// Scripts can be refetched
			if( ~BFL&BFL_SCRIPTS_INITIALIZED )
				fetchRequired();
				
			multiTimer([id, "", 10, FALSE]);
			
		}
		
	}
	
	else if( id == "ACK" )
		sendAck();
	
	// Workaround for SL bad listeners
	else if( id == "REREZ" ){
	
		integer p = llCeil(llFrand(0xFFFFFFF));
		llSetRemoteScriptAccessPin(p);
		Remoteloader$load(cls$name, p, 2, FALSE); // Note: This may be dropped
		multiTimer([id, 0, 10, FALSE]);
		
	} 

}

// Fetches required scripts
fetchRequired(){
	
	integer i; list fromHUD; list fromLevel;
	for( ; i<count(required); i += 2){
		
		if( l2i(required, i) )
			fromHUD += l2s(required, i+1);
		else 
			fromLevel += l2s(required, i+1);
			
	}
	
	if( fromHUD )
		Remoteloader$load(mkarr(fromHUD), pin, 2, NO_REMOTE);
	if( fromLevel )
		gotLevelData$getScripts(requester, pin, mkarr(fromLevel));

}

sendPlayers(){
	
	string huds = mkarr(PLAYER_HUDS);
	string players = mkarr(PLAYERS);
	
	db4$freplace(gotTable$portal, portalRow$players, players);
	db4$freplace(gotTable$portal, portalRow$huds, huds);
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

attemptPos( vector pos ){
	int att = llSetRegionPos(pos);
	if( !att && !llGetAttached() )
		llOwnerSay("!SIM ERROR! Unable to position asset. Check build and object entry at "+(str)pos);
}

integer LIVE;

#define isLive() LIVE

integer ackListen;

default{

    on_rez(integer mew){
	
        if( mew ){
			
            multiTimer(["REREZ", 0, 0.1, FALSE]);
			setText((str)mew);
			return;
			
        }
		setText("");
		
    }
	
	// we do not reset on rez. This is only run when manually reset or when remoteloaded
    state_entry(){
	
		debugCommon("[Ini "+shortUUID()+"] State entry");
		evtChan = Portal$evtChan(llGetOwner());
		requester = spawner = mySpawner();		
		
		PLAYERS = [(string)llGetOwner()];
		db4$freplace(gotTable$portal, portalRow$players, mkarr(PLAYERS));
		db4$freplace(gotTable$portal, portalRow$huds, "[]");
		
        initiateListen();
		llListen(AOE_CHAN, "", "", "");
		
		
        pin = llCeil(llFrand(0xFFFFFFF));
        llSetRemoteScriptAccessPin(pin);
		Root$getPlayers("INI");
		
		if( !llGetStartParameter() )
			return;
		
		list desc = llJson2List(llGetStartString());
		LIVE = ((llGetStartParameter()&~1) == 2); // bit 2 marks it as live (this script was fetched from HUD). it does not mean that the monster should attack
		
        if( LIVE ){
			
			NO_REMOTE = (llGetStartParameter() == 3); // Legacy. Prevents deferred loading.
		
			// Find required objects
			int i;
			list refresh = PORTAL_SEARCH_OBJECTS;
			list get_objects;
			while( count(refresh) ){
			
				string val = llList2String(refresh,0); 
				refresh = llDeleteSubList(refresh,0,0);  
				if( llGetInventoryType(val) != INVENTORY_NONE ){ 
				
					llRemoveInventory(val); 
					get_objects += val;
					
				}
				
			}
		
            // Request scripts that can be updated from HUD
            list check = PORTAL_SEARCH_SCRIPTS;
            for( i = 0; i < count(check); ++i ){
			
				str val = l2s(check, i);
                if( llGetInventoryType(val) == INVENTORY_SCRIPT )
                    required += (list)1 + val;
                
            }
			
			
			// Required together
			if( llGetInventoryType("got LevelLite") == INVENTORY_SCRIPT )
				required+= [1, "got LevelData"];
				
			// Status needs NPCInt which offloads it
			if( llGetInventoryType("got Status") == INVENTORY_SCRIPT )
				required+= [1, "got NPCInt"];
			

			
			debugUncommon("[Ini  "+shortUUID()+"] Requested scripts "+mkarr(required));
			
			
			INI_DATA = l2s(desc, 4); // custom spawn desc
			vector pos = (vector)l2s(desc, 0);
			SPAWNROUND = l2s(desc, 2);
			
			// Modern
			if( desc ){
			
				integer spFlags = l2i(desc, 1);
				if( spFlags & PortalRezFlag$dummy ){
					BFL = BFL|BFL_IS_DEBUG;
				}
				if( spFlags & PortalRezFlag$ack )
					BFL = BFL|BFL_NEED_ACK;
				
				requester = l2s(desc, 3);
				
				if( pos )
					attemptPos(pos);
				
				string desc = INI_DATA;

				if( desc ){
				
					if( BFL&BFL_IS_DEBUG )
						desc = "$"+desc;
					
					llSetObjectDesc(desc);
					if( llJsonValueType(INI_DATA, []) == JSON_ARRAY ){
					
						list ini = llJson2List(INI_DATA);
						integer i;
						for( ; i<llGetListLength(ini) && ini != []; ++i ){
						
							list v = llJson2List(llList2String(ini, i));
							string task = llList2String(v, 0);
							if( task == "SC" || task == "PR" || task == "HSC" ){
							
								v = llDeleteSubList(v, 0, 0);
								// Make sure there's actually an asset
								if( v ){
								
									// Only add to required ini if it's scripts
									if( task == "SC" || task == "HSC" ){
									
										integer n;
										for( ; n < count(v); ++n ){
										
											string val = llList2String(v, n);
											if( llListFindList(required, [val]) == -1 )
												required+=[
													task == "HSC",		// From HUD
													val					// Name
												];
												
										}
										
									}
									/*
									if( task == "HSC" )
										Remoteloader$load(mkarr(v), pin, 2, NO_REMOTE);
									*/
									else
										gotLevelData$getScripts(requester, pin, mkarr(v)); // Requests prims
									
									
								}
								// Remove this from data that is sent out, since we only need to send monster/status specific stuff
								ini = llDeleteSubList(ini, i, i);
								i--;
								
							}
							
						}
						
						INI_DATA = mkarr(ini);
						
					}
					
				}

			}
			// Legacy
			else{
			
				int startParams = l2i(llGetPrimitiveParams([PRIM_TEXT]), 0);
				
				llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, startParams&BIT_TEMP]); // Legacy
				startParams = startParams & ~BIT_TEMP;
				int hasDesc = startParams & BIT_GET_DESC;
				
				// legacy positioning
				if( !hasDesc ){
				
					vector p = llGetRootPosition();

					// I can't remember what 1 is for but if it's 0 then it's not a region position
					if( startParams > 1 )
						pos = p-vecFloor(p)+int2vec(startParams);
					// If no position is set then we regard it as debug (got LevelLite relies on this behavior)
					else 
						startParams = startParams|BIT_DEBUG;

					
					// Checks if pos is actually received
					if( pos != ZERO_VECTOR )
						attemptPos(pos);
						
					if( startParams&BIT_DEBUG )
						BFL = BFL|BFL_IS_DEBUG;
						
				}
					
			}
			
			fetchRequired();
			//Remoteloader$load( mkarr(llList2ListStrided(llDeleteSubList(required, 0, 0), 0, -1, 2)), pin, 2, NO_REMOTE );
			
			// Before LSD we relied on using prim text. These settings are still provided for legacy reasons.
			// Build the first config
			integer live = (~BFL&BFL_IS_DEBUG)>0;
			list text = [
				pos, 						// Spawn pos
				live, 	// Is live
				INI_DATA, 					// Custom desc data
				SPAWNROUND					// Spawnround
			];
			setText(mkarr(text));
			
			db4$freplace(gotTable$portal, portalRow$desc, INI_DATA);
			db4$freplace(gotTable$portal, portalRow$pos, (str)pos);
			db4$freplace(gotTable$portal, portalRow$live, (str)live);
			db4$freplace(gotTable$portal, portalRow$group, SPAWNROUND);
			db4$freplace(gotTable$portal, portalRow$spawner, requester);
			
			
			multiTimer(["INI", "", 5, TRUE]);
			
			for( i = 0; i < count(get_objects); ++i ){
				
				Spawner$getAsset(l2s(get_objects, i));
				
			}
			
        } 
		
        if( required == [] ){
            BFL = BFL|BFL_SCRIPTS_INITIALIZED;
			sendAck();
		}
		else
			multiTimer(["POSTQUERY", 0, 10, TRUE]); // Try to refetch if it fails
		checkIni();
		
		
    }
    
    timer(){
		multiTimer([]);
    }
    
	#define LISTEN_LIMIT_FREETEXT \
	if( chan == SpawnerConst$ACK_CHAN+1 ){ \
		multiTimer(["ACK"]); \
		llListenRemove(ackListen); \
		return; \
	} \
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
			debugUncommon("[Ini "+shortUUID()+"] Players "+mkarr(PLAYERS));
			debugUncommon("[Ini "+shortUUID()+"] Got HUDS "+mkarr(PLAYER_HUDS));
			

			sendPlayers();
			
			if( !isLive() )
				return;
				
			//qd("PLAYERS from root: "+mkarr(PLAYERS));
			multiTimer(["INI"]);
			BFL = BFL|BFL_GOT_PLAYERS;
			checkIni();
			
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
			
			Remoteloader$load(cls$name, p, nr, TRUE);
			
        }
			
		else if( METHOD == PortalMethod$remoteLoad ){
			
			llRemoteLoadScriptPin(
				method_arg(0), 		// targ,
				method_arg(1),		// script name
				l2i(PARAMS, 2),		// pin
				TRUE,				// Running
				l2i(PARAMS, 3)		// Start param
			);
			
		}
		
		else if( METHOD == PortalMethod$sendPlayers ){
			
			sendPlayers();
			
		}
		else if( METHOD == PortalMethod$remove && 
			(
				(	
					(
						llGetInventoryType("got LevelLite") == INVENTORY_NONE || 
						Portal$getLive()
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
			if( method_arg(0) == requester ){
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
            Remoteloader$load(cls$name, p, 3, TRUE);
			
		}
		else if(METHOD == PortalMethod$debugPlayers){
			
			Root$getPlayers("INI");
			qd(mkarr(PLAYERS));			
			
		}
		else if( METHOD == PortalMethod$removeBySpawnround && method_arg(0) == SPAWNROUND ){
			remove();
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

