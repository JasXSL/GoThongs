// Extends got FX
#define USE_EVENTS
#define USE_SHARED ["got Status"]
#define FXConf$useEvtListener
#include "got/_core.lsl" 


integer STATUS;
integer FX_FLAGS;
key _NPC_TARG;

// Against is data from the package, data is data from the event
integer evtCheck(string script, integer evt, string data, string against){
    if(script == ""){
        if(evt == INTEVENT_SPELL_ADDED)
            if(data != jVal(against, [0]))return FALSE;
    }
    
    return TRUE;
}

evtListener(string script, integer evt, string data){
    if(script == "got FXCompiler" && evt == FXCEvt$update)FX_FLAGS = (integer)jVal(data, [0]);
    else if(script == "got Status"){
        if(evt == StatusEvt$flags)STATUS = (integer)data;
        else if(evt == StatusEvt$dead && (integer)data)FX$rem(FALSE, "", "", "", 0, FALSE, PF_DETRIMENTAL, 0, 0);
    }
    else if(script == "#ROOT" && evt == RootEvt$targ)
        _NPC_TARG = j(data, 0);
}

#define isDead() (STATUS&(StatusFlag$dead|StatusFlag$raped))
integer checkCondition(key caster, integer cond, list data, integer flags){
    if(~flags&PF_ALLOW_WHEN_QUICKRAPE && FX_FLAGS&fx$F_QUICKRAPE)return FALSE;

    if(cond == fx$COND_IS_NPC)return FALSE;
    
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
    
    list greaterCheck = [fx$COND_HP_GREATER_THAN, fx$COND_MANA_GREATER_THAN, fx$COND_AROUSAL_GREATER_THAN, fx$COND_PAIN_GREATER_THAN];
    integer pos;
    if(~(pos=llListFindList(greaterCheck, [cond]))){
        list shares = [StatusShared$dur, StatusShared$mana, StatusShared$arousal, StatusShared$pain];
        string dta = db2$get("got Status", [llList2String(shares, pos)]);
        if((float)jVal(dta, [1])<=0)return FALSE;
        if((float)jVal(dta, [0])/(float)jVal(dta, [1])<=llList2Float(data, 0))return FALSE;
    }
    return TRUE;
}

#include "got/classes/packages/got FX.lsl"
      

