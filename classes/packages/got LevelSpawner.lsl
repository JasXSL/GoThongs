#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

vector startPos;

quit(){
    startPos = ZERO_VECTOR;
}

key CURRENT_LEVEL;
int LOADING;
key PRELOADED_TEXTURE;

preloadNewTexture(){
	key texture;
	
	int nrEntries = db4$getIndex(gotTable$loadingScreens);
	int grab = floor(llFrand(nrEntries));
	texture = db4$get(gotTable$loadingScreens, grab);
	if( texture ){}
	else
		texture= DEFAULT_SCREEN;
	
	PRELOADED_TEXTURE = texture;
	llSetTexture(texture, ALL_SIDES);
	
}

toggleLoadingScreen( int visible ){
	
	list textures = [];
	if( visible ){
	
		// Seat the player
		list cubeTasks = (list)
			SupportcubeBuildTask(Supportcube$tSetPos, llGetRootPosition()) + 
			SupportcubeBuildTask(Supportcube$tDelay, .1) + 
			SupportcubeBuildTask(Supportcube$tForceSit, FALSE + TRUE)
		;
		RLV$cubeTaskOn(llGetOwner(), cubeTasks);
		ptSet("LOADED", 20, FALSE);
		GUI$setOverlay(LINK_ALL_OTHERS, PRELOADED_TEXTURE);
		
		preloadNewTexture();
		
		return;
		
	}
	
	
	GUI$setOverlay(LINK_ALL_OTHERS, 1);

}

onEvt(string script, integer evt, list data){


    if( script == "got RootAux" && evt == RootAuxEvt$cleanup ){
	
		integer manual = l2i(data, 0);
        if( manual ){
		
			startPos = ZERO_VECTOR;			
			toggleLoadingScreen(FALSE);
			
		}
		
    }
	
	if( script == "#ROOT" && evt == RootEvt$level ){
		
		CURRENT_LEVEL = l2k(data, 0);
		// Level spawned so lower loading timer
		if( CURRENT_LEVEL )
			ptSet("LOADED", 4, FALSE);
		
	}
	
	if( script == "got Bridge" && evt == BridgeEvt$loadingScreensChanged )
		preloadNewTexture();
		
	
}

ptEvt( string id ){

	if( id == "LOADED" ){
		
		toggleLoadingScreen(FALSE);
		
	}

}

checkPerms(){
	integer i;
	for(; i < llGetInventoryNumber(INVENTORY_OBJECT); ++i ){
		
		str name = llGetInventoryName(INVENTORY_OBJECT, i);
		integer mask = llGetInventoryPermMask(name, MASK_NEXT);
		if( ~mask & PERM_TRANSFER )
			qd("Warning, level '"+name+"' is no trans");
		if( ~mask & PERM_COPY )
			qd("Warning, level '"+name+"' is no copy");
		if( ~mask & PERM_MODIFY )
			qd("Warning, level '"+name+"' is no mod");
		
	}
}

default{

	state_entry(){
		preloadNewTexture();		
		checkPerms();
	}

	timer(){ptRefresh();}
	
	changed( integer change ){
		
		if( ~change & CHANGED_INVENTORY )
			return;
			
		checkPerms();
	
	}
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    
    if(method$isCallback)return;

    if( METHOD == LevelSpawnerMethod$spawnLevel && method$byOwner ){
	
		string level = method_arg(0);
		
		if(llGetInventoryType(level) != INVENTORY_OBJECT){
			qd(level+" not found in the HUD. You may be missing a mod install. Remember that you have to install mods each time you update your HUD!");
			quit();
            return;
        }
		
        if(startPos == ZERO_VECTOR || llVecDist(startPos, llGetRootPosition())>300){
			startPos = llGetRootPosition()+<0,0,8>;
		}
            
		
		// Show loading screen but max 20 seconds
		toggleLoadingScreen(TRUE);
		
		
		runOnDbPlayers(idx, targ,
			if( targ != llGetOwner() )
				LevelSpawner$setLoading(targ);
		)
			
        // Clear old
        Portal$killAll();
        Level$despawn();
        key att = _portal_spawn_v3(
			level, 
			startPos, 
			ZERO_ROTATION, 
			<0,0,8>, 
			FALSE,
			"_LV_",
			id,
			"",
			[]
		);
		if( att == "" ){
			llOwnerSay("Level failed to rez at target position. Move to a large clear area and try again.");
			startPos = ZERO_VECTOR;
		}
		
    }
	if( METHOD == LevelSpawnerMethod$setLoading )
		toggleLoadingScreen(TRUE);

 
	if(METHOD == LevelSpawnerMethod$remInventory && method$internal){
        list assets = llJson2List(method_arg(0));
        list_shift_each(assets, val,
            if(llGetInventoryType(val) == INVENTORY_OBJECT){
                llRemoveInventory(val);
            }
        )
    }
    
    
    
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}

