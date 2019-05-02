#define USE_EVENTS
#include "got/_core.lsl"

string ANIM_BASE;				// Base anim. Looping all throughout the scene
integer ANIM_STEP;				// Current step of the scene
integer ANIM_MAX_STEPS;			// Max steps tied to scene
integer ANIM_STARTED;			// All players are seated and animation has begun
float ANIM_MIN_TIME = 0.6;		// Min time between animation triggers
float ANIM_MAX_TIME = 1.2;		// Max time between animation trigger
float ANIM_DURATION = 20;		// Total seconds to animate
integer LIVE;					// Spawned through a portal

list TARGETS;
list PLAYERS;
list PLAYER_HUDS;
list CACHE_SEATED;
list PLAYER_FLAGS;
int FLAGS;

int BFL;
#define BFL_PUBLIC 0x1		// Allow anyone to sit

#define setAnimTimer() ptSet("anim", llFrand(ANIM_MAX_TIME-ANIM_MIN_TIME)+ANIM_MIN_TIME, FALSE)
onEvt(string script, integer evt, list data){
    
    if( script == "got Portal" && evt == PortalEvt$playerHUDs )
        PLAYER_HUDS = data;
    
    if( Portal$plif )
        PLAYERS = data;
    
    if( script == "got Portal" && evt == PortalEvt$desc_updated ){
		
		LIVE = TRUE;
	
		list player_flags;
		float anim_min_time = 0.6;
		float anim_max_time = 1.2;
		float anim_duration = 20;
		int flags = l2i(data, 4);
		
		if( llJsonValueType(l2s(data, 5), []) == JSON_ARRAY )
			player_flags = llJson2List(l2s(data, 5));
	
		// Config
		if( isset(l2s(data, 1)) )
			anim_min_time = l2f(data, 1);
		if( isset(l2s(data, 2)) )
			anim_max_time = l2f(data, 2);

		if( l2f(data, 3) > 5 )
			anim_duration = l2f(data, 3);
			
		// Players that should sit on this. Root prim is always 0 and 
		list players = llJson2List(l2s(data, 0));
		

		startAnim(
			players,
			player_flags,
			anim_duration,
			anim_min_time,
			anim_max_time,
			flags
		);

    }
	
}

startAnim( list players, list player_flags, float anim_duration, float anim_min_time, float anim_max_time, int flags ){


	if( anim_duration < 5.0 )
		anim_duration = 5.0;
	if( anim_min_time < 0.1 )
		anim_min_time = 0.1;
	if( anim_max_time < anim_min_time )
		anim_max_time = anim_max_time;
	
	
	PLAYER_FLAGS = player_flags;
	ANIM_MIN_TIME = anim_min_time;		// Min time between animation triggers
	ANIM_MAX_TIME = anim_max_time;		// Max time between animation trigger
	ANIM_DURATION = anim_duration;		// Total seconds to animate
	FLAGS = flags;
	TARGETS = players;
	
	// Prim order, root is always the first player
	list order = [1,0,0,0,0,0,0,0];
	links_each( nr, name,
	
		int desc = l2i(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0);
		if( nr != 1 && name == "POSEBALL" ){
			order = llListReplaceList(order, (list)nr, desc, desc);
		}
	)
	
	// Assign players to their prims
	integer pl = 0;
	list_shift_each(players, targ,

		int f = fx$F_QUICKRAPE;
		if( l2i(player_flags, pl)&1 )
			f = f|fx$F_SHOW_GENITALS;
		
		qd(llKey2Name(llGetLinkKey(l2i(order, pl)))+" "+llKey2Name(targ));
		
		FX$send(targ, "", "["+(string)WF_ALLOW_WHEN_DEAD+",0,0,0,["+(str)anim_duration+","+(str)(PF_ALLOW_WHEN_DEAD|PF_ALLOW_WHEN_QUICKRAPE)+",\"forceSat\",[[13,"+(str)f+"],[31,\""+(str)llGetLinkKey(l2i(order, pl))+"\",0]]]]", 0);
		++pl;
		
	)
	
	ptSet("fail", 5, FALSE);
	
}

// Starts an anim set on all players
anim( string anim ){
    
    llMessageLinked(LINK_THIS, 0, "aN"+anim+"_t", "");
    if( llGetPermissions()&PERMISSION_TRIGGER_ANIMATION )
        llStartAnimation(anim+"_a");
    
}

// Checks if all poseballs are seated and unsits non players
integer allSeated(){

	integer success = TRUE;
    links_each(nr, name,
		
		string t = llAvatarOnLinkSitTarget(nr);
		if( llListFindList(TARGETS, (list)t) == -1 && t != NULL_KEY ){
			llUnSit(t);
			success = FALSE;
		}
        else if( (nr == 1 || name == "POSEBALL") && t == NULL_KEY ){
			success = FALSE;
		}
    )
    return success;
	
}

// Requests permissions and checks if all players are seated
reqPerm(){
    
	// Request permissions if needed
    if( llAvatarOnSitTarget() != NULL_KEY && ~llGetPermissions()&PERMISSION_TRIGGER_ANIMATION )
        llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);

	// All players are seated
    if( allSeated() ){
        
        llSleep(.1);					// Needed because the other scripts must reqest permissions
        anim(ANIM_BASE);				// Start the idle animations
        setAnimTimer();					// Set timer for active animations
        ptUnset("fail");				// Success, do not fail
        ANIM_STARTED = TRUE;					// It has started
        raiseEvent(gotPlayerPoserEvt$start, "");
		CACHE_SEATED = [];
		integer i;
		links_each(nr, name,
			key t = llAvatarOnLinkSitTarget(nr);
			if( t )
				CACHE_SEATED += t;
		)
		
    }
	// Not all players are seated
    else{
        
        ptUnset("anim");
		// This has already started so now delete
        if( ANIM_STARTED )
            end();
            
    }
}

// Unsit and kill the seater
end(){

	runOnPlayers(targ,
		Level$playerSceneDone(targ, ANIM_STARTED, CACHE_SEATED);
	)
	raiseEvent(gotPlayerPoserEvt$end, "");
	
	list_shift_each(CACHE_SEATED, targ,
		fxlib$remForceSit(targ);
		Status$playerSceneDone(targ);
	)

    llSleep(1);
	if( LIVE )
		llDie();
	
}

// PandaTimer
ptEvt( string id ){
    
	// Start active animation
    if( id == "anim" ){
        
        anim(ANIM_BASE+"_"+(str)(ANIM_STEP+1));
        if( ++ANIM_STEP >= ANIM_MAX_STEPS )
            ANIM_STEP = 0;

		raiseEvent(gotPlayerPoserEvt$animStep, (str)ANIM_STEP);
		setAnimTimer();
		
    }
	// Fail timeout
    else if( id == "fail" )
        end();
    
}



default{

	on_rez( integer bap ){ llResetScript(); }
	
    state_entry(){
        
        PLAYERS = [(string)llGetOwner()];
        
		// Set sit targets
        links_each(nr, name,
		
            if( nr == 1 || name == "POSEBALL" )
                llLinkSitTarget(nr, <0,0,.01>, ZERO_ROTATION);
                
        )
        
		// Automatically fetch animations
        integer i;
        for(; i<llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
            
            string name = llGetInventoryName(INVENTORY_ANIMATION, i);
            list split = explode("_", name);
            if( l2s(split, -1) == "a" ){
			
                if( l2i(split, -2) )
                    ++ANIM_MAX_STEPS;
                else
                    ANIM_BASE = implode("_", llDeleteSubList(split, -1, -1));
					
            }
            
        }
        
        memLim(1.5);
		// Get permissions if somebody is sitting on this
        reqPerm();
        
		raiseEvent(evt$SCRIPT_INIT, "");
		
    }
    
    timer(){ptRefresh();}
    
    changed(integer change){
        
        if( change & CHANGED_LINK )
            reqPerm();
            
    }
    
    #include "xobj_core/_LM.lsl"
	
	if( method$byOwner ){
			
		if( METHOD == gotPlayerPoserMethod$test ){
			list players = llJson2List(method_arg(0)); 
			list player_flags = llJson2List(method_arg(1));
			float anim_duration = l2f(PARAMS, 2);
			float anim_min_time = l2f(PARAMS, 3); 
			float anim_max_time = l2f(PARAMS, 4);
			int flags = l2i(PARAMS, 5);
			
			startAnim( 
				players, 
				player_flags, 
				anim_duration, 
				anim_min_time, 
				anim_max_time, 
				flags
			);
			
		}
		
	}
	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  

}
