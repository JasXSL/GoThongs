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

	if( startsWith(id, "WF_") )
		drawWeaponEffect(llGetSubString(id, 3, -1));

	// Check if we are attached. If not, request permissions.
    else if( id == TIMER_CHECK_ATTACH ){
        
		if( llGetAttached() )
            multiTimer([id]);
        else{
            
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
			
        }
		
    }
    
	// See if our offsets have changed.
    else if(id == TIMER_CHECK_OFFSETS){
        
		if( !llGetStartParameter() || !llGetAttached() || ~BFL&BFL_INI )
			return;
        
        vector p = llGetLocalPos();
        rotation r = llGetLocalRot();
        vector sc = llGetScale();
        
		// Offset change
        if( p != POS || r != ROT ){
            
			POS = p; ROT = r;
            WeaponLoader$storeOffset(p, r);
			
        }
        
		// Scale change
        if( SC != sc ){
		
            SC = sc;
            float multi = sc.z/baseScale.z;
            WeaponLoader$storeScale(multi);
			
        }
        
    }
	
	
    
}

// Remove
kill(){

    llDie();
    if( llGetAttached() && llGetPermissions()&PERMISSION_ATTACH )
        llDetachFromAvatar();
    
}

updatePos(){
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
        PRIM_POSITION, POS,
        PRIM_ROTATION, ROT
    ]);
    POS = llGetLocalPos();
    ROT = llGetLocalRot();
}

drawWeaponEffect( string val ){

	int prim = 0;
	float age = 0.5;
	vector color = (<1,.5,.5>);
	float scale = 0.3;
	float alpha = 0.5;
	float glow = 0.3;
	float duration = 0.7;
	
	if( isset(j(val, 0)) )  
		prim = (int)j(val, 0);
	if( isset(j(val, 1)) )  
		age = (float)j(val, 1)/100;
	if( isset(j(val, 2)) )  
		color = (vector)j(val, 2);
	if( isset(j(val, 3)) )  
		scale = (float)j(val, 3)/100;
	if( isset(j(val, 4)) )  
		alpha = (float)j(val, 4)/10;
	if( isset(j(val, 5)) )  
		glow = (float)j(val,5)/10;
	if( isset(j(val, 6)) )  
		duration = (float)j(val,6)/100;
	
	llLinkParticleSystem(l2i(BOXES, prim), ([  
		PSYS_PART_FLAGS,
			PSYS_PART_EMISSIVE_MASK|
			PSYS_PART_INTERP_COLOR_MASK|
			PSYS_PART_INTERP_SCALE_MASK|
			PSYS_PART_RIBBON_MASK|
			PSYS_PART_FOLLOW_VELOCITY_MASK
		,
		PSYS_PART_MAX_AGE, age,
		PSYS_PART_START_COLOR, color,
		PSYS_PART_END_COLOR, color*1.25,
		PSYS_PART_START_SCALE,<scale,scale,0>,
		PSYS_PART_END_SCALE,<.0,.0,0>, 
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
		PSYS_SRC_BURST_RATE, 0.01,
		PSYS_SRC_ACCEL, <0,0,0>,
		PSYS_SRC_BURST_PART_COUNT, 1,
		PSYS_SRC_BURST_RADIUS, 0.0,
		PSYS_SRC_BURST_SPEED_MIN, 0.0,
		PSYS_SRC_BURST_SPEED_MAX, 0.01,
		PSYS_SRC_ANGLE_BEGIN,   0.0, 
		PSYS_SRC_ANGLE_END,     0.0,
		PSYS_SRC_OMEGA, <0,0,0>,
		PSYS_SRC_MAX_AGE, duration, 
		PSYS_SRC_TEXTURE, "f2d25672-2387-5acb-bd16-fe0b13e37f98",
		PSYS_PART_START_ALPHA, alpha,
		PSYS_PART_END_ALPHA, 0,
		PSYS_PART_START_GLOW, glow,
		PSYS_PART_END_GLOW, 0
		
	]));
	
}

handleWeaponEffect( list PARAMS ){

	
	list_shift_each( PARAMS, val,
		
		float delay = 0.3;
		if( isset(j(val, 7)) )
			delay = (float)j(val, 7)/100;
		
		if( delay <= 0 )
			drawWeaponEffect(val);
		else
			multiTimer(["WF_"+val, "", delay, FALSE]);
		
	)
	
	


}

// Visual effect boxes
list BOXES = [0,0,0];
list SINGLES;

int WFX_CHAN;
int SET_CHAN;


default{ 

    // Rez param is (9th bit)HAND, 8-leftmost-bits Attach SLOT
    on_rez(integer start){
	
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetText((string)start, ZERO_VECTOR, 0);
        
		if( start ){
		
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
            integer pin = floor(llFrand(0xFFFFFFF));
            llSetRemoteScriptAccessPin(pin);
            runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
			
        }     

    }
    
	
    state_entry(){
	
        initiateListen();
        memLim(1.5);
        integer startParam = l2i(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]), 0);
        SLOT = startParam & 255;
        HAND = (startParam & 256) > 0;
		baseScale = llGetScale();
		
		WFX_CHAN = gotWeaponFxChan;
		SET_CHAN = gotWeaponSettingChan;
		llListen(WFX_CHAN, "", "", "");
		llListen(SET_CHAN, "", "", "");
		
		
        if( llGetStartParameter() ){
		
            llOwnerSay("@acceptpermission=add");
            raiseEvent(evt$SCRIPT_INIT, "");
            multiTimer([TIMER_CHECK_ATTACH, "", 2, TRUE]);
			
        }
		
		links_each( nr, name,
			
			if( startsWith(name, "PRT") ){
				
				int n = (int)llGetSubString(name, 3, -1);
				BOXES = llListReplaceList(BOXES, [nr], n, n);
				llLinkParticleSystem(nr, []);
		
			}
			else if( l2s(llGetLinkPrimitiveParams(nr, [PRIM_DESC]), 0) != "IGNORE" && nr > 1 )
				SINGLES += nr;
			
		)
		
    }
    
    attach(key id){
	
        if( !llGetStartParameter() )
			return;
			
        if( id ){
            
			if( ~BFL&BFL_INI )
                llRegionSayTo(mySpawner(), 12, "INI"+(str)HAND);
            else
                updatePos();
			
			multiTimer([TIMER_CHECK_OFFSETS, "", 2, TRUE]);
			
        }
		
    }
    
    run_time_permissions(integer perm){
	
        if( perm & PERMISSION_ATTACH && !llGetAttached() )
            llAttachToAvatarTemp(SLOT);
		
        
    }
    
	#define LISTEN_LIMIT_FREETEXT \
		integer isOwner = llGetOwnerKey(id) == llGetOwner(); \
		if( isOwner && chan == WFX_CHAN ) \
			return handleWeaponEffect(llJson2List(message)); \
		if( isOwner && chan == SET_CHAN ){\
			int data = (int)message; \
			int task = data&0x3F; \
			data = data >> 6; \
			if( task == gotWeapon$ctask$toggle ){ \
				\
				integer t = data&1; \
				if( HAND ) \
					t = data&2; \
				\
				list out; \
				integer i; \
				for(; i<count(SINGLES); ++i ) \
					out+= (list)PRIM_LINK_TARGET + l2i(SINGLES, i) + \
						PRIM_COLOR + ALL_SIDES + ONE_VECTOR + (t>0); \
				llSetLinkPrimitiveParamsFast(0, out); \
			 \
			} \
		}
		
	
    #include "xobj_core/_LISTEN.lsl"

    timer(){ multiTimer([]); }

	// Link messages
    #include "xobj_core/_LM.lsl"

        if( method$isCallback || !method$byOwner )
			return;
        
            
		if( 
			METHOD == WeaponMethod$remove && 
			(
				method_arg(0) == llGetObjectName()+(string)HAND || 
				id == "" || 
				method_arg(0) == "*"
			) || 
			method_arg(0) == "_WEAPON_"
		)kill();
        
        else if( METHOD == WeaponMethod$ini ){
		
			BFL = BFL|BFL_INI;			
			integer slot = l2i(PARAMS, 0);
			POS = (vector)method_arg(1);
			ROT = (rotation)method_arg(2);
			float sc = l2f(PARAMS, 3);
			if( sc )
				llScaleByFactor(sc);
			
			SC = llGetScale();
			
			if( slot != SLOT ){
			
				SLOT = slot;
				if( llGetPermissions() & PERMISSION_ATTACH )
					llAttachToAvatarTemp(SLOT);
					
			}
			else
				updatePos();
			
		}
		

    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 

