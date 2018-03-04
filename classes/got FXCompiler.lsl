

#define FXCFlag$STUNNED 1

// When you add something here, make sure you also set it as a default in got Passives global var: list compiled_actives;
// Multipliers should actually be additive when setting them through passives. so .1 is 1.1x
//#define FXCEvt$update 1				// See _core TASK_FX - It has replaced this but still uses the same index
	#define FXCUpd$ATTACH -3			// (arr)attachments - 
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
	
	#define FXCUpd$PAIN_MULTI 9			// (float)multiplier - Default 1 - Pain taken
	#define FXCUpd$AROUSAL_MULTI 10		// (float)multiplier - Default 1 - Arousal taken
	
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
	#define FXCUpd$CONVERSION 28		// (arr)conversions - Converts damage types into another. See below
	#define FXCUpd$SPRINT_FADE_MULTI 29	// (float)multiplier - Lower = longer sprint
	#define FXCUpd$BACKSTAB_MULTI 30	// (float)multiplier - Increases or lowers damage from behind
	#define FXCUpd$SWIM_SPEED_MULTI 31	// (float)multiplier - Default 1
	
// Settings that are are not multiplicative
#define FXCUpd$non_multi [FXCUpd$FLAGS, FXCUpd$UNSET_FLAGS, FXCUpd$DODGE, FXCUpd$CRIT, FXCUpd$HP_ADD, FXCUpd$MANA_ADD, FXCUpd$AROUSAL_ADD, FXCUpd$PAIN_ADD, FXCUpd$TEAM]
// Settings that are arrays that should be appended
#define FXCUpd$arrays [FXCUpd$CONVERSION]

#define FXCEvt$hitFX 1					// (vec)color, (int)flags, (key)attacker
#define FXCEvt$pullStart 2				// void - Pull has started
#define FXCEvt$pullEnd 3				// void - A pull effect has ended
#define FXCEvt$spellMultipliers 4		// (arr)spell_dmg_done_multi, (arr)SPELL_MANACOST_MULTI, (arr)SPELL_CASTTIME_MULTI, (arr)SPELL_COOLDOWN_MULTI - PC only - Contains 3 indexed arrays of floats indexed 0-4 for the spells.

	
	
// Conversion:
// Bits:
    // 0000000 (7) (int)percent_conversion, 1-100
	// 00(8-9) (int)from - 00 = hp, 01 = mana, 10 = arousal, 11 = pain
	// 00(10-11) (int)to - == || ==
	// 0(12) (bool)dont_reduce - Do not reduce incoming damage, but still apply conversion
	// 0(13) (bool)non_detrimental - Makes conversion trigger from gaining HP/Mana or losing pain/arousal
	// 0(14) (bool)inverse - Makes conversion subtract instead of add
	// 0(15-20) (int)multiplier - Multiplies percentage against this value minus 1. 0 = 1x, 1=2x. Max is 15 which is 16x
	
#define FXC$CONVERSION_HP 0
#define FXC$CONVERSION_MANA 1
#define FXC$CONVERSION_AROUSAL 2
#define FXC$CONVERSION_PAIN 3

#define FXC$CF_DONT_REDUCE 0x1       // Do not reduce incoming damage, but still apply conversion
#define FXC$CF_NON_DETRIMENTAL 0x2   // Makes conversion trigger from gaining HP/Mana or losing pain/arousal
#define FXC$CF_INVERSE 0x4           // Makes conversion subtract instead of add

// Builds conversion: FXC$buildConversion(20,FX$CONVERSION_HP,FX$CONVERSION_MANA, FX$CF_DONT_REDUCE)
#define FXC$buildConversion(percent, from, to, flags, multiplier) \
    (percent|(from<<7)|(to<<9)|(flags<<11)|(multiplier<<14))

#define FXC$conversionPerc(conversion) (conversion&127)
#define FXC$conversionFrom(conversion) ((conversion>>7)&3)
#define FXC$conversionTo(conversion) ((conversion>>9)&3)
#define FXC$conversionDontReduce(conversion) ((conversion>>11)&FXC$CF_DONT_REDUCE)
#define FXC$conversionNonDetrimental(conversion) ((conversion>>11)&FXC$CF_NON_DETRIMENTAL)
#define FXC$conversionInverse(conversion) ((conversion>>11)&FXC$CF_INVERSE)
#define FXC$conversionMultiplier(conversion) (((conversion>>14)&0xF)+1)
	
	
// LIBRARY



// These are INSTNAT tasks that are shared
#define dumpFxInstants() \
	if(t == fx$RAND){ \
        float chance = l2f(fx,1); \
        if(llList2Integer(fx,2))chance*=stacks; \
        if(llFrand(1)>chance)t = -1; \
        else{ \
            fxs = llDeleteSubList(fx, 0, 2)+fxs; \
		} \
    } \
	else if(t == fx$REM_BY_NAME){ \
		string s; \
		if( l2i(fx, 3) ) \
			s = caster; \
        FX$rem(llList2Integer(fx,2), l2s(fx,1), "", s, 0, FALSE, 0,0,0); \
	} \
	else if(t == fx$TRIGGER_SOUND){ \
        list sounds = [l2s(fx,1)]; \
        if(llJsonValueType(l2s(fx,1), []) == JSON_ARRAY)sounds = llJson2List(l2s(fx,1)); \
        if(!l2i(fx,3))llTriggerSound(randElem(sounds), llList2Float(fx, 2)); \
		else triggerSoundOn(llGetKey(), randElem(sounds), llList2Float(fx, 2)); \
    } \
	else if(t == fx$FULLREGEN)Status$fullregen(); \
	else if(t == fx$DISPEL){ \
        integer flags = -PF_DETRIMENTAL; \
        if(l2i(fx,1))flags = PF_DETRIMENTAL; \
        integer maxnr = llList2Integer(fx, 2); \
		FX$rem(FALSE, "", "", "", 0, FALSE, flags, TRUE, maxnr); \
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
		if(!targs || targs&FXAF$SELF || (targs&FXAF$CASTER && t == "")){ \
			FX$run("", l2s(fx,1)); \
		} \
		if(t != "" && targs&FXAF$CASTER && (range<=0 || llVecDist(llGetPos(), prPos(caster))<=range)){ \
			FX$send(caster, llGetKey(), l2s(fx,1), TEAM); \
		} \
		if(targs&FXAF$AOE){ \
			FX$aoe(range, llGetKey(), l2s(fx,1), TEAM); \
		} \
	}\
	else if(t == fx$ADD_STACKS){ \
		FX$addStacks(LINK_ROOT, llList2Integer(fx, 1), llList2String(fx, 2), llList2Integer(fx, 3), llList2String(fx, 4), llList2Integer(fx, 5), llList2Integer(fx, 6), llList2Integer(fx, 7), llList2Integer(fx, 8), llList2Integer(fx, 9)); \
	} \

	
// Texture desc, npc/pc specific
#ifdef IS_NPC
	#define ATD Status$addTextureDesc(pid, llList2String(fx, 0), llList2String(fx, 1), timesnap, (int)(duration*10), getStacks(pid, TRUE));
	#define RTD Status$remTextureDesc(pid);
#else
	#define ATD Evts$addTextureDesc(pid, llList2String(fx, 0), llList2String(fx, 1), timesnap, (int)(duration*10), getStacks(pid, TRUE));
	#define RTD Evts$remTextureDesc(pid);
#endif




// These are ADD tasks that are shared
#define dumpFxAddsShared() \
	if(t == fx$SET_FLAG){ \
		addDFX( pid, t, fx ); \
		recacheFlags(); \
		jump fxContinue; \
	} \
    else if(t == fx$UNSET_FLAG){ \
        addDFX( pid, t, fx ); \
		recacheFlags(); \
		jump fxContinue; \
	} \
	else if(t == fx$ICON){ \
		ATD \
		jump fxContinue; \
	} \
	else if( t == fx$SPELL_DMG_TAKEN_MOD && l2i(fx, 2) ) \
		fx = llListReplaceList(fx, (list)key2int(caster), 2, 2); \
	else if( l2i(fx, 1) && (t == fx$DAMAGE_TAKEN_MULTI || t == fx$HEALING_TAKEN_MULTI || t == fx$DAMAGE_DONE_MULTI ) ) \
		fx = llListReplaceList(fx, (list)key2int(caster), 1, 1);
	
	
// These are REM tasks that are shared
#define dumpFxRemsShared() \
	if(t == fx$SET_FLAG) \
		recacheFlags(); \
    else if(t == fx$UNSET_FLAG) \
		recacheFlags(); \
    else if(t == fx$ICON){ \
        RTD \
	}\

	
	