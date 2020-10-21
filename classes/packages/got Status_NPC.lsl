/*
	
	WARNING
	This script is saturated. You cannot add more features to it.
	
*/
#define USE_EVENTS
#define IS_NPC

integer BFL = 0; 
#define BFL_DEAD 0x1
#define BFL_FRIENDLY 0x2
#define BFL_STATUS_TIMER 0x4 
#define BFL_INITIALIZED 0x8
#define BFL_STATUS_QUEUE 0x10		// Send status on timeout
#define BFL_STATUS_SENT 0x20		// Status sent
#define BFL_AGGROED_ONCE 0x40		// If aggroed at least once
#define BFL_DESC_OVERRIDE 0x80

#define isAnimesh() (RF&Monster$RF_ANIMESH)

#define startAnim( anim ) \
	MeshAnim$startAnim(anim); MaskAnim$start(anim)
	
#define stopAnim( anim ) \
	MeshAnim$stopAnim(anim); MaskAnim$stop(anim)
#define BFL_NOAGGRO (BFL_FRIENDLY|BFL_DEAD)

#define initialized() (BFL&BFL_INITIALIZED)
#define memDebug(name, lst) 
//#define memDebug(name, lst) qd(name+" Entries: "+(str)count(lst));



//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"



list PLAYERS;
list PLAYER_HUDS;

float maxHP = -1;

// Conf stuff
int sex;
float dmg = 10;         // Damage of melee attacks
float HP = 100;
float preHP = 1;
float AR;			// aggro range
key aSnd;         	// Aggro sound
key daSnd;     		// Drop aggro sound
list atSnd;        	// Attack sound
key dSnd;         	// Death sound 
key icon;
string drops;			// JSON array of sub arrays of [(str)asset, (float)drop_chance]
integer rAdd;		// Hitbox range add for players to hit ME
integer hAdd;		// LOS check height offset from the default 0.5m above root prim
integer MH;			// Melee height, Used for RP
float hoverHeight;
#define hAdd() ((float)hAdd/10)

// (float)aggro, (key)id, (int)flags
#define AGGRO_STRIDE 3
list AG;	// aggro
#define AGFLAG_NOT_AGGROD 1


key AT;			// Aggro target. Should be a HUD or NPC UUID

integer tDEF = TEAM_NPC;			// This is the team set by the HUD itself, can be overridden by fxTeam
integer TEAM = TEAM_NPC;




// Effects
integer SF = 0; 		// Status flags
integer SFP = 0;		// Status flags pre
// See ots Monster
integer RF;				// Runtime flags

// FX
integer FF = 0;			// FX Flags
list fmDD;				// Damage done modifiers
float fmCR = 0;			// crit chance
integer fxTeam = -1;
// Damage taken modifiers
list fmDT;
// Healing taken modifiers
list fmHT;
list SDTM;



list cID;		// Custom ID (str)id, (var)mixed - Used for got Level integration

// Updates description with the proper team
#define setTeam(team) tDEF = team; outputStats(FALSE)
#define isFFA() l2s(PLAYERS, 0) == "*"

// Description is $M$(int)team$(int)HP_BITWISE$(int)rAdd(decimeters)$(int)hAdd$(int)status_flags$(int)monster_flags$(int)fx_flags$sex
#define updateDesc() if(~BFL&BFL_DESC_OVERRIDE){\
	llSetObjectDesc( \
		"$M$"+ \
		(str)TEAM+"$"+ \
		(str)(llRound(HP/maxHP*127)<<21)+"$"+ \
		(str)rAdd+"$"+ \
		(str)(hAdd-llRound(hoverHeight*10))+ \
		"$"+(str)SF+ \
		"$"+(str)RF+ \
		"$"+(str)FF+ \
		"$"+(str)sex); \
}

#define dropag( player, type ) \
	runMethod((str)LINK_THIS, cls$name, StatusMethod$monster_dropAggro, [player, type], TNN)

vector groundPoint(){
	
	vector root = llGetRootPosition();
	root.z -= hoverHeight;
	return root;

}

ag( key pl, float ag ){

    if( BFL&BFL_NOAGGRO || RF&(Monster$RF_FREEZE_AGGRO|Monster$RF_NOAGGRO) )
		return;
    
	list pre = AG;

    if( pl ){
	
        integer pre = count(AG);
        integer pos = llListFindList(AG, [pl]);
        key top; integer i;
        if( ~pos ){
		
            float nr = llList2Float(AG, pos-1);
            nr+=ag;
            if( nr<=0 )
				dropag(pl, TRUE);
            else{
			
                // Newly aggroed
                integer flag = llList2Integer(AG, pos+1);
                if( flag&AGFLAG_NOT_AGGROD )
                    AG = llListReplaceList(AG, [flag&~AGFLAG_NOT_AGGROD], pos+1, pos+1);
                
                AG = llListReplaceList(AG, [nr], pos-1, pos-1);
				
            }
			
        }
		else if( ag>0 ){
		
			AG += [ag, pl, 0];
			memDebug("AG", AG);
			
		}
        
		// First time aggoed
        if(AG != [] && !pre && aSnd != "" ){
		
			llTriggerSound(aSnd, 1);
			Status$monster_aggroed(pl, 10, TEAM);
			
		}
		
    }
	
    AG = llListSort(AG, AGGRO_STRIDE, FALSE);

    key at = "";
    integer i;
    for( i=0; i<count(AG) && AG != []; i+=AGGRO_STRIDE ){
	
		// Aggro target has left
		key t = l2k(AG, i+1);
        if( llKey2Name(t) == "" || llVecDist(groundPoint(), prPos(t)) > 20 ){
		
			AG = llDeleteSubList(AG, i, i+AGGRO_STRIDE-1);
			i-= AGGRO_STRIDE;
			
		}
		else if( ~llList2Integer(AG, i+2)&AGFLAG_NOT_AGGROD ){
		
            at = llList2Key(AG, i+1);
            i = count(AG);
			
        }
		
    }
    
    if( at != AT ){ 
	
        AT = at;
        if( at == "" && daSnd != "" )
            llTriggerSound(daSnd, 1);
		else if( at != "" ){
		
			if( ~RF&Monster$RF_NO_TARGET ) 
				Root$targetMe(at, icon, FALSE, TEAM);
				
			if( RF&Monster$RF_IS_BOSS && ~BFL&BFL_AGGROED_ONCE ){
			
				runOnPlayers(targ,
					GUI$toggleBoss(targ, icon, FALSE);
				)
				BFL = BFL|BFL_AGGROED_ONCE;
				
			}
			
		}
		
        raiseEvent(StatusEvt$monster_gotTarget, mkarr([AT]));
		
    }
	
	if( AG != pre )
		raiseEvent(StatusEvt$monster_aggro, mkarr(llList2ListStrided(llDeleteSubList(AG, 0, 0), 0, -1, AGGRO_STRIDE)));
	
}


// f = force
outputStats( integer f ){

	
	// NPC has been ressurected
	if( HP > 0 && SF&StatusFlag$dead ){
	
		raiseEvent(StatusEvt$dead, "0");
		SF = SF&~StatusFlag$dead;
		MaskAnim$restartOverride("idle");
		stopAnim("die");
		AG = [];
		AT = "";
		
	}
	
	// Check team
	integer t = fxTeam;
	if(t == -1)
		t = tDEF;
		
	integer pre = TEAM;
	
	// Needed for TEAM to be in the description
	TEAM = t;
	updateDesc();

	if( BFL&BFL_STATUS_SENT && !f && TEAM == pre ){
		
		BFL = BFL|BFL_STATUS_QUEUE;
		return;
		
	}

	if( SFP != SF ){
	
		raiseEvent(StatusEvt$flags, llList2Json(JSON_ARRAY,[SF, SFP]));
		SFP = SF;
		
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
	ptSet("_", .5, FALSE);
	
}







#define dtaInt l2i(dta,0)
#define dtaFloat l2f(dta,0)
#define dtaStr l2s(dta,0)

// Settings received
#define onSettings(settings) \
	list d = llJson2List(portalConf$desc); \
	list_shift_each(d, v, \
		list dta = llJson2List(v); \
		if(l2s(dta, 0) == "ID"){ \
			list cid = cID; \
			cID = llDeleteSubList(dta, 0, 0); \
			if((str)cid != (str)cID){ \
				Level$idEvent(LevelEvt$idSpawned, llList2String(cID, 0), mkarr(llDeleteSubList(cID, 0, 0)), portalConf$spawnround); \
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
			RF = dtaInt; \
		if(idx == MLC$maxhp) \
			maxHP = dtaFloat; \
		if(idx == MLC$aggro_range) \
			AR = dtaFloat; \
		if(idx == MLC$aggro_sound) \
			aSnd = dtaStr; \
		if(idx == MLC$dropaggro_sound) \
			daSnd = dtaStr; \
		if(idx == MLC$attacksound) \
			atSnd = llJson2List(dtaStr); \
		if(idx == MLC$deathsound) \
			dSnd = dtaStr; \
		if(idx == MLC$icon) \
			icon = dtaStr; \
		if(idx == MLC$dmg) \
			dmg = dtaFloat; \
		if(idx == MLC$range_add) \
			rAdd = dtaInt; \
		if(idx == MLC$height_add) \
			hAdd = dtaInt; \
		if( idx == MLC$hover_height ) \
			hoverHeight = dtaFloat; \
		if(idx == MLC$team && dtaStr != "") \
			team = dtaInt; \
		if(idx == MLC$drops) \
			drops = dtaStr; \
		if( idx == MLC$melee_height ) \
			MH = dtaInt; \
		if( idx == MLC$sex ) \
			sex = dtaInt; \
	} \
	if(mhp == -1 || HP>maxHP) \
		HP = maxHP; \
	if(AR > 0){ \
		ptSet("A", 2, TRUE); \
	}else{ \
		ptUnset("A"); \
	} \
	if(llJsonValueType(drops, []) != JSON_ARRAY)drops = "[]"; \
	setTeam(team); \
	debugUncommon("Setting team from onSettings: "+(str)team); \
	if(~BFL&BFL_INITIALIZED){ \
		BFL = BFL|BFL_INITIALIZED; \
		raiseEvent(StatusEvt$monster_init, ""); \
	} \



#define onEvt(script, evt, data) \
	if( script == "got Portal" && (evt == evt$SCRIPT_INIT || evt == PortalEvt$players) ){ \
        PLAYERS = data; \
		if( AR > 0 && portalConf$live ){ \
			ptSet("A", 1, TRUE); \
		} \
    } \
	else if( script == "got Portal" && evt == PortalEvt$playerHUDs ) \
		PLAYER_HUDS = data; \
	else if( script == "got Monster" ){ \
	    if( evt == MonsterEvt$runtimeFlagsChanged ){\
			RF = l2i(data, 0); \
			updateDesc() \
		} \
		else if( evt == MonsterEvt$attack ){ \
			\
			key targ = llList2Key(data, 0); \
            float crit = 1; \
			if( llFrand(1) < fmCR ) \
				crit = 2; \
			float dm = 1; \
			integer pos = llListFindList(fmDD, (list)0); \
			if( ~pos ) \
				dm = dm*l2f(fmDD, pos+1); \
			if( ~(pos = llListFindList(fmDD, (list)key2int(targ))) ) \
				dm = dm*l2f(fmDD, pos+1); \
			\
			integer dmg = llRound(dmg*dm*crit*10); \
			integer pain = llRound(dmg*.2); \
			list h = [6,"<-1,-1,-1>"];\
			myAngX(targ, ang) \
			if( llFabs(ang) < PI_BY_TWO ){ \
				if( MH == 0 ) \
					h+= fxhfFlag$SLOT_GROIN; \
				else if(MH == 1) \
					h+= fxhfFlag$SLOT_BREASTS; \
			} \
			else if( MH == 0 ) \
				h+= fxhfFlag$SLOT_BUTT; \
			string hitfx = mkarr(h); \
            FX$send( \
				targ, \
				llGetKey(), \
				"[1,0,0,0,[0,1,\"\",[[1,"+ \
					llInsertString((str)dmg,llStringLength((str)dmg)-1,".")+ \
				"],[3,"+ \
					llInsertString((str)pain, llStringLength((str)pain)-1, ".")+ \
				"],"+hitfx+"]]]", TEAM); \
        } \
		else if( evt == MonsterEvt$attackStart && count(atSnd) ){ \
            llTriggerSound(randElem(atSnd), 1); \
        } \
    } \
	else if( evt == evt$TOUCH_START ){ \
		if( initialized() && ~RF&Monster$RF_NO_TARGET ) \
			Root$targetMe(l2s(data, 1), icon, TRUE, TEAM); \
	} \
	else if( script == "got NPCSpells" ){ \
		if( evt == NPCSpellsEvt$SPELL_CAST_START || evt == NPCSpellsEvt$SPELL_CAST_FINISH || evt == NPCSpellsEvt$SPELL_CAST_INTERRUPT ){ \
			SF = SF&~StatusFlag$casting; \
			if( evt == NPCSpellsEvt$SPELL_CAST_START ) \
				SF = SF|StatusFlag$casting; \
			outputStats(FALSE); \
		} \
	}

	
	
#define ptEvt(id) \
	if( id == "_" ){ \
		BFL = BFL&~BFL_STATUS_SENT; \
		if( BFL&BFL_STATUS_QUEUE ){ \
			BFL = BFL&~BFL_STATUS_QUEUE; \
			outputStats(FALSE); \
		} \
	} \
    else if( id == "A" && ~BFL&BFL_NOAGGRO ){ \
		parseDesc(AT, resources, status, fx, sex, team, monsterFlags, armor); \
		if( \
			AT != "" && \
			( \
				status&StatusFlags$NON_VIABLE || \
				fx&fx$UNVIABLE ||  \
				team == TEAM || \
				monsterFlags&Monster$RF_INVUL \
			) \
		){ \
			dropag(AT, TRUE); \
		} \
		else if( AT == "" ){ \
			llSensor("", "", AGENT|ACTIVE, AR, PI); \
		} \
    }\
	else if( id == "WIPE" ) \
		llDie();
	

_MT(string id, integer t)
{
    float g = llGetTime();
    if (!(id == ""))
    {
        integer pos = llListFindList(_mt, (list)id);
        float to = (float)(t & ~0x80000000) / 100;
        float nx = to + g;
        if ((~t) & ((integer)-0x80000000))
            to = 0;
        if (~pos)
            _mt = llDeleteSubList(_mt, ~-pos, -~pos);
        if (t)
            _mt = _mt + ((list)nx + id + to);
    }
    for (t = 0; t < (_mt != []); t = 3 + t)
    {
        if (!(g < llList2Float(_mt, t)))
        {
            float re = llList2Float(_mt, -~-~t);
            string id = llList2String(_mt, -~t);
            if (re == ((float)0))
            {
                _mt = llDeleteSubList(_mt, t, -~-~t);
                t = ((integer)-3) + t;
            }
            else
                _mt = llListReplaceList(_mt, (list)(g + re), t, t);
			
            ptEvt(id);
        }
    }
    if (_mt == [])
    {
        llSetTimerEvent(0);
        return;
    }
    _mt = llListSort(_mt, 3, 1);
	float n = llList2Float(_mt, 0) + -g;
    if (!(0 < n))
        n = 0.01;
	llSetTimerEvent(n);
}
	

default 
{
    state_entry(){
	
        raiseEvent(evt$SCRIPT_INIT, "");
		setTeam(tDEF);
		
    }
	
	sensor( integer total ){
		
		vector root = groundPoint();
		
		integer ffa = isFFA();
		while( total-- ){
		
            key k = llDetectedKey(total);
			integer type = llDetectedType(total);
			
			// These can not be relied on for PC
			parseDesc(k, resources, status, fx, sex, team, mf, armor);
			vector ppos = prPos(k);
			float dist =llVecDist(ppos, root);
			float range = AR;
			
			float ang;
			if( isAnimesh() ){
				prAngleOn(k, ang, ZERO_ROTATION);
			}
			else{
				prAngleOn(k, ang, llEuler2Rot(<0,PI_BY_TWO,0>));
			}
			
			if( llFabs(ang)>PI_BY_TWO && ~RF&Monster$RF_360_VIEW )
				range *= 0.25;
				
						
			if(
				(
					(type&AGENT && (ffa || ~llListFindList(PLAYERS, [(str)k]))) || 
					(llGetSubString(prDesc(k), 0, 2) == "$M$" && team != TEAM && ~mf&Monster$RF_INVUL)
				) && ~RF&Monster$RF_NOAGGRO && ~BFL&BFL_NOAGGRO &&
				dist < range
			){
			
				list ray = llCastRay(root+<0,0,1+hAdd()>, ppos+<0,0,1>, ([RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]));
				if( llList2Integer(ray, -1) == 0 )
					Status$get(k, "aggro");

			}
			
        }
		
	}
	
    
    
    timer(){ptRefresh();}
    
	#define LM_PRE \
		if(nr == TASK_FX){ \
			list data = llJson2List(s); \
			FF = l2i(data, FXCUpd$FLAGS); \
			fmCR = i2f(l2f(data, FXCUpd$CRIT))-1; \
			fxTeam = l2i(data, FXCUpd$TEAM); \
			outputStats(FALSE); \
		}\
		else if(nr == TASK_MONSTER_SETTINGS){\
			list data = llJson2List(s); \
			onSettings(data); \
		} \
		else if( nr == TASK_OFFENSIVE_MODS )\
			fmDD = llJson2List(j(s, 0));  \
		else if( nr ==  TASK_SPELL_MODS ){ \
			SDTM = llJson2List(j(s, 0)); \
			fmDT = llJson2List(j(s, 1)); \
			fmHT = llJson2List(j(s, 2)); \
		}
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
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
	
	
	
	if( METHOD == StatusMethod$batchUpdateResources && ~SF&StatusFlag$dead ){
	
		key attacker = l2s(PARAMS, 0);	// Attacker is prepended
		PARAMS = llDeleteSubList(PARAMS, 0, 0);
		
		// First part is a tokenized attacker, we remove it because we need the full attacker in NPC
		while(PARAMS){
		
			integer type = l2i(PARAMS, 0);
			integer len = l2i(PARAMS, 1);
			list data = llList2List(PARAMS, 2, 2+len-1);		// See SMBUR$* at got Status
			PARAMS = llDeleteSubList(PARAMS, 0, 2+len-1);
			float amount = i2f(llList2Float(data, 0));	
			string spellName = l2s(data, 1);					// Spell name
			integer flags = l2i(data, 2);				// Spell flags
			float steal = l2f(data, 3);					// Life steal
			
			// HP Damage
			if(type == SMBUR$durability){
			
				float pre = HP;
				
				
				if( flags & SMAFlag$FORCE_PERCENTAGE ){
					HP = maxHP*(-amount);
				}
				else{
					float spdmtm = 1;
					integer cn = key2int(attacker);
					integer i;
					for( i=0; i<count(SDTM); i+=3 ){
					
						if( 
							llList2String(SDTM, i) == spellName && 
							( !l2i(SDTM, i+1) || l2i(SDTM, i+1) == cn ) 
						){
							
							float nr = llList2Float(SDTM, i+2);
							if( nr <0 )
								nr = 0;
							spdmtm = nr;
							i = count(SDTM);
							
						}
						
					}

					amount*=spdmtm;
					
					
					if( flags&SMAFlag$IS_PERCENTAGE )
						amount*=maxHP;
						
					if(amount<0){
					
						// Damage taken multiplier
						float fmdt = 1;
						integer pos = llListFindList(llList2ListStrided(fmDT, 0,-1,2), (list)0);
						if( ~pos )
							fmdt *= l2f(fmDT, pos*2+1);
						if( ~(pos = llListFindList(llList2ListStrided(fmDT, 0,-1,2), (list)key2int(attacker))) )
							fmdt *= l2f(fmDT, pos*2+1);
								
						amount*=fmdt;
						parseDesc(attacker, _r, _s, _f, _st, team, _mo, _a)
						if( attacker != "" && team != TEAM )
							ag(attacker, llFabs(amount));
						
					}
					else{
					
						// Healing taken multiplier
						float fmht = 1;
						// Add wildcard
						integer pos = llListFindList(llList2ListStrided(fmHT, 0,-1,2), (list)0);
						if( ~pos )
							fmht *= l2f(fmHT, pos*2+1);
						// Add specific attacker
						if( ~(pos = llListFindList(llList2ListStrided(fmHT, 0,-1,2), (list)key2int(attacker))) )
							fmht *= l2f(fmHT, pos*2+1);
						amount*= fmht;
						
					}
					
					raiseEvent(StatusEvt$hurt, llList2Json(JSON_ARRAY, [(str)amount, attacker]));
					if( amount<0 && RF&Monster$RF_INVUL )
						return;
					
					HP += amount;
					
					Status$handleLifeSteal(amount, steal, attacker)
				}
				if( HP <= 0 && HP != pre ){
				
					HP = 0;
					Status$kill(LINK_THIS);
					return;
					
				}
				else if( HP > maxHP )
					HP = maxHP;
				
				if(pre != HP)
					outputStats(FALSE);
				
			}
		}
		outputStats(FALSE);
	}
	
	if(METHOD == StatusMethod$fullregen){
	
		BFL = BFL|BFL_INITIALIZED;
		HP = maxHP;
		
		outputStats(TRUE);
		
	}
	else if(METHOD == StatusMethod$setTeam){
		debugUncommon("Setting team from method by "+SENDER_SCRIPT+" : "+method_arg(0));
		setTeam(l2i(PARAMS, 0)); 
	}
		

	// Combat stuff below here
	if( !initialized() )
		return;
	
    if( method$isCallback ){
	
        if( METHOD == StatusMethod$get && id!="" && SENDER_SCRIPT == "got Status" && CB == "aggro" ){

			// agc checks if it should rape or not
			integer flags = (integer)method_arg(0);
			if(!_attackable(PARAMS) || llList2Integer(PARAMS,7) == TEAM){
				dropag(id, TRUE);
				return;
			}                
			ag(id, 10);
			
		} 
        return;
		
    }
	

	// Sets runtime flags
	if(METHOD == StatusMethod$monster_setFlag)
		SF = SF|(integer)method_arg(0);
	
	else if(METHOD == StatusMethod$monster_remFlag)
		SF = SF&~(integer)method_arg(0);
	
	else if( METHOD == StatusMethod$kill ){
	
		HP = 0;
		
		if(RF&Monster$RF_IS_BOSS){
			runOnPlayers(targ, GUI$toggleBoss(targ, "", FALSE);)
		}
		
		Level$idEvent(LevelEvt$idDied, llList2String(cID, 0), mkarr(llDeleteSubList(cID, 0, 0)), portalConf$spawnround);
		
		
		SF = SF|StatusFlag$dead;
		raiseEvent(StatusEvt$dead, "1");
		startAnim("die");
		
		llSleep(.1);
		stopAnim("idle");
		stopAnim("walk");
		stopAnim("attack");
		BFL = BFL&~BFL_INITIALIZED; 	// Prevent further interaction
		llSetObjectDesc("");			// Prevent targeting

		
		if(dSnd)
			llTriggerSound(dSnd, 1);
			
		outputStats(TRUE);
		
		// The monster will remove itself
		if( ~RF&Monster$RF_NO_DEATH ){
		
			if( ~RF & Monster$RF_MINOR ){
			
				// Drop loot
				list d = llListRandomize(llJson2List(drops), 1);
				list_shift_each(d, val,
					if(llFrand(1)<(float)j(val, 1)){ 
						Spawner$spawn(j(val,0), (groundPoint()+<0,0,.5>), llGetRot(), "[\"M\"]", FALSE, FALSE, "");
						d = [];
					}
				)
				
				int avg; 
				runOnHUDs(targ,
					parseArmor(targ, armor)
					integer n;
					for(; n<5; ++n)
						avg += Status$getArmorVal( armor, n );
				)
				float perc = (float)avg/(count(PLAYERS)*50*5);
				
				float rand = llFrand(1);
				// 0-30% based on missing armor of the party
				if( maxHP >= 40 && rand < 0.05+(1.0-perc)*0.25 ){
				
					list ray = llCastRay(llGetPos()+<0,0,1>, llGetPos()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
					if( l2i(ray, -1) == 1 ){
						
						vector pos = l2v(ray, 1)+<0,0,.75>;
						Spawner$spawn("Armor Scraps", pos, 0, "", FALSE, TRUE, "ARMOR");
						
					}
					
				}
				
			}
			
			ptSet("WIPE", 10, FALSE);
			
		}
		else{
			// The monster will die but not delete itself
			raiseEvent(StatusEvt$death_hit, "");
		}
		
		
		
	}

	// Get status
    else if( METHOD == StatusMethod$get )
        CB_DATA = (list)SF + FF + floor(HP/maxHP) + 0 + 0 + 0 + 0 + TEAM;
    

	// Drop aggro from this
    else if( METHOD == StatusMethod$monster_dropAggro ){
	
		// sending ALL will reset all aggro
		if( method_arg(0) == "ALL" ){
			AG = [];
		}
		else{
		
			key player = method_arg(0);
			integer complete = l2i(PARAMS, 0);
			integer pos = llListFindList(AG, [player]);
			if(~pos){
				if(complete == 3)AG = llListRandomize(AG, AGGRO_STRIDE);
				else if(complete == 2)AG = llListReplaceList(AG, [llFrand(10)], pos-1, pos-1);
				else if(complete)AG = llDeleteSubList(AG, pos-1, pos+AGGRO_STRIDE-2);
				else AG = llListReplaceList(AG, [llList2Integer(AG, pos+1)|AGFLAG_NOT_AGGROD], pos+1, pos+1);
			}
		}
		ag("",0);
		
	}
	
    // This person wants to target me
	else if(METHOD == StatusMethod$monster_attemptTarget && ~RF&Monster$RF_NO_TARGET)
        Root$targetMe(prRoot(id), icon, (integer)method_arg(0), TEAM);
    // Add aggro
	else if(METHOD == StatusMethod$monster_aggro){
        ag(method_arg(0), (float)method_arg(1));
	}
    else if(METHOD == StatusMethod$monster_taunt){
		key t = method_arg(0);
		integer inverse = (int)method_arg(1);
				
		integer i;
		for( ; i<count(AG); i+=AGGRO_STRIDE ){
		
			if( (llList2Key(AG, i+1) == t) == inverse )
				AG = llListReplaceList(AG, [1.0], i, i);
				
		}
		
		if( !inverse && t != "" )
			ag(t, 20);
		else
			ag("",0);
			
	}   
	
	//Nearby monster has found aggro
	else if(METHOD == StatusMethod$monster_aggroed && ~RF&Monster$RF_NOAGGRO && l2i(PARAMS, 2) == TEAM ){
		
		key p = method_arg(0);
		vector pp = prPos(p);
		float r = (float)method_arg(1);
		if(llVecDist(groundPoint(), pp) > r)
			return;
		list ray = llCastRay(llGetRootPosition()+<0,0,1+hAdd()>, pp, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
		if(llList2Integer(ray, -1) == 0)
			ag(p,10);
		
	}

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

