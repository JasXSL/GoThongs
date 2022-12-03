#define USE_EVENTS
#include "got/_core.lsl"

vector startPos;

quit(){
    startPos = ZERO_VECTOR;
}

key CURRENT_LEVEL;
int LOADING;
list PLAYERS;
key PRELOADED_TEXTURE;
list TEXTURES = [
	"4f484ea3-8aa0-f09b-3173-ea61a5221ab4", // Panda VS Skel
	"ae46da92-2078-0882-db82-39fa3e5b3ec5", // Fuyu & friend
	"10a121c0-6296-749e-090c-67800975873b",	// Climbing rope
	"683ed954-20f6-8026-1f42-b32bbfce5479",	// Riding the elevator
	"ff0e1b2e-d9e4-0f78-7a81-4bca426cf6b9",	// Imp lair entrance
	"042d3ef6-a923-adcf-67e1-085f444c1fe7", // Sun in PanRi
	"451eff51-5fdb-4430-06ea-c6405538eab6",	// Kitsu & tiger
	"2779b923-f813-28ac-38dd-19bddc3ac6b6"	// Dei dragon in tavern
];

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
		
		
		PRELOADED_TEXTURE = randElem(TEXTURES);
		llSetTexture(PRELOADED_TEXTURE, ALL_SIDES);
		
		return;
		
	}
	
	
	GUI$setOverlay(LINK_ALL_OTHERS, 1);

}

onEvt(string script, integer evt, list data){

	if( script == "#ROOT" && evt == RootEvt$players )
		PLAYERS = data;

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
		PRELOADED_TEXTURE = randElem(TEXTURES);
		llSetTexture(PRELOADED_TEXTURE, ALL_SIDES);
		
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
		
		
		runOnPlayers(targ,
			if( targ != llGetOwner() )
				LevelSpawner$setLoading(targ);
		)
			
        // Clear old
        Portal$killAll();
        Level$despawn();
        _portal_spawn_std(level, startPos, ZERO_ROTATION, <0,0,8>, FALSE, FALSE, FALSE);
		
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

