// Extends got FX
#define USE_EVENTS
#define USE_DB4

#include "got/_core.lsl" 

#define IS_INVUL_CHECK() (FX_FLAGS&fx$F_INVUL || STATUS&StatusFlag$invul)



#define FXConf$useEvtListener
#define evtListener(script, evt, data) \
if(script == "got Status" && evt == StatusEvt$flags ){ \
	STATUS = l2i(data, 0); \
}

#define isDead() (STATUS&(StatusFlag$dead|StatusFlag$raped))

integer checkCondition(key caster, integer cond, list data, integer flags, integer team){

	int genitals = (int)db4$fget(hudTable$status, hudTable$status$genitals);
	if(
		(~flags&PF_ALLOW_WHEN_QUICKRAPE && FX_FLAGS&fx$F_QUICKRAPE) ||
		(cond == fx$COND_HAS_GENITALS && ((genitals & llList2Integer(data,0)) != llList2Integer(data,0)))
	){
		return FALSE;
	}

	if( cond == fx$COND_IS_NPC ){
		if( hud$status$team() == TEAM_PC )
			return FALSE;
	}
	
    if(cond == fx$COND_HAS_STATUS){
        list_shift_each(data, val, 
            if(STATUS&(integer)val)return TRUE; 
        )
        return FALSE;
    }
     
    if(cond == fx$COND_HAS_FXFLAGS){
        list_shift_each(data, val, 
            if(FX_FLAGS&(integer)val)return TRUE;
        )
        return FALSE;
    }

	// This only works because fx$COND_*_GREATER_THAN has the same number sequence as hudTable$status$hp/mp/arousal/pain and hudTable$status$max*
	list tables = (list)hudTable$status$hp + hudTable$status$mana + hudTable$status$arousal + hudTable$status$pain;
	list maxTables = (list)hudTable$status$maxHp + hudTable$status$maxMana + hudTable$status$maxArousal + hudTable$status$maxPain;
	int gtStart = fx$COND_HP_GREATER_THAN;
	int gtLen = 4;
	integer i;
	for(; i < gtLen; ++i ){
		integer n = i+gtStart;
		if( cond == n ){
			float perc = (float)db4$fget(hudTable$status, l2s(tables, i))/(float)db4$fget(hudTable$status, l2s(maxTables, i));
			if( perc <= l2f(data, 0) )
				return FALSE;
		}
	}
	
    return TRUE;

}

#include "got/classes/packages/got FX.lsl"
      

