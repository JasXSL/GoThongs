/*
    V1
*/
#include "got/_core.lsl"

key TARGET;

timerEvent(string id, string data){
    if(id == "FAIL")llDie();
    else if(id == "STEP"){
        STEP();
    }
}

ini(){
    raiseEvent(ProjectileEvt$gotTarget, TARGET);
    
    if(!(integer)llGetObjectDesc() && !(integer)jVal(llGetObjectDesc(), [0])){
        multiTimer(["FAIL", "", 10, FALSE]);
        multiTimer(["STEP", "", .1, TRUE]);
        vector vrot = llRot2Euler(prRot(llGetOwner()));
        llSetRegionPos(prPos(llGetOwner())+<0,0,.5>+llRot2Fwd(llEuler2Rot(<0,0,vrot.z>))*.5);
        STEP();
    }else multiTimer(["FAIL"]);
}

float motion_time( float mt)
{
    mt = llRound(45.0*mt)/45.0;
    if ( mt > 0.11111111 ) return mt;
    else return 0.11111111;
}

STEP(){
    boundsHeight(TARGET, b)
    //qd(b);
    if(llGetAgentSize(TARGET))b = 0;
    vector to = prPos(TARGET)+<0,0,b/2>;
     
    
    if(to == ZERO_VECTOR)llDie();
    if(llVecDist(llGetPos(), to)<.5){
        llSetLinkAlpha(LINK_SET, 0, ALL_SIDES);
        raiseEvent(ProjectileEvt$targetReached, TARGET);
        Status$hitfx(TARGET);
        llSleep(2);
        llDie();
    }
    
    float dist = llVecDist(llGetPos(), to);
    if(dist>3)dist=3;
    
    vector pos = llVecNorm(to-llGetPos());
    rotation rot = llRotBetween(<0.0,.0,1.0>, pos)/llGetRot();
    pos*=dist;
    llSetKeyframedMotion([pos, rot, motion_time(.3*(dist/3))], []);
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

