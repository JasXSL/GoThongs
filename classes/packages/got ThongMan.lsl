#define USE_DB4
#define SCRIPT_IS_ROOT
#define ALLOW_USER_DEBUG 1
#include "got/_core.lsl"


integer BFL;
#define BFL_DEAD 1

vector DEFAULT_COLOR = ONE_VECTOR;

// Defaults
int currentState = ThongManPreset$DEFAULT;
int lastState;
vector color = ONE_VECTOR;				// Active color
vector hit = <1,1,1>;				// Color of last hit
vector fxcolor = ZERO_VECTOR;
float fxglow;							// Todo: Implement later
float time_hit;							// llGetTime() of last time we were hit
float time_fx;
float last_rain;	// set to true if rain noise is detected on ground

list TMP_VIS; // Works same as fxcolor but on a timer
// [(float)added, (float)dur, (vec)color, (float)glow, (int)type]
#define TMPVIS_STRIDE 5
int rainState;

// Returns a slice on success
list getActiveTmpVis(){

	// Find if there is something in TMP_VIS
	integer i;
	for(; i < count(TMP_VIS); i += TMPVIS_STRIDE ){
		
		float started = l2f(TMP_VIS, i);
		float dur = l2f(TMP_VIS, i+1);
		if( llGetTime() < started+dur )
			return llList2List(TMP_VIS, i, TMPVIS_STRIDE-1);
		
		
	}
	return [];
	
}

vector getColor(){
	if( fxcolor == ZERO_VECTOR )
		return color;
	vector out = fxcolor;
	return out;
}

pruneTmpVis(){
	list prune;
	integer i;
	for(; i < count(TMP_VIS); i += TMPVIS_STRIDE ){
		
		float started = l2f(TMP_VIS, i);
		float dur = l2f(TMP_VIS, i+1);
		if( llGetTime() < started+dur )
			prune += llList2List(TMP_VIS, i, i+TMPVIS_STRIDE-1);
		
	}
	TMP_VIS = prune;
}


updateDesc( integer st ){
	
	list d = explode("$$", llGetObjectDesc());
	if( llGetObjectDesc() == "(No Description)" || llGetObjectDesc() == "" )
		d = [];
		
	integer i = count(d);
	while( i-- ){
		
		list sub = explode("$", l2s(d, i));
		if( l2s(sub, 0) == "TAG" ){
			
			int n = count(sub);
			int found;
			while( n-- && !found ){
			
				list subtag = explode("_", l2s(sub, n));
				if( found = (l2s(subtag, 0) == "gottv") )
					sub = llListReplaceList(sub, (list)("gottv_"+(str)st), n, n);					
				
				
			}
			
			if( !found )
				sub += (list)("gottv_"+(str)st);
		
			d = llListReplaceList(d, (list)llDumpList2String(sub, "$"), i,i);
			llSetObjectDesc(llDumpList2String(d, "$$"));
			return;
		}
		
	}
	// No meta tags setup yet. We need to add one
	llSetObjectDesc("TAG$gottv_"+(str)st);

}

draw(){
	
	vector activeColor = getColor();
	int st = currentState;
	if( st == ThongManPreset$DEFAULT && rainState )
		st = ThongManPreset$WET;
		
	list slice = getActiveTmpVis();
	if( slice ){
		
		vector v = (vector)l2s(TMP_VIS, 2);
		if( l2i(TMP_VIS, 4) )
			st = l2i(TMP_VIS, 4);
		if( v != ZERO_VECTOR )
			activeColor = v;
	
	}
	
	
	
	if( BFL & BFL_DEAD )
		st = ThongManPreset$DEAD;
		
	float delta = llGetTime()-time_hit;
	// Legacy takes presidence
	if( time_hit > 0 && delta < 1.5 ){
		
		delta -= 0.5; // hold time
		if( delta < 0 )
			delta = 0;
		else if( delta > 1 )
			delta = 1;
		activeColor = activeColor*delta + hit*(1.0-delta);
		
	}
	
	if( st != lastState ){
		lastState = st;
		updateDesc(st);		
	}
	
	list set;
	int prim;
	for( prim = 1; prim <= llGetNumberOfPrims(); ++prim ){
		
		list keys = llLinksetDataFindKeys("^gotTM"+(str)st+":\\[\""+llGetLinkName(prim), 0, 0);
		if( keys ){
			
			set += (list)PRIM_LINK_TARGET + prim;
			
			int i;
			for(; i < count(keys); ++i ){
				
				string k = l2s(keys, i);
				int pos = llSubStringIndex(k, ":");
				list dta = llJson2List(llGetSubString(k, pos+1, -1));
				int face = l2i(dta, 1);
				key texture = llLinksetDataRead(k);
				if( texture == JSON_NULL )
					texture = "4f3fa15e-5a28-d8c5-64d7-ceded5644899"; // Default hidden
				else if( texture == "LEGACY" )
					texture = "";
				set += (list)
					PRIM_RENDER_MATERIAL + face + texture
				;
				// Bugs out if doing this while dead
				if( st )
					set += (list)PRIM_GLTF_BASE_COLOR + face + "" + "" + "" + "" + activeColor + "" + "" + "" + "";
			
			}
			
			
		}
	
	}
	PP(0, set);
	
}

takeHit( vector col ){

	if( BFL&BFL_DEAD )
		return;
    
	if( col == <-1,-1,-1> )
		col = ZERO_VECTOR;
		
	if( col != ZERO_VECTOR ){
		hit = col;
		time_hit = llGetTime();
		multiTimer(["HIT", 0, 0.5, FALSE]);
	}
	else if( time_hit <= 0 )
		multiTimer(["HIT"]);
		
	draw();
    raiseEvent(ThongManEvt$hit, mkarr((list)col));
    
	
}


timerEvent(string id, string data){

    if( id == "HIT" ){
	
		draw();
		if( llGetTime()-time_hit < 1.5 )
			multiTimer(["HIT", 0, .01, FALSE]);
		else
			time_hit = 0;
		
    }
	// Particle stop
	else if( llGetSubString(id, 0, 1) == "P_" )
		llLinkParticleSystem((int)llGetSubString(id, 2, -1), []);
	// Death particles off (needed because SL will play a stopped particle system when prim is edited)
	else if( id == "DP" ){
		llLinkParticleSystem(2, []);
	}
	else if( id == "TMPVIS" ){
		
		pruneTmpVis();
		if( TMP_VIS ){
			
			// Only update when top priority fades
			float dur = l2f(TMP_VIS, 0)+l2f(TMP_VIS, 1)-llGetTime();
			if( dur < .1 )
				dur = .1;
			multiTimer([id, 0, dur, FALSE]);
			
		}
		draw();
		
	}
	else if( id == "RAIN" ){
		
		list ray = llCastRay(llGetPos(), llGetPos()-<0,0,10>, RC_DEFAULT);
		if( l2i(ray, -1) != 1 )
			return;
			
		string desc = prDesc(l2k(ray, 0));
		getDescTaskData(desc, ss, "SS");
		if( l2s(ss,0) == "ra" ) // Rain detected
			last_rain = llGetTime();
		
		// Checks if we are wet from rain
		int rs = (last_rain > 0 && llGetTime()-last_rain < 30);
		if( rainState != rs ){
			rainState = rs;
			draw();
		}
		
	}
	
}

fetch(){
	integer pin = llCeil(llFrand(0xFFFFFFF));
	llSetRemoteScriptAccessPin(pin);
	Remoteloader$load(cls$name, pin, 2, TRUE);
}

default{
    
    timer(){multiTimer([]);}
    
    state_entry(){
	
		llStopSound();
        llListen(239186, "", llGetOwner(), "");
        initiateListen();
		llLinkParticleSystem(2, []);
		raiseEvent(evt$SCRIPT_INIT, "");
		ThongMan$attached();
		draw();
		
		multiTimer(["RAIN", 0, 2, TRUE]);
		
    }
	
	attach( key id ){
	
		if( id )
			fetch();
			
	}
    
    
    
    // This is the listener
    #include "xobj_core/_LISTEN.lsl"
    
    
    
    run_time_permissions(integer perm){
        if( perm&PERMISSION_ATTACH )
			llDetachFromAvatar();
    }

    
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
	
	// Hit effect
	if(METHOD == ThongManMethod$hit){
	
		string color = method_arg(0);
		vector c = (vector)color;
		if( color == "" )
			c = <-1,-1,-1>;
		takeHit(c);
		
	}
	
	// Temp override of visual
	else if( METHOD == ThongManMethod$fxVisual ){
	
		// Reset defaults
		vector color = (vector)method_arg(0);
		float glow = l2f(PARAMS, 1);
		integer cs = l2i(PARAMS, 2);
		float dur = l2f(PARAMS, 3);
		if( !cs )
			cs = ThongManPreset$DEFAULT; // prevent dead state
		
		
		if( dur > 0 ){

			pruneTmpVis();
			// Todo: Add to a list of effects
			list add = (list)color + glow + cs;
			integer pos = llListFindStrided(TMP_VIS, add, 2,-1, TMPVIS_STRIDE); // Pos includes the offset, so if you want start of stride you need to subtract 2 from pos

			if( ~pos )
				TMP_VIS = llListReplaceList(TMP_VIS, (list)llGetTime() + dur, pos-2, pos-1);
			else
				TMP_VIS += (list)llGetTime() + dur + add;
				
			TMP_VIS = llListSort(TMP_VIS, TMPVIS_STRIDE, FALSE); // Sort it so the last 
			// [(vec)color, (float)glow, (int)type, (float)dur, (float)added]
			
			multiTimer(["TMPVIS", 0, dur+.1, FALSE]);

		}
		// Old style where one overrides the other
		else{
			time_fx = cs;
			currentState = cs;
			fxcolor = color;
			fxglow = glow;
		
		}
		
		draw();
		
	}
	else if( METHOD == ThongManMethod$remTempVisuals ){
		
		TMP_VIS = [];
		multiTimer(["TMPVIS"]);
		draw();
	}
	
    if(method$byOwner){
	
		// Prevents multiple attachments
        if( METHOD == ThongManMethod$attached ){
		
            if( llGetAttached() )
				llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
				
        }
		
		// Loop a sound
		else if( METHOD == ThongManMethod$sound ){
		
			key id = method_arg(0);
			float vol = (float)method_arg(1);
			integer loop = l2i(PARAMS, 2);
			if( vol <= 0 )
				vol = 1;
				
			if( id ){
			
				if(loop)
					llLoopSound(id, vol);
				else
					llTriggerSound(id, vol);
					
			}
			else 
				llStopSound();
				
		}
		
		// Resets the script
        else if(METHOD == ThongManMethod$reset){
		
            if( (int)method_arg(0) )
				llOwnerSay("Fetching");
            fetch();
			
        }
		
		
		// Add or remove particles
		else if( METHOD == ThongManMethod$particles ){
		
			float timeout = l2f(PARAMS, 0);
			integer prim = l2i(PARAMS, 1);
			if( prim == 0 )
				prim = LINK_THIS;
				
			list data = llJson2List(method_arg(2));
			
			integer i;
			for( ; i < count(data); ++i ){
				
				string s = llList2String(data, i);
				// Check if vector
				if( llGetSubString(s, 0,0) == "<" && llGetSubString(s, -1, -1) == ">" )
					data = llListReplaceList(data, [(vector)s], i, i);
				
			}
			
			llLinkParticleSystem(prim, data);
			if( timeout > 0 )
				multiTimer(["P_"+(string)prim, "", timeout, FALSE]);
				
		}
		
		// Dead or nude
		else if( METHOD == ThongManMethod$dead ){
		
			multiTimer(["A"]); // Remove current fade effect
			integer dead = l2i(PARAMS, 0);
			integer fx = l2i(PARAMS, 1);
			
			if( dead ){
			
				BFL = BFL|BFL_DEAD;
				llStopSound();
				if( fx ){
				
					llLinkParticleSystem(2, [
						PSYS_PART_MAX_AGE,.2, // max age
						PSYS_PART_FLAGS, 
							PSYS_PART_EMISSIVE_MASK|
							PSYS_PART_INTERP_COLOR_MASK|
							PSYS_PART_INTERP_SCALE_MASK|
							//PSYS_PART_RIBBON_MASK|
							PSYS_PART_FOLLOW_VELOCITY_MASK
							, // flags, glow etc
						PSYS_PART_START_COLOR, <1, 0, 1.>, // startcolor
						PSYS_PART_END_COLOR, <1, 1, 1.>, // endcolor
						PSYS_PART_START_SCALE, <.0, .0, 0>, // startsize
						PSYS_PART_END_SCALE, <.05, .05, 0>, // endsize
						PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE, // pattern
						PSYS_SRC_BURST_RATE, 0.01, // rate
						PSYS_SRC_ACCEL, <0,0,-5>,  // push
						PSYS_SRC_BURST_PART_COUNT, 10, // count
						PSYS_SRC_BURST_RADIUS, 0.1, // radius
						PSYS_SRC_BURST_SPEED_MIN, 2.0, // minSpeed
						PSYS_SRC_BURST_SPEED_MAX, 4., // maxSpeed
						// PSYS_SRC_TARGET_KEY, NULL_KEY, // target
						PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
						PSYS_SRC_MAX_AGE, .5, // life
						PSYS_SRC_TEXTURE, "3c4c846e-450f-d2b9-adfd-117d5aa2c9b7", // texture
						
						PSYS_PART_START_ALPHA, 1, // startAlpha
						PSYS_PART_END_ALPHA, 1.0, // endAlpha
						PSYS_PART_START_GLOW, 0.2,
						PSYS_PART_END_GLOW, 1,
						
						PSYS_SRC_ANGLE_BEGIN, 0, // angleBegin
						PSYS_SRC_ANGLE_END, 0 // angleend
						
					]);
					llTriggerSound("a0f4e168-1eb0-465e-2db9-5beaa2e2891a", 1);
					multiTimer(["DP", 0, 1, FALSE]);
					
				}			
				
				
			}
			else
				BFL = BFL&~BFL_DEAD;
				
			
			draw();
			raiseEvent(ThongManEvt$death, mkarr([(BFL&BFL_DEAD)>0]));
			
		}
    }

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
