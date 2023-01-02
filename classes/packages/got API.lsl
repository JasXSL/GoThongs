#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

integer chan;
list bindings;			// (key)targ, (int)chan
list PASSIVES;

float adtmod = 1.0;		// Global active damage taken mod
float addmod = 1.0;		// Global active damage done mod
onEvt(string script, integer evt, list data){

	if( bindings ){
		
		// Pregenerate the message
		string msg = GotAPI$buildAction(GotAPI$actionEvt, ([
			script, evt, mkarr(data)
		]));
		
		integer i;
		for( ; i < count(bindings); i += 2 )
			llRegionSayTo(llList2Key(bindings, i), llList2Integer(bindings, i+1), msg);
			
	}

}

outputBindStatus(key id, integer bound){
	integer evt = GotAPIEvt$bound;
	if(!bound)
		evt = GotAPIEvt$unbound;
		
	string msg = GotAPI$buildAction(GotAPI$actionEvt, ([
		llGetScriptName(), evt
	]));
	llRegionSayTo(id, GotAPI$chan(llGetOwnerKey(id)), msg);
}

timerEvent(string id, string data){
	
	// Make sure the asset remains within the region
	if(id == "P"){
		integer i;
		for(i=0; i<count(bindings) && bindings != []; i+=2){
			if(llKey2Name(l2k(bindings, i)) == ""){
				bindings = llDeleteSubList(bindings, i, i+1);
				i-=2;
			}
		}
		
	}
	
}
default{

    state_entry(){
	
		PLAYERS = [(str)llGetOwner()];
		chan = GotAPI$chan(llGetOwner());
		llListen(chan, "", "", "");
		llRegionSay(chan, GotAPI$buildAction(GotAPI$actionIni, []));
		multiTimer(["P", "", 10, TRUE]);
    }
	
	timer(){multiTimer([]);}
	
	listen(integer chan, string name, key id, string message){

		if(!startsWith(message, "GA|"))
			return;
			
		if( llListFindList(PLAYERS, [(str)llGetOwnerKey(id)]) == -1 )
			return;
			
		list data = llJson2List(llGetSubString(message, 3, -1));
		integer command = llList2Integer(data, 0);
		data = llDeleteSubList(data, 0, 0);
		
		if( command == GotAPI$cmdBind || command == GotAPI$cmdUnbind ){
		
			key targ = id;
			if(llList2Key(data, 0))targ = llList2Key(data, 0);
			integer pos = llListFindList(bindings, [targ]);
			

			if( command == GotAPI$cmdBind && ~pos )
				return outputBindStatus(targ, TRUE);
			if( command == GotAPI$cmdUnbind && pos == -1 )
				return outputBindStatus(targ, FALSE);
				
			// Bind
			if( command == GotAPI$cmdBind ){
				
				bindings+= [targ, GotAPI$chan(llGetOwnerKey(targ))];
				outputBindStatus(targ, TRUE);
				
			}
			// Unbind
			else{
				
				bindings = llDeleteSubList(bindings, pos, pos+1);
				outputBindStatus(targ, FALSE);
				
			}
			
			
		}
		
		else if( command == GotAPI$cmdEmulateEvent && llGetOwnerKey(id) == llGetOwner() )
			onEvt( l2s(data, 0), l2i(data, 1), llJson2List(l2s(data, 2)) );

	}
	
	
	#define LM_PRE \
		if( nr == TASK_FX ) \
			PASSIVES = llJson2List(s); \
		else if( nr ==  TASK_SPELL_MODS ){ \
			list l = llJson2List(j(s, 1)); /* Spell damage done mod */ \
			int pos = llListFindList(l, (list)0); \
			adtmod = 1;\
			if( ~pos )\
				adtmod = l2f(l, pos+1);\
		} \
		else if( nr == TASK_OFFENSIVE_MODS ){ \
			list l = llJson2List(j(s, 0)); \
			int pos = llListFindList(l, (list)0); \
			addmod = 1;\
			if( ~pos )\
				addmod = l2f(l, pos+1);\
		}
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    if( METHOD == GotAPIMethod$getStats ){
		
		list descs = fx$FLAG_DESCS;
		list descsOut;
		
		// Dumps all passive stats
		llOwnerSay("    :: MODIFIERS ::");
		int f = l2i(PASSIVES, 0);
		integer i;
		for( ; i<32; ++i ){
			if( f&(1<<i) )
				descsOut += l2s(descs, i);
		}
		llOwnerSay("FLAGS > "+llList2CSV(descsOut));
		descs = descsOut = [];
		
		llOwnerSay("RESOURCE MODIFIERS > "+
			l2s(PASSIVES, FXCUpd$HP_MULTIPLIER)+"% +"+l2s(PASSIVES, FXCUpd$HP_ADD)+" HP | "+
			l2s(PASSIVES, FXCUpd$MANA_MULTIPLIER)+"% +"+l2s(PASSIVES, FXCUpd$MANA_ADD)+" MP | "+
			l2s(PASSIVES, FXCUpd$PAIN_MULTIPLIER)+"% +"+l2s(PASSIVES, FXCUpd$PAIN_ADD)+" Pain | "+
			l2s(PASSIVES, FXCUpd$AROUSAL_MULTIPLIER)+"% +"+l2s(PASSIVES, FXCUpd$AROUSAL_ADD)+" Arousal"
			
		);
		
		
		llOwnerSay(
			"POWER> "+
			(str)llRound(l2i(PASSIVES, FXCUpd$DAMAGE_DONE)*addmod)+"% Damage & Healing done | "+
			l2s(PASSIVES, FXCUpd$HEAL_DONE_MOD)+"% Bonus healing | "+
			l2s(PASSIVES, FXCUpd$CRIT)+"% Crit chance | "+
			l2s(PASSIVES, FXCUpd$BACKSTAB_MULTI)+"% Damage done from  behind"
		);
		
		
		llOwnerSay(
			"REGEN > "+
			l2s(PASSIVES, FXCUpd$HP_REGEN)+"% HP | "+
			l2s(PASSIVES, FXCUpd$MANA_REGEN)+"% MP | "+
			l2s(PASSIVES, FXCUpd$PAIN_REGEN)+"% Pain | "+
			l2s(PASSIVES, FXCUpd$AROUSAL_REGEN)+"% Arousal | "+
			(str)(l2i(PASSIVES, FXCUpd$COMBAT_HP_REGEN)-100)+"% Combat HP Regen"
		);
		
		
		llOwnerSay("DEFENSES > "+
			(str)(100-l2i(PASSIVES, FXCUpd$DODGE))+"% Dodge | "+	// Dodge is inverse
			(str)llRound(l2i(PASSIVES, FXCUpd$DAMAGE_TAKEN)*adtmod)+"% Damage Taken | "+
			l2s(PASSIVES, FXCUpd$HEAL_MOD)+"% Healing received | "+
			l2s(PASSIVES, FXCUpd$HP_ARMOR_DMG_MULTI)+"% HP to armor damage multiplier | "+
			l2s(PASSIVES, FXCUpd$ARMOR_DMG_MULTI)+"% Global armor damage multiplier | "+
			l2s(PASSIVES, FXCUpd$QTE_MOD)+"% Quick time event haste"			
		);
		
		llOwnerSay("BEFUDDLE CHANCE > "+l2s(PASSIVES,FXCUpd$BEFUDDLE)+"%");
		llOwnerSay("MANA COST > "+l2s(PASSIVES, FXCUpd$MANACOST)+"%");
		
		llOwnerSay("PROCS > "+
			l2s(PASSIVES,FXCUpd$PROC_BEN)+"% Beneficial proc chance | "+
			l2s(PASSIVES,FXCUpd$PROC_DET)+"% Detrimental proc chance"
		);
		
		llOwnerSay("SPEED > "+
			l2s(PASSIVES, FXCUpd$CASTTIME)+"% cast time multiplier | "+
			l2s(PASSIVES, FXCUpd$COOLDOWN)+"% cooldown multiplier | "+
			l2s(PASSIVES, FXCUpd$MOVESPEED)+"% sprint regeneration | "+
			l2s(PASSIVES, FXCUpd$SPRINT_FADE_MULTI)+"% sprint duration increase | "+
			l2s(PASSIVES, FXCUpd$SWIM_SPEED_MULTI)+"% swim speed"			
		);
		
		
	}
	
	if( method$byOwner && METHOD == GotAPIMethod$dumpLSD ){
		list keys = llLinksetDataListKeys(0,-1);
        integer i;
        for( i = 0; i < count(keys); ++i )
            llOwnerSay(l2s(keys, i)+" >> "+llLinksetDataRead(l2s(keys, i)));
	}

	if(method$byOwner && METHOD == GotAPIMethod$list && !(method$isCallback)){
		
		llOwnerSay("Currently bound items: Item | Owner | Chan");
		integer i;
		for(i=0; i<llGetListLength(bindings); i+= 2){
			key item = llList2Key(bindings, i);
			llOwnerSay(llKey2Name(item) +" | "+ llKey2Name(llGetOwnerKey(item)) +" | "+ llList2String(bindings, i+1));
		}
		
	}
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

