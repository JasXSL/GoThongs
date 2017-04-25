#include "got/_core.lsl"

integer BFL;
#define BFL_INI 0x1

integer HAND; // 0 = mainhand 1 = offhand
integer SLOT;
vector POS;
rotation ROT;
vector SC;
vector baseScale;

#define TIMER_CHECK_ATTACH "a"
#define TIMER_CHECK_OFFSETS "b"
timerEvent(string id, string data){
    if(id == TIMER_CHECK_ATTACH){
        if(llGetAttached()){
            multiTimer([id]);
        }else{
            llOwnerSay("@acceptpermission=add");
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        }
    }
    
    else if(id == TIMER_CHECK_OFFSETS){
        if(!llGetStartParameter())return;
        
        vector p = llGetLocalPos();
        rotation r = llGetLocalRot();
        vector sc = llGetScale();
        
        if(p != POS || r != ROT){
            POS = p; ROT = r;
            WeaponLoader$storeOffset(p, r);
        }
        
        if(SC != sc){
            SC = sc;
            float multi = sc.z/baseScale.z;
            WeaponLoader$storeScale(multi);
        }
        
    }
    
}

kill(){
    llDie();
    if(llGetAttached() && llGetPermissions()&PERMISSION_ATTACH){
        llDetachFromAvatar();
    }
}

updatePos(){
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
        PRIM_POSITION, POS,
        PRIM_ROTATION, ROT
    ]);
    POS = llGetLocalPos();
    ROT = llGetLocalRot();
}


default
{ 
    // Rez param is (9th bit)HAND, 8-leftmost-bits Attach SLOT
    on_rez(integer start){
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetText((string)start, ZERO_VECTOR, 0);
        if(start){
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
            integer pin = floor(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(pin);
            runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
        }     
    }
    
    state_entry()
    {
        initiateListen();
        memLim(1.5);
        integer startParam = l2i(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]), 0);
        SLOT = startParam & 255;
        HAND = (startParam & 256) > 0;
        if(llGetStartParameter()){
            llOwnerSay("@acceptpermission=add");
            raiseEvent(evt$SCRIPT_INIT, "");
            multiTimer([TIMER_CHECK_ATTACH, "", 2, TRUE]);
        }
        baseScale = llGetScale();
    }
    
    attach(key id){
        if(!llGetStartParameter())return;
        if(id){
            if(~BFL&BFL_INI)
                llRegionSayTo(mySpawner(), 12, "INI"+(str)HAND);
            else
                updatePos();
        }
    }
    
    run_time_permissions(integer perm){
        if(perm & PERMISSION_ATTACH && !llGetAttached()){
            llAttachToAvatarTemp(SLOT);
        }
    }
    
    #include "xobj_core/_LISTEN.lsl"

    timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
        /*
            Included in all these calls:
            METHOD - (int)method
            INDEX - (int)obj_index
            PARAMS - (var)parameters
            SENDER_SCRIPT - (var)parameters
            CB - The callback you specified when you sent a task
        */
        if(method$isCallback)return;
        
        if(method$byOwner){
            if(METHOD == WeaponMethod$remove && (method_arg(0) == llGetObjectName()+(string)HAND || id == "" || method_arg(0) == "*") || method_arg(0) == "_WEAPON_"){
                kill();
            }
            else if(METHOD == WeaponMethod$ini){
                BFL = BFL|BFL_INI;
                multiTimer([TIMER_CHECK_OFFSETS, "", 2, TRUE]);
                
                integer slot = l2i(PARAMS, 0);
                POS = (vector)method_arg(1);
                ROT = (rotation)method_arg(2);
                float sc = l2f(PARAMS, 3);
                if(sc){
                    llScaleByFactor(sc);
                }
                SC = llGetScale();
                
                if(slot != SLOT){
                    SLOT = slot;
                    if(llGetPermissions() & PERMISSION_ATTACH)
                        llAttachToAvatarTemp(SLOT);
                }
                else{
                    updatePos();
                }
            }
        }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 

