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
float DISTANCE = 1;
float ANGLE = 1;

integer STATE;

#define text(txt) llSetLinkPrimitiveParamsFast(2, [PRIM_TEXT, (str)(txt), <1,1,1>, 1]) 

#define stopOnCheck() ( \
	STATE != MONSTER_STATE_IDLE || \
	STATUS_FLAGS&StatusFlag$dead || \
	FXFLAGS&(fx$F_STUNNED|fx$F_ROOTED) || \
	MONSTER_FLAGS&Monster$RF_IMMOBILE \
)

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
	if(l2i(data, 2) || ascale != ZERO_VECTOR)
		fwd = <1,0,0>;
	
	fwd = fwd*rot*multi;
	
	
	point += fwd*DISTANCE;

	//text(" DIR: "+(str)ANGLE+" Axis: "+(str)fwd);
	
	return point;	
}

// Warps directly to the position if possible
warp(){
	
	vector pos = targetPos();
	if(pos == ZERO_VECTOR)		// No need to stop follow here, tick will automatically remove it
		return;
	
	list ray = llCastRay(pos+<0,0,1>, pos-<0,0,1>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
	if(l2i(ray, -1) == 1 && llVecDist(pos+<0,0,1>, l2v(ray, 1))>.1){
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		llSleep(.1);
		llSetRegionPos(pos);
	}
	
	// Prevents warp from being spammed
	BFL = BFL&~BFL_DO_WARP;
	BFL = BFL&~BFL_WARP_TIMER;
}

integer moveInDir(vector dir, float speed){
	if(dir == ZERO_VECTOR)return FALSE;
    dir = llVecNorm(dir);
	vector gpos = llGetPos();
    
	// Determines how smooth it should run, timer even should be faster than this
	float STEPPING = 0.3;
	
	float sp = speed;
	if(sp<0.3)sp = 0.3;
	if(sp>3)sp = 3;
	

    dir = dir*sp*STEPPING;
	vector a = <0,0,1>;	// Max climb distance
	vector b = <0,0,-3>;	// Max drop distance
	
	// movement, hAdd() is not added
    // Check if too high climb or too steep drop
	list r = llCastRay((gpos+dir+a), (gpos+dir+b), ([RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS, RC_DATA_FLAGS, RC_GET_ROOT_KEY]));
    if(
		// Too steep drop
		llList2Integer(r, -1) <=0 || 
		// Inside a wall
		llVecDist(llGetPos()+dir+<0,0,1>, llList2Vector(r, 1))<.1
	){
		return FALSE;
    }
    	
	vector z = llList2Vector(r, 1);
			
    llSetKeyframedMotion([z-gpos, 1.*STEPPING], [KFM_DATA, KFM_TRANSLATION]);
    llLookAt(gpos+<dir.x, dir.y, 0>, 1, 1);
    return TRUE;
}


onEvt(string script, integer evt, list data){
    if(script == "got Monster"){
		if(evt == MonsterEvt$state){
			STATE = l2i(data, 0);
			if(STATE != MONSTER_STATE_IDLE)
				BFL = BFL&~BFL_WALKING;
		}
		else if(evt == MonsterEvt$runtimeFlagsChanged){
			MONSTER_FLAGS = l2i(data, 0);
		}
    }
	
	else if(script == "got Status"){
		if(evt == StatusEvt$flags){
			STATUS_FLAGS = l2i(data, 0);		
		}
		else if(evt == StatusEvt$dead){
			STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;		// Prevents sliding after death
			if(l2i(data, 0) && MONSTER_FLAGS&Monster$RF_NO_DEATH){
				multiTimer(["REVIVE", "", 15, FALSE]);
			}
			else if(!l2i(data, 0))
				multiTimer(["REVIVE"]);
		}
	}
	
	
}



timerEvent(string id, string data){
	if(id == "tick"){
		// Only allow when follower is idle
		if(stopOnCheck())
			return;
		
		
		vector point = targetPos();
		if(point == ZERO_VECTOR){
			if(BFL&BFL_HAS_TARGET){
				raiseEvent(FollowerEvt$targetLost, "");
				BFL = BFL&~BFL_HAS_TARGET;
			}
			return;
		}
		
		BFL = BFL|BFL_HAS_TARGET;
	
		vector gpos = llGetPos();
		
		// Successfully determined a place to go (and not in range)
		integer success;
		
		float dist = llVecDist(<gpos.x, gpos.y, 0>, <point.x, point.y, 0>);
		if(dist > DISTANCE/2){
			list los = llCastRay(gpos+<0,0,1>, point+<0,0,1>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
			
			if(l2i(los, -1) == 0){
				vector dir = llVecNorm(<point.x, point.y, 0>-<gpos.x, gpos.y, 0>);
				success = moveInDir(dir, dist);
			}
			
			
			if(!success){		// Couldn't find a path
				if(BFL&BFL_DO_WARP){
					warp();
				}
				else if(~BFL&BFL_WARP_TIMER){
					multiTimer(["WARP", "", 3, FALSE]);
					BFL = BFL|BFL_WARP_TIMER;
				}
			}
			else if(~BFL&BFL_WALKING){
				MaskAnim$start("walk");
				BFL = BFL|BFL_WALKING;
			}

		}
		
		if(!success && BFL&BFL_WALKING){
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
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    if(method$isCallback){
        return;
    }
    
    if(method$internal){
        
        if(METHOD == FollowerMethod$enable){            
            TARGET = method_arg(0);
            DISTANCE = l2f(PARAMS, 1);
            ANGLE = l2f(PARAMS, 2);
			multiTimer(["tick", "", .25, TRUE]);
			Monster$setFlags(Monster$RF_FOLLOWER);
			//qd("Follower enabled, with DISTANCE: "+(str)DISTANCE+" Dir: "+(str)ANGLE);
        }
        
        else if(METHOD == FollowerMethod$disable){
            TARGET = "";    
			multiTimer(["tick"]);
			Monster$unsetFlags(Monster$RF_FOLLOWER);
		}
        
    }
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}


