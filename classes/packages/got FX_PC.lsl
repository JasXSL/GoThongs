// Extends got FX
#define USE_EVENTS
#define FXConf$useEvtListener
#include "got/_core.lsl" 

#define IS_INVUL_CHECK() (FX_FLAGS&fx$F_INVUL || STATUS&StatusFlag$invul)

integer STATUS;
integer GENITALS;
key _NPC_TARG;

float hp_perc = 1;
float mana_perc = 1;
float arousal_perc = 0;
float pain_perc = 0;

integer TEAM = TEAM_PC;

#define evtListener(script, evt, data) \
if(script == "got Status"){ \
	integer n = llList2Integer(data, 0); \
    if(evt == StatusEvt$flags)STATUS = n; \
    else if(evt == StatusEvt$dead && n)FX$rem(FALSE, "", "", "", 0, FALSE, PF_DETRIMENTAL, 0, 0); \
	else if(evt == StatusEvt$genitals)GENITALS = n; \
	else if(evt == StatusEvt$resources){ \
		hp_perc = llList2Float(data,0)/llList2Float(data,1); \
		mana_perc = llList2Float(data,2)/llList2Float(data,3); \
		arousal_perc = llList2Float(data,4)/llList2Float(data,5); \
		pain_perc = llList2Float(data,6)/llList2Float(data,7); \
	} \
} \
else if(script == "#ROOT"){ \
	if(evt == RootEvt$targ) \
		_NPC_TARG = l2s(data, 0); \
	else if(evt == RootEvt$players) \
		PLAYERS = data; \
}

#define isDead() (STATUS&(StatusFlag$dead|StatusFlag$raped))

integer checkCondition(key caster, integer cond, list data, integer flags, integer team){
	if(
		(~flags&PF_ALLOW_WHEN_QUICKRAPE && FX_FLAGS&fx$F_QUICKRAPE) ||
		(cond == fx$COND_IS_NPC && TEAM == TEAM_PC) ||
		(cond == fx$COND_HAS_GENITALS && ((GENITALS & llList2Integer(data,0)) != llList2Integer(data,0)))
	){
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
    
	if(cond == fx$COND_CASTER_IS_BEHIND){
		prAngX(caster, ang);
		return (llFabs(ang)<PI_BY_TWO  && ~FX_FLAGS&fx$F_ALWAYS_BACKSTAB);
	}

    list greaterCheck = [fx$COND_HP_GREATER_THAN, fx$COND_MANA_GREATER_THAN, fx$COND_AROUSAL_GREATER_THAN, fx$COND_PAIN_GREATER_THAN];
    integer pos;
    if(~(pos=llListFindList(greaterCheck, [cond]))){
        list shares = [hp_perc, mana_perc, arousal_perc, pain_perc];

		if(llList2Float(shares, pos)<=l2f(data,0))
			return FALSE;
    }
    return TRUE;
}

#include "got/classes/packages/got FX.lsl"
      

