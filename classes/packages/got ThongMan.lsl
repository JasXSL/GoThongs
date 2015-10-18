#define SCRIPT_IS_ROOT
#define ALLOW_USER_DEBUG 1
#define USE_EVENTS
#include "got/_core.lsl"

vector DEFAULT_COLOR  = <1,1,1>;
list DEFAULT_SPECULAR = [PRIM_SPECULAR, ALL_SIDES, "6c7b07d9-9c9c-f272-815b-abae6e3fbf67", <3,3,0>, <0,0,0>, 0, <0.435, 0.435, 0.435>, 110,0];
float DEFAULT_GLOW = 0;


integer BFL;
#define BFL_DEAD 1
#define BFL_INITIALIZED 2


integer PHYSID; // ID of physical thong. Should be in description

list FACES_ENHANCED = [3];
integer enhanced;

// Defaults
vector color = <1,1,1>;
vector hit = <1,1,1>;
vector fxcolor = ZERO_VECTOR;
float fxglow = 0;
list fxspecular = [];

updateDefaults(){
    color = DEFAULT_COLOR;
    list specular = DEFAULT_SPECULAR;
    list glow = [PRIM_GLOW, ALL_SIDES, DEFAULT_GLOW];
    
    if(fxcolor != ZERO_VECTOR){
        color = fxcolor;
        specular = llListReplaceList(specular, ["59facb66-4a72-40a2-815c-7d9b42c56f60"], 2, 2);
        glow = llListReplaceList(glow, [fxglow], -1, -1);
        if(fxspecular != [])
            specular = [PRIM_SPECULAR, ALL_SIDES]+fxspecular;
    }
    raiseEvent(ThongManEvt$ini, mkarr(([enhanced])));
	
    if(BFL&BFL_DEAD)return;
    list out;
    list all = jiggles;

    list_shift_each(all, val, 
        out+=([PRIM_LINK_TARGET, (integer)val]);
        out+=([PRIM_COLOR, ALL_SIDES, color]);
        if((integer)val != root)out+=0;
        else{
            out+=1;
            if(!enhanced){
				integer i;
				for(i=0; i<llGetListLength(FACES_ENHANCED); i++)
					out+=([PRIM_COLOR, llList2Integer(FACES_ENHANCED, i), <1,1,1>, 0]);
			}
        }
        out+=specular+glow;
    )
    llSetLinkPrimitiveParamsFast(0, out);
	
}


restore(){ 
	if(BFL&BFL_DEAD)return;
    list set = [];
    integer i;
    for(i=0; i<llGetListLength(jiggles); i++){
        if(llList2Integer(jiggles,i) != root)
            set+=[linkAlpha(llList2Integer(jiggles,i), 0, ALL_SIDES)];
    }
    if(set)llSetLinkPrimitiveParamsFast(0, set); 
    updateDefaults();
}


takeHit(vector col){
	if(BFL&BFL_DEAD)return;
    raiseEvent(ThongManEvt$hit, mkarr([col]));
    hit = col;
    MeshAnim$startAnim("Jiggle");
    llSetLinkColor(LINK_SET, col, ALL_SIDES);

    
    multiTimer(["A",1., .1, FALSE]);
}


timerEvent(string id, string data){
    if(id == "A"){
        float d = (float)data;
        d-=.1;
        if(d>0)multiTimer(["A", d, .05, FALSE]);
        vector v = color*(1.-d)+hit*d;
        llSetLinkColor(LINK_SET, v, ALL_SIDES);
    }
	else if(llGetSubString(id, 0, 1) == "P_"){
		llLinkParticleSystem((integer)llGetSubString(id, 2, -1), []);
	}
}

onEvt(string script, integer evt, string data){
    if(script == "ton MeshAnim"){
        if(evt == evt$SCRIPT_INIT){
            llSetRemoteScriptAccessPin(0);
        }else if(data == "OUT")
            restore();
    }
} 

setOnInvolved(list params){
	// Sets primitive params on all the main prims
	integer i; list out;
	for(i=0; i<llGetListLength(jiggles); i++)out+=[PRIM_LINK_TARGET, llList2Integer(jiggles, i)]+params;
	llSetLinkPrimitiveParamsFast(0, out);
}

integer root;
list jiggles;
default
{
    on_rez(integer mew){llResetScript();}
    
    timer(){multiTimer([]);}
    
    state_entry()
    {
		llStopSound();
        llListen(239186, "", llGetOwner(), "");
        initiateListen();
        
        if(!llGetStartParameter()){
            integer pin = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(pin);
            Remoteloader$load(cls$name, pin, 2);
            return;
        }
        
        
        
        
        
        if(llGetInventoryType("ton MeshAnim") == INVENTORY_SCRIPT){
            integer pin = llCeil(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(pin);
            Remoteloader$load("ton MeshAnim", pin, 2);
        }
        
        links_each(nr, name, 
			string s = (string)llGetLinkPrimitiveParams(nr, [PRIM_DESC]);
            if(llToLower(llGetSubString(name, 0, 3)) == "main"){
                jiggles += nr;
                if((integer)llGetSubString(name, -1, -1) == 1){
                    root = nr;
                    if(llJsonValueType(s, []) == JSON_ARRAY){
                        list l = llJson2List(s);
						if(llJsonValueType(llList2String(l, 0), []) == JSON_ARRAY)
							FACES_ENHANCED = llJson2List(llList2String(l,0));
                        else if(llList2Integer(l,0) != -1)
							FACES_ENHANCED = [llList2Integer(l,0)];
						else FACES_ENHANCED = [];
							
                    }
                }
            }
			
        )
		
        
        list desc = llJson2List(llStringTrim(llGetObjectDesc(), STRING_TRIM));
        PHYSID = llList2Integer(desc, 0);
        raiseEvent(evt$SCRIPT_INIT, "");
        BFL = BFL|BFL_INITIALIZED;
        
        Root$refreshThong(PHYSID);  
    }
    
    
    
    // This is the listener
    #include "xobj_core/_LISTEN.lsl"
    
    
    
    run_time_permissions(integer perm){
        if(perm&PERMISSION_ATTACH)llDetachFromAvatar();
    }

    
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    if(method$byOwner){
        if(METHOD == ThongManMethod$attached){
            if(llGetAttached())llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        }
		else if(METHOD == ThongManMethod$loopSound){
			key id = method_arg(0);
			float vol = (float)method_arg(1);
			if(id)llLoopSound(id, vol);
			else llStopSound();
		}
        else if(METHOD == ThongManMethod$reset){
            qd("Resetting");
            llResetScript();
        }
        else if(METHOD == ThongManMethod$get){
            if(!llGetStartParameter())llResetScript();
            else Root$refreshThong(PHYSID);
        }
        else if(METHOD == ThongManMethod$set){
			if(PHYSID <= 0 && id != ""){
				raiseEvent(ThongManEvt$getVisuals, "");
				return;
			}
            PARAMS = method_arg(0);
			
			if(method_arg(0) != "")
				DEFAULT_COLOR = (vector)method_arg(0);
            
			DEFAULT_GLOW = (float)method_arg(1);
            
            list diffuse = llJson2List(method_arg(2));
            list bump = llJson2List(method_arg(3));
            list specular = llJson2List(method_arg(4));
			
			if(diffuse != [])
				diffuse = [PRIM_TEXTURE, ALL_SIDES, llList2String(diffuse, 0), (vector)llList2String(diffuse,1), (vector)llList2String(diffuse,2), llList2Float(diffuse,3)];
            
			if(bump != [])
				bump = [PRIM_NORMAL, ALL_SIDES, llList2String(bump, 0), (vector)llList2String(bump,1), (vector)llList2String(bump,2), llList2Float(bump,3)];
            
			if(specular != [])
				specular = [PRIM_SPECULAR, ALL_SIDES, llList2String(specular, 0), (vector)llList2String(specular,1), (vector)llList2String(specular,2), llList2Float(specular,3), (vector)llList2String(specular,4), llList2Integer(specular,5), llList2Integer(specular,6)];


            enhanced = (integer)method_arg(5);
            
			
			setOnInvolved(diffuse+bump+specular);
            DEFAULT_SPECULAR = specular;
            updateDefaults();
			restore();
        }
        else if(METHOD == ThongManMethod$hit){
            takeHit((vector)method_arg(0));
        }
        else if(METHOD == ThongManMethod$fxVisual){
            fxcolor = (vector)method_arg(0);
            fxglow = (float)method_arg(1);
            fxspecular = llJson2List(method_arg(2));
            fxspecular = llListReplaceList(fxspecular, [(vector)llList2String(fxspecular, 1)], 1, 1);
            fxspecular = llListReplaceList(fxspecular, [(vector)llList2String(fxspecular, 2)], 2, 2);
            fxspecular = llListReplaceList(fxspecular, [(vector)llList2String(fxspecular, 4)], 4, 4);
            if(llList2String(fxspecular, 0) == "")
                fxspecular = llListReplaceList(fxspecular, ["6c7b07d9-9c9c-f272-815b-abae6e3fbf67"], 0, 0);
                
            updateDefaults();
        }
		else if(METHOD == ThongManMethod$particles){
			float timeout = (float)method_arg(0);
			integer prim = (integer)method_arg(1);
			if(prim == 0)prim = LINK_THIS;
			list data = llJson2List(method_arg(2));
			
			integer i;
			for(i=0; i<llGetListLength(data); i++){
				string s = llList2String(data, i);
				if(llGetSubString(s, 0,0) == "<" && llGetSubString(s, -1, -1) == ">")data = llListReplaceList(data, [(vector)s], i, i);
			}
			
			llLinkParticleSystem(prim, data);
			if(timeout>0)
				multiTimer(["P_"+(string)prim, "", timeout, FALSE]);
		}
		else if(METHOD == ThongManMethod$dead){
			multiTimer(["A"]); // Remove current fade effect
			integer dead = (integer)method_arg(0);
			if(dead){
				BFL = BFL|BFL_DEAD;
				llLinkParticleSystem(2, [
					PSYS_PART_MAX_AGE,.3, // max age
					PSYS_PART_FLAGS, 
						PSYS_PART_EMISSIVE_MASK|
						PSYS_PART_INTERP_COLOR_MASK|
						PSYS_PART_INTERP_SCALE_MASK|
						//PSYS_PART_RIBBON_MASK|
						PSYS_PART_FOLLOW_VELOCITY_MASK
						, // flags, glow etc
					PSYS_PART_START_COLOR, <1, 0, 1.>, // startcolor
					PSYS_PART_END_COLOR, <1, 1, 1.>, // endcolor
					PSYS_PART_START_SCALE, <.2, .2, 0>, // startsize
					PSYS_PART_END_SCALE, <.0, .0, 0>, // endsize
					PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE, // pattern
					PSYS_SRC_BURST_RATE, 0.01, // rate
					PSYS_SRC_ACCEL, <0,0,0>,  // push
					PSYS_SRC_BURST_PART_COUNT, 10, // count
					PSYS_SRC_BURST_RADIUS, 0.2, // radius
					PSYS_SRC_BURST_SPEED_MIN, .0, // minSpeed
					PSYS_SRC_BURST_SPEED_MAX, 2., // maxSpeed
					// PSYS_SRC_TARGET_KEY, NULL_KEY, // target
					PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
					PSYS_SRC_MAX_AGE, 1, // life
					PSYS_SRC_TEXTURE, "3c4c846e-450f-d2b9-adfd-117d5aa2c9b7", // texture
					
					PSYS_PART_START_ALPHA, .5, // startAlpha
					PSYS_PART_END_ALPHA, 0.0, // endAlpha
					PSYS_PART_START_GLOW, 0.1,
					PSYS_PART_END_GLOW, 0,
					
					PSYS_SRC_ANGLE_BEGIN, 0, // angleBegin
					PSYS_SRC_ANGLE_END, 0 // angleend
					
				]);
				multiTimer(["P_2", "", 2, FALSE]);
				MeshAnim$stopAnim("Jiggle");
				llTriggerSound("a0f4e168-1eb0-465e-2db9-5beaa2e2891a", 1);
				llSetLinkAlpha(LINK_SET, 0, ALL_SIDES);
				llSleep(2);
				llSetLinkAlpha(LINK_SET, 0, ALL_SIDES);
			}else{
				BFL = BFL&~BFL_DEAD;
				restore();
				
			}
		}
    }

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
