#define USE_EVENTS
#define IS_NPC
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define initialized() (BFL&BFL_INITIALIZED)

list PLAYERS;

float maxHP = 100;

// Conf stuff
float dmg = 10;         // Damage of melee attacks
float HP = 100;
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

// (float)aggro, (key)id, (int)flags
#define AGGRO_STRIDE 3
list AGGRO;
#define AGFLAG_NOT_AGGROD 1

key aggroTarg;			// Should always be an object

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
// See ots Monster
integer RUNTIME_FLAGS;

// FX
integer FXFLAGS = 0;
float fxModDmgTaken = 1;
float fxModDmgDone = 1;
float fxModCrit = 0;
float fxModHealingTaken = 1;

list SPELL_DMG_TAKEN_MOD;


#define SPSTRIDE 6
list SPELL_ICONS;   // [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks]


list OUTPUT_STATUS_TO; 

list CUSTOM_ID;		// (str)id, (var)mixed - Used for got Level integration

// Updates description with the proper team
#define setTeam(team) TEAM = team; raiseEvent(StatusEvt$team, (str)TEAM)
#define isFFA() l2s(PLAYERS, 0) == "*"

// Description is $M$(int)team$(int)HP_BITWISE$(int)range_add(decimeters)
#define updateDesc() if(~BFL&BFL_DESC_OVERRIDE){llSetObjectDesc("$M$"+(str)TEAM+"$"+(str)(llRound(HP/maxHP*127)<<21)+"$"+(str)range_add);}


dropAggro(key player, integer complete){
    integer pos = llListFindList(AGGRO, [player]);
    if(~pos){
		if(complete == 3)AGGRO = llListRandomize(AGGRO, AGGRO_STRIDE);
		else if(complete == 2)AGGRO = llListReplaceList(AGGRO, [llFrand(10)], pos-1, pos-1);
        else if(complete)AGGRO = llDeleteSubList(AGGRO, pos-1, pos+AGGRO_STRIDE-2);
        else AGGRO = llListReplaceList(AGGRO, [llList2Integer(AGGRO, pos+1)|AGFLAG_NOT_AGGROD], pos+1, pos+1);
    }
    aggro("",0);
}

float spdmtm(string spellName){
    if(!isset(spellName))return 1;
    integer i;
    for(i=0; i<llGetListLength(SPELL_DMG_TAKEN_MOD); i+=2){
        if(llList2String(SPELL_DMG_TAKEN_MOD, i) == spellName){
            float nr = llList2Float(SPELL_DMG_TAKEN_MOD, i+1);
            if(nr <0)return 0;
            return nr;
        }
    }
    return 1;
}

outputTextures(){
	integer i; list out;
	for(i=0; i<llGetListLength(SPELL_ICONS); i+=SPSTRIDE){
		out+= llDeleteSubList(llList2List(SPELL_ICONS, i, i+SPSTRIDE-1), 2, 2);
	}
	string s = llDumpList2String(out,",");
    for(i=0; i<llGetListLength(OUTPUT_STATUS_TO); i++)
        GUI$setSpellTextures(llList2Key(OUTPUT_STATUS_TO, i), s);
}

addHP(float amount, key attacker, string spellName, integer flags, integer update){
	
	

    if(STATUS_FLAGS&StatusFlag$dead)return;
    float pre = HP;
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE)
		amount*=maxHP;
		
    if(amount<0){
		if(RUNTIME_FLAGS&Monster$RF_INVUL)return;
        amount*=fxModDmgTaken;
		
        if(attacker){
            aggro(attacker, llFabs(amount));
        }
		raiseEvent(StatusEvt$hurt, llList2Json(JSON_ARRAY, [(str)amount, attacker]));
    }
    else{
		amount*= fxModHealingTaken;
	}
	
    HP += amount;
    if(HP<=0 && HP != pre){
		HP = 0;
		outputStats(TRUE);
		if(RUNTIME_FLAGS&Monster$RF_IS_BOSS){
			runOnPlayers(targ, GUI$toggleBoss(targ, "");)
		}
		list_shift_each(OUTPUT_STATUS_TO, val, Root$clearTargetOn(val);)
		Level$idEvent(LevelEvt$idDied, llList2String(CUSTOM_ID, 0), mkarr(llDeleteSubList(CUSTOM_ID, 0, 0)));
		
        
        STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;
        raiseEvent(StatusEvt$dead, "1");
		anim("die", TRUE);
        
        llSleep(.1);
		anim("idle", FALSE);
		anim("walk", FALSE);
		anim("attack", FALSE);
        BFL = BFL&~BFL_INITIALIZED; 	// Prevent further interaction
		llSetObjectDesc("");			// Prevent targeting
        
		list d = llListRandomize(llJson2List(drops), 1);
		list_shift_each(d, val,
			if(llFrand(1)<(float)j(val, 1)){ 
				Spawner$spawn(j(val,0), (llGetPos()+<0,0,.5>), llGetRot(), "", FALSE, FALSE, "");
				d = [];
			}
		)
        
        
        if(deathsound)llTriggerSound(deathsound, 1);
        if(~RUNTIME_FLAGS&Monster$RF_NO_DEATH){
            llSleep(2);
            llDie();
        }
		else{
			raiseEvent(StatusEvt$death_hit, "");
		}
    }else if(HP > maxHP)HP = maxHP;
    
    if(pre != HP && update)
        outputStats(FALSE);
    
}

aggroCheck(key k, float mod){
    if(RUNTIME_FLAGS&Monster$RF_NOAGGRO)return;
    if(BFL&BFL_NOAGGRO)return;
    
    vector ppos = prPos(k);
    float dist =llVecDist(ppos, llGetPos()); 
    
    if(dist>100)return;
    
    integer ainfo = llGetAgentInfo(k);
    float range = aggro_range*mod;
    vector add = <0,0,1>;
    if(mod <= 1){
        list odata = llGetObjectDetails(k, [OBJECT_POS, OBJECT_ROT]);
        float bet = llRot2Angle(llRotBetween(llVecNorm(<0,0,1> * llGetRot()), llVecNorm(llList2Vector(odata, 0)-llGetPos())));
        if(bet>PI_BY_TWO)range*=.5;
        if(ainfo&AGENT_CROUCHING){
            add = ZERO_VECTOR;
            range *= .5;
            if(bet>PI_BY_TWO)range=.5;
        }
    }
    
    
    if(dist<range){
        list ray = llCastRay(llGetPos()+add, ppos+add, ([RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]));
        if(llList2Integer(ray, -1) == 0){
            Status$get(k, "aggro");
        } 
    }
	
	
}




aggro(key player, float ag){
	//qd(RUNTIME_FLAGS&Monster$RF_FREEZE_AGGRO);
    if(BFL&BFL_NOAGGRO || RUNTIME_FLAGS&(Monster$RF_FREEZE_AGGRO|Monster$RF_NOAGGRO))return;
    
	list pre = AGGRO;
	
	
    if(player){
        integer pre = llGetListLength(AGGRO);
        integer pos = llListFindList(AGGRO, [player]);
        key top; integer i;
        if(~pos){
            float nr = llList2Float(AGGRO, pos-1);
            nr+=ag;
            if(nr<=0)dropAggro(player, TRUE);
            else{
                // Newly aggroed
                integer flag = llList2Integer(AGGRO, pos+1);
                if(flag&AGFLAG_NOT_AGGROD)
                    AGGRO = llListReplaceList(AGGRO, [flag&~AGFLAG_NOT_AGGROD], pos+1, pos+1);
                
                AGGRO = llListReplaceList(AGGRO, [nr], pos-1, pos-1);
            }
        }else if(ag>0)AGGRO += [ag, player, 0];
        
		// First time aggoed
        if(AGGRO != [] && !pre){
            if(aggrosound){
				llTriggerSound(aggrosound, 1);
				Status$monster_aggroed(player, 10, TEAM);
			}
		}
    }
    AGGRO = llListSort(AGGRO, AGGRO_STRIDE, FALSE);
    
    
    key at = "";
    integer i;
    for(i=0; i<llGetListLength(AGGRO); i+=AGGRO_STRIDE){
        if(~llList2Integer(AGGRO, i+2)&AGFLAG_NOT_AGGROD){
            at = llList2Key(AGGRO, i+1);
            i = llGetListLength(AGGRO);
        }
    }
    
    if(at != aggroTarg){ 
        aggroTarg = at;
        if(at == ""){
            if(dropaggrosound)
                llTriggerSound(dropaggrosound, 1);
        }else{
			if(~RUNTIME_FLAGS&Monster$RF_NO_TARGET) Root$targetMe(at, icon, FALSE, TEAM);
			if(RUNTIME_FLAGS&Monster$RF_IS_BOSS && ~BFL&BFL_AGGROED_ONCE){
				runOnPlayers(targ,
					GUI$toggleBoss(targ, icon);
				)
				BFL = BFL|BFL_AGGROED_ONCE;
			}
		}
        raiseEvent(StatusEvt$monster_gotTarget, mkarr([aggroTarg]));
    }
	
	if(AGGRO != pre){
		raiseEvent(StatusEvt$monster_aggro, mkarr(llList2ListStrided(llDeleteSubList(AGGRO, 0, 0), 0, -1, AGGRO_STRIDE)));
	}
}

onEvt(string script, integer evt, list data){
	if(script == "got Portal" && evt == evt$SCRIPT_INIT){
        PLAYERS = data;
		if(aggro_range)multiTimer(["A", "", 1, TRUE]);
    }
	
	
	else if(script == "got Monster"){
	    if(evt == MonsterEvt$runtimeFlagsChanged){
            integer pre = RUNTIME_FLAGS;
			RUNTIME_FLAGS = llList2Integer(data,0);
			
			if(
				(pre&Monster$RF_NO_TARGET) != (RUNTIME_FLAGS&Monster$RF_NO_TARGET) && 
				RUNTIME_FLAGS&Monster$RF_NO_TARGET
			){
				// Can no longer be targeted
				list_shift_each(OUTPUT_STATUS_TO, val, Root$clearTargetOn(val);)
			}
        }
		
		else if(evt == MonsterEvt$attack){
            key targ = llList2Key(data, 0);
            float crit = 1;
			if(llFrand(1)<fxModCrit)crit = 2;
			integer dmg = llRound(dmg*fxModDmgDone*crit*10);
			integer pain = llRound(dmg*.2);
			
            FX$send(targ, llGetKey(), "[1,0,0,0,[0,1,\"\",[[1,"+llInsertString((str)dmg,llStringLength((str)dmg)-1,".")+"],[3,"+llInsertString((str)pain, llStringLength((str)pain)-1, ".")+"],[6,\"<1,.5,.5>\"]],[],[],[],0,0,0]]", TEAM);
        }
		
		else if(evt == MonsterEvt$attackStart){
            if(attacksound)
                llTriggerSound(attacksound, 1);
            
        }
    }
}

outputStats(integer force){
	updateDesc();

	if(BFL&BFL_STATUS_SENT && !force){
		BFL = BFL|BFL_STATUS_QUEUE;
		return;
	}
	if(RUNTIME_FLAGS&Monster$RF_IS_BOSS){
		OUTPUT_STATUS_TO = PLAYERS;
	}
    raiseEvent(StatusEvt$flags, (string)STATUS_FLAGS);
    raiseEvent(StatusEvt$monster_hp_perc, (string)(HP/maxHP));
	BFL = BFL|BFL_STATUS_SENT;
	multiTimer(["_", "", .5, FALSE]);
}


timerEvent(string id, string data){
	if(id == "_"){
		BFL = BFL&~BFL_STATUS_SENT;
		if(BFL&BFL_STATUS_QUEUE){
			BFL = BFL&~BFL_STATUS_QUEUE;
			outputStats(FALSE);
		}
	}
    else if(id == "A"){
        if(BFL&BFL_NOAGGRO)return;
        if(aggroTarg != ""){
		
			parseDesc(aggroTarg, resources, status, fx, sex, team);
            
			
			if(
				status&StatusFlags$NON_VIABLE ||
				fx&fx$UNVIABLE || 
				team == TEAM
			){
				dropAggro(aggroTarg, TRUE);
			}
			
            
			return;
        }
		
		// Ping enemies within aggro range
		llSensor("", "", AGENT|ACTIVE, aggro_range, PI);
    }else if(id == "OT"){
        outputTextures();
    }
}

anim(string anim, integer start){
	integer meshAnim = (llGetInventoryType("ton MeshAnim") == INVENTORY_SCRIPT);
	if(start){
		if(meshAnim)MeshAnim$startAnim(anim);
		else if(anim=="die")MaskAnim$restartOverride(anim);
		else{
			MaskAnim$start(anim);
		}
	}else{
		if(meshAnim)MeshAnim$stopAnim(anim);
		else MaskAnim$stop(anim);
	}
}


// Settings received
onSettings(list settings){
	
	// Check for ID
	list d = llJson2List(portalConf());
	list_shift_each(d, v,
		list dta = llJson2List(v);
		if(l2s(dta, 0) == "ID"){
			list cid = CUSTOM_ID;
			CUSTOM_ID = llDeleteSubList(dta, 0, 0);
			if((str)cid != (str)CUSTOM_ID)
				Level$idEvent(LevelEvt$idSpawned, llList2String(CUSTOM_ID, 0), mkarr(llDeleteSubList(CUSTOM_ID, 0, 0)));
		}
	)
	
	
	while(settings){
		integer idx = l2i(settings, 0);
		list dta = llList2List(settings, 1, 1);
		settings = llDeleteSubList(settings, 0, 1);
		#define dtaInt l2i(dta,0)
		#define dtaFloat l2f(dta,0)
		#define dtaStr l2s(dta,0)
		
		// Runtime flags
		if(idx == 0)
			RUNTIME_FLAGS = dtaInt;
		// Max HP
		if(idx == MLC$maxhp)
			maxHP = dtaFloat;
		if(idx == MLC$aggro_range)
			aggro_range = dtaFloat;
			
		if(idx == MLC$aggro_sound)
			aggrosound = dtaStr;
			
		if(idx == MLC$dropaggro_sound)
			dropaggrosound = dtaStr;
			
		if(idx == MLC$takehit_sound)
			takehitsound = dtaStr;
		
		if(idx == MLC$attacksound)
			attacksound = dtaStr;
		
		if(idx == MLC$deathsound)
			deathsound = dtaStr;
		
		if(idx == MLC$icon)
			icon = dtaStr;
		
		if(idx == MLC$dmg)
			dmg = dtaFloat;
			
		if(idx == MLC$range_add)
			range_add = dtaInt;
			
		// Brackets are important here
		if(idx == MLC$team && dtaStr != ""){
			setTeam(dtaInt);
		}
			

		if(idx == MLC$rapePackage && isset(dtaStr))
			rapeName = dtaStr;
		
		if(idx == MLC$drops)
			drops = dtaStr;
		
		if(llJsonValueType(drops, []) != JSON_ARRAY)drops = "[]";

        
		
	}
	
	// Limits
	HP = maxHP;
	if(aggro_range > 0)
		multiTimer(["A", "", 2, TRUE]);
	else
		multiTimer(["A"]);
	updateDesc();
	
	if(~BFL&BFL_INITIALIZED){
		BFL = BFL|BFL_INITIALIZED;
		raiseEvent(StatusEvt$monster_init, "");
	}
}


default 
{
    state_entry(){
        if(llGetStartParameter()){
            raiseEvent(evt$SCRIPT_INIT, "");
        }
		setTeam(TEAM);
		updateDesc();
    }
	
	sensor(integer total){
		integer ffa = isFFA();
		

		while(total--){
            key k = llDetectedKey(total);
			integer type = llDetectedType(total);
			string desc = prDesc(k);

			if(
				(type&AGENT && TEAM != TEAM_PC && (ffa || ~llListFindList(PLAYERS, [(str)k]))) || 
				(llGetSubString(desc, 0, 2) == "$M$" && (int)llGetSubString(desc, 3, 3) != TEAM)
			){
				aggroCheck(k, 1);
			}
        }
	}
	
	
    
    touch_start(integer total){
		if(!initialized() || RUNTIME_FLAGS&Monster$RF_NO_TARGET)return;
        Root$targetMe(llDetectedKey(0), icon, TRUE, TEAM);
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
        outputStats(FALSE); \
	}\
	else if(nr == TASK_MONSTER_SETTINGS)\
		onSettings(llJson2List(s));
	
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
	
	
	
	if(METHOD == StatusMethod$batchUpdateResources){
		while(PARAMS){
			integer type = l2i(PARAMS, 0);
			integer len = l2i(PARAMS, 1);
			list data = llList2List(PARAMS, 2, 2+len-1);		// See SMBUR$* at got Status
			PARAMS = llDeleteSubList(PARAMS, 0, 2+len-1);
			float amount = i2f(llList2Float(data, 0));	
			string name = l2s(data, 1);					// Spell name
			integer flags = l2i(data, 2);				// Spell flags
			key id = l2s(data, 3);
			
			// Apply
			if(type == SMBUR$durability)  
				addHP(amount, id, name, flags, FALSE);
		}
		outputStats(FALSE);
	}
	
	
	if(!initialized()){
		return;
	}
    if(method$isCallback){
        if(METHOD == StatusMethod$get && id!="" && SENDER_SCRIPT == "got Status"){
            if(CB == "aggro"){
                
                // agc checks if it should rape or not
                integer flags = (integer)method_arg(0);
                if(!_attackable(PARAMS) || llList2Integer(PARAMS,7) == TEAM){
                    dropAggro(id, TRUE);
                    return;
                }                
                aggro(id, 10);
            } 
        }  
        return;
    }
	
	
	
    if(id == ""){
		if(METHOD == StatusMethod$addTextureDesc){
            SPELL_ICONS += [(integer)method_arg(0), (key)method_arg(1), (str)method_arg(2), (int)method_arg(3), (int)method_arg(4), (int)method_arg(5)];
			multiTimer(["OT", "", .1, FALSE]);
        }
        else if(METHOD == StatusMethod$remTextureDesc){
            integer pid = (integer)method_arg(0);
            integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
			if(pos == -1)return;
			
            SPELL_ICONS = llDeleteSubList(SPELL_ICONS, pos*SPSTRIDE, pos*SPSTRIDE+SPSTRIDE-1);
            multiTimer(["OT", "", .1, FALSE]);
        }
		else if(METHOD == StatusMethod$stacksChanged){
			integer pid = (integer)method_arg(0);
            integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
			if(pos == -1)return;
			
			SPELL_ICONS = llListReplaceList(SPELL_ICONS, [(int)method_arg(1),(int)method_arg(2),(int)method_arg(3)], pos*SPSTRIDE+3,pos*SPSTRIDE+5);
            //qd("Refreshing spell icons: "+mkarr(SPELL_ICONS));
			multiTimer(["OT", "", .1, FALSE]);
		}
    }
    
    if(method$byOwner){
		// Sets runtime flags
        if(METHOD == StatusMethod$monster_setFlag){
            STATUS_FLAGS = STATUS_FLAGS|(integer)method_arg(0);
        }
        else if(METHOD == StatusMethod$monster_remFlag){
            STATUS_FLAGS = STATUS_FLAGS&~(integer)method_arg(0);
        }
    }
	
	
    
	// This person has toggled targeting on you
    if(METHOD == StatusMethod$setTargeting){
        integer on = (integer)method_arg(0);
        integer pos = llListFindList(OUTPUT_STATUS_TO, [(str)id]);
        if(!on){
            if(pos == -1)return;
            OUTPUT_STATUS_TO = llDeleteSubList(OUTPUT_STATUS_TO, pos, pos);
        }else{
            if(pos == -1)OUTPUT_STATUS_TO += (str)id;
            outputStats(TRUE);
            outputTextures();
        }
		NPCSpells$setOutputStatusTo(OUTPUT_STATUS_TO);
    }
	
	else if(METHOD == StatusMethod$monster_rapeMe){
		list ray = llCastRay(llGetPos()+<0,0,1>, prPos(id), [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
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
		anim("hit", TRUE);
        if(takehitsound)llTriggerSound(takehitsound, 1);
    }
	// Whenever spell modifiers have changed
    else if(METHOD == StatusMethod$spellModifiers){
        SPELL_DMG_TAKEN_MOD = llJson2List(method_arg(0));
    }
	// Get the description of an effect affecting me
    else if(METHOD == StatusMethod$getTextureDesc){
        if(id == "")id = llGetOwner();
		
		integer pid = (integer)method_arg(0);
        integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
        if(pos == -1)return;
		
		llRegionSayTo(llGetOwnerKey(id), 0, llList2String(SPELL_ICONS, pos*SPSTRIDE+2));
    }
	// Drop aggro from this
    else if(METHOD == StatusMethod$monster_dropAggro)
        dropAggro(method_arg(0), (integer)method_arg(1));
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
	else if(METHOD == StatusMethod$monster_aggroed && ~RUNTIME_FLAGS&Monster$RF_NOAGGRO){
		if(l2i(PARAMS, 2) != TEAM)return;
		
		key p = method_arg(0);
		vector pp = prPos(p);
		float r = (float)method_arg(1);
		if(llVecDist(llGetPos(), pp) > r)return;
		list ray = llCastRay(llGetPos()+<0,0,1>, pp, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
		if(llList2Integer(ray, -1) == 0){
			aggro(p,10);
		}
	}
	else if(METHOD == StatusMethod$setTeam){
		
		setTeam(l2i(PARAMS, 0));
		updateDesc();
		
	}
	
	
	
	
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

