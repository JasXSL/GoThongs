#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

float vol_min = 0.1;
float vol_max = 0.25;
float speed_min = 1.5;
float speed_max = 1.5;
string ANIM = "";
int max_steps;
integer step;
int P_PARTS;
int P_PARTS2;


integer BFL;
#define BFL_LIVE 0x1
#define BFL_HAS_CONF 0x2
#define BFL_STARTED 0x4

integer CFLAGS;

#define setThrustTimer() ptSet("thr", llFrand(speed_max-speed_min)+speed_min, FALSE)

#define seat() llOwnerSay("@sit:"+(str)llGetKey()+"=force,unsit=n")

list SOUNDS = ["72d65db8-31fe-375b-8716-89e3963fbf7d","90b0ec1a-d5d2-3e18-ed0d-c5fb7c6885fd","f9194db3-9606-2264-3cde-765430179069"];

float cTick;

ptEvt( str id ){
    
    if( id == "thr" && llAvatarOnSitTarget() != NULL_KEY && max_steps ){
		 
        llStopObjectAnimation(ANIM+"_"+(str)(step+1)+"_a");
        if( ++step >= max_steps )
            step = 0;
            
		raiseEvent(gotAnimeshSceneEvt$thrust, "");
		
        if( llGetPermissions()&PERMISSION_TRIGGER_ANIMATION )
            llStartAnimation(ANIM+"_"+(str)(step+1)+"_t");
        llStartObjectAnimation(ANIM+"_"+(str)(step+1)+"_a");
        setThrustTimer();
        
        triggerSound();
        
        if( CFLAGS & gotAnimeshScene$cfParts )
            triggerParts();
        
        
    }
	
	if( id == "MV" ){
	
		float delta = 0;
		if( cTick > 0 )
			delta = llGetTime()-cTick;
		cTick = llGetTime();
		if( LEVEL&CONTROL_UP )
			zOffs += 0.1*delta;
		else
			zOffs -= 0.1*delta;
		
		if( zOffs < -1 )
			zOffs = -1;
		else if( zOffs > 1 )
			zOffs = 1;
		updatePos();
		
	}
	
	if( id == "resit" )
		seat();
    
}

begin(){
	
	if( BFL&BFL_LIVE && BFL&BFL_HAS_CONF ){
		seat();
	}
}

triggerSound(){

	if( count(SOUNDS) )
        llTriggerSound(randElem(SOUNDS), llFrand(vol_max-vol_min)+vol_min);

}

triggerParts(){
	llLinkParticleSystem(P_PARTS, [  
		PSYS_PART_FLAGS,
			PSYS_PART_EMISSIVE_MASK|
			PSYS_PART_INTERP_COLOR_MASK|
			PSYS_PART_INTERP_SCALE_MASK//|
			//PSYS_PART_BOUNCE_MASK|
			//PSYS_PART_WIND_MASK|
			//PSYS_PART_FOLLOW_SRC_MASK|
			//PSYS_PART_TARGET_POS_MASK|
			//PSYS_PART_FOLLOW_VELOCITY_MASK
			
		,
		PSYS_PART_MAX_AGE, .75,
		
		PSYS_PART_START_COLOR, <1,1,1>,
		PSYS_PART_END_COLOR, <1,1,1>,
		
		PSYS_PART_START_SCALE,<.25,.25,0>,
		PSYS_PART_END_SCALE,<.0,.05,0>, 
						
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
		
		PSYS_SRC_BURST_RATE, 0.021,
		
		PSYS_SRC_ACCEL, <0,0,-1.5>,
		
		PSYS_SRC_BURST_PART_COUNT, 1,
		
		PSYS_SRC_BURST_RADIUS, 0.05,
		
		PSYS_SRC_BURST_SPEED_MIN, 0.0,
		PSYS_SRC_BURST_SPEED_MAX, .1,
		
		//PSYS_SRC_TARGET_KEY,"",
		
		PSYS_SRC_ANGLE_BEGIN,   0.0, 
		PSYS_SRC_ANGLE_END,     0.0,
		
		PSYS_SRC_OMEGA, <0,0,0>,
		
		PSYS_SRC_MAX_AGE, 0.3,
						
		PSYS_SRC_TEXTURE, "8c9ef740-85c8-50fb-bc2f-cda43ef8d406",
		
		PSYS_PART_START_ALPHA, 0,
		PSYS_PART_END_ALPHA, .25,
		
		PSYS_PART_START_GLOW, 0,
		PSYS_PART_END_GLOW, 0
		
	]);
	llLinkParticleSystem(P_PARTS2, [  
		PSYS_PART_FLAGS,
			PSYS_PART_EMISSIVE_MASK|
			PSYS_PART_INTERP_COLOR_MASK|
			PSYS_PART_INTERP_SCALE_MASK//|
			//PSYS_PART_BOUNCE_MASK|
			//PSYS_PART_WIND_MASK|
			//PSYS_PART_FOLLOW_SRC_MASK|
			//PSYS_PART_TARGET_POS_MASK|
			//PSYS_PART_FOLLOW_VELOCITY_MASK
			
		,
		PSYS_PART_MAX_AGE, .3,
		
		PSYS_PART_START_COLOR, <.8,.8,1>,
		PSYS_PART_END_COLOR, <1,1,1>,
		
		PSYS_PART_START_SCALE,<.0,.0,0>,
		PSYS_PART_END_SCALE,<.05,.05,0>, 
						
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
		
		PSYS_SRC_BURST_RATE, 0.025,
		
		PSYS_SRC_ACCEL, <0,0,-1>,
		
		PSYS_SRC_BURST_PART_COUNT, 1,
		
		PSYS_SRC_BURST_RADIUS, 0.0,
		
		PSYS_SRC_BURST_SPEED_MIN, 0.25,
		PSYS_SRC_BURST_SPEED_MAX, .5,
		
		//PSYS_SRC_TARGET_KEY,"",
		
		PSYS_SRC_ANGLE_BEGIN,   0.0, 
		PSYS_SRC_ANGLE_END,     0.0,
		
		PSYS_SRC_OMEGA, <0,0,0>,
		
		PSYS_SRC_MAX_AGE, 0.2,
						
		PSYS_SRC_TEXTURE, "8c9ef740-85c8-50fb-bc2f-cda43ef8d406",
		
		PSYS_PART_START_ALPHA, 0,
		PSYS_PART_END_ALPHA, 1,
		
		PSYS_PART_START_GLOW, 0,
		PSYS_PART_END_GLOW, 0
		
	]);
}

onEvt(string script, integer evt, list data){
    
    if( script == "got Portal" && evt == evt$SCRIPT_INIT ){
        
		BFL = BFL&~BFL_LIVE;
		if( portalConf$live ){
		
			PP(0, (list)PRIM_TEMP_ON_REZ + TRUE);
			BFL = BFL|BFL_LIVE;
			updateMonsterPos();	// Portal may override our initial pos set. Do it again here.
			begin();
			ptSet("resit", 2, TRUE);
			
        }
    }
	
    
}

vector POS;
rotation ROT;
float zOffs;

updatePos(){
    
	vector pos = POS;
	pos.z += zOffs;
	
    llSitTarget(pos, ROT);
    links_each( nr, name,
        
        vector size = llGetAgentSize(llGetLinkKey(nr));
        if( size ){

            float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
            llSetLinkPrimitiveParamsFast(nr, 
                (list)PRIM_POS_LOCAL + 
                (pos + <0.0, 0.0, 0.4> - (llRot2Up(ROT) * fAdjust)) +
                PRIM_ROT_LOCAL + ROT
            );
            //llRequestPermissions(llGetLinkKey(nr), PERMISSION_TRIGGER_ANIMATION); -- This was causing problems with the new adjustment hotkeys. Not sure why this is here.

        }
        
    )   
    
}

int NO_DIE;
int LEVEL;
int EDGE;
float HEIGHT; // Offset from ground to put animation. Needed here because it gets start data before portal loads and sets position.

updateMonsterPos(){

	if( HEIGHT != 0 && llAvatarOnSitTarget() == NULL_KEY ){
		
		vector apos = prPos(llGetOwner());
		list ray = llCastRay(apos, apos-<0,0,10>, RC_DEFAULT);
		if( l2i(ray, -1) == 1 ){
			
			llSetRegionPos(l2v(ray, 1)+<0,0,HEIGHT>);
			
		}
		
	}
	
}


default{
    
    state_entry(){
        
        llLinkParticleSystem(LINK_SET, []);
        raiseEvent(evt$SCRIPT_INIT, "");
        if( llAvatarOnSitTarget() )
            llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
        
        links_each(nr, name,
            
            if( name == "PARTS" )
                P_PARTS = nr;
            if( name == "PARTS2" )
                P_PARTS2 = nr;
                
        )
		
		llSetStatus(STATUS_PHANTOM, TRUE);
		
		stopAllObjectAnimations()

        
    }
    
    timer(){
        ptRefresh();
    }
    
    changed( integer change ){
        
        if( change & CHANGED_LINK ){
            
            key t = llAvatarOnSitTarget();
            
            if( t ){
                
                if( t != llGetOwner() )
                    return llUnSit(t);
              
				ptUnset("resit");
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS);
				BFL = BFL|BFL_STARTED;
				
            }
            else if( !NO_DIE ){
			
                ptUnset("thr");
				if( portalConf$live )
					llDie();
					
            }
        }
        
    }
    
    run_time_permissions( integer perm ){
        
        if( perm & PERMISSION_TRIGGER_ANIMATION ){
            
			list anims = llGetAnimationList(llGetOwner());
			list_shift_each(anims, anim,
				llStopAnimation(anim);
			)
			
			llStopObjectAnimation(ANIM+"_a");
			llStartObjectAnimation(ANIM+"_a");
            if( ANIM )
                llStartAnimation(ANIM+"_t");
            setThrustTimer();
            raiseEvent(gotAnimeshSceneEvt$start, "");
			
        }
		
		if( perm & PERMISSION_TAKE_CONTROLS ){
			llTakeControls(CONTROL_UP|CONTROL_DOWN, TRUE, FALSE);
		}
        
    }
    
	
	control( key id, integer level, integer edge ){
		
		if( ~level & edge& (CONTROL_UP|CONTROL_DOWN) ){
			ptUnset("MV");
			cTick = 0;
		}
		if( level & edge & (CONTROL_UP|CONTROL_DOWN) ){
			ptSet("MV", 0.1, TRUE);
		}
		
		
		LEVEL = level;
		EDGE = edge;
		
	}
	
	
    #include "xobj_core/_LM.lsl"
	
	if( method$byOwner && METHOD == 0 ){
		llOwnerSay("Resetting");
		llResetScript();
	}
	
	
	
	if( method$byOwner && METHOD == gotAnimeshSceneMethod$killByName && method_arg(0) == llGetObjectName() ){
		llOwnerSay("@unsit=y");
		llDie();
	}
		
	if( method$byOwner && METHOD == gotAnimeshSceneMethod$orient ){
		POS = (vector)method_arg(0);
		ROT = (rotation)method_arg(1);
        updatePos();
    }
	
	if( method$byOwner && METHOD == gotAnimeshSceneMethod$stop ){
	
		NO_DIE = true;
		key ast = llAvatarOnSitTarget();
		if( ast ){
		
			PP(0, (list)PRIM_TEMP_ON_REZ + FALSE);
			llOwnerSay("@unsit=y");
			llUnSit(ast);
			ptUnset("resit");
			
		}
		
	}
    
	
    if( !method$internal )
        return;
        
	if( METHOD == gotAnimeshSceneMethod$trigger ){
		
		int n = l2i(PARAMS, 0);
		if( n&1 )
			triggerParts();
		if( n&2 )
			triggerSound();
		
	}
	
    if( METHOD == gotAnimeshSceneMethod$begin ){
        
        // Configure. Begin if live.
        string params = method_arg(0);
        string anim = j(params, gotAnimeshScene$cAnim);
        if( isset(anim) ){
            
            max_steps = step = 0;
            ANIM = anim;
            integer i;
            for( ; i<llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
                
                list spl = explode("_", llGetInventoryName(INVENTORY_ANIMATION, i));
                if( 
                    l2s(spl, -1) == "a" && 
                    implode("_", llDeleteSubList(spl, -2, -1)) == ANIM 
                )++max_steps;
                
            }
            
            
            if( 
                llAvatarOnSitTarget() != NULL_KEY && 
                llGetPermissions()&PERMISSION_TRIGGER_ANIMATION 
            ){
                llStartAnimation(ANIM+"_t");
				llStartObjectAnimation(ANIM+"_a");
				raiseEvent(gotAnimeshSceneEvt$start, "");
            }
			
        }
        
        if( (vector)j(params, gotAnimeshScene$cPos) ){
			POS = (vector)j(params, gotAnimeshScene$cPos);
			ROT = (rotation)j(params, gotAnimeshScene$cRot);
            updatePos();
        }
        if( isset(j(params, gotAnimeshScene$cSpeedMin)) )
            speed_min = (float)j(params, gotAnimeshScene$cSpeedMin);
        if( isset(j(params, gotAnimeshScene$cSpeedMax)) )
            speed_max = (float)j(params, gotAnimeshScene$cSpeedMax);
            
        if( isset(j(params, gotAnimeshScene$cSoundVolMin)) )
            vol_min = (float)j(params, gotAnimeshScene$cSoundVolMin);
        if( isset(j(params, gotAnimeshScene$cSoundVolMax)) )
            vol_max = (float)j(params, gotAnimeshScene$cSoundVolMax);
        
        
        HEIGHT = (float)j(params, gotAnimeshScene$cHeight);
        updateMonsterPos();
        
        if( isset(j(params, gotAnimeshScene$cFlags)) )
            CFLAGS = (int)j(params, gotAnimeshScene$cFlags);
        
            
        if( llJsonValueType(params, (list)gotAnimeshScene$cSound) == JSON_ARRAY )
            SOUNDS = llJson2List(j(params, gotAnimeshScene$cSound));
        
        if( speed_min < .2 )
            speed_min = .2;
        if( speed_max < .2 )
            speed_max = .2;
        if( speed_min > speed_max )
            speed_max = speed_min;
        
        if( vol_min < .0 )
            vol_min = .0;
        if( vol_max < .0 )
            vol_max = .0;
        if( vol_min > vol_max )
            vol_max = vol_min;
        
        if( anim )
            setThrustTimer();
        
		BFL = BFL|BFL_HAS_CONF;
		begin();
        
    }
    
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

