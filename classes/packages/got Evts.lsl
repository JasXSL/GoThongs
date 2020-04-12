#define USE_EVENTS
#include "got/_core.lsl"

integer BFL;
#define BFL_RECENT_CACHE 0x1
#define BFL_QTE_PRESSED 0x2 // QTE button pressed
#define BFL_TEXTURES_SENT 0x4			// Block sending more textures
#define BFL_TEXTURES_SCHEDULED 0x8		// Textures should be sent when cooldown expires
#define BFL_LR 0x10						// We're currently pressing left right

#define CARPAL_PROTECTION 0.5			// Adds a max cap on how fast you can press

integer TEAM = TEAM_PC;

integer pointer;
list output_cache = [];		// score, key
list nearby_cache = [];		// key, key...
vector cache_pos;
rotation cache_rot;
key cache_targ;

int P_BUTTONS;
int P_BAR;

#define SPSTRIDE 7
list SPELL_ICONS;   // [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks, (int)flags]


list TARGETED_BY;	// Players currently actively targeting you

#define descIsProper(desc) llGetSubString(desc, 0, 2) == "$M$" && (int)llGetSubString(desc, 3, 3) != TEAM

// If FIRST is true, it will ignore current target
output(integer first){

	if( output_cache == [] ){
	
		integer i;
		for(; i<llGetListLength(nearby_cache); ++i ){
		
			key t = l2k(nearby_cache, i);
			vector pos = prPos(t);
				
			float dist = llVecDist(pos, llGetRootPosition());
			float angle = llRot2Angle(llRotBetween(llRot2Fwd(llGetRot()), llVecNorm(pos-llGetRootPosition())))*RAD_TO_DEG;
			float score = dist+angle/8;
			
			// Prevents targeting the same one again
			if( first && t == cache_targ )
				score = 9001;
			output_cache += [score, llList2Key(nearby_cache, i)];
			
		}
		output_cache = llListSort(output_cache, 2, TRUE);
		
	}

	if( output_cache == [] )
		return;
	
	
	integer i;
	for(; i<llGetListLength(output_cache); i+=2 ){
	
		if( pointer>=llGetListLength(output_cache)/2 )
			pointer = 0;
		
		key t = llList2Key(output_cache, pointer*2+1);
		vector pos = prPos(t);
		list ray = llCastRay(llGetRootPosition(), pos+<0,0,.5>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
		
		string desc = prDesc(t);
		if( llList2Integer(ray, -1) <1 && descIsProper(desc) ){
		
			Status$monster_attemptTarget(t, true);
			return;
			
		}
		pointer++;
		
	}
}

onEvt( string script, integer evt, list data ){

	if( script == "got Status" && evt == StatusEvt$team )
		TEAM = l2i(data,0);
	else if( script == "#ROOT" ){
	
		if( evt == RootEvt$targ )
			cache_targ = l2s(data, 0);
			
		else if( evt == evt$BUTTON_PRESS && QTE_STAGES > 0 ){
			
			list map = [
				CONTROL_UP|CONTROL_FWD,
				CONTROL_LEFT|CONTROL_ROT_LEFT,
				CONTROL_DOWN|CONTROL_BACK,
				CONTROL_RIGHT|CONTROL_ROT_RIGHT
			];
			
			integer i;
			for(; i<count(map); ++i ){
			
				if( l2i(map, i)&l2i(data, 0) ){
					qteButtonTouched(i);
					return;
				}
				
			}
			
		}
		
		else if(evt == evt$TOUCH_START && QTE_STAGES > 0 && l2i(data, 0) == P_BUTTONS){

			integer face = l2i(data, 2);
			integer pos = llListFindList(QTE_KEYMAP+QTE_BORDERMAP, [face]);
			if(pos == -1)
				return;
			if(pos > 3)
				pos -= 4;
			
			qteButtonTouched(pos);
		}
		
	}
	else if( evt == StatusEvt$targeted_by && script == "got Status" ){
		
		TARGETED_BY = data;
		ptSet("OP", .2, FALSE);
		
	}
	else if( script == "got Status" && evt == StatusEvt$dead && l2i(data, 0) && QTE_STAGES > 0 ){
	
		debugCommon("Ending because player died")
		toggleQTE(FALSE, FALSE);
		
	}
	
}

float fxMod = 1.0;	// Multiplier against nr steps in a QTE

// Position of the QTE widget
#define BASE_POS <0.023560, -0.303590, 0.647901>

list QTE_SENDER_DATA;			// (key)id||(int)link, (str)scriptName, (str)custom
integer QTE_STAGES;
integer QTE_KEY;
	#define QTE_KEY_UP 0
	#define QTE_KEY_LEFT 1
	#define QTE_KEY_DOWN 2
	#define QTE_KEY_RIGHT 3
list QTE_KEYMAP = [7,0,1,2];		// Faces
list QTE_BORDERMAP = [3,4,5,6];		// Faces
float QTE_DELAY;
integer QTE_FLAGS;	// See the header files. These are Evts$qFlags
integer QTE_LR_FLASH;
float QTE_LR_PERC = 0.5;
float QTE_DELTA;	// Used for LR to get around lag

qteButtonTouched( integer button ){
	
	if( BFL&BFL_QTE_PRESSED )
		return;
		
	integer success = (button == QTE_KEY);
	
	// Handle LR
	if( QTE_FLAGS & Evts$qFlags$LR ){
		
		if( success ){
			
			if( QTE_KEY == QTE_KEY_LEFT )
				QTE_KEY = QTE_KEY_RIGHT;
			else
				QTE_KEY = QTE_KEY_LEFT;
			BFL = BFL|BFL_LR;	// Mark that we are pressing
			ptSet("lrPress", CARPAL_PROTECTION, FALSE);
			
		}
		return;
	}
	
	// Normal
	
	// SUCCESS
	if(success){
	
		llPlaySound("45ab8496-0fad-b8f9-281d-02aaf588e306", 1);
		// DONE
		if( --QTE_STAGES == 0 ){
			
			debugCommon("Ending QTE because all buttons pressed")
			toggleQTE(FALSE, FALSE);
			return;
			
		}
		toggleQTE(TRUE, FALSE);
		
	}
	else{
		llPlaySound("dafef83b-035f-b2b8-319d-daac01b0936e", 1);
		llSetLinkColor(P_BUTTONS, <1,.25,.25>, l2i(QTE_BORDERMAP, button));
		llSetLinkTextureAnim(P_BUTTONS, ANIM_ON|LOOP|PING_PONG, l2i(QTE_BORDERMAP, button), 16,2, 0,0, 120);
		ptSet("QTEf", 1+QTE_DELAY, FALSE);
		BFL = BFL|BFL_QTE_PRESSED;
	}
	
	sendCallback(l2s(QTE_SENDER_DATA, 0), l2s(QTE_SENDER_DATA, 1), EvtsMethod$startQuicktimeEvent, mkarr(([EvtsEvt$QTE$BUTTON, success])), l2s(QTE_SENDER_DATA, 2));
	
}

toggleQTE(integer on, integer instant){
	
	if(!on){
	
		ptUnset("QTE");
		ptUnset("next");
		ptUnset("lrTick");
		ptUnset("lrPress");
		llSetLinkPrimitiveParamsFast(P_BUTTONS, [
			PRIM_POSITION, ZERO_VECTOR, PRIM_SIZE, ZERO_VECTOR,
			PRIM_LINK_TARGET, P_BAR, PRIM_POSITION, ZERO_VECTOR, PRIM_SIZE, ZERO_VECTOR
		]);
		
		onQteEnd(TRUE);
		QTE_STAGES = 0;
		
		return;
	}
	
	BFL = BFL &~ (BFL_QTE_PRESSED|BFL_LR);
	
	llSetLinkPrimitiveParamsFast(P_BUTTONS, [PRIM_SIZE, ZERO_VECTOR]);
	float time = 0.1;
	if( !instant )
		time += QTE_DELAY;
		
	if( ~QTE_FLAGS & Evts$qFlags$LR )
		ptSet("next", time, FALSE);
	else{
	
		llSetLinkPrimitiveParamsFast(P_BAR, [PRIM_SIZE, <0.22755, 0.02960, 0.01814>, PRIM_POSITION, BASE_POS+<0,0,-.1>]);
		ptSet("lrTick", 0.1, TRUE);
		QTE_DELTA = llGetTime();
		QTE_KEY = QTE_KEY_LEFT;
		
	}
}

onQteEnd( int success ){

	sendCallback(
		l2s(QTE_SENDER_DATA, 0), 
		l2s(QTE_SENDER_DATA, 1), 
		EvtsMethod$startQuicktimeEvent, 
		mkarr((list)EvtsEvt$QTE$END + success), 
		l2s(QTE_SENDER_DATA, 2)
	);
	raiseEvent(EvtsEvt$QTE, "0");
	QTE_SENDER_DATA = [];
	
}


ptEvt( string id ){

	if( id == "CACHE" )
		BFL = BFL&~BFL_RECENT_CACHE;
		
	// Advance QTE stage
	else if( llGetSubString(id,0,2) == "QTE" ){
		
		debugCommon("Stages left "+(str)QTE_STAGES);
		toggleQTE(QTE_STAGES, llGetSubString(id, -1, -1) == "f");
		
	}
	// Set spell textures
	else if(id == "OP"){
	
		// Always send to self
		integer i; list out;
		for( ; i<llGetListLength(SPELL_ICONS) && i/SPSTRIDE < 8; i+=SPSTRIDE )
			out+= llDeleteSubList(llList2List(SPELL_ICONS, i, i+SPSTRIDE-1), 2, 2);
		GUI$setMySpellTextures(out);
	
		// Textures sent too recently
		if( BFL&BFL_TEXTURES_SENT || !count(TARGETED_BY) ){
		
			BFL = BFL|BFL_TEXTURES_SCHEDULED;
			return;
			
		}
			
		BFL = BFL_TEXTURES_SENT;
		
		string s = llDumpList2String(out,",");
		for( i=0; i<count(TARGETED_BY); i+= 2 ){
			
			integer n = l2i(TARGETED_BY, i+1);
			if( n&NPCInt$targeting )
				GUI$setSpellTextures(l2s(TARGETED_BY, i), s);
		
		}
		ptSet("OPE", count(TARGETED_BY)*0.25, FALSE);
		
    }
	// Texture send cooldown
	else if( id == "OPE" ){
		
		BFL = BFL&~BFL_TEXTURES_SENT;
		if( BFL&BFL_TEXTURES_SCHEDULED )
			ptSet("OP", 0.1, FALSE);			
		
	}
	
	// Draw the QTE button
	else if( id == "next" ){
	
		vector scale = <0.21188, 0.14059, 0.13547>;
		vector pos = <0.023560, -0.303590, 0.647901>;
		QTE_KEY = llFloor(llFrand(4));
		integer i;
		list out = [PRIM_POSITION, pos,PRIM_SIZE, scale];
		for(i=0; i<4; ++i){
			vector color = ZERO_VECTOR;
			if( i == QTE_KEY )
				color = <.5,1,.5>;
			out+= [PRIM_COLOR, l2i(QTE_BORDERMAP, i), color, 1];
		}
		llSetLinkTextureAnim(P_BUTTONS, ANIM_ON|LOOP|PING_PONG, l2i(QTE_BORDERMAP, QTE_KEY), 16,2, 0,0, 120);
		PP(P_BUTTONS, out);
		
		BFL = BFL&~BFL_QTE_PRESSED;
		
	}
	// Stops the carpal tunnel protection
	else if( id == "lrPress" ){
		BFL = BFL&~BFL_LR;
	}
	// Flash left / right buttons on LR event
	else if( id == "lrTick" ){
	
		float amount = (float)QTE_STAGES/100;
		if( amount <= 0 )
			amount = 0.3;
			
		// Currently pressing
		if( BFL&BFL_LR ){
			// Multiply by fx
			float f = fxMod;
			if( fxMod <= 0 )
				f = 0.1;
			amount /= f;
			if( QTE_FLAGS & Evts$qFlags$LR_CAN_FAIL )	// Slow down fail because it starts at 40%
				amount *= 0.6;
		}else{
			// Fade speed is always half speed
			amount = -amount/2;			
		}
		
		
			
		float time = llGetTime();
		float delta = time-QTE_DELTA;
		QTE_DELTA = time;
		QTE_LR_PERC += amount*delta;
				
		if( QTE_LR_PERC < 0 )
			QTE_LR_PERC = 0;
			
		list out = [PRIM_LINK_TARGET, P_BAR, PRIM_TEXTURE, 2, GUI$BAR_TEXTURE, <.5,1,1>, <.25-.5*QTE_LR_PERC, 0, 0>, 0];
	
		// Check if fail
		if( QTE_FLAGS & Evts$qFlags$LR_CAN_FAIL && QTE_LR_PERC <= 0 ){
			onQteEnd(FALSE);
			toggleQTE(FALSE, FALSE);
			return;
		}
		else if( QTE_LR_PERC >= 1 ){
			onQteEnd(TRUE);
			toggleQTE(FALSE, FALSE);	// Finished
			return;
		}
	
		vector scale = <0.21188, 0.14059, 0.13547>;
		integer i;
		++QTE_LR_FLASH;
		out += [PRIM_LINK_TARGET, P_BUTTONS, PRIM_POSITION, BASE_POS,PRIM_SIZE, scale];
		for(i=0; i<4; ++i){
		
			vector color = ZERO_VECTOR;
			if( (i == 1 && !(QTE_LR_FLASH%2)) || (i == 3 && QTE_LR_FLASH%2) ){
				color = <.5,1,.5>;
				llSetLinkTextureAnim(P_BUTTONS, ANIM_ON|LOOP|PING_PONG, l2i(QTE_BORDERMAP, i), 16,2, 0,0, 120);
			}
			out+= [PRIM_COLOR, l2i(QTE_BORDERMAP, i), color, 1];
			
		}
		
		PP(0, out);
		
	}
	
}

default{

    state_entry(){
	
        llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoThongs, 1");
        llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoT, 1");
        memLim(1.5);
		
		links_each(nr, name,
		
			if(name == "QTEVT")
				P_BUTTONS = nr;
			if( name == "QTE_BAR" )
				P_BAR = nr;
				
		)
		
		string tx = "b6f0605b-e818-7dfc-353f-9e458c956816";
		llSetLinkPrimitiveParamsFast(P_BUTTONS, [
			PRIM_TEXTURE, ALL_SIDES, "37545817-a832-f9ae-a379-750a095463db", <1./16,1./2,0>, <1./32-1./16*8,1./4, 0>, 0,
			PRIM_TEXTURE, 7, tx, <1./4,1,0>, <-1./8-1./4,0, 0>, 0,
			PRIM_TEXTURE, 0, tx, <1./4,1,0>, <-1./8,0, 0>, 0,
			PRIM_TEXTURE, 1, tx, <1./4,1,0>, <-1./8+1./4,0, 0>, 0,
			PRIM_TEXTURE, 2, tx, <1./4,1,0>, <-1./8+1./4*2,0, 0>, 0			
		]);
		
		toggleQTE(FALSE, FALSE);
		
    }
    changed(integer change){
        if(change&CHANGED_REGION){
			resetAll();
		}
    }
    
    attach(key id){
        if(id == NULL_KEY){
			llOwnerSay("@detachall:JasX/onAttach/GoThongs=force");
			llOwnerSay("@detachall:JasX/onAttach/GoT=force");
			
            llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoThongs, 0");
            llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoT, 0");
        }
    }
	
	sensor(integer total){
		integer i;
		for(i=0; i<total; i++){
			string desc = prDesc(llDetectedKey(i));
			if(descIsProper(desc)){
				nearby_cache+=llDetectedKey(i);
			}
			
		}
		
		output(TRUE);
	}
	
	
	timer(){
		ptRefresh();
	}
	
	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		fxMod = i2f(l2f(data, FXCUpd$QTE_MOD)); \
    } \
	
    #include "xobj_core/_LM.lsl" 
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }
    
    if(method$internal){
	
        if(METHOD == EvtsMethod$cycleEnemy){
			
			
			if(
				// Moved more than 1m
				llVecDist(llGetRootPosition(), cache_pos)>1 || 
				// Rotated more than 45 deg
				llAngleBetween(llGetRot(), cache_rot)>PI/8 || 
				// Not cached within 4 sec
				~BFL&BFL_RECENT_CACHE || 
				// Nobody nearby found
				nearby_cache == []
			){
				// Build a new list of targets
				BFL = BFL|BFL_RECENT_CACHE;
				cache_pos = llGetRootPosition();
				cache_rot = llGetRot();
				nearby_cache = [];
				output_cache = [];
				pointer = 0;
				llSensor("", "", SCRIPTED, 14, PI_BY_TWO);
			}
			else{
				pointer++;
				output(FALSE);
			}
			ptSet("CACHE", 4, FALSE);
		}
		
		else if(
			METHOD == EvtsMethod$addTextureDesc ||
			METHOD == EvtsMethod$remTextureDesc ||
			METHOD == EvtsMethod$stacksChanged
		){
			
			if( METHOD == EvtsMethod$addTextureDesc ){
				// [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks, (int)pflags]
				SPELL_ICONS += 
					// PID
					(list)l2i(PARAMS, 0) + 
					// Texture
					method_arg(1) +
					// Desc
					method_arg(2) + 
					// Added
					l2i(PARAMS, 3) + 
					// Duration
					l2i(PARAMS, 4) + 
					// Stacks
					l2i(PARAMS, 5) +
					// Flags
					l2i(PARAMS, 6)
				;
			}
			else if(METHOD == EvtsMethod$remTextureDesc){
			
				integer pid = l2i(PARAMS, 0);
				integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
				if( pos == -1 )
					return;
				
				SPELL_ICONS = llDeleteSubList(SPELL_ICONS, pos*SPSTRIDE, pos*SPSTRIDE+SPSTRIDE-1);
				
			}
			else{
			
				integer pid = (integer)method_arg(0);
				integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
				if( pos == -1 )
					return;
				
				SPELL_ICONS = llListReplaceList(SPELL_ICONS, 
					(list)l2i(PARAMS, 1) +l2i(PARAMS, 2) + l2i(PARAMS, 3), 
				pos*SPSTRIDE+3,pos*SPSTRIDE+5);
				
			}
			
			
			// Set textures after 0.2 sec of finishing receiving updates
			ptSet("OP", 0.2, FALSE);
			
			
        }

    }
	
	if( METHOD == EvtsMethod$startQuicktimeEvent ){
	
		debugCommon("Start received: "+mkarr(PARAMS)+" from "+SENDER_SCRIPT)
		QTE_STAGES = floor(l2i(PARAMS, 0)*fxMod);
		if( QTE_STAGES < 1 && l2i(PARAMS, 0) > 0 )
			QTE_STAGES = 1;
		QTE_DELAY = l2f(PARAMS, 2);
			
		QTE_FLAGS = l2i(PARAMS, 3);
		
		// QTE_STAGES has a default on LR. Use -1 to end
		if( QTE_STAGES == 0 && QTE_FLAGS&Evts$qFlags$LR )
			QTE_STAGES = 30;
		
		// Tells any active QTE sender that it has ended, useful if QTE ended by someone other than the one that initiated it
		if( QTE_STAGES < 1 )
			onQteEnd(FALSE);
		else
			raiseEvent(EvtsEvt$QTE, (str)QTE_STAGES);
		
		CB_DATA = [EvtsEvt$QTE$APPLY];
		list targ = [nr];
		if(id != "")
			targ = [id];
			
		QTE_SENDER_DATA = targ+[SENDER_SCRIPT, CB];
		
		QTE_LR_PERC = 0;
		if( QTE_FLAGS & Evts$qFlags$LR_CAN_FAIL )
			QTE_LR_PERC = .4;
			
		
		float preDelay = l2f(PARAMS, 1);
		if( preDelay ){
			ptSet("QTE", preDelay, FALSE);
			BFL = BFL|BFL_QTE_PRESSED;
		}
		else{
			
			debugCommon("Starting QTE immediately with stages "+(str)QTE_STAGES)
			toggleQTE((QTE_STAGES > 0), TRUE);	// -1 should also stop
			
		}
		
	}
	
	else if(METHOD == EvtsMethod$getTextureDesc){
        
		if( id == "" )
			id = llGetOwner();
		
		integer pid = (integer)method_arg(0);
        integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);

        if( pos == -1 )
			return;
		
		llRegionSayTo(llGetOwnerKey(id), 0, evtsStringitizeDesc(
			llList2String(SPELL_ICONS, pos*SPSTRIDE+2),
			l2i(SPELL_ICONS, pos*SPSTRIDE+5)
		));
		
    }

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}



