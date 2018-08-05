/*
    V1
*/
#include "got/_core.lsl"
integer FLAGS;
key TARGET;
float MAX_DIST;
float SPEED;
float WIGGLE_POW = 0.5;
float WIGGLE_ANGLE;

vector endPos(){
	boundsHeight(TARGET, b)
    if(llGetAgentSize(TARGET))b = 0;
	return prPos(TARGET)+<0,0,b/2>;
}

timerEvent(string id, string data){
    if(id == "FAIL")llDie();
    else if(id == "STEP"){
        STEP();
    }
}

ini(){
    
    
    if(!(integer)llGetObjectDesc() && !(integer)jVal(llGetObjectDesc(), [ProjectileDesc$preventDefault])){
	
        multiTimer(["FAIL", "", 10, FALSE]);
        multiTimer(["STEP", "", .1, TRUE]);
		
		list data = llJson2List(llGetObjectDesc());
        FLAGS = l2i(data, ProjectileDesc$flags);
		SPEED = l2f(data, ProjectileDesc$speed);
		WIGGLE_POW = l2f(data, ProjectileDesc$wiggleIntensity);
		if(SPEED <= 0)
			SPEED = 1;
		else if(SPEED <= 0.1)
			SPEED = 0.1;
		
		vector vrot = llRot2Euler(prRot(llGetOwner()));
		vector startPos = prPos(llGetOwner())+<0,0,.5>+llRot2Fwd(llEuler2Rot(<0,0,vrot.z>))*.5;

		rotation r = llRotBetween( <1.0,0.0,0.0>, llVecNorm( endPos() - startPos ) );
        
		
		llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, r]);
		llSetRegionPos(startPos);
        STEP();
		
    }else 
		multiTimer(["FAIL"]);
	
	raiseEvent(ProjectileEvt$gotTarget, TARGET);
}

float motion_time( float mt)
{
    mt = llRound(45.0*mt)/45.0;
    if ( mt > 0.11111111 ) return mt;
    else return 0.11111111;
}

vector czBezier(float seg, vector start, vector handle1, vector handle2, vector end){
    float u = 1-seg;
    float sseg = seg*seg;
    float uu = u*u;
    return ((uu*u)*start)+(3*uu*seg*handle1)+(3*u*sseg*handle2)+((sseg*seg)*end);
}

STEP(){
    
    vector to = endPos();
	float dist = llVecDist(llGetPos(), to);
	
	if(MAX_DIST == 0){
		MAX_DIST = dist;
		WIGGLE_POW = (llFrand(WIGGLE_POW)-WIGGLE_POW/2)+WIGGLE_POW;
		WIGGLE_ANGLE = llFrand(TWO_PI);
	}
	
    if(to == ZERO_VECTOR)llDie();
    if(dist<.3){
        llSetLinkAlpha(LINK_SET, 0, ALL_SIDES);
        raiseEvent(ProjectileEvt$targetReached, TARGET);
        NPCInt$hitfx(TARGET);
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
        llSleep(2);
        llDie();
    }
    
	
	vector basepos = llVecNorm(to-llGetPos());
	
	vector add;
	if(WIGGLE_POW){
		/*
		float d = dist;
		if(d > MAX_DIST)
			d = MAX_DIST;
		vector start; vector end = <1,0,0>;
		vector handleA = <0.153, 0, 0.3>;
		vector handleB = <.226,0,0.024>;
		float scaleModifier = MAX_DIST;
		vector cur = czBezier(1.-(dist/MAX_DIST), start, handleA, handleB, end);
		add = <0, 0, cur.z>*scaleModifier;
		*/
		float z = llSin((dist*2/MAX_DIST)*PI+PI_BY_TWO)*(dist/MAX_DIST);
		rotation r = llRotBetween(<1,.0,.0>, basepos);
		rotation angle = llEuler2Rot(<WIGGLE_ANGLE, 0, 0>);
		add = <0,0,z*WIGGLE_POW>*angle*r;
	}
	
    if(dist>3)dist=3;
    
    vector pos = basepos+add;
    rotation rot = llRotBetween(<1,.0,.0>, pos)/llGetRot();
	
    pos*=dist*SPEED;
	float t = .3*(dist/3);
	
	if(t == 0)
		return llDie();
		
	// Die if velocity is too great, prevents a script error
	if(llVecMag(pos)/t > 200){
		return llDie();
	}
	
    llSetKeyframedMotion([pos, rot, motion_time(t)], []);
	
	
}


default
{
    state_entry(){
        llSetStatus(STATUS_PHANTOM, TRUE);
        raiseEvent(evt$SCRIPT_INIT, "");
        memLim(1.5);
        if(llGetStartParameter() == 2){
            SpellFX$getTarg("CB");
            multiTimer(["FAIL", "", 5, FALSE]);
        }
    }
    
    timer(){
        multiTimer([]);
    }
    
    #include "xobj_core/_LM.lsl" 
    /*
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    if(method$isCallback){
        if(method$byOwner){
            if(SENDER_SCRIPT == "got SpellFX" && METHOD == SpellFXMethod$getTarg){
                TARGET = method_arg(0);
                if(TARGET)ini();
                else llDie();
            }
        }
        return;
    }
    
    if(method$internal){
        
    }
    
    if(method$byOwner){
        
    }


    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}

