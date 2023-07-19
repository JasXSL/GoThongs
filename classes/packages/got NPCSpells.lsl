#define USE_DB4
#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

// HP Cache
float hp = 1;

integer monster_flags;
integer spell_flags;
integer spell_id;

key aggro_target;
key spell_targ;
key spell_targ_real;							// HUD or same as spell_targ



integer BFL;
#define BFL_CASTING 1
#define BFL_INTERRUPTED 2
#define BFL_DEAD 4
#define BFL_RECENT_CAST 0x8			// Used to limit spells from casting too often
#define BFL_SILENCED 0x10
#define BFL_CC 0x20					// Waiting for clearCast

float spells_per_sec_limit = 0.5;			// Max spells per sec that can be cast

// Effects
integer STATUS_FLAGS = 0; 					// Status flags
integer RUNTIME_FLAGS;						// Monster flags

// FX
integer FXFLAGS = 0;
float fxModDmgDone = 1;
float fxCTM = 1;
float fxCDM = 1;

integer height_add;		// LOS check height offset from the default 0.5m above root prim
#define hAdd() ((float)height_add/10)

list cooldowns;
list OUTPUT_STATUS_TO;			// (str)name, (int)types
list DISABLED;

float CAST_START_TIME;
float CAST_END_TIME;
string CACHE_NAME;              // Name of spell cast

integer P_TXT;


// Stack overflowable things
string spells_set_by_script = "got LocalConf"; 	// Script that set the spells

list CACHE;				// Spell arrays from localconf
list CUSTOMCAST;		// Data about a cast triggered from a method
list AGGROED;			// Keys of players we have aggroed
int TEAM;


updateText(){

	integer i;
	integer perc = llRound(hp*100);
		
	string text;
	vector color = <1, .8, .8>;
	
	if( BFL&BFL_DEAD )
		text = "";
	else{
	
		list names = [];
		for( i=0; i<llGetListLength(OUTPUT_STATUS_TO); i+=2 ){

			string n = llGetSubString(l2s(OUTPUT_STATUS_TO, i), 0, 15);
			
			integer f = l2i(OUTPUT_STATUS_TO, i+1);
			
			if(n != ""){
			
				string o = "🡺 "+llToUpper(n)+"\n";
				// Focus
				if( ~f&NPCInt$targeting )
					o = "👁️ "+llToLower(n)+"\n";
				names+= o;
				
			}
			
		}
		
		text += (string)names;
		string middle =  "❤️ "+(str)perc+" ❤️";
		text+= middle;
			
		if( BFL&BFL_CASTING && CAST_END_TIME != CAST_START_TIME && ~spell_flags&NPCS$FLAG_HIDDEN ){
		
			
			
			list d = llJson2List(llList2String(CACHE, spell_id));
			if( spell_id == -1 )
				d = CUSTOMCAST;
				
			integer flags = llList2Integer(d, NPCS$SPELL_FLAGS);
		
			color = <.8,.6,1>;
			integer tBlocks = llRound((CAST_END_TIME-llGetTime())/(CAST_END_TIME-CAST_START_TIME)*5);
			string add = CACHE_NAME;
			for( i=0; i<5; ++i ){
				if( i < tBlocks )
					add = "▶"+add+"◀";
				else
					add = " "+add+" ";
			}
			if( flags&NPCS$FLAG_NO_INTERRUPT )
				add = "🔒"+add+"🔒";
			
			text += "\n"+add;
			
		}
		else if( BFL&BFL_INTERRUPTED ){
			
			color = <.8, 1, .8>;
			text += "\n[ Interrupted! ]";
			
		}
		
	}
	
    llSetLinkPrimitiveParamsFast(P_TXT, [PRIM_TEXT, text, color, 1]);
	
	ptSet("FDE", (OUTPUT_STATUS_TO == [])*2.0, 0);
	
}

onEvt(string script, integer evt, list data){

	if( script == "got Monster" && evt == MonsterEvt$runtimeFlagsChanged ){

		RUNTIME_FLAGS = llList2Integer(data,0);
		if( RUNTIME_FLAGS & Monster$RF_NO_SPELLS && BFL&BFL_CASTING ){
			endCast(FALSE, TRUE);
		}

    }
	
	
	else if( script == "got Status" ){
        
		if( evt == StatusEvt$flags )
            STATUS_FLAGS = llList2Integer(data,0);
        
		else if( evt == StatusEvt$team )
			TEAM = l2i(data, 0);
		
		else if( evt == StatusEvt$monster_gotTarget ){
            
			aggro_target = llList2String(data, 0);
			// Add random cooldowns
			
		}
        
		else if( evt == StatusEvt$monster_hp_perc && hp != llList2Float(data, 0) ){
			
			hp = llList2Float(data,0);
			updateText();

        }
		
		else if( evt == StatusEvt$dead ){
		
			BFL = BFL&~BFL_DEAD;
			if( l2i(data, 0) ){
				BFL = BFL|BFL_DEAD;
				if( BFL&BFL_CASTING ){
					endCast(FALSE, TRUE);
				}
			}
			updateText();
			
        }
		
		else if( evt == StatusEvt$monster_aggro )
			AGGROED = data;
		
    }
}

clearCast(){

	if( monster_flags )
		Monster$unsetSpellFlags(monster_flags);
	Monster$lookOverride("");
	BFL = BFL&~BFL_CC;
	
}

endCast( integer success, integer force ){
    
	if( ~BFL&BFL_CASTING )
		return;
		
    integer evt = NPCSpellsEvt$SPELL_CAST_INTERRUPT;
    
	list d = llJson2List(llList2String(CACHE, spell_id));

	if( spell_id == -1 )
		d = CUSTOMCAST;
	
    integer flags = llList2Integer(d, NPCS$SPELL_FLAGS);
	// Normally custom casts are not affected by force interrupts because they might go invulnerable and silence during an intermission
	// Use force 2 or greater to interrupt these
	if( flags&NPCS$FLAG_NO_INTERRUPT && !success && (!force || spell_id == -1) && force < 2 )
		return;
	
    float recasttime = llList2Float(d, NPCS$SPELL_RECASTTIME)*fxCDM;
	
    if( recasttime>0 && (success || ~flags&NPCS$FLAG_RESET_CD_ON_INTERRUPT) ){
	
        cooldowns += spell_id;
        ptSet("CD_"+(string)spell_id, recasttime, FALSE);
		
    }
	
    if( success )
		evt = NPCSpellsEvt$SPELL_CAST_FINISH;
		
	// Set internal interrupt timer
    else if( ~flags&NPCS$FLAG_RESET_CD_ON_INTERRUPT ){
	
        BFL = BFL|BFL_INTERRUPTED;
        ptSet("IR", 3, FALSE);
		
    }
    raiseEvent(evt, mkarr(([spell_id, spell_targ, spell_targ_real, l2s(d, NPCS$SPELL_NAME)])));

	ptUnset("CB");
	ptUnset("CAST");
	BFL = BFL&~BFL_CASTING;

    if( !success || (CAST_END_TIME-CAST_START_TIME > 0.1 && success) ){
	
		updateText();
		BFL = BFL|BFL_CC;
		
		
	}
	ptSet("CC", 1, FALSE);
	
}

startCast(integer spid, key targ, integer isCustom){

	if(
		(
			BFL&(BFL_RECENT_CAST|BFL_CASTING|BFL_CC) || 
			RUNTIME_FLAGS&Monster$RF_NO_SPELLS
		) && !isCustom
	)return;

	parseDesc(targ, resources, status, fx, sex, team, rf, arm, _a);
    if( status&StatusFlags$NON_VIABLE && !isCustom )
		return;
	// Data comes from parseDesc, 0 is the attach point.
	
	key real = targ;
	// If attached, use the owner key
	if( prAttachPoint(targ) )
		targ = llGetOwnerKey(targ);

	BFL = BFL|BFL_RECENT_CAST;
	ptSet("SPS", spells_per_sec_limit, FALSE);

	
    spell_targ = targ;
	spell_targ_real = real;
    
	list d = llJson2List(llList2String(CACHE, spid));
	if( isCustom )
		d = CUSTOMCAST;
		
    integer flags = llList2Integer(d, NPCS$SPELL_FLAGS);
    float casttime = llList2Float(d, NPCS$SPELL_CASTTIME);
	float recasttime = llList2Float(d, NPCS$SPELL_RECASTTIME);
	if( ~flags&NPCS$FLAG_IGNORE_HASTE ){
	
		casttime*=fxCTM;
		recasttime*=fxCDM;
		
	}
    
    if( flags&NPCS$FLAG_LOOK_OVERRIDE ){
	
        Monster$lookOverride(targ);
		/*
		if( casttime<=0 )
			ptSet("LAT", 1, FALSE); // Stop lookat
		*/
	}
    
	BFL = BFL|BFL_CASTING;
    BFL = BFL&~BFL_INTERRUPTED;
       
                       
    CAST_START_TIME = llGetTime();
    CAST_END_TIME = llGetTime()+casttime;
    CACHE_NAME = llList2String(d, NPCS$SPELL_NAME);
                       
    // Monster flags to set
    spell_flags = flags;
    monster_flags = 0;
    if( flags&NPCS$FLAG_ROOT )
		monster_flags = monster_flags|Monster$RF_IMMOBILE;
    if( flags&NPCS$FLAG_PACIFY )
		monster_flags = monster_flags|Monster$RF_PACIFIED;
    if( flags&NPCS$FLAG_NOROT )
		monster_flags = monster_flags|Monster$RF_NOROT;
       
    spell_id = spid;
       
	if( casttime <= 0.1 )
		endCast(TRUE, FALSE); // Immediately finish the cast
	
	else{
	
		str data = mkarr((list)spid + spell_targ + spell_targ_real + l2s(d, NPCS$SPELL_NAME));
		// Non instant
		raiseEvent(NPCSpellsEvt$SPELL_CAST_START, data);
		ptSet("CAST", casttime, FALSE);
		ptSet("CB", 0.5, TRUE);
		Monster$setSpellFlags(monster_flags);
		updateText();
		
	}
    
}

ptEvt(string id){
	
	// float DSTART = llGetTime();
	
    if( id == "FDE" ){
        
		list active = llGetLinkPrimitiveParams(P_TXT, (list)PRIM_TEXT);
        float rem = llList2Float(active, 2)-.05;
		if(rem < 0)
			rem = 0;
		llSetLinkPrimitiveParamsFast(P_TXT, [PRIM_TEXT, l2s(active, 0), l2v(active, 1), rem]);
        if( rem <= 0 )
			return;
        ptSet("FDE", .05, FALSE);
		
    }
	/*
	else if( id == "LAT" )
		Monster$lookOverride("");
	*/
	else if( id == "SPS" )
		BFL = BFL&~BFL_RECENT_CAST;
    
	else if( id == "IR" )
		BFL = BFL&~BFL_INTERRUPTED;
    
	else if( id == "F" ){
		

		// Find a spell to cast here
        if( 
			aggro_target == "" || 
			BFL&(BFL_CASTING|BFL_DEAD|BFL_INTERRUPTED|BFL_RECENT_CAST|BFL_SILENCED|BFL_CC) || 
			RUNTIME_FLAGS&Monster$RF_NO_SPELLS ||
			FXFLAGS & fx$NOCAST
		)return;
        		
		// Create an index of [(int)index, (str)data]
        list r;
        integer i;
        for( ; i<count(CACHE); ++i )
			r+=[i, llList2String(CACHE, i)];
        r = llListRandomize(r, 2);
		
		// Loop through the index
        for( i=0; i<count(r); i+=2 ){
		
            integer spid = llList2Integer(r, i);
			
		
			// Not on cooldown
            if( llListFindList(cooldowns, [spid]) == -1 && llListFindList(DISABLED, (list)spid) == -1 ){
			
                list d = llJson2List(llList2String(r, i+1));
                integer flags = llList2Integer(d, NPCS$SPELL_FLAGS);
                float range = llList2Float(d, NPCS$SPELL_RANGE);
                float minrange = llList2Float(d, NPCS$SPELL_MIN_RANGE);
                int sexReq = llList2Integer(d, NPCS$SPELL_TARG_SEX);
				int fxReq = l2i(d, NPCS$SPELL_TARG_FX);
				int statusReq = l2i(d, NPCS$SPELL_TARG_STATUS);
				int roleReq = l2i(d, NPCS$SPELL_TARG_ROLE);
				float angle = l2f(d, NPCS$SPELL_ROT);
				
				
				integer sInverse = statusReq < 0;
				if( sInverse )
					statusReq = -statusReq;
				integer fInverse = fxReq < 0;
				if( fInverse )
					fxReq = -fxReq;
				
                
                // Default to aggro_target
                list p = [aggro_target];
				// Randomize all aggroed targets
                if( flags&NPCS$FLAG_CAST_AT_RANDOM )
					p = llListRandomize(AGGROED, 1);
					
				// Loop through the players
                while( count(p) ){
				
                    key targ = llList2Key(p, 0);
                    p = llDeleteSubList(p, 0, 0);
                    vector ppos = prPos(targ);
                    float dist = llVecDist(llGetRootPosition(), ppos);
                    list ray = llCastRay(llGetRootPosition()+<0,0,1+hAdd()>, ppos, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
					
					// Get some info about the target
					parseDesc(targ, resources, status, fx, sex, team, rf, arm, _a);
					// Todo: Make it react to non-animesh NPCs some time? Worth keeping rotation to only X?
					
					myAngX(targ, ang)
															
                    if(
						(range<=0 || dist<range) && 
						(~flags&NPCS$FLAG_IGNORE_TANK || targ != aggro_target) && 
						dist>=minrange && 
						llList2Integer(ray, -1) == 0 && 
						!(status&StatusFlags$NON_VIABLE) && 
						~fx&(fx$UNVIABLE|fx$F_INVUL) &&
						(!sexReq || (sex&sexReq) == sexReq) &&
						(!roleReq || roleReq&role2flag(getRoleFromSex(sex))) &&
						(!fxReq || ((fx&fxReq) == fxReq) == !fInverse) &&
						(!statusReq || ((status&statusReq) == statusReq) == !sInverse) &&
						team != TEAM &&
						(angle == 0 || (angle < 0 && llFabs(ang) > -angle) || (angle > 0 && llFabs(ang) < angle))
					){
                        
						if( flags&NPCS$FLAG_REQUEST_CASTSTART ){
                            // Request start cast
							runMethod(
								(str)LINK_ROOT, 
								spells_set_by_script, 
								LocalConfMethod$checkCastSpell, 
								[
									llList2Integer(r, i), 
									targ,
									l2s(d, NPCS$SPELL_NAME)
								], 
								"SPELL;"+llList2String(r,i)+";"+(string)targ
							);
                        }
                        else{
						
							startCast(spid, targ, FALSE);
							return;
							
						}
						
                        if(~flags&(NPCS$ALLOW_MULTIPLE_CHECKS|NPCS$FLAG_REQUEST_CASTSTART))
							return;
						
                    }
					
                
				}
				
            }
			
        }
        
        ptSet("F", 1, TRUE);
    }
	
    else if( llGetSubString(id, 0, 2) == "CD_" ){
	
        integer id = (integer)llGetSubString(id, 3, -1);
        integer pos = llListFindList(cooldowns, [id]);
        if(~pos)
			cooldowns = llDeleteSubList(cooldowns, pos, pos);
			
    }
	
	// Cast finish
    else if( id == "CAST" )
        endCast( TRUE, FALSE );
		
	// Cast bar
    else if( id == "CB" )
		updateText();
	
	else if( id == "CC" ){
		clearCast();
	}
	// llOwnerSay("DD ptEvt "+id+" = "+(str)(llGetTime()-DSTART));
	
}

// Settings received
onSettings(list settings){
	
	while(settings){
		integer idx = l2i(settings, 0);
		list dta = llList2List(settings, 1, 1);
		settings = llDeleteSubList(settings, 0, 1);
		#define dtaInt l2i(dta,0)
		#define dtaFloat l2f(dta,0)
		#define dtaStr l2s(dta,0)

		if(idx == MLC$height_add)
			height_add = dtaInt;
		// Flags
		else if(idx == MLC$RF)
			RUNTIME_FLAGS = l2i(dta,0);
	}
	
}

// turns a var ID into an index. Allowing you to find a spell by index (int) or name (anything else)
int list2index( list v ){
	// Find by name if ID is not int
	if( llGetListEntryType(v, 0) != TYPE_INTEGER ){
		integer i;
		for(; i<count(CACHE); ++i ){
			if( j(l2s(CACHE, i), NPCS$SPELL_NAME) == l2s(v, 0) )
				return i;
		}
		
	}
	return l2i(v, 0);
}

default {

    state_entry(){
        if(llGetStartParameter())
            raiseEvent(evt$SCRIPT_INIT, "");
        links_each(nr, name, 
            if(name == "TXT")P_TXT = nr;
        )
		llSetLinkPrimitiveParamsFast(P_TXT, [PRIM_TEXT, "", ZERO_VECTOR, 0]);
        //PLAYERS = [llGetOwner()];
    }
	
	touch_start(integer total){
	
		raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
		
    }
    
    timer(){ptRefresh();}
    
	#define LM_PRE \
	if( nr == TASK_FX ){ \
		FXFLAGS = (int)fx$getDurEffect(fxf$SET_FLAG); \
		if( RUNTIME_FLAGS & Monster$RF_IS_BOSS ){ \
			FXFLAGS = FXFLAGS&~(fx$F_STUNNED|fx$F_SILENCED); \
		} \
		fxModDmgDone = (float)j(fx$getDurEffect(fxf$DAMAGE_DONE_MULTI), 0); \
        fxCTM = (float)fx$getDurEffect(fxf$CASTTIME_MULTI);  \
        fxCDM = (float)fx$getDurEffect(fxf$COOLDOWN_MULTI); \
        if( BFL&BFL_CASTING && FXFLAGS&fx$NOCAST ) \
            endCast( FALSE, TRUE ); \
	} \
	else if( nr == TASK_MONSTER_SETTINGS )\
		onSettings(llJson2List(s));
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
	//float DSTART = llGetTime();
	
    // Here's where you receive callbacks from running methods
    if( method$isCallback ){
	
        if( llGetSubString(CB, 0, 5) == "SPELL;" && l2i(PARAMS, 0) ){
		
            list split = llParseString2List(CB, [";"], []);
            startCast(llList2Integer(split, 1), llList2String(split, 2), FALSE);
			
        }
        return;
		
    }
    
    if(!method$byOwner)
		return;

	if( METHOD == NPCSpellsMethod$setSpells ){
		
		spells_set_by_script = SENDER_SCRIPT;
		// Clear cooldowns from previous spells
		list_shift_each(cooldowns, cd,
			ptUnset("CD_"+cd);
		)
		cooldowns = [];
	
		// Todo: LSD
		CACHE = PARAMS;
		integer i;
		for( ; i<llGetListLength(CACHE); ++i ){
		
			integer flags = (integer)jVal(llList2String(CACHE, i), [NPCS$SPELL_FLAGS]);
			if( flags&NPCS$FLAG_DISABLED_ON_START )
				cooldowns+=i;
				
		}
		
		// Start frame ticker
		ptSet("F", 1+llFrand(2), TRUE);
		
		raiseEvent(NPCSpellsEvt$SPELLS_SET, SENDER_SCRIPT);
		
	}
	
	else if( METHOD == NPCSpellsMethod$disableSpells ){
	
		list_shift_each(PARAMS, id,
			
			integer idx = list2index((list)id);
			ptUnset("CD_"+(str)idx);
			integer n = list2index((list)idx);	// Convert to integer if it is a string name
			
			if( llListFindList(DISABLED, (list)n) == -1 )
				DISABLED += idx;
				
		)
		
	}
	
	else if( METHOD == NPCSpellsMethod$triggerCooldown ){
	
		integer i;
		for(; i < count(PARAMS); ++i ){
			
			float recasttime;
			string id = l2s(PARAMS, i);
			if( llJsonValueType(id, []) == JSON_ARRAY ){
				recasttime = (float)j(id, 1);
				id = j(id, 0);
			}
			
			integer n = list2index((list)id);
			
			if( recasttime <= 0 ){
				list d = llJson2List(llList2String(CACHE, (int)n));
				recasttime = llList2Float(d, NPCS$SPELL_RECASTTIME)*fxCDM;
			}
			if( llListFindList(cooldowns, (list)n) == -1 )
				cooldowns+= (int)n;
				
			
			ptSet("CD_"+(str)n, recasttime, FALSE);
		
		}
		
	}
	
	else if( METHOD == NPCSpellsMethod$interrupt ){
		endCast(FALSE, l2i(PARAMS, 0));
	}
	
	else if( METHOD == NPCSpellsMethod$setOutputStatusTo ){
	
		OUTPUT_STATUS_TO = [];
		int i;
		for(;i<count(PARAMS); i+=2)
			OUTPUT_STATUS_TO += 
				(list)llList2String(
					explode(" ", llGetDisplayName(llGetOwnerKey(llList2Key(PARAMS, i)))),
					0
				)+
				l2i(PARAMS, i+1);
		
		updateText();
		
	}
	
	else if( METHOD == NPCSpellsMethod$setConf ){
	
		spells_per_sec_limit = (float)method_arg(0);
		if( spells_per_sec_limit <= 0 )
			spells_per_sec_limit = 0.5;
			
	}
	
	// Wipes cooldowns and enables spells
	else if( METHOD == NPCSpellsMethod$wipeCooldown ){
		
		
		integer id = list2index(PARAMS);
		integer pos = llListFindList(cooldowns, (list)id);
		
		if( ~pos )
			cooldowns = llDeleteSubList(cooldowns, pos, pos);
		pos = llListFindList(DISABLED, (list)id);
		if( ~pos )
			DISABLED = llDeleteSubList(DISABLED, pos, pos);
	}
	
	else if( METHOD == NPCSpellsMethod$silence ){
	
		if( l2i(PARAMS, 0) ){
			endCast(FALSE, TRUE);
			BFL = BFL|BFL_SILENCED;
		}
		else
			BFL = BFL&~BFL_SILENCED;
		
	}
	
	else if( METHOD == NPCSpellsMethod$customCast ){
	
		endCast(FALSE, TRUE);
		//flags, casttime, name, targ
		CUSTOMCAST = [l2i(PARAMS, 0), l2f(PARAMS, 1), 0, 0, method_arg(2), 0]; // Should match the normal cache
		startCast(-1, method_arg(3), TRUE);
		
	}
	
	
		
    
	//llOwnerSay("DD linkMessage "+(str)METHOD+" = "+(str)(llGetTime()-DSTART));
	

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
