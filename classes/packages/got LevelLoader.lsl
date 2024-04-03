#define USE_DB4
#include "got/_core.lsl"

#define log(text) //llOwnerSay(llGetTimestamp()+" "+text)

// Used for "" loading and reporting
integer BFL;
list WAITING_HUD;				// Groups that are spawning from hud at start of level
list WAITING_LOCAL;				// Groups that are spawning from local at start of level
#define BFL_WAITING_BUFFER 0x1	// When spawning "" a buffer of 5 sec is set to allow for additional custom spawns
#define BFL_WAITING_LOAD 0x2	// Waiting to finish loading

checkIni(){

	if( WAITING_HUD == [] && WAITING_LOCAL == [] && ~BFL&BFL_WAITING_BUFFER && BFL&BFL_WAITING_LOAD ){
		
		qd("Load finished");
		BFL = BFL&~BFL_WAITING_LOAD;
		raiseEvent(LevelLoaderEvt$levelLoaded, "");
		
	}
}

addIni( list groups ){
	
	integer i;
	for(; i < count(groups); ++i ){
		
		list l = llList2List(groups, i, i);
		if( llListFindList(WAITING_HUD, l) == -1 )
			WAITING_HUD += l;
		if( llListFindList(WAITING_LOCAL, l) == -1 )
			WAITING_LOCAL += l;
		
	}
	
}

timerEvent( string id, string data ){

	if( id == "INI" ){
		
		BFL = BFL&~BFL_WAITING_BUFFER;
		checkIni();
		
	}
	
}

default{

    state_entry(){
	
		if( llGetStartParameter() == 2 )
			raiseEvent(evt$SCRIPT_INIT, "");
		
    }
    
	
	timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
	if(method$isCallback){
	
		if( SENDER_SCRIPT == "got Spawner" && (METHOD == SpawnerMethod$spawnThese || METHOD == SpawnerMethod$spawn) ){
		
			if( BFL&BFL_WAITING_LOAD ){
			
				list parse = llJson2List(CB);
				list groups = llJson2List(l2s(parse, 1));
				if( l2s(parse, 0) == "HUD" ){
					
					integer i;
					for(; i < count(groups); ++i ){
						
						int pos = llListFindList(WAITING_HUD, llList2List(groups, i, i));
						if( ~pos ){
							
							WAITING_HUD = llDeleteSubList(WAITING_HUD, pos, pos);
						
						}
						
					}
				
				}
				else if( l2s(parse, 0) == "CUSTOM" ){
				
					integer i;
					for(; i < count(groups); ++i ){
						
						int pos = llListFindList(WAITING_LOCAL, llList2List(groups, i, i));
						if( ~pos ){
							
							WAITING_LOCAL = llDeleteSubList(WAITING_LOCAL, pos, pos);
						
						}
						
					}
				
				}
				
				checkIni();
				
			}
			
			raiseEvent(LevelLoaderEvt$queueFinished, CB);
			
		}
		return;
		
	}
	

	// Spawn the level
    if(METHOD == LevelLoaderMethod$load && method$internal){
	
        integer debug = (integer)method_arg(0);
		list groups = (list)method_arg(1);
		if( llJsonValueType(method_arg(1), []) == JSON_ARRAY )
			groups = llJson2List(method_arg(1));
		
		// Spawning the whole thing if the first group is "" (IE. load live)
		if( l2s(groups, 0) == "" ){
			
			WAITING_HUD = WAITING_LOCAL = [];
			qd("Live was requested" +mkarr(groups));
			BFL = BFL|BFL_WAITING_BUFFER|BFL_WAITING_LOAD;
			multiTimer(["INI", 0, 5, FALSE]);
			
		}
		
		if( BFL&BFL_WAITING_BUFFER )
			addIni(groups);

		integer outHudLen;
		list outHud;				// Data to push to HUD spawner
		integer outLocalLen;
		list outLocal;				// Data to push to local spawner
		list data;					// Asset data
		
        // Spawn things
		LevelAux$forSpawns( total, idx ){
			
			list spdata = LevelAux$getSpawnData(idx);
			list group = llList2List(spdata, 5, 5);
			if( group == [] )
				group = [""];
				
			// This group should be spawned right now
			if( ~llListFindList(groups, group) && spdata != [] ){
				
				string chunk = mkarr((list)
					l2s(spdata, 1) + // Name
					((vector)l2s(spdata, 2)+llGetRootPosition()) + // Pos
					l2s(spdata, 3) + // Rot
					l2s(spdata, 4) + // Desc
					debug +
					FALSE + 
					l2s(spdata, 5) // group
				);
				
				int spawner = l2i(spdata, 0);
				
				// HUD Spawned
				if( !spawner ){
					
					if( llStringLength(chunk)+outHudLen > 480 ){
						
						// Send out
						Spawner$spawnThese(llGetOwner(), outHud);
						outHud = [];
						outHudLen = 0;
						
					}
					
					outHud += chunk;
					outHudLen += llStringLength(chunk);
					
				}
				// Local spawned
				else{
				
					if( llStringLength(chunk)+outLocalLen > 1024 ){
						
						// Send out
						Spawner$spawnThese(LINK_THIS, outLocal);
						outLocal = [];
						outLocalLen = 0;
						
					}
					
					outLocal += chunk;
					outLocalLen += llStringLength(chunk);
				
				}
				
				
			}
			
		
		}
		
		// Spawn the last and add a finish callback
		Spawner$spawnThese(
			llGetOwner(), 
			outHud + mkarr((list)
				"_CB_" + 
				("[\"HUD\","+mkarr(groups)+"]")
			)
		);
		Spawner$spawnThese(
			LINK_THIS, 
			outLocal + mkarr((list)
				"_CB_" + 
				("[\"CUSTOM\","+mkarr(groups)+"]")
			)
		);
		
		
    }
	
	
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

