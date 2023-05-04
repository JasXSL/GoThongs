#ifndef _gotFXCompiler
#define _gotFXCompiler


#define FXCOMPILER_HEAD 0
#define FXCOMPILER_RUN 1
#define FXCOMPILER_ADD 2
#define FXCOMPILER_REM 3

#define gotTable$fxCompilerSpellMods$spellDamageTakenMods 0			// Array of [(str)spellName, (int)playerID, (float)dmgmod]
#define gotTable$fxCompilerSpellMods$senderDamageTakenMods 1		// [int charID, float modifier]
#define gotTable$fxCompilerSpellMods$senderHealingTakenMod 2		// [int charID, float modifier]




/*
	These are PASSIVE effects.
	When building active effects sent to got FX, see _lib_fx.lsl in the root folder

*/
#define FXCFlag$STUNNED 1

	
#define FXCEvt$hitFX 1					// (vec)color, (int)flags, (key)attacker
#define FXCEvt$pullStart 2				// void - Pull has started
#define FXCEvt$pullEnd 3				// void - A pull effect has ended
//#define FXCEvt$spellMultipliers 4		// Replaced with LSD (arr)spell_dmg_done_multi, (arr)SPELL_MANACOST_MULTI, (arr)SPELL_CASTTIME_MULTI, (arr)SPELL_COOLDOWN_MULTI - PC only - Contains 3 indexed arrays of floats indexed 0-4 for the spells.

	
	
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
    (percent|(from<<7)|(to<<9)|((flags)<<11)|(multiplier<<14))

#define FXC$conversionPerc(conversion) (conversion&127)
#define FXC$conversionFrom(conversion) ((conversion>>7)&3)
#define FXC$conversionTo(conversion) ((conversion>>9)&3)
#define FXC$conversionDontReduce(conversion) ((conversion>>11)&FXC$CF_DONT_REDUCE)
#define FXC$conversionNonDetrimental(conversion) ((conversion>>11)&FXC$CF_NON_DETRIMENTAL)
#define FXC$conversionInverse(conversion) ((conversion>>11)&FXC$CF_INVERSE)
#define FXC$conversionMultiplier(conversion) (((conversion>>14)&0xF)+1)
	
	
// LIBRARY
#ifndef IS_NPC
	#define spawn Spawner$spawnInt
	#define handleSmartHeal() \
		if( targs&FXAF$SMART_HEAL ){ \
			\
			int cTeam = hud$status$team(); \
			float s = llGetTime(); \
			list targ; float chp = 1; \
			db4$each(gotTable$evtsNpcNear, index, row, \
				key hud = j(row, 1); \
				smartHealDescParse(hud, resources, status, fx, team) \
				if( team == cTeam && !(status&StatusFlags$NON_VIABLE) && !(fx&fx$UNVIABLE) ){ \
					float hp = (float)(resources>>21&127)/127.0; \
					if( (hp <= chp || targ == []) && llVecDist(llGetPos(), prPos(hud)) <= 10 ){ \
						if( hp < chp ) \
							targ = []; \
						targ += hud; \
						chp = hp; \
					} \
				} \
			) \
			key t = randElem(targ); \
			if( t != "" && t != llGetKey() )\
				FX$send(t, llGetKey(), l2s(fx,0), cTeam); \
			if( t == llGetKey() ) \
				FX$run("", l2s(fx,0)); \
		}
#else
	#define spawn Spawner$spawn
	#define handleSmartHeal()
#endif




// These are INSTNAT tasks that are shared
#define dumpFxInstants() \
	if( t == fx$RAND ){ \
		float multi = (float)fx$getDurEffect(fxf$PROC_BEN); \
		if( pflags & PF_DETRIMENTAL )\
			multi = (float)fx$getDurEffect(fxf$PROC_DET); \
        float chance = l2f(fx,0)*multi; \
		if( l2i(fx,1) ) \
			chance*=stacks; \
		if( llFrand(1.0) > chance ) \
			t = -1; \
        else{ \
            fxs = llListInsertList(fxs, llDeleteSubList(fx, 0, 1), i+1); \
			/*Might cause issues. We will see. Need to test.*/ \
		} \
    } \
	if(t == fx$REM_BY_NAME){ \
		string s; \
		if( l2i(fx, 2) ) \
			s = caster; \
        FX$rem(l2i(fx,1), l2s(fx,0), "", s, 0, FALSE, 0,0,0,FALSE); \
	} \
	else if(t == fx$TRIGGER_SOUND){ \
        list sounds = llList2List(fx,0,0); \
        if( llJsonValueType(l2s(fx,0), []) == JSON_ARRAY ) \
			sounds = llJson2List(l2s(fx,0)); \
        if( !l2i(fx,2) ) \
			llTriggerSound(randElem(sounds), llList2Float(fx, 1)); \
		else \
			triggerSoundOn(llGetKey(), randElem(sounds), llList2Float(fx, 1)); \
    } \
	else if(t == fx$FULLREGEN) \
		Status$fullregen(); \
	else if(t == fx$DISPEL){ \
        integer flags = -PF_DETRIMENTAL; \
        if( l2i(fx,0) ) \
			flags = PF_DETRIMENTAL; \
        integer maxnr = llList2Integer(fx, 1); \
		/* raiseEvt, name, tag, sender, pix, runOnRem, flags, count, dispellerUUID */ \
		FX$rem(FALSE, "", "", "", 0, FALSE, flags, maxnr, caster, FALSE); \
    } \
	else if(t == fx$REM){ \
		FX$rem(l2s(fx, 0), l2s(fx, 1), l2s(fx, 2), l2s(fx, 3), l2s(fx, 4), l2s(fx, 5), l2s(fx, 6), l2s(fx, 7), l2s(fx, 8), FALSE); \
	} \
	else if(t == fx$REGION_SAY){ \
		int flags = l2i(fx, 2); \
		str msg = implode((str)stacks, explode(fx$RSConst$stacks,l2s(fx,1))); \
		if( flags&fx$RSFlag$to_owner ) \
			llRegionSayTo(llGetOwner(), l2i(fx, 0), msg); \
		else \
			llRegionSay(l2i(fx,0), msg); \
	} \
	else if( t == fx$ADD_FX ){ \
		int targs = l2i(fx,1); \
		float range = l2f(fx,2); \
		key t = caster; \
		if( t == llGetOwner() || t == llGetKey() ) \
			t = ""; \
		if( !targs || targs&FXAF$SELF || (targs&FXAF$CASTER && t == "") ){ \
			FX$run("", l2s(fx,0)); \
		} \
		if(t != "" && targs&FXAF$CASTER && (range<=0 || llVecDist(llGetRootPosition(), prPos(caster))<=range)){ \
			FX$send(caster, llGetKey(), l2s(fx,0), team); \
		} \
		if(targs&FXAF$AOE){ \
			FX$aoe(range, llGetKey(), l2s(fx,0), team); \
		} \
		handleSmartHeal(); \
	}\
	else if(t == fx$ADD_STACKS){ \
		FX$addStacks(LINK_ROOT, l2i(fx, 0), l2s(fx, 1), l2i(fx, 2), l2s(fx, 3), l2i(fx, 4), l2i(fx, 5), l2i(fx, 6), l2i(fx, 7), l2i(fx, 8), l2f(fx,9), false); \
	} \
	else if(t == fx$SPAWN_MONSTER){ \
			\
		vector rot = llRot2Euler(llGetRot());\
		rotation r = llEuler2Rot(<0,0,rot.z>);\
		list ray = llCastRay(llGetRootPosition(), llGetRootPosition()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);\
		vector pos = llList2Vector(ray, 1);\
		if(pos == ZERO_VECTOR){\
			vector ascale = llGetAgentSize(llGetOwner());\
			pos = llGetRootPosition()-<0,0,ascale.z/2>;\
		}\
		\
		if( l2i(fx, 4) ) \
			Spawner$spawnTarg( \
				caster, \
				l2s(fx, 0),  \
				pos+((vector)l2s(fx, 1)*r),  \
				llEuler2Rot(<0,PI_BY_TWO,0>)*(rotation)l2s(fx,2)*r,  \
				l2s(fx,3),  \
				FALSE,  \
				TRUE,  \
				"" \
			);\
		else \
			spawn( \
				l2s(fx, 0),  \
				pos+((vector)l2s(fx, 1)*r),  \
				llEuler2Rot(<0,PI_BY_TWO,0>)*(rotation)l2s(fx,2)*r,  \
				l2s(fx,3),  \
				FALSE,  \
				TRUE,  \
				"" \
			);\
		\
	}\
	
	
	
#endif
	