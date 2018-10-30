/*
	Anim syntax:
		Base = animName_a / animName_t
		Steps = animName_1_a / animName_1_t, for multiple animations increase 1 to 2, 3 etc
	
	Pose instigator animations _a are always on the root prim
	
	Links:
		Root prim is always seat #0
		After that you make prims and name them POSEBALL with description being the index of the seat. Such as 1 or 2
		
	Scripts:
		Make a copy of the number script and name it the same as the player index, root prim is 0. For two players you need a "1" script. For three a "2" script etc
		
	Description:
		When spawned the description is a JSON array with the following indexes:
		0 : (array)player_keys | UUIDs of players in order to put on this
		1 : (float)anim_min_time | Min time between animation triggers
		2 : (float)anim_max_time | Max time between animation triggers
		3 : (float)duration | Total duration of scene. Min 5
*/
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

list PLAYERS;
list PLAYER_HUDS;
list CACHE_SEATED;

#define setAnimTimer() ptSet("anim", llFrand(ANIM_MAX_TIME-ANIM_MIN_TIME)+ANIM_MIN_TIME, FALSE)
onEvt(string script, integer evt, list data){
    
    if( script == "got Portal" && evt == PortalEvt$playerHUDs )
        PLAYER_HUDS = data;
    
    if( Portal$plif )
        PLAYERS = data;
    
    if( script == "got Portal" && evt == PortalEvt$desc_updated ){
		
		LIVE = TRUE;
	
		// Config
		if( isset(l2s(data, 1)) )
			ANIM_MIN_TIME = l2f(data, 1);
		if( isset(l2s(data, 2)) )
			ANIM_MAX_TIME = l2f(data, 2);
			
		if( ANIM_MIN_TIME < 0.1 )
			ANIM_MIN_TIME = 0.1;
		if( ANIM_MAX_TIME < ANIM_MIN_TIME )
			ANIM_MAX_TIME = ANIM_MIN_TIME;
		
		if( l2f(data, 3) > 5 )
			ANIM_DURATION = l2f(data, 3);
        
		// Players that should sit on this. Root prim is always 0 and 
        list players = llJson2List(l2s(data, 0));
        list order = [1,0,0,0,0,0,0,0];
        links_each( nr, name,
		
            int desc = l2i(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0);
            if( nr != 1 && name == "POSEBALL" )
                order = llListReplaceList(order, (list)nr, desc, desc);
				
        )
		
		// Assign players to their prims
        integer pl = 0;
        list_shift_each(players, targ,

			FX$send(targ, "", "["+(string)WF_ALLOW_WHEN_DEAD+",0,0,0,["+(str)ANIM_DURATION+","+(str)(PF_ALLOW_WHEN_DEAD|PF_ALLOW_WHEN_QUICKRAPE)+",\"forceSat\",[[13,16],[31,\""+(str)llGetLinkKey(l2i(order, pl))+"\",0]]]]", 0);
            ++pl;
			
        )
		
        ptSet("fail", 5, FALSE);
        
    }
	
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
		if( llListFindList(PLAYERS, (list)t) == -1 && t != NULL_KEY ){
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
	on_rez( integer bap ){
		llResetScript();
	}
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
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  

}
