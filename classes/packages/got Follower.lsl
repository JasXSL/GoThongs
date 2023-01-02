#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"


integer STATUS_FLAGS;
integer MONSTER_FLAGS;
integer FXFLAGS;

integer BFL;
// Warp queued
#define BFL_WARP_TIMER 0x1
#define BFL_DO_WARP 0x2
#define BFL_WALKING 0x4
// Tracks if follower is in the sim
#define BFL_HAS_TARGET 0x8

// Target followed
key TARGET;
float BOUNDS = 0.5;		// How far from the point before navigating to it again
float DISTANCE = 1;		// Distance from player to put the point to go to
float ANGLE = 1;

integer STATE;

#define text(txt) llSetLinkPrimitiveParamsFast(2, [PRIM_TEXT, (str)(txt), <1,1,1>, 1]) 

#define stopOnCheck() ( \
	STATE != MONSTER_STATE_IDLE || \
	STATUS_FLAGS&StatusFlag$dead || \
	FXFLAGS&(fx$F_STUNNED|fx$F_ROOTED) || \
	MONSTER_FLAGS&Monster$RF_IMMOBILE \
)

float speed = 1;
float height_add;
float hoverHeight;
#define hAdd() ((float)height_add/10)
#define isAnimesh() (MONSTER_FLAGS&Monster$RF_ANIMESH)
#define getSpeed() speed


vector groundPoint(){
	
	vector root = llGetRootPosition();
	root.z -= hoverHeight;
	return root;

}

vector targetPos(){

	list data = llGetObjectDetails(TARGET, [OBJECT_POS, OBJECT_ROT, OBJECT_ATTACHED_POINT, OBJECT_ROOT]);

	// Tracking happens here
	vector point = l2v(data, 0);
	
	if(point == ZERO_VECTOR)
		return ZERO_VECTOR;
		
	// Rotation
	rotation rot = l2r(data, 1);
	
	
	rotation multi = llEuler2Rot(<0,0,PI+ANGLE>);

	
	vector ascale = llGetAgentSize(l2k(data, 3));
	point-= <0,0,ascale.z/2>;
	
	vector fwd = <0,0,1>;
	if( l2i(data, 2) || ascale != ZERO_VECTOR )
		fwd = <1,0,0>;
		
	
	float dist = llVecDist(llGetPos(), point);
	if( dist > 1 )
		fwd /= dist;	// Offset can be decreased based on distance
	fwd = fwd*rot*multi;
	
	
	point += fwd*DISTANCE;

	//text(" DIR: "+(str)ANGLE+" Axis: "+(str)fwd);
	
	return point;	
	
}

// Warps directly to the position if possible
warp(){
	
	vector pos = targetPos();
	if( pos == ZERO_VECTOR )		// No need to stop follow here, tick will automatically remove it
		return;
	
	list ray = llCastRay(pos+<0,0,1>, pos-<0,0,1>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
	if( l2i(ray, -1) == 1 && llVecDist(pos+<0,0,1>, l2v(ray, 1)) > .1 ){
	
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		llSleep(.1);
		llSetRegionPos(pos+<0,0,hoverHeight>);
		
	}
	
	// Prevents warp from being spammed
	BFL = BFL&~BFL_DO_WARP;
	BFL = BFL&~BFL_WARP_TIMER;
}

list stripSelfIntersects( list rc, integer stride ){
	
	integer rem; integer i;
	for(; i < count(rc)-1; i += stride ){
		
		if( prRoot(l2k(rc, i)) == llGetKey() ){
			++rem;
			rc = llDeleteSubList(rc, 0, stride-1);
		}
	
	}
	
	return llListReplaceList(rc, (list)(l2i(rc, -1)-rem), -1, -1);
	
}

integer moveInDir( vector dir, float speedMulti ){

	if( dir == ZERO_VECTOR )
		return FALSE;
		
	debugCommon("Moving. Flags: "+(str)MONSTER_FLAGS);
	
    dir = llVecNorm(dir);
	vector gpos = groundPoint();
	
	float sp = getSpeed()/speedMulti;
		
    if( ~MONSTER_FLAGS&Monster$RF_IMMOBILE && ~FXFLAGS&fx$F_ROOTED && sp > 0 ){
        
        dir = dir*speedMulti;
		
		bool flying = MONSTER_FLAGS & Monster$RF_FLYING;
		rotation baseRot = llGetRootRotation();
		if( ~MONSTER_FLAGS & Monster$RF_ANIMESH )
			baseRot = llEuler2Rot(<0,-PI_BY_TWO,0>)*baseRot;

		// Vertical raycast
		vector rayStart = gpos;
		
		// Nonflying tries to locate the ground in front of the monster
		float bz = -1; float az = 1;
		if( flying )	// Flying draws a straight line towards where they want to go, centered at their middlepoint
			bz = az = hoverHeight;


        list r = llCastRay(
			gpos+<0,0,hAdd()+1>*baseRot, 
			gpos+dir+<0,0,bz>*baseRot, 
			[RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS, RC_DATA_FLAGS, RC_GET_ROOT_KEY, RC_MAX_HITS, 3]
		);
		r = stripSelfIntersects(r, 2);


        vector hit = l2v(r, 1);
		
		if(
			(!flying && l2i(r, -1) <= 0) ||		// Not flying and not found (too steep drop)
			(flying && l2i(r, -1))				// Flying and found (blocked)
		)return FALSE;
        
		vector z = llList2Vector(r, 1);
		if( flying )
			z = gpos+dir;
			
		float dist = llVecMag(z-gpos);
		float speed = dist*sp;	// Technically this is always the same because distance changes based on input speed
		
		if( speed < 0.12 )
			speed = 0.12;
			
        llSetKeyframedMotion([z-gpos, speed], [KFM_DATA, KFM_TRANSLATION]);
		
		
    }else 
		return FALSE;
    
    if( ~MONSTER_FLAGS&Monster$RF_NOROT && ~FXFLAGS&fx$F_STUNNED )
		lookAt(gpos+<dir.x, dir.y, 0>);
		
	
    return TRUE;
}

lookAt( vector pos ){
	
	
	debugCommon("Animesh "+(str)isAnimesh());
	vector mpos = llGetPos();
	pos.z = mpos.z;
	if( isAnimesh() )
		llRotLookAt(llRotBetween(<1,0,0>, llVecNorm(pos-mpos)), 1, 1);
	else
		llLookAt(pos,1,1);
	

}



onEvt(string script, integer evt, list data){

    if(script == "got Monster"){
	
		if( evt == MonsterEvt$state )
			STATE = l2i(data, 0);

		else if( evt == MonsterEvt$inRange && BFL&BFL_WALKING ){
		
			BFL = BFL&~BFL_WALKING;
			MaskAnim$stop("walk");
			
		}
		
		else if( evt == MonsterEvt$runtimeFlagsChanged )
			MONSTER_FLAGS = l2i(data, 0);
		
    }
	
	else if(script == "got Status"){
	
		if( evt == StatusEvt$flags )
			STATUS_FLAGS = l2i(data, 0);		
		
		else if( evt == StatusEvt$dead ){
		
			STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;		// Prevents sliding after death
			if( l2i(data, 0) && MONSTER_FLAGS&Monster$RF_NO_DEATH )
				multiTimer(["REVIVE", "", 15, FALSE]);
			
			else if( !l2i(data, 0) )
				multiTimer(["REVIVE"]);
				
		}
		
	}
	
	
}


onSettings(list settings){ 

	integer flagsChanged;
	while( settings ){
		integer idx = l2i(settings, 0);
		list dta = llList2List(settings, 1, 1);
		settings = llDeleteSubList(settings, 0, 1);
		
		// Movement speed
		if( idx == 1 && l2f(dta,0)>0 )
			speed = l2f(dta,0);

		if( idx == MLC$height_add )
			height_add = l2i(dta,0);
		
		if( idx == MLC$hover_height )
			hoverHeight = l2f(dta, 0);
		
	}
	
	// Limits
	if(speed<=0)
		speed = 1;

}


timerEvent(string id, string data){

	if( id == "tick" ){
	
		// Only allow when follower is idle
		if( stopOnCheck() )
			return;
		
		
		vector point = targetPos();
		if( point == ZERO_VECTOR ){
		
			if( BFL&BFL_HAS_TARGET ){
			
				raiseEvent(FollowerEvt$targetLost, "");
				BFL = BFL&~BFL_HAS_TARGET;
				
			}
			
			return;
			
		}
		
		BFL = BFL|BFL_HAS_TARGET;
	
		vector gpos = groundPoint();
		
		// Successfully determined a place to go (and not in range)
		integer success;
		
		vector dPoint = prPos(TARGET);
		float dist = llVecDist(<gpos.x, gpos.y, 0>, <point.x, point.y, 0>);	
		float dist2 = llVecDist(<gpos.x, gpos.y, 0>, <dPoint.x, dPoint.y, 0>);	
		//llSetText((str)dist, <1,1,1>, 1);
		
		// Have to be far away from both the target player and the target offset pos
		if( dist > BOUNDS && dist2 > BOUNDS ){
		
		
			list los = llCastRay(gpos+<0,0,1>, point+<0,0,1>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
			
			if( l2i(los, -1) == 0 ){
			
				vector dir = llVecNorm(<point.x, point.y, 0>-<gpos.x, gpos.y, 0>);
				success = moveInDir(dir, dist/2);	// Move faster if far away
				
			}
			
			
			if(!success){		// Couldn't find a path
			
				if( BFL&BFL_DO_WARP ){
					warp();
				}
				else if( ~BFL&BFL_WARP_TIMER ){
				
					multiTimer(["WARP", "", 3, FALSE]);
					BFL = BFL|BFL_WARP_TIMER;
					
				}
			}
			else if( ~BFL&BFL_WALKING ){
				
				MaskAnim$start("walk");
				BFL = BFL|BFL_WALKING;
				
			}

		}
		
		if( !success && BFL&BFL_WALKING ){
		
			BFL = BFL&~BFL_WALKING;
			llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
			MaskAnim$stop("walk");
			
		}
		
	}
	
	else if(id == "WARP"){
		BFL = BFL|BFL_DO_WARP;
	}
	else if(id == "REVIVE"){
		Status$fullregen();
	}
}


default 
{
    // Timer event
    //timer(){multiTimer([]);}
    state_entry(){
        memLim(2);
        raiseEvent(evt$SCRIPT_INIT, "");
   }
    
	timer(){multiTimer([]);}
    
	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		FXFLAGS = l2i(data, FXCUpd$FLAGS); \
	} \
	else if(nr == TASK_MONSTER_SETTINGS){\
		onSettings(llJson2List(s)); \
	}\
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    if(method$isCallback)
        return;
    
    
    if(method$internal){
        
        if(METHOD == FollowerMethod$enable){     

			debugUncommon("Enabling follower");
            TARGET = method_arg(0);
            DISTANCE = l2f(PARAMS, 1);
            ANGLE = l2f(PARAMS, 2);
			BOUNDS = l2f(PARAMS, 3);
			if( BOUNDS < 0.5 )
				BOUNDS = 0.5;
			multiTimer(["tick", "", .25, TRUE]);
			Monster$setFlags(Monster$RF_FOLLOWER);
			//qd("Follower enabled, with DISTANCE: "+(str)DISTANCE+" Dir: "+(str)ANGLE);
        }
        
        else if(METHOD == FollowerMethod$disable){
		
			debugUncommon("Disabling follower");
            TARGET = "";    
			multiTimer(["tick"]);
			multiTimer(["WARP"]);
			
			Monster$unsetFlags(Monster$RF_FOLLOWER);
			
		}
        
    }
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}


