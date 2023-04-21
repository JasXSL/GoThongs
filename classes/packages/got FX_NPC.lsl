#define USE_DB4
#define USE_EVENTS
#define IS_NPC
#define FXConf$useEvtListener
#include "got/_core.lsl" 


float hp = 1;
key aggro;

integer TEAM = TEAM_NPC;
#define evtListener(script, evt, data){ \
    if(script == "got Status"){ \
        if( evt == StatusEvt$flags ) \
			STATUS = l2i(data,0); \
        else if( evt == StatusEvt$monster_hp_perc ) \
			hp = l2f(data,0); \
        else if( evt == StatusEvt$monster_gotTarget ) \
			aggro = l2s(data, 0); \
    } \
}

#define isDead() (STATUS&StatusFlag$dead)
integer checkCondition(key caster, integer cond, list data, integer flags, integer team){

    if( cond == fx$COND_IS_NPC && TEAM == TEAM_PC )
		return FALSE;
    
    if( cond == fx$COND_HAS_STATUS ){
		integer i;
		for(; i < count(data); ++i ){
		
            if( STATUS & l2i(data, i) )
				return TRUE; 
        
		}
        return FALSE;
    }
    
    if(cond == fx$COND_TARGETING_CASTER){
	
        if( llGetOwnerKey(caster) != aggro )
			return FALSE;
        return TRUE;
		
    }
     
    if(cond == fx$COND_HAS_FXFLAGS){
		integer i;
		for(; i < count(data); ++i ){
			if( FX_FLAGS&l2i(data, i) )
				return TRUE;
        }
        return FALSE;
    }

    if( cond == fx$COND_HP_GREATER_THAN && hp <= llList2Float(data, 0) )
        return FALSE;
    
    return TRUE;
}

#include "got/classes/packages/got FX.lsl"
      
