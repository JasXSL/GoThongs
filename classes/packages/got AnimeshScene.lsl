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

list SOUNDS = ["72d65db8-31fe-375b-8716-89e3963fbf7d","90b0ec1a-d5d2-3e18-ed0d-c5fb7c6885fd","f9194db3-9606-2264-3cde-765430179069"];

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
    
}

begin(){
	
	if( BFL&BFL_LIVE && BFL_HAS_CONF ){
		llOwnerSay("@sit:"+(str)llGetKey()+"=force,unsit=n");
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
        
		PP(0, (list)PRIM_TEMP_ON_REZ + TRUE);
        BFL = BFL|BFL_LIVE;
		begin();
        
    }
    
}

updatePos( vector pos, rotation rot ){
    
    llSitTarget(pos, rot);
    links_each( nr, name,
        
        vector size = llGetAgentSize(llGetLinkKey(nr));
        if( size ){
            
            float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
            llSetLinkPrimitiveParamsFast(nr, 
                (list)PRIM_POS_LOCAL + 
                (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) +
                PRIM_ROT_LOCAL + rot
            );
            llRequestPermissions(llGetLinkKey(nr), PERMISSION_TRIGGER_ANIMATION);

        }
        
    )   
    
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
		
		integer i;
        list names = llGetObjectAnimationNames();
        for(i=0; i<count(names); ++i )
            llStopObjectAnimation(l2s(names, i));

        
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
                    
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
				BFL = BFL|BFL_STARTED;
				
            }
            else{
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
			
            if( ANIM )
                llStartAnimation(ANIM+"_t");
            setThrustTimer();
            
        }
        
    }
    
    #include "xobj_core/_LM.lsl"
	
	if( method$byOwner && METHOD == gotAnimeshSceneMethod$killByName && method_arg(0) == llGetObjectName() ){
		llOwnerSay("@unsit=y");
		llDie();
	}
		
	if( method$byOwner && METHOD == gotAnimeshSceneMethod$orient ){
        updatePos( (vector)method_arg(0), (rotation)method_arg(1) );
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
            
            llStartObjectAnimation(ANIM+"_a");
            if( 
                llAvatarOnSitTarget() != NULL_KEY && 
                llGetPermissions()&PERMISSION_TRIGGER_ANIMATION 
            ){
                llStartAnimation(ANIM+"_t");
            }
			
        }
        
        if( (vector)j(params, gotAnimeshScene$cPos) )
            updatePos( (vector)j(params, gotAnimeshScene$cPos), (rotation)j(params, gotAnimeshScene$cRot));
        
        if( isset(j(params, gotAnimeshScene$cSpeedMin)) )
            speed_min = (float)j(params, gotAnimeshScene$cSpeedMin);
        if( isset(j(params, gotAnimeshScene$cSpeedMax)) )
            speed_max = (float)j(params, gotAnimeshScene$cSpeedMax);
            
        if( isset(j(params, gotAnimeshScene$cSoundVolMin)) )
            vol_min = (float)j(params, gotAnimeshScene$cSoundVolMin);
        if( isset(j(params, gotAnimeshScene$cSoundVolMax)) )
            vol_max = (float)j(params, gotAnimeshScene$cSoundVolMax);
        
        
        float h = (float)j(params, gotAnimeshScene$cHeight);
        if( h ){
            
            list ray = llCastRay(llGetPos()+<0,0,.5>, llGetPos()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
            if( l2i(ray, -1) == 1 ){
                
                llSetRegionPos(l2v(ray, 1)+<0,0,h>);
                
            }
            
        }
        
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

