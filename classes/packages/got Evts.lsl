#define USE_EVENTS
#include "got/_core.lsl"

integer BFL;
#define BFL_RECENT_CACHE 0x1
#define BFL_QTE_PRESSED 0x2 // QTE button pressed
#define BFL_TEXTURES_SENT 0x4			// Block sending more textures
#define BFL_TEXTURES_SCHEDULED 0x8		// Textures should be sent when cooldown expires

integer TEAM = TEAM_PC;

integer pointer;
list output_cache = [];		// score, key
list nearby_cache = [];		// key, key...
vector cache_pos;
rotation cache_rot;
key cache_targ;

integer P_BUTTONS;

#define SPSTRIDE 6
list SPELL_ICONS;   // [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks]


list TARGETED_BY;	// Players currently actively targeting you

#define descIsProper(desc) llGetSubString(desc, 0, 2) == "$M$" && (int)llGetSubString(desc, 3, 3) != TEAM

// If FIRST is true, it will ignore current target
output(integer first){
	if(output_cache == []){
		integer i;
		for(i=0; i<llGetListLength(nearby_cache); i++){
			key t = l2k(nearby_cache, i);
			vector pos = prPos(t);
				
			float dist = llVecDist(pos, llGetRootPosition());
			float angle = llRot2Angle(llRotBetween(llRot2Fwd(llGetRot()), llVecNorm(pos-llGetRootPosition())))*RAD_TO_DEG;
			float score = dist+angle/8;
			
			// Prevents targeting the same one again
			if(first && t == cache_targ)
				score = 9001;
			output_cache += [score, llList2Key(nearby_cache, i)];
		}
		output_cache = llListSort(output_cache, 2, TRUE);
	}

	if(output_cache == [])return;
	
	
	
	integer i;
	for(i=0; i<llGetListLength(output_cache); i+=2){
		if(pointer>=llGetListLength(output_cache)/2)pointer = 0;
		
		key t = llList2Key(output_cache, pointer*2+1);
		vector pos = prPos(t);
		list ray = llCastRay(llGetRootPosition(), pos+<0,0,.5>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
		
		string desc = prDesc(t);
		if(llList2Integer(ray, -1) <1 && descIsProper(desc)){
			Status$monster_attemptTarget(t, true);
			return;
		}
		pointer++;
	}
}

onEvt(string script, integer evt, list data){
	if(script == "got Status" && evt == StatusEvt$team)
		TEAM = l2i(data,0);
	else if(script == "#ROOT"){
	
		if(evt == RootEvt$targ)
			cache_targ = l2s(data, 0);
			
		else if(evt == evt$BUTTON_PRESS && QTE_STAGES > 0){
			
			list map = [
				CONTROL_UP|CONTROL_FWD,
				CONTROL_LEFT|CONTROL_ROT_LEFT,
				CONTROL_DOWN|CONTROL_BACK,
				CONTROL_RIGHT|CONTROL_ROT_RIGHT
			];
						
			integer i;
			for(i=0; i<count(map); ++i){
				if(l2i(map, i)&l2i(data, 0)){
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
	
}

list QTE_SENDER_DATA;			// (key)id||(int)link, (str)scriptName, (str)custom
integer QTE_STAGES;
integer QTE_KEY;
	#define QTE_KEY_UP 0
	#define QTE_KEY_LEFT 1
	#define QTE_KEY_DOWN 2
	#define QTE_KEY_RIGHT 3
list QTE_KEYMAP = [7,0,1,2];		// Faces
list QTE_BORDERMAP = [3,4,5,6];		// Faces

qteButtonTouched(integer button){
	if(BFL&BFL_QTE_PRESSED)
		return;
		
	integer success = (button == QTE_KEY);
	// SUCCESS
	
	if(success){
		llPlaySound("45ab8496-0fad-b8f9-281d-02aaf588e306", 1);
		// DONE
		if(--QTE_STAGES == 0){
			toggleQTE(FALSE);
			onQteEnd(TRUE);
			return;
		}
		
		toggleQTE(TRUE);
	}
	else{
		llPlaySound("dafef83b-035f-b2b8-319d-daac01b0936e", 1);
		llSetLinkColor(P_BUTTONS, <1,.25,.25>, l2i(QTE_BORDERMAP, button));
		llSetLinkTextureAnim(P_BUTTONS, ANIM_ON|LOOP|PING_PONG, l2i(QTE_BORDERMAP, button), 16,2, 0,0, 120);
		ptSet("QTE", 2, FALSE);
		BFL = BFL|BFL_QTE_PRESSED;
	}
	
	sendCallback(l2s(QTE_SENDER_DATA, 0), l2s(QTE_SENDER_DATA, 1), EvtsMethod$startQuicktimeEvent, mkarr(([EvtsEvt$QTE$BUTTON, success])), l2s(QTE_SENDER_DATA, 2));
	
}

toggleQTE(integer on){
	
	if(!on){
		ptUnset("QTE");
		llSetLinkPrimitiveParamsFast(P_BUTTONS, [PRIM_POSITION, ZERO_VECTOR, PRIM_SIZE, ZERO_VECTOR]);
		return;
	}
	
	vector scale = <0.21188, 0.14059, 0.13547>;
	vector pos = <0.023560, -0.303590, 0.647901>;
	llSetLinkPrimitiveParams(P_BUTTONS, [PRIM_SIZE, ZERO_VECTOR]);
	
	QTE_KEY = llFloor(llFrand(4));
	integer i;
	list out = [PRIM_POSITION, pos,PRIM_SIZE, scale];
	for(i=0; i<4; ++i){
		vector color = ZERO_VECTOR;
		if(i == QTE_KEY)
			color = <.5,1,.5>;
		out+= [PRIM_COLOR, l2i(QTE_BORDERMAP, i), color, 1];
	}
	llSetLinkTextureAnim(P_BUTTONS, ANIM_ON|LOOP|PING_PONG, l2i(QTE_BORDERMAP, QTE_KEY), 16,2, 0,0, 120);
	PP(P_BUTTONS, out);
	
	BFL = BFL&~BFL_QTE_PRESSED;
	
}

onQteEnd(integer success){
	sendCallback(l2s(QTE_SENDER_DATA, 0), l2s(QTE_SENDER_DATA, 1), EvtsMethod$startQuicktimeEvent, mkarr(([EvtsEvt$QTE$END, success])), l2s(QTE_SENDER_DATA, 2));
	raiseEvent(EvtsEvt$QTE, "0");
	QTE_SENDER_DATA = [];
}


ptEvt( string id ){

	if(id == "CACHE")
		BFL = BFL&~BFL_RECENT_CACHE;
	else if(id == "QTE")
		toggleQTE(QTE_STAGES);
	else if(id == "OP"){
	
		// Always send to self
		integer i; list out;
		for( i=0; i<llGetListLength(SPELL_ICONS) && i/SPSTRIDE < 8; i+=SPSTRIDE )
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
	else if( id == "OPE" ){
		
		BFL = BFL&~BFL_TEXTURES_SENT;
		if( BFL&BFL_TEXTURES_SCHEDULED )
			ptSet("OP", 0.1, FALSE);			
		
	}
	
}

default
{
    state_entry(){
        llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoThongs, 1");
        llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoT, 1");
        memLim(1.5);
		
		links_each(nr, name,
			if(name == "QTEVT")
				P_BUTTONS = nr;
		)
		
		string tx = "b6f0605b-e818-7dfc-353f-9e458c956816";
		llSetLinkPrimitiveParamsFast(P_BUTTONS, [
			PRIM_TEXTURE, ALL_SIDES, "37545817-a832-f9ae-a379-750a095463db", <1./16,1./2,0>, <1./32-1./16*8,1./4, 0>, 0,
			PRIM_TEXTURE, 7, tx, <1./4,1,0>, <-1./8-1./4,0, 0>, 0,
			PRIM_TEXTURE, 0, tx, <1./4,1,0>, <-1./8,0, 0>, 0,
			PRIM_TEXTURE, 1, tx, <1./4,1,0>, <-1./8+1./4,0, 0>, 0,
			PRIM_TEXTURE, 2, tx, <1./4,1,0>, <-1./8+1./4*2,0, 0>, 0			
		]);
		
		toggleQTE(FALSE);
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
	
	// This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
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
				// [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks]
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
					l2i(PARAMS, 5)
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
	
	if(METHOD == EvtsMethod$startQuicktimeEvent){
		QTE_STAGES = l2i(PARAMS, 0);
		
		// Tells any active QTE sender that it has ended, useful if QTE ended by someone other than the one that initiated it
		if(!QTE_STAGES)
			onQteEnd(FALSE);
		else
			raiseEvent(EvtsEvt$QTE, (str)QTE_STAGES);
		
		CB_DATA = [EvtsEvt$QTE$APPLY];
		list targ = [nr];
		if(id != "")
			targ = [id];
			
		QTE_SENDER_DATA = targ+[SENDER_SCRIPT, CB];
		
		
		
		float preDelay = l2f(PARAMS, 1);
		if(preDelay){
			ptSet("QTE", preDelay, FALSE);
			BFL = BFL|BFL_QTE_PRESSED;
		}
		else
			toggleQTE(QTE_STAGES);
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



