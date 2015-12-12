

#define FXCFlag$STUNNED 1

#define FXCEvt$update 1					// Array of below values
	#define FXCUpd$FLAGS 0
	#define FXCUpd$MANA_REGEN 1
	#define FXCUpd$DAMAGE_DONE 2
	#define FXCUpd$DAMAGE_TAKEN 3
	#define FXCUpd$DODGE 4
	#define FXCUpd$CASTTIME 5
	#define FXCUpd$COOLDOWN 6
	#define FXCUpd$MANACOST 7
	#define FXCUpd$CRIT 8
#define FXCEvt$pullStart 2				// void - Pull has started
#define FXCEvt$pullEnd 3				// void - A pull effect has ended
	
	
	
// LIBRARY

// These are INSTNAT tasks that are shared
#define dumpFxInstants() \
	if(t == fx$RAND){ \
        float chance = (float)v; \
        if(llList2Integer(fx,2))chance*=stacks; \
        if(llFrand(1)>chance)t = -1; \
        else{ \
            fxs = llDeleteSubList(fx, 0, 2)+fxs; \
		} \
    } \
	else if(t == fx$DEBUG){ \
        qd("Debug FX: "+llList2String(fx,1)); \
	} \
	else if(t == fx$REM_BY_NAME) \
        FX$rem(llList2Integer(fx,2), v, "", "", 0, FALSE, 0,0,0); \
	else if(t == fx$TRIGGER_SOUND){ \
        list sounds = [v]; \
        if(llJsonValueType(v, []) == JSON_ARRAY)sounds = llJson2List(v); \
        llTriggerSound(randElem(sounds), llList2Float(fx, 2)); \
    } \
	else if(t == fx$FULLREGEN)Status$fullregen(); \
	else if(t == fx$DISPEL){ \
        integer detrimental = (integer)v; \
        if(detrimental)detrimental = PF_DETRIMENTAL; \
        integer maxnr = llList2Integer(fx, 2); \
		FX$rem(FALSE, "", "", "", 0, FALSE, detrimental, TRUE, maxnr); \
    } \
	else if(t == fx$REM){ \
		FX$rem(llList2String(fx, 1), llList2String(fx, 2), llList2String(fx, 3), llList2String(fx, 4), llList2String(fx, 5), llList2String(fx, 6), llList2String(fx, 7), llList2String(fx, 8), llList2String(fx, 9)); \
	} \
	else if(t == fx$REGION_SAY){ \
		llRegionSay((integer)v, llList2String(fx,2)); \
	} \
		

// These are ADD tasks that are shared
#define dumpFxAddsShared() \
	if(t == fx$SET_FLAG){ \
        SET_FLAGS = manageList(FALSE, SET_FLAGS, [pid,llList2Integer(fx, 1)]); \
	} \
    else if(t == fx$UNSET_FLAG) \
        UNSET_FLAGS = manageList(FALSE, UNSET_FLAGS, [pid,llList2Integer(fx, 1)]); \
	else if(t == fx$DAMAGE_TAKEN_MULTIPLIER) \
        DAMAGE_TAKEN_MULTI = manageList(FALSE, DAMAGE_TAKEN_MULTI, [pid,llList2Float(fx, 1)]);   \
    else if(t == fx$DAMAGE_DONE_MULTIPLIER) \
        DAMAGE_DONE_MULTI = manageList(FALSE, DAMAGE_DONE_MULTI, [pid,llList2Float(fx, 1)]); \
    else if(t == fx$SPELL_DMG_TAKEN_MOD) \
        SPELL_DMG_TAKEN_MOD = manageList(FALSE, SPELL_DMG_TAKEN_MOD, [pid,llList2String(fx,1), llList2Float(fx, 2)]); \
	else if(t == fx$ICON){ \
        Status$addTextureDesc(llList2String(fx, 1), llList2String(fx, 2)); \
	}else if(t == fx$DODGE) \
        DODGE_MULTI = manageList(FALSE, DODGE_MULTI, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$CASTTIME_MULTIPLIER) \
        CASTTIME_MULTIPLIER = manageList(FALSE, CASTTIME_MULTIPLIER, [pid,llList2Float(fx, 1)]); \
    else if(t == fx$COOLDOWN_MULTIPLIER) \
        COOLDOWN_MULTIPLIER = manageList(FALSE, COOLDOWN_MULTIPLIER, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$CRIT_MULTIPLIER)\
		CRIT_MULTIPLIER = manageList(FALSE, CRIT_MULTIPLIER, [pid,llList2Float(fx, 1)]); \
	

// These are REM tasks that are shared
#define dumpFxRemsShared() \
	if(t == fx$SET_FLAG) \
        SET_FLAGS = manageList(TRUE, SET_FLAGS, [pid, 0]); \
    else if(t == fx$UNSET_FLAG) \
        UNSET_FLAGS = manageList(TRUE, UNSET_FLAGS, [pid, 0]); \
    else if(t == fx$DAMAGE_TAKEN_MULTIPLIER) \
        DAMAGE_TAKEN_MULTI = manageList(TRUE, DAMAGE_TAKEN_MULTI, [pid, 0]); \
    else if(t == fx$DAMAGE_DONE_MULTIPLIER) \
        DAMAGE_DONE_MULTI = manageList(TRUE, DAMAGE_DONE_MULTI, [pid, 0]); \
    else if(t == fx$SPELL_DMG_TAKEN_MOD) \
        SET_FLAGS = manageList(TRUE, SET_FLAGS, [pid, 0, 0]); \
    else if(t == fx$ICON){ \
        Status$remTextureDesc(llList2String(fx, 1)); \
	}\
    else if(t == fx$DODGE) \
        DODGE_MULTI = manageList(TRUE, DODGE_MULTI, [pid, 0]); \
    else if(t == fx$CASTTIME_MULTIPLIER) \
        CASTTIME_MULTIPLIER = manageList(TRUE, CASTTIME_MULTIPLIER, [pid, 0]); \
    else if(t == fx$COOLDOWN_MULTIPLIER) \
        COOLDOWN_MULTIPLIER = manageList(TRUE, COOLDOWN_MULTIPLIER, [pid, 0]); \
	else if(t == fx$CRIT_MULTIPLIER)\
		CRIT_MULTIPLIER = manageList(TRUE, CRIT_MULTIPLIER, [pid,0]); \
	
	
	
	
	