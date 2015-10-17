

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

	
	
	
// LIBRARY

// These are ADD tasks that are shared
#define dumpFxAddsShared() \
	if(t == fx$SET_FLAG) \
        SET_FLAGS = manageList(FALSE, SET_FLAGS, [pid,llList2Integer(fx, 1)]); \
    else if(t == fx$UNSET_FLAG) \
        UNSET_FLAGS = manageList(FALSE, UNSET_FLAGS, [pid,llList2Integer(fx, 1)]); \
	else if(t == fx$DAMAGE_TAKEN_MULTIPLIER) \
        DAMAGE_TAKEN_MULTI = manageList(FALSE, DAMAGE_TAKEN_MULTI, [pid,llList2Float(fx, 1)]);   \
    else if(t == fx$DAMAGE_DONE_MULTIPLIER) \
        DAMAGE_DONE_MULTI = manageList(FALSE, DAMAGE_DONE_MULTI, [pid,llList2Float(fx, 1)]); \
    else if(t == fx$SPELL_DMG_TAKEN_MOD) \
        SPELL_DMG_TAKEN_MOD = manageList(FALSE, SPELL_DMG_TAKEN_MOD, [pid,llList2String(fx,1), llList2Float(fx, 2)]); \
	else if(t == fx$ICON) \
        Status$addTextureDesc(llList2String(fx, 1), llList2String(fx, 2)); \
	else if(t == fx$DODGE) \
        DODGE_MULTI = manageList(FALSE, DODGE_MULTI, [pid,llList2Float(fx, 1)]); \
	else if(t == fx$CASTTIME_MULTIPLIER) \
        CASTTIME_MULTIPLIER = manageList(FALSE, CASTTIME_MULTIPLIER, [pid,llList2Float(fx, 1)]); \
    else if(t == fx$COOLDOWN_MULTIPLIER) \
        COOLDOWN_MULTIPLIER = manageList(FALSE, COOLDOWN_MULTIPLIER, [pid,llList2Float(fx, 1)]); \


// These are REM tasks that are shared
#define dumpFxRemsShared() \
	// Things that shouldn't happen if the effect was overwritten rather than ended \
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
    else if(t == fx$ICON) \
        Status$remTextureDesc(llList2String(fx, 1)); \
    else if(t == fx$DODGE) \
        DODGE_MULTI = manageList(TRUE, DODGE_MULTI, [pid, 0]); \
    else if(t == fx$CASTTIME_MULTIPLIER) \
        CASTTIME_MULTIPLIER = manageList(TRUE, CASTTIME_MULTIPLIER, [pid, 0]); \
    else if(t == fx$COOLDOWN_MULTIPLIER) \
        COOLDOWN_MULTIPLIER = manageList(TRUE, COOLDOWN_MULTIPLIER, [pid, 0]); \
	
	
	
	
	
	