/*
	
	WARNING
	This script is saturated. You cannot add more features to it.
	
*/
#define USE_EVENTS
#define IS_NPC
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define initialized() (BFL&BFL_INITIALIZED)

#define memDebug(name, lst) 
//#define memDebug(name, lst) qd(name+" Entries: "+(str)count(lst));


list PLAYERS;

float maxHP = -1;

// Conf stuff
float dmg = 10;         // Damage of melee attacks
float HP = 100;
float preHP = 1;
float aggro_range;
key aggrosound;         //
key dropaggrosound;     //
key takehitsound;       //
key attacksound;        //
key deathsound;         // 
key icon;
string rapeName;        // Usually prim name
string drops;			// JSON array of sub arrays of [(str)asset, (float)drop_chance]
integer range_add;		// Hitbox range add for players to hit ME
integer height_add;		// LOS check height offset from the default 0.5m above root prim
integer melee_height;	// Used for RP
#define hAdd() ((float)height_add/10)

// (float)aggro, (key)id, (int)flags
#define AGGRO_STRIDE 3
list AGGRO;
#define AGFLAG_NOT_AGGROD 1


key aggroTarg;			// Should always be an object

integer TEAM_DEFAULT = TEAM_NPC;			// This is the team set by the HUD itself, can be overridden by fxTeam
integer TEAM = TEAM_NPC;

integer BFL = 0; 
#define BFL_DEAD 0x1
#define BFL_FRIENDLY 0x2
#define BFL_STATUS_TIMER 0x4 
#define BFL_INITIALIZED 0x8
#define BFL_STATUS_QUEUE 0x10		// Send status on timeout
#define BFL_STATUS_SENT 0x20		// Status sent
#define BFL_AGGROED_ONCE 0x40		// If aggroed at least once
#define BFL_DESC_OVERRIDE 0x80

#define BFL_NOAGGRO (BFL_FRIENDLY|BFL_DEAD)

// Effects
integer STATUS_FLAGS = 0; 
integer STATUS_FLAGS_PRE = 0;
// See ots Monster
integer RUNTIME_FLAGS;

// FX
integer FXFLAGS = 0;
float fxModDmgTaken = 1;
float fxModDmgDone = 1;
float fxModCrit = 0;
float fxModHealingTaken = 1;
integer fxTeam = -1;

list SPELL_DMG_TAKEN_MOD;


#define SPSTRIDE 3
list SPELL_ICONS;   // [(int)PID, (csv)"(key)texture, (int)added, (int)duration, (int)stacks", (str)desc]

list OUTPUT_STATUS_TO; // (key)id, (int)flags

list CUSTOM_ID;		// (str)id, (var)mixed - Used for got Level integration

// Updates description with the proper team
#define setTeam(team) TEAM_DEFAULT = team; outputStats(FALSE,__LINE__)
#define isFFA() l2s(PLAYERS, 0) == "*"

// Description is $M$(int)team$(int)HP_BITWISE$(int)range_add(decimeters)$(int)height_add$(int)status_flags$(int)monster_flags$(int)fx_flags
#define updateDesc() if(~BFL&BFL_DESC_OVERRIDE){llSetObjectDesc("$M$"+(str)TEAM+"$"+(str)(llRound(HP/maxHP*127)<<21)+"$"+(str)range_add+"$"+(str)height_add+"$"+(str)STATUS_FLAGS+"$"+(str)RUNTIME_FLAGS+"$"+(str)FXFLAGS);}

#define dropAggro( player, type ) \
	runMethod((str)LINK_THIS, cls$name, StatusMethod$monster_dropAggro, [player, type], TNN)

// this can be truncated a bit to preserve memory
outputTextures(){

	integer i; string out;
	for( i=0; i<llGetListLength(SPELL_ICONS); i+=SPSTRIDE )
		out+= l2s(SPELL_ICONS, i)+","+l2s(SPELL_ICONS,i+1)+",";
	
	
	list opstat = OUTPUT_STATUS_TO;
	if( RUNTIME_FLAGS&Monster$RF_IS_BOSS )
		opstat = PLAYERS;
		
	out = llDeleteSubString(out, -1, -1);
	
    for( i = 0; i<count(opstat); i+= 2)
		GUI$setSpellTextures(l2s(opstat, i), out);
	
	
}


#define aggroCheck(k) \
    if(RUNTIME_FLAGS&Monster$RF_NOAGGRO || BFL&BFL_NOAGGRO)return; \
    vector ppos = prPos(k); \
    float dist =llVecDist(ppos, llGetPos());  \
    if(dist>100)return; \
    integer ainfo = llGetAgentInfo(k); \
    float range = aggro_range; \
	prAngZ(k, ang) \
	if(llFabs(ang)>PI_BY_TWO && ~RUNTIME_FLAGS&Monster$RF_360_VIEW) \
		range *= 0.25; \
    if(dist<range){ \
        list ray = llCastRay(llGetPos()+<0,0,1+hAdd()>, ppos+<0,0,1>, ([RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS])); \
        if(llList2Integer(ray, -1) == 0){ \
            Status$get(k, "aggro"); \
        }  \
    }




aggro( key player, float ag ){

    if( BFL&BFL_NOAGGRO || RUNTIME_FLAGS&(Monster$RF_FREEZE_AGGRO|Monster$RF_NOAGGRO) )
		return;
    
	list pre = AGGRO;
	
	
    if( player ){
	
        integer pre = llGetListLength(AGGRO);
        integer pos = llListFindList(AGGRO, [player]);
        key top; integer i;
        if( ~pos ){
		
            float nr = llList2Float(AGGRO, pos-1);
            nr+=ag;
            if(nr<=0)
				dropAggro(player, TRUE);
            else{
                // Newly aggroed
                integer flag = llList2Integer(AGGRO, pos+1);
                if(flag&AGFLAG_NOT_AGGROD)
                    AGGRO = llListReplaceList(AGGRO, [flag&~AGFLAG_NOT_AGGROD], pos+1, pos+1);
                
                AGGRO = llListReplaceList(AGGRO, [nr], pos-1, pos-1);
            }
			
        }
		else if( ag>0 ){
		
			AGGRO += [ag, player, 0];
			memDebug("AGGRO", AGGRO);
			
		}
        
		// First time aggoed
        if(AGGRO != [] && !pre && aggrosound != "" ){
		
			llTriggerSound(aggrosound, 1);
			Status$monster_aggroed(player, 10, TEAM);
			
		}
		
    }
	
    AGGRO = llListSort(AGGRO, AGGRO_STRIDE, FALSE);
    
    
    key at = "";
    integer i;
    for( i=0; i<llGetListLength(AGGRO) && AGGRO != []; i+=AGGRO_STRIDE ){
	
		// Aggro target has left
		key t = l2k(AGGRO, i+1);
        if(llKey2Name(t) == "" || llVecDist(llGetPos(), prPos(t)) > 20){
		
			AGGRO = llDeleteSubList(AGGRO, i, i+AGGRO_STRIDE-1);
			i-= AGGRO_STRIDE;
			
		}
		else if(~llList2Integer(AGGRO, i+2)&AGFLAG_NOT_AGGROD){
		
            at = llList2Key(AGGRO, i+1);
            i = llGetListLength(AGGRO);
			
        }
		
    }
    
    if(at != aggroTarg){ 
	
        aggroTarg = at;
        if( at == "" && dropaggrosound != "" ){
            llTriggerSound(dropaggrosound, 1);
        }else if( at != "" ){
		
			if( ~RUNTIME_FLAGS&Monster$RF_NO_TARGET ) 
				Root$targetMe(at, icon, FALSE, TEAM);
				
			if( RUNTIME_FLAGS&Monster$RF_IS_BOSS && ~BFL&BFL_AGGROED_ONCE ){
			
				runOnPlayers(targ,
					GUI$toggleBoss(targ, icon, FALSE);
				)
				BFL = BFL|BFL_AGGROED_ONCE;
				
			}
			
		}
		
        raiseEvent(StatusEvt$monster_gotTarget, mkarr([aggroTarg]));
		
    }
	
	if(AGGRO != pre)
		raiseEvent(StatusEvt$monster_aggro, mkarr(llList2ListStrided(llDeleteSubList(AGGRO, 0, 0), 0, -1, AGGRO_STRIDE)));
	
}


outputStats( integer force, integer line ){

	
	// NPC has been ressurected
	if( HP>0 && STATUS_FLAGS&StatusFlag$dead ){
	
		raiseEvent(StatusEvt$dead, "0");
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
		MaskAnim$restartOverride("idle");
		AGGRO = [];
		aggroTarg = "";
		
	}
	
	// Check team
	integer t = fxTeam;
	if(t == -1)
		t = TEAM_DEFAULT;
		
	integer pre = TEAM;
	
	// Needed for TEAM to be in the description
	TEAM = t;
	updateDesc();

	if( BFL&BFL_STATUS_SENT && !force && TEAM == pre ){
		
		BFL = BFL|BFL_STATUS_QUEUE;
		return;
		
	}
	
	
	
	if( STATUS_FLAGS_PRE != STATUS_FLAGS ){
	
		raiseEvent(StatusEvt$flags, llList2Json(JSON_ARRAY,[STATUS_FLAGS, STATUS_FLAGS_PRE]));
		STATUS_FLAGS_PRE = STATUS_FLAGS;
		
	}
	
	// Team change goes after because we need to update description first
	if( pre != t ){
	
		raiseEvent(StatusEvt$team, (str)TEAM);
		runOnPlayers(targ,
			Root$forceRefresh(targ, llGetKey());
		)
		
	}
	
	float perc = HP/maxHP;
	if( perc != preHP && maxHP > 0 ){
	
		preHP = perc;
		raiseEvent(StatusEvt$monster_hp_perc, (string)perc);
		
	}
	
	BFL = BFL|BFL_STATUS_SENT;
	multiTimer(["_", .5, FALSE]);
	
}


#define timerEvent(id) \
	if( id == "_" ){ \
		BFL = BFL&~BFL_STATUS_SENT; \
		if( BFL&BFL_STATUS_QUEUE ){ \
			BFL = BFL&~BFL_STATUS_QUEUE; \
			outputStats(FALSE, __LINE__); \
		} \
	} \
    else if( id == "A" && ~BFL&BFL_NOAGGRO ){ \
        if( aggroTarg != "" ){ \
			parseDesc(aggroTarg, resources, status, fx, sex, team, monsterFlags); \
			if( \
				status&StatusFlags$NON_VIABLE || \
				fx&fx$UNVIABLE ||  \
				team == TEAM || \
				monsterFlags&Monster$RF_INVUL \
			){ \
				dropAggro(aggroTarg, TRUE); \
			} \
			return; \
        } \
		llSensor("", "", AGENT|ACTIVE, aggro_range, PI); \
    }else if(id == "OT"){ \
        outputTextures(); \
    } 

// Overwrite the default one
#define TIMERSTRIDE 4
// timeout, id, looptime, repeating
multiTimer(list data){
    integer i;
    if(data != []){
        integer pos = llListFindList(llList2ListStrided(llDeleteSubList(_TIMERS,0,0), 0, -1, TIMERSTRIDE), llList2List(data,0,0));
        if(~pos)_TIMERS = llDeleteSubList(_TIMERS, pos*TIMERSTRIDE, pos*TIMERSTRIDE+TIMERSTRIDE-1);
        if(llGetListLength(data)==TIMERSTRIDE-1)_TIMERS+=[llGetTime()+llList2Float(data,2)]+data;
    }
    for(i=0; i<llGetListLength(_TIMERS); i+=TIMERSTRIDE){
        if(llList2Float(_TIMERS,i)<=llGetTime()){
            string t = llList2String(_TIMERS, i+1);
            if(!llList2Integer(_TIMERS,i+TIMERSTRIDE-1))_TIMERS= llDeleteSubList(_TIMERS, i, i+TIMERSTRIDE-1);
            else _TIMERS= llListReplaceList(_TIMERS, [llGetTime()+llList2Float(_TIMERS,i+2)], i, i);
            timerEvent(t);
            i-=TIMERSTRIDE;
        }
    }
    if(_TIMERS== []){llSetTimerEvent(0); return;}
    _TIMERS= llListSort(_TIMERS, TIMERSTRIDE, TRUE);
    float t = llList2Float(_TIMERS,0)-llGetTime();
    if(t<.01)t=.01;
    llSetTimerEvent(t);
}

#define startAnim( anim ) \
	MeshAnim$startAnim(anim); MaskAnim$start(anim)
	
#define stopAnim( anim ) \
	MeshAnim$stopAnim(anim); MaskAnim$stop(anim)


#define dtaInt l2i(dta,0)
#define dtaFloat l2f(dta,0)
#define dtaStr l2s(dta,0)

// Settings received
#define onSettings(settings) \
	list d = llJson2List(portalConf$desc); \
	list_shift_each(d, v, \
		list dta = llJson2List(v); \
		if(l2s(dta, 0) == "ID"){ \
			list cid = CUSTOM_ID; \
			CUSTOM_ID = llDeleteSubList(dta, 0, 0); \
			if((str)cid != (str)CUSTOM_ID){ \
				Level$idEvent(LevelEvt$idSpawned, llList2String(CUSTOM_ID, 0), mkarr(llDeleteSubList(CUSTOM_ID, 0, 0)), portalConf$spawnround); \
			} \
		} \
	) \
	 \
	float mhp = maxHP; \
	integer team = TEAM; \
	while(settings){ \
		integer idx = l2i(settings, 0); \
		list dta = llList2List(settings, 1, 1); \
		settings = llDeleteSubList(settings, 0, 1); \
		if(idx == 0) \
			RUNTIME_FLAGS = dtaInt; \
		if(idx == MLC$maxhp) \
			maxHP = dtaFloat; \
		if(idx == MLC$aggro_range) \
			aggro_range = dtaFloat; \
		if(idx == MLC$aggro_sound) \
			aggrosound = dtaStr; \
		if(idx == MLC$dropaggro_sound) \
			dropaggrosound = dtaStr; \
		if(idx == MLC$takehit_sound) \
			takehitsound = dtaStr; \
		if(idx == MLC$attacksound) \
			attacksound = dtaStr; \
		if(idx == MLC$deathsound) \
			deathsound = dtaStr; \
		if(idx == MLC$icon) \
			icon = dtaStr; \
		if(idx == MLC$dmg) \
			dmg = dtaFloat; \
		if(idx == MLC$range_add) \
			range_add = dtaInt; \
		if(idx == MLC$height_add) \
			height_add = dtaInt; \
		if(idx == MLC$team && dtaStr != "") \
			team = dtaInt; \
		if(idx == MLC$rapePackage && isset(dtaStr)) \
			rapeName = dtaStr; \
		if(idx == MLC$drops) \
			drops = dtaStr; \
		if( idx == MLC$melee_height ) \
			melee_height = dtaInt; \
	} \
	if(mhp == -1 || HP>maxHP) \
		HP = maxHP; \
	if(aggro_range > 0){ \
		multiTimer(["A", 2, TRUE]); \
	}else \
		multiTimer(["A"]); \
	if(llJsonValueType(drops, []) != JSON_ARRAY)drops = "[]"; \
	setTeam(team); \
	if(~BFL&BFL_INITIALIZED){ \
		BFL = BFL|BFL_INITIALIZED; \
		raiseEvent(StatusEvt$monster_init, ""); \
	} \




#define onEvt(script, evt, data) \
	if( script == "got Portal" && (evt == evt$SCRIPT_INIT || evt == PortalEvt$players) ){ \
        PLAYERS = data; \
		if(aggro_range)multiTimer(["A", 1, TRUE]); \
    } \
	else if( script == "got Monster" ){ \
	    if( evt == MonsterEvt$runtimeFlagsChanged ){ \
            integer pre = RUNTIME_FLAGS; \
			RUNTIME_FLAGS = llList2Integer(data,0); \
			list opstat = OUTPUT_STATUS_TO; \
			if(RUNTIME_FLAGS&Monster$RF_IS_BOSS) \
				opstat = PLAYERS; \
			if( \
				(pre&Monster$RF_NO_TARGET) != (RUNTIME_FLAGS&Monster$RF_NO_TARGET) &&  \
				RUNTIME_FLAGS&Monster$RF_NO_TARGET \
			){ \
				integer i; \
				for( i = 0; i < count(opstat); i+= 2) \
					Root$clearTargetOn(l2s(opstat, i)); \
			} \
			updateDesc(); \
        } \
		else if( evt == MonsterEvt$attack ){ \
			key targ = llList2Key(data, 0); \
            float crit = 1; \
			if( llFrand(1) < fxModCrit ) \
				crit = 2; \
			integer dmg = llRound(dmg*fxModDmgDone*crit*10); \
			integer pain = llRound(dmg*.2); \
			list h = [6,"<-1,-1,-1>"];\
			myAngX(targ, ang) \
			if( llFabs(ang) < PI_BY_TWO ){ \
				if( melee_height == 0 ) \
					h+= fxhfFlag$SLOT_GROIN; \
				else if(melee_height == 1) \
					h+= fxhfFlag$SLOT_BREASTS; \
			} \
			else if( melee_height == 0 ) \
				h+= fxhfFlag$SLOT_BUTT; \
			string hitfx = mkarr(h); \
            FX$send( \
				targ, \
				llGetKey(), \
				"[1,0,0,0,[0,1,\"\",[[1,"+ \
					llInsertString((str)dmg,llStringLength((str)dmg)-1,".")+ \
				"],[3,"+ \
					llInsertString((str)pain, llStringLength((str)pain)-1, ".")+ \
				"],"+hitfx+"],[],[],[],0,0,0]]", TEAM); \
        } \
		else if( evt == MonsterEvt$attackStart && attacksound != "" ){ \
            llTriggerSound(attacksound, 1); \
        } \
    } \
	else if( evt == evt$TOUCH_START && initialized() && ~RUNTIME_FLAGS&Monster$RF_NO_TARGET ){ \
        Root$targetMe(l2s(data, 1), icon, TRUE, TEAM); \
	} \

	

default 
{
    state_entry(){
        raiseEvent(evt$SCRIPT_INIT, "");
		setTeam(TEAM_DEFAULT);
    }
	
	sensor(integer total){
		integer ffa = isFFA();
		while(total--){
            key k = llDetectedKey(total);
			integer type = llDetectedType(total);
			
			parseDesc(k, resources, status, fx, sex, team, mf);
			
			if(
				(type&AGENT && TEAM != TEAM_PC && (ffa || ~llListFindList(PLAYERS, [(str)k]))) || 
				(llGetSubString(prDesc(k), 0, 2) == "$M$" && team != TEAM && ~mf&Monster$RF_INVUL)
			){
				aggroCheck(k);
			}
        }
	}
	
    
    
    timer(){multiTimer([]);}
    
	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		FXFLAGS = l2i(data, FXCUpd$FLAGS); \
        fxModDmgTaken = i2f(l2f(data, FXCUpd$DAMAGE_TAKEN)); \
        fxModDmgDone = i2f(l2f(data, FXCUpd$DAMAGE_DONE)); \
		fxModHealingTaken = i2f(l2f(data, FXCUpd$HEAL_MOD)); \
		fxModCrit = i2f(l2f(data, FXCUpd$CRIT)); \
		fxTeam = l2i(data, FXCUpd$TEAM); \
        outputStats(FALSE,__LINE__); \
	}\
	else if(nr == TASK_MONSTER_SETTINGS){\
		list data = llJson2List(s); \
		onSettings(data); \
	} \
	
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
	
	// Methods that should be allowed even when not initialized
	// Initialization ends if the NPC dies
	if(METHOD == StatusMethod$monster_overrideDesc){
		string d = method_arg(0);
		
		if(d){
			BFL = BFL|BFL_DESC_OVERRIDE;
			
			list out = [];
            links_each(nr, name,
                out+=([PRIM_LINK_TARGET, nr, PRIM_DESC, "ROOT"]);
            )
            out+= [PRIM_LINK_TARGET, LINK_ROOT, PRIM_DESC, d];
            PP(0,out);
			llSetStatus(STATUS_PHANTOM, FALSE);
			return;
		}
		llSetStatus(STATUS_PHANTOM, TRUE);
		BFL = BFL&~BFL_DESC_OVERRIDE;
		updateDesc();
	}
	
	
	
	if(METHOD == StatusMethod$batchUpdateResources && ~STATUS_FLAGS&StatusFlag$dead){
		while(PARAMS){
			integer type = l2i(PARAMS, 0);
			integer len = l2i(PARAMS, 1);
			list data = llList2List(PARAMS, 2, 2+len-1);		// See SMBUR$* at got Status
			PARAMS = llDeleteSubList(PARAMS, 0, 2+len-1);
			float amount = i2f(llList2Float(data, 0));	
			string spellName = l2s(data, 1);					// Spell name
			integer flags = l2i(data, 2);				// Spell flags
			key attacker = l2s(data, 3);
			
			
			
			// Apply
			if(type == SMBUR$durability){
				float pre = HP;
				
				float spdmtm = 1;

				integer i;
				for(i=0; i<count(SPELL_DMG_TAKEN_MOD); i+=2){
					if(llList2String(SPELL_DMG_TAKEN_MOD, i) == spellName){
						float nr = llList2Float(SPELL_DMG_TAKEN_MOD, i+1);
						if(nr <0)
							spdmtm = 0;
						spdmtm = nr;
						i = count(SPELL_DMG_TAKEN_MOD);
					}
				}
				
				amount*=spdmtm;
				
				
				if(flags&SMAFlag$IS_PERCENTAGE)
					amount*=maxHP;
					
				if(amount<0){
					amount*=fxModDmgTaken;
					parseDesc(attacker, _r, _s, _f, _st, team, _mo)
					if(attacker != "" && team != TEAM){
						aggro(attacker, llFabs(amount));
					}
				}
				else{
					amount*= fxModHealingTaken;
				}
				
				raiseEvent(StatusEvt$hurt, llList2Json(JSON_ARRAY, [(str)amount, attacker]));
				if(amount<0 && RUNTIME_FLAGS&Monster$RF_INVUL)return;
				
				HP += amount;
				if(HP<=0 && HP != pre){
					HP = 0;
					Status$kill(LINK_THIS);
					return;
				}
				else if(HP > maxHP)HP = maxHP;
				
				if(pre != HP)
					outputStats(FALSE,__LINE__);
				
			}
		}
		outputStats(FALSE,__LINE__);
	}
	
	if(METHOD == StatusMethod$fullregen){
		BFL = BFL|BFL_INITIALIZED;
		HP = maxHP;
		outputStats(TRUE,__LINE__);
	}
	else if(METHOD == StatusMethod$setTeam){
		
		setTeam(l2i(PARAMS, 0));
		
	}
	
	
	
	
	
	// Combat stuff below here
	if(!initialized()){
		return;
	}
    if(method$isCallback){
        if( METHOD == StatusMethod$get && id!="" && SENDER_SCRIPT == "got Status" && CB == "aggro" ){

			// agc checks if it should rape or not
			integer flags = (integer)method_arg(0);
			if(!_attackable(PARAMS) || llList2Integer(PARAMS,7) == TEAM){
				dropAggro(id, TRUE);
				return;
			}                
			aggro(id, 10);
		} 
        return;
    }
	
	
	
    if(id == ""){
	
		if(METHOD == StatusMethod$addTextureDesc){
		
            SPELL_ICONS += [
				(integer)method_arg(0), 
				method_arg(1)+","+method_arg(3)+","+method_arg(4)+","+method_arg(5), 
				(str)method_arg(2)
			];
			multiTimer(["OT", .05, FALSE]);
			
        }
        else if(METHOD == StatusMethod$remTextureDesc){
		
            integer pid = (integer)method_arg(0);
            integer pos = llListFindList(SPELL_ICONS, [pid]);
			if( pos == -1 )
				return;
			
            SPELL_ICONS = llDeleteSubList(SPELL_ICONS, pos, pos+SPSTRIDE-1);
            multiTimer(["OT", .3, FALSE]);
			
        }
		else if(METHOD == StatusMethod$stacksChanged){
		
			integer pid = (integer)method_arg(0);
            integer pos = llListFindList(SPELL_ICONS, [pid]);
			if( pos == -1 )
				return;
			
			list spl = llCSV2List(l2s(SPELL_ICONS, pos+1));
			spl = llListReplaceList(spl, [(int)method_arg(1),(int)method_arg(2),(int)method_arg(3)], 1, -1);
			SPELL_ICONS = llListReplaceList(SPELL_ICONS, [implode(",", spl)], pos+1,pos+1);
			multiTimer(["OT", .2, FALSE]);
			
		}
    }
    

	// Sets runtime flags
	if(METHOD == StatusMethod$monster_setFlag){
		STATUS_FLAGS = STATUS_FLAGS|(integer)method_arg(0);
	}
	else if(METHOD == StatusMethod$monster_remFlag){
		STATUS_FLAGS = STATUS_FLAGS&~(integer)method_arg(0);
	}

	
	
    
	// This person has toggled targeting on you
    if(METHOD == StatusMethod$setTargeting){
	
		integer flags = (integer)method_arg(0);
        integer pos = llListFindList(OUTPUT_STATUS_TO, [(str)id]);
		
		integer remove;
		if( flags < 0 ){
			
			flags = llAbs(flags);
			remove = TRUE;
			
		}
		
		integer cur = l2i(OUTPUT_STATUS_TO, pos+1);
		
		// Remove from existing
		if( ~pos && remove )
			cur = cur&~flags;
		// Add either new or existing
		else if( 
			(~pos && !remove && (cur|flags) != flags ) ||
			( pos == -1 && !remove )
		)cur = cur|flags;
		// Cannot remove what does not exist
		else
			return;
		
		// Exists, update
		if( ~pos && cur )
			OUTPUT_STATUS_TO = llListReplaceList(OUTPUT_STATUS_TO, [cur], pos+1, pos+1);
		// Exists, delete
		else if( ~pos && !cur )
			OUTPUT_STATUS_TO = llDeleteSubList(OUTPUT_STATUS_TO, pos, pos+1);
		// Insert new
		else
			OUTPUT_STATUS_TO += [(str)id, cur];


		if( cur ){
		
            outputStats(TRUE,__LINE__);
            outputTextures();
			
        }
		
		//raiseEvent(StatusEvt$targeted_by, mkarr(OUTPUT_STATUS_TO));
		NPCSpells$setOutputStatusTo(OUTPUT_STATUS_TO);
		
    }
	
	else if(METHOD == StatusMethod$kill){
		HP = 0;
		
		if(RUNTIME_FLAGS&Monster$RF_IS_BOSS){
			runOnPlayers(targ, GUI$toggleBoss(targ, "", FALSE);)
		}
		list_shift_each(OUTPUT_STATUS_TO, val, Root$clearTargetOn(val);)
		
		Level$idEvent(LevelEvt$idDied, llList2String(CUSTOM_ID, 0), mkarr(llDeleteSubList(CUSTOM_ID, 0, 0)), portalConf$spawnround);
		
		
		STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;
		raiseEvent(StatusEvt$dead, "1");
		startAnim("die");
		
		llSleep(.1);
		stopAnim("idle");
		stopAnim("walk");
		stopAnim("attack");
		BFL = BFL&~BFL_INITIALIZED; 	// Prevent further interaction
		llSetObjectDesc("");			// Prevent targeting

		
		if(deathsound)llTriggerSound(deathsound, 1);
		
		// The monster will remove itself
		if(~RUNTIME_FLAGS&Monster$RF_NO_DEATH){
			// Drop loot
			list d = llListRandomize(llJson2List(drops), 1);
			list_shift_each(d, val,
				if(llFrand(1)<(float)j(val, 1)){ 
					Spawner$spawn(j(val,0), (llGetPos()+<0,0,.5>), llGetRot(), "", FALSE, FALSE, "");
					d = [];
				}
			)
			llSleep(2);
			llDie();
		}
		else{
			// The monster will die but not delete itself
			raiseEvent(StatusEvt$death_hit, "");
		}
		
		outputStats(TRUE,__LINE__);
	}
	
	else if(METHOD == StatusMethod$monster_rapeMe && ~RUNTIME_FLAGS&Monster$RF_INVUL){
		
		parseDesc(id, resources, status, fx, sex, team, mf);
		
		if(team == TEAM)
			return;
	
		list ray = llCastRay(llGetPos()+<0,0,1+hAdd()>, prPos(id)+<0,0,1>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
		if(llList2Integer(ray, -1) == 0){
		
			if(!isset(rapeName))
				rapeName = llGetObjectName();
			Bridge$fetchRape(llGetOwnerKey(id), rapeName);
			
		}
		
	}
	
	// Get status
    else if(METHOD == StatusMethod$get){
        CB_DATA = [STATUS_FLAGS, FXFLAGS, floor(HP/maxHP), 0, 0, 0, 0, TEAM];
    }
	// Take hit animation
    else if(METHOD == StatusMethod$monster_takehit){
		startAnim("hit");
        if(takehitsound)llTriggerSound(takehitsound, 1);
    }
	// Whenever spell modifiers have changed
    else if(METHOD == StatusMethod$spellModifiers){
        SPELL_DMG_TAKEN_MOD = llJson2List(method_arg(0));
    }
	// Get the description of an effect affecting me
    else if( METHOD == StatusMethod$getTextureDesc ){
	
        if( id == "" )
			id = llGetOwner();
		
		integer pid = (integer)method_arg(0);
        integer pos = llListFindList(SPELL_ICONS, [pid]);
        if( pos == -1 )
			return;
		
		llRegionSayTo(llGetOwnerKey(id), 0, llList2String(SPELL_ICONS, pos+2));
		
    }
	
	// Drop aggro from this
    else if(METHOD == StatusMethod$monster_dropAggro){
	
		key player = method_arg(0);
		integer complete = l2i(PARAMS, 0);
		integer pos = llListFindList(AGGRO, [player]);
		if(~pos){
			if(complete == 3)AGGRO = llListRandomize(AGGRO, AGGRO_STRIDE);
			else if(complete == 2)AGGRO = llListReplaceList(AGGRO, [llFrand(10)], pos-1, pos-1);
			else if(complete)AGGRO = llDeleteSubList(AGGRO, pos-1, pos+AGGRO_STRIDE-2);
			else AGGRO = llListReplaceList(AGGRO, [llList2Integer(AGGRO, pos+1)|AGFLAG_NOT_AGGROD], pos+1, pos+1);
		}
		aggro("",0);
		
	}
	
    // This person wants to target me
	else if(METHOD == StatusMethod$monster_attemptTarget && ~RUNTIME_FLAGS&Monster$RF_NO_TARGET)
        Root$targetMe(id, icon, (integer)method_arg(0), TEAM);
    // Add aggro
	else if(METHOD == StatusMethod$monster_aggro){
        aggro(method_arg(0), (float)method_arg(1));
	}
    else if(METHOD == StatusMethod$monster_taunt){
		key t = method_arg(0);
		integer inverse = (int)method_arg(1);
		
		integer i;
		for(i=0; i<llGetListLength(AGGRO); i+=AGGRO_STRIDE){
			if((llList2Key(AGGRO, i+1) == t) == inverse){
				AGGRO = llListReplaceList(AGGRO, [1.0], i, i);
			}
		}
		aggro("",0);
	}   
	
	//Nearby monster has found aggro
	else if(METHOD == StatusMethod$monster_aggroed && ~RUNTIME_FLAGS&Monster$RF_NOAGGRO && l2i(PARAMS, 2) == TEAM ){
		
		key p = method_arg(0);
		vector pp = prPos(p);
		float r = (float)method_arg(1);
		if(llVecDist(llGetPos(), pp) > r)return;
		list ray = llCastRay(llGetPos()+<0,0,1+hAdd()>, pp, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
		if(llList2Integer(ray, -1) == 0)
			aggro(p,10);
		
	}
	
	
	
	
	
	
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

