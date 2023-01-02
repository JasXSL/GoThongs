#define USE_DB4
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
list PLAYER_FLAGS;
int FLAGS;

list POS_OFFSETS;				// Same index as the players
list ROT_OFFSETS;				// Same index as the players

list TO_PLAY;					// (key)id, (str)anim


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
		list posOffsets = llJson2List(l2s(data, 6));
		list rotOffsets = llJson2List(l2s(data, 7));
		
		startAnim(
			players,
			player_flags,
			anim_duration,
			anim_min_time,
			anim_max_time,
			flags,
			posOffsets,
			rotOffsets
		);

    }
	
}

forceSit( string targ ){

	integer pos = llListFindList(TARGETS, (list)targ);
	if( pos == -1 )
		return;
		
	int f = fx$F_QUICKRAPE;
	if( l2i(PLAYER_FLAGS, pos)&1 )
		f = f|fx$F_SHOW_GENITALS;
		
	FX$send(targ, "", "["+
		(string)(WF_ALLOW_WHEN_DEAD|WF_ALLOW_WHEN_QUICKRAPE)+","+
		"0,0,"+
		"0,"+
		"["+
			(str)ANIM_DURATION+","+
			(str)(PF_ALLOW_WHEN_DEAD|PF_ALLOW_WHEN_QUICKRAPE|PF_TRIGGER_IMMEDIATE)+","+
			"\"forceSat\","+
			"["+
				"[13,"+(str)f+"],"+
				"[31,\""+(str)llGetKey()+"\",0]"+
			"]"+
		"],"+
		"[],[],[],0,0,1"+
	"]", 0);

}

startAnim( list players, list player_flags, float anim_duration, float anim_min_time, float anim_max_time, int flags, list posOffsets, list rotOffsets ){


	if( anim_duration < 5.0 )
		anim_duration = 5.0;
	if( anim_min_time < 0.1 )
		anim_min_time = 0.1;
	if( anim_max_time < anim_min_time )
		anim_max_time = anim_max_time;
	
	POS_OFFSETS = posOffsets;
	ROT_OFFSETS = rotOffsets;
	PLAYER_FLAGS = player_flags;
	ANIM_MIN_TIME = anim_min_time;		// Min time between animation triggers
	ANIM_MAX_TIME = anim_max_time;		// Max time between animation trigger
	ANIM_DURATION = anim_duration;		// Total seconds to animate
	FLAGS = flags;
	TARGETS = players;
	
	// Assign players to their prims
	list_shift_each(players, targ,
		forceSit(targ);
	)
	
	ptSet("retry", 1, TRUE);
	ptSet("fail", 5, FALSE);
	
}

// Requests permissions for and shifts off the next animation
reqNextAnim(){
	

	str player = l2s(TO_PLAY, 0);
	while( count(TO_PLAY) && prRoot(player) != llGetKey() ){
		player = l2s(TO_PLAY, 2);
		TO_PLAY = llDeleteSubList(TO_PLAY, 0, 1);
	}
	
	if( !count(TO_PLAY) )
		return;
	TO_PLAY = llDeleteSubList(TO_PLAY, 0, 0);
	llRequestPermissions(player, PERMISSION_TRIGGER_ANIMATION);
	
}

// Starts an anim set on all players
anim( string anim ){

	TO_PLAY = [];
	integer i;
	for(; i<count(TARGETS); ++i ){
	
		TO_PLAY += l2s(TARGETS, i);
		str suffix = "_a";
		if( i == 1 )
			suffix = "_t";
		else if( i )
			suffix = "_t"+(str)i;
		TO_PLAY += (anim+suffix);
		
	}
	
    reqNextAnim();
    
}

integer getPlayerLink( key id ){

	integer i;
	for(i = 1; i <= llGetNumberOfPrims(); ++i ){
		
		if( llGetLinkKey(i) == id )
			return i;
		
	}
	return 0;

}

// Checks if all poseballs are seated and unsits non players
integer allSeated(){

	// Unsit unauthorized avatars
	links_each(nr, name,
		
		string id = llGetLinkKey(nr);
		if( llGetAgentSize(id) ){
		
			int pos = llListFindList(TARGETS, (list)id);
			if( pos == -1 )
				llUnSit(id);
			
		}

    )
	
	if( !count(TARGETS) )
		return FALSE;
	
	// See if all targets are present
	int i;
	for(; i<count(TARGETS); ++i ){
	
		if( prRoot(l2k(TARGETS, i)) != llGetKey() )
			return FALSE;
			
	}
    
    return true;
	
}

// Requests permissions and checks if all players are seated
onSeatChange(){
    
	// All players are seated
    if( allSeated() ){
        
		// Update position
		integer i;
		for( ; i < count(TARGETS); ++i ){
			
			key targ = l2k(TARGETS, i);
			integer ln = getPlayerLink(targ);
			if( ln ){
				
				vector scale = llGetAgentSize(targ);
				vector pos = (vector)l2s(POS_OFFSETS, i);
				rotation rot = (rotation)l2s(ROT_OFFSETS, i);
			
				float fAdjust = ((((0.008906 * scale.z) + -0.049831) * scale.z) + 0.088967) * scale.z;
				llSetLinkPrimitiveParamsFast(ln, (list)
					PRIM_POSITION + (pos+ <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) +
					PRIM_ROT_LOCAL + rot
				);
				
			}
		}
		
        anim(ANIM_BASE);				// Start the idle animations
        setAnimTimer();					// Set timer for active animations
        ptUnset("fail");				// Success, do not fail
        ANIM_STARTED = TRUE;					// It has started
        raiseEvent(gotPlayerPoserEvt$start, "");
		ptUnset("retry");
		
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
		Level$playerSceneDone(targ, ANIM_STARTED, TARGETS);
	)
	raiseEvent(gotPlayerPoserEvt$end, "");
	ptUnset("retry");
	
	list_shift_each(TARGETS, targ,
		fxlib$remForceSit(targ);
		Status$playerSceneDone(targ);
	)

    llSleep(1);
	if( LIVE )
		llDie();
	
	ANIM_STARTED = false;
	
}

// PandaTimer
ptEvt( string id ){
    
	// Start active animation
    if( id == "anim" ){
        
		if( ANIM_MAX_STEPS ){
		
			anim(ANIM_BASE+"_"+(str)(ANIM_STEP+1));
			if( ++ANIM_STEP >= ANIM_MAX_STEPS )
				ANIM_STEP = 0;
				
		}
		raiseEvent(gotPlayerPoserEvt$animStep, (str)ANIM_STEP);
		setAnimTimer();
		
    }
	// Fail timeout
    else if( id == "fail" )
        end();
    
	else if( id == "retry" ){
		// Try seating players
		
		integer i;
		for(; i<count(TARGETS); ++i ){
			
			key targ = l2k(TARGETS, i);
			if( prRoot(targ) != llGetKey() )
				forceSit(targ);
			
			
		}
			
	}
	
}



default{

	on_rez( integer bap ){ llResetScript(); }
	
    state_entry(){
        
        PLAYERS = [(string)llGetOwner()];
        
		
		links_each( nr, name,
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
        onSeatChange();
        
		raiseEvent(evt$SCRIPT_INIT, "");
		
    }
    
    timer(){ptRefresh();}
    
    changed(integer change){
        
        if( change & CHANGED_LINK )
            onSeatChange();
            
    }
    
	run_time_permissions( integer perm ){
		if( perm & PERMISSION_TRIGGER_ANIMATION ){
			
			str anim = l2s(TO_PLAY, 0);
			if( anim )
				llStartAnimation(anim);
			TO_PLAY = llDeleteSubList(TO_PLAY, 0, 0);
			reqNextAnim();
			
		}
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
			list posOffsets = llJson2List(method_arg(6));
			list rotOffsets = llJson2List(method_arg(7));
			
			startAnim( 
				players, 
				player_flags, 
				anim_duration, 
				anim_min_time, 
				anim_max_time, 
				flags,
				posOffsets,
				rotOffsets
			);
			
		}
		
	}
	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  

}
