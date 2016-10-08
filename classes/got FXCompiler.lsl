

#define FXCFlag$STUNNED 1

// When you add something here, make sure you also set it as a default in got Passives global var: list compiled_actives;
// Multipliers should actually be additive when setting them through passives. so .1 is 1.1x
//#define FXCEvt$update 1				// See _core TASK_FX - It has replaced this but still uses the same index
	#define FXCUpd$ATTACH -3			// (arr)attachments
	#define FXCUpd$PROC -2				// Special case used in got Passives, See the got Passives.lsl function buildProc() for data
	#define FXCUpd$UNSET_FLAGS -1		// Special case only used when setting got Passives 
	#define FXCUpd$FLAGS 0 				// (int)flags - Default 0
	#define FXCUpd$MANA_REGEN 1			// (float)multiplier - Default 1
	#define FXCUpd$DAMAGE_DONE 2		// (float)multiplier - Default 1
	#define FXCUpd$DAMAGE_TAKEN 3		// (float)multiplier - Default 1
	#define FXCUpd$DODGE 4				// (float)add - Default 0
	#define FXCUpd$CASTTIME 5			// (float)multiplier - Default 1
	#define FXCUpd$COOLDOWN 6			// (float)multiplier - Default 1
	#define FXCUpd$MANACOST 7			// (float)multiplier - Default 1
	#define FXCUpd$CRIT 8				// (float)add - Default 0
	
	#define FXCUpd$PAIN_MULTI 9			// (float)multiplier - Default 1
	#define FXCUpd$AROUSAL_MULTI 10		// (float)multiplier - Default 1
	
	// Mainly passives, multipliers are actually ADDitive so 0.1 would mean multiply by 1.1
	#define FXCUpd$HP_ADD 11			// (int)hp - Default 0
	#define FXCUpd$HP_MULTIPLIER 12		// (float)multiplier - Default 1
	#define FXCUpd$MANA_ADD 13			// (int)mana - Default 0
	#define FXCUpd$MANA_MULTIPLIER 14	// (float)multiplier - Default 1
	#define FXCUpd$AROUSAL_ADD 15		// (int)arousal - Default 0
	#define FXCUpd$AROUSAL_MULTIPLIER 16// (float)multiplier - Default 1
	#define FXCUpd$PAIN_ADD 17			// (int)pain - Default 0
	#define FXCUpd$PAIN_MULTIPLIER 18	// (float)multiplier - Default 1
	#define FXCUpd$HP_REGEN 19			// (float)multiplier - Default 1 
	#define FXCUpd$PAIN_REGEN 20		// (float)multiplier - Default 1
	#define FXCUpd$AROUSAL_REGEN 21		// (float)multiplier - Default 1
	#define FXCUpd$SPELL_HIGHLIGHTS 22	// (int)bitwise - A bitwise combination of 0x1 = rest, 0x2 abil1... to highlight
	
	#define FXCUpd$HEAL_MOD 23			// (float)multiplier - Default 1 
	#define FXCUpd$MOVESPEED 24			// (NPC)(float)multiplier - Default 1
	#define FXCUpd$HEAL_DONE_MOD 25		// (PC)
	#define FXCUpd$TEAM 26				// (int)team
	#define FXCUpd$BEFUDDLE 27			// (float)multiplier
	
// Settings that are are not multiplicative
#define FXCUpd$non_multi [FXCUpd$FLAGS, FXCUpd$UNSET_FLAGS, FXCUpd$DODGE, FXCUpd$CRIT, FXCUpd$HP_ADD, FXCUpd$MANA_ADD, FXCUpd$AROUSAL_ADD, FXCUpd$PAIN_ADD, FXCUpd$TEAM]
	
#define FXCEvt$pullStart 2				// void - Pull has started
#define FXCEvt$pullEnd 3				// void - A pull effect has ended
#define FXCEvt$spellMultipliers 4		// (arr)spell_dmg_done_multi, (arr)SPELL_MANACOST_MULTI, (arr)SPELL_CASTTIME_MULTI, (arr)SPELL_COOLDOWN_MULTI - PC only - Contains 3 indexed arrays of floats indexed 0-4 for the spells.

	
	
// LIBRARY
recacheFlags(){
	integer pre = CACHE_FLAGS;
	integer i; CACHE_FLAGS = 0;
    for(i=0; i<llGetListLength(SET_FLAGS); i+=2)CACHE_FLAGS = CACHE_FLAGS|llList2Integer(SET_FLAGS,i+1);
    for(i=0; i<llGetListLength(UNSET_FLAGS); i+=2)CACHE_FLAGS = CACHE_FLAGS&~llList2Integer(UNSET_FLAGS,i+1);
	#ifndef IS_NPC
	if(~pre&fx$F_NO_PULL && CACHE_FLAGS&fx$F_NO_PULL)llStopMoveToTarget();
	#endif
}


// These are INSTNAT tasks that are shared
#define dumpFxInstants() \
	if(t == fx$RAND){ \
        float chance = l2f(fx,1); \
        if(llList2Integer(fx,2))chance*=stacks; \
        if(llFrand(1)>chance)t = -1; \
        else{ \
            fxs = llDeleteSubList(fx, 0, 2)+fxs; \
		} \
    }else if(t == fx$DEBUG){ \
        qd("Debug FX: "+llList2String(fx,1)); \
	} \
	else if(t == fx$REM_BY_NAME){ \
        FX$rem(llList2Integer(fx,2), l2s(fx,1), "", "", 0, FALSE, 0,0,0); \
	} \
	else if(t == fx$TRIGGER_SOUND){ \
        list sounds = [l2s(fx,1)]; \
        if(llJsonValueType(l2s(fx,1), []) == JSON_ARRAY)sounds = llJson2List(l2s(fx,1)); \
        llTriggerSound(randElem(sounds), llList2Float(fx, 2)); \
    } \
	else if(t == fx$FULLREGEN)Status$fullregen(); \
	else if(t == fx$DISPEL){ \
        integer detrimental = l2i(fx,1); \
        if(detrimental)detrimental = PF_DETRIMENTAL; \
        integer maxnr = llList2Integer(fx, 2); \
		FX$rem(FALSE, "", "", "", 0, FALSE, detrimental, TRUE, maxnr); \
    } \
	else if(t == fx$REM){ \
		FX$rem(llList2String(fx, 1), llList2String(fx, 2), llList2String(fx, 3), llList2String(fx, 4), llList2String(fx, 5), llList2String(fx, 6), llList2String(fx, 7), llList2String(fx, 8), llList2String(fx, 9)); \
	} \
	else if(t == fx$REGION_SAY){ \
		llRegionSay(l2i(fx,1), llList2String(fx,2)); \
	} \
	else if(t == fx$ADD_FX){ \
		int targs = l2i(fx,2); \
		float range = l2f(fx,3); \
		key t = caster; \
		if(t == llGetOwner() || t == llGetKey()){t = "";} \
		if(!targs || targs&FXAF$SELF || (targs&FXAF$CASTER && t == "")){FX$run("", l2s(fx,1));} \
		if(t != "" && targs&FXAF$CASTER && (range<=0 || llVecDist(llGetPos(), prPos(caster))<=range)){ \
			FX$send(caster, llGetKey(), l2s(fx,1), TEAM); \
		} \
		if(targs&FXAF$AOE){FX$aoe(range, llGetKey(), l2s(fx,1), TEAM);} \
	}\
	else if(t == fx$ADD_STACKS){ \
		FX$addStacks(LINK_ROOT, llList2Integer(fx, 1), llList2String(fx, 2), llList2Integer(fx, 3), llList2String(fx, 4), llList2Integer(fx, 5), llList2Integer(fx, 6), llList2Integer(fx, 7), llList2Integer(fx, 8), llList2Integer(fx, 9)); \
	} \


// These are ADD tasks that are shared
#define dumpFxAddsShared() \
	if(t == fx$SET_FLAG){ \
        SET_FLAGS = manageList(FALSE, SET_FLAGS, [pid,llList2Integer(fx, 1)]); \
		recacheFlags(); \
	} \
    else if(t == fx$UNSET_FLAG){ \
        UNSET_FLAGS = manageList(FALSE, UNSET_FLAGS, [pid,llList2Integer(fx, 1)]); \
		recacheFlags(); \
	} \
	else if(t == fx$DAMAGE_TAKEN_MULTI) \
        DAMAGE_TAKEN_MULTI = manageList(FALSE, DAMAGE_TAKEN_MULTI, [pid,llList2Float(fx, 1)]);   \
    else if(t == fx$DAMAGE_DONE_MULTI) \
        DAMAGE_DONE_MULTI = manageList(FALSE, DAMAGE_DONE_MULTI, [pid,llList2Float(fx, 1)]); \
    else if(t == fx$SPELL_DMG_TAKEN_MOD) \
        SPELL_DMG_TAKEN_MOD = manageList(FALSE, SPELL_DMG_TAKEN_MOD, [pid,llList2String(fx,1), llList2Float(fx, 2)]); \
	else if(t == fx$ICON){ \
        Status$addTextureDesc(pid, llList2String(fx, 1), llList2String(fx, 2), timesnap, (int)(duration*10), getStacks(pid, TRUE)); \
	}else if(t == fx$DODGE) \
        DODGE_ADD = manageList(FALSE, DODGE_ADD, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$CASTTIME_MULTI){ \
        CASTTIME_MULTI = manageList(FALSE, CASTTIME_MULTI, [pid,llList2Float(fx, 1)]); \
	} \
    else if(t == fx$COOLDOWN_MULTI) \
        COOLDOWN_MULTI = manageList(FALSE, COOLDOWN_MULTI, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$CRIT_ADD)\
		CRIT_ADD = manageList(FALSE, CRIT_ADD, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$HEALING_TAKEN_MULTI)\
		HEAL_MOD = manageList(FALSE, HEAL_MOD, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$SET_TEAM)\
		TEAM_MOD = manageList(FALSE, HEAL_MOD, [pid,l2i(fx, 1)]); \
	
	
// These are REM tasks that are shared
#define dumpFxRemsShared() \
	if(t == fx$SET_FLAG){ \
        SET_FLAGS = manageList(TRUE, SET_FLAGS, [pid, 0]); \
		recacheFlags(); \
	}\
    else if(t == fx$UNSET_FLAG){ \
        UNSET_FLAGS = manageList(TRUE, UNSET_FLAGS, [pid, 0]); \
		recacheFlags(); \
	}\
    else if(t == fx$DAMAGE_TAKEN_MULTI) \
        DAMAGE_TAKEN_MULTI = manageList(TRUE, DAMAGE_TAKEN_MULTI, [pid, 0]); \
    else if(t == fx$DAMAGE_DONE_MULTI) \
        DAMAGE_DONE_MULTI = manageList(TRUE, DAMAGE_DONE_MULTI, [pid, 0]); \
    else if(t == fx$SPELL_DMG_TAKEN_MOD) \
        SPELL_DMG_TAKEN_MOD = manageList(TRUE, SPELL_DMG_TAKEN_MOD, [pid, 0, 0]); \
    else if(t == fx$ICON){ \
        Status$remTextureDesc(pid); \
	}\
    else if(t == fx$DODGE) \
        DODGE_ADD = manageList(TRUE, DODGE_ADD, [pid, 0]); \
    else if(t == fx$CASTTIME_MULTI) \
        CASTTIME_MULTI = manageList(TRUE, CASTTIME_MULTI, [pid, 0]); \
    else if(t == fx$COOLDOWN_MULTI) \
        COOLDOWN_MULTI = manageList(TRUE, COOLDOWN_MULTI, [pid, 0]); \
	else if(t == fx$CRIT_ADD)\
		CRIT_ADD = manageList(TRUE, CRIT_ADD, [pid,0]); \
	else if(t == fx$HEALING_TAKEN_MULTI)\
		HEAL_MOD = manageList(TRUE, HEAL_MOD, [pid,0]); \
	else if(t == fx$SET_TEAM)\
		TEAM_MOD = manageList(TRUE, TEAM_MOD, [pid,0]); \

	
	