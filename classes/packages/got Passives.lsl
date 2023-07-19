// Todo: Do we need passives? Can we reroute them to actives?
// We can probably reroute all events to fxcompiler if we do

#define USE_EVENTS
#define USE_DB4
#include "got/_core.lsl"

list REM_ON_CLEAN;	// names of passives that should be removed on cleanup
list REM_ON_UNSIT;	// names of passives that should be removed when unsitting



// Map the fxcompiler values plus FXCUpdPRE (to allow negative) to corresponding values in _lib_fx, or 0 if passive only
// This MUST match the nr of types in got FXCompiler. Otherwise strangeness will occur.
// Values that cannot be remapped are set to FXCMAP_NONE
#define FXCMAP_NONE -0xFF
list FXCMap = [
	fx$ATTACH, 								// -3
	FXCMAP_NONE,							// -2 Procs
	fx$UNSET_FLAG,							// -1
	fx$SET_FLAG,					// 0
	fx$MANA_REGEN_MULTI,			// 1
	fx$DAMAGE_DONE_MULTI,			// 2
	fx$DAMAGE_TAKEN_MULTI,			// 3
	fx$DODGE,						// 4
	fx$CASTTIME_MULTI,				// 5
	fx$COOLDOWN_MULTI,				// 6
	fx$MANA_COST_MULTI,				// 7
	fx$CRIT_ADD,					// 8
	fx$PAIN_MULTI,					// 9
	fx$AROUSAL_MULTI,				// 10
	fx$HP_ADD, /* HP add */				// 11
	fx$HP_MULTI,							// 12
	fx$MANA_ADD, /* Mana add */				// 13
	fx$MANA_MULTI,							// 14
	fx$MAX_AROUSAL_ADD, /* Arousal add*/			// 15
	fx$MAX_AROUSAL_MULTI,					// 16
	fx$MAX_PAIN_ADD, /* Pain add*/				// 17
	fx$MAX_PAIN_MULTI,						// 18
	fx$HP_REGEN_MULTI, /* Out of combat regen */	// 19
	fx$PAIN_REGEN_MULTI, /* Pain regen multi */		// 20
	fx$AROUSAL_REGEN_MULTI, /* Arousal regen multi */	// 21
	fx$SPELL_HIGHLIGHT,				// 22
	fx$HEALING_TAKEN_MULTI,			// 23
	fx$MOVE_SPEED,					// 24
	fx$HEALING_DONE_MULTI,			// 25
	fx$SET_TEAM,					// 26
	fx$BEFUDDLE,					// 27
	fx$CONVERSION,					// 28
	fx$SPRINT_FADE_MULTI, /* Sprint fade multi */	// 29
	fx$BACKSTAB_MULTI, /* Backstab multi */		// 30
	fx$SWIM_SPEED_MULTI, /* Swim speed multi */		// 31
	fx$FOV,									// 32
	fx$PROC_BEN,					// 33
	fx$PROC_DET,					// 34
	fx$HP_ARMOR_DMG_MULTI,			// 35
	fx$ARMOR_DMG_MULTI,				// 36
	fx$QTE_MOD,						// 37
	fx$COMBAT_HP_REGEN,				// 38
	fx$SPELL_DMG_TAKEN_MOD,			// 39
	fx$SPELL_DMG_DONE_MOD			// 40
];





ptEvt(string id){

	// Todo: Replace with offset from llGetTime()
	if(llGetSubString(id, 0,2) == "CD_"){
	
		integer n = (int)llGetSubString(id, 3, -1);
		
	}
	
}

onEvt(string script, integer evt, list data){
    
    if( script == "got Bridge" && evt == BridgeEvt$userDataChanged ){
	
		data = llJson2List(hud$bridge$userData());
        data = llJson2List(l2s(data, BSUD$WDATA));
		data = llJson2List(l2s(data, 2));
		Passives$set(LINK_THIS, "_WEAPON_", data, 0);				
		return;
		
    }
	
	// Remove passives that should be removed on cleanup
	else if(script == "got RootAux" && evt == RootAuxEvt$cleanup){
	
		integer i; list remove = REM_ON_CLEAN;
		for( ; i < count(remove); ++i ){
			Passives$rem(LINK_THIS, l2s(remove, i));
		}
		
	}

}

timerEvent( str id, str data ){
	
	if( id == "SC" && REM_ON_UNSIT != [] && ~llGetAgentInfo(llGetOwner()) & AGENT_SITTING ){
			
		integer i; list remove = REM_ON_UNSIT;
		for( ; i < count(remove); ++i )
			Passives$rem(LINK_THIS, l2s(remove, i));
		
	}
	
}

default{
    // Reset to defaults
	state_entry(){
		/*
		int i;
		for( ; i < count(FXCDefaults); ++i )
			db4$replace(gotTable$passivesOutput, i, l2s(FXCDefaults, i));
		*/
		
		multiTimer(["SC", 0, 1, TRUE]);
		
	}
	
	timer(){
		multiTimer([]);
	}
	


    #include "xobj_core/_LM.lsl" 
    if(method$isCallback){
        return;
    }
    
    
    /*
        Adds a passive
    */
    if(METHOD == PassivesMethod$set){
	
        str oName = method_arg(0);
		str name = "p$"+oName;
		integer flags = l2i(PARAMS, 2);
		//str table = gotTable$passivesInput;
		list effects = llJson2List(method_arg(1));

		int pos = llListFindList(REM_ON_CLEAN, (list)oName);
		if( ~pos )
			REM_ON_CLEAN = llDeleteSubList(REM_ON_CLEAN, pos, pos);
		pos = llListFindList(REM_ON_UNSIT, (list)oName);
		if( ~pos )
			REM_ON_UNSIT = llDeleteSubList(REM_ON_UNSIT, pos, pos);
				
		// Remove existing
		FX$rem(
			false, // raiseEvent
			name, 
			"", "", 0, // Tag, sender, pix, 
			FALSE, // runOnRem
			0, 		// flags
			1, 		// maxnr
			"", 	// dispeller
			TRUE	// Allow passive
		);
		
		// Delete
		if( effects == [] )
			return;
		
		if( flags & Passives$FLAG_REM_ON_CLEANUP )
			REM_ON_CLEAN += oName;
		if( flags & Passives$FLAG_REM_ON_UNSIT )
			REM_ON_UNSIT += oName;
		
		debugUncommon("Transpiling "+method_arg(1));
		list fx;
		list events;
		integer i;
		for(; i < count(effects); i += 2 ){
		
			int type = l2i(effects, i);
			list val = llList2List(effects, i+1, i+1);
			int to = l2i(FXCMap, type+3);	// +3 because it starts at -3
			
			if( type == FXCUpd$PROC ){
				
				val = llJson2List(l2s(val, 0));
				list triggers = llJson2List(l2s(val, Passives$procTriggers));			
				int maxTargs = l2i(val, Passives$procMaxTargets);
				float cd = l2f(val, Passives$procCooldown);
				
				float procChance = l2f(val, Passives$procChance);
				int procFlags = l2i(val, Passives$procFlags);
				str wrapper = l2s(val, Passives$procWrapper);
				val = [];
				
				debugUncommon("Converting triggers "+mkarr(triggers));
				// Note: Avoid multiple triggers if you can because they are a waste of memory
				int t;
				for( ; t < count(triggers); ++t ){
					
					// Fail
					if( llJsonValueType(l2s(triggers, t), []) != JSON_ARRAY ){
						llOwnerSay("Error: Non-array trigger found in passive: '"+name+"'. Did you forget to make the triggers an array of arrays?");
						return;
					}
					
					list trig = llJson2List(l2s(triggers, t));
					int targ = l2i(trig, Passives$pt$targ);
					int targOut;
					// Transpile targets
					if( targ > 0 )
						targOut = -targ;	// FX uses negative target to pull from event param
					else{
					
						targ = llAbs(targ);
						if( targ & Passives$TARG_AOE )
							targOut = targOut | TARG_AOE;
						if( targ & Passives$TARG_SELF )
							targOut = targOut | TARG_VICTIM;
							
					}
					
					str script = l2s(trig, Passives$pt$script);
					int evt = l2i(trig, Passives$pt$evt);
					str args = l2s(trig, Passives$pt$args);
					float range = l2f(trig, Passives$pt$range);
					events += fx$buildEvent( evt, script, targOut, maxTargs, wrapper, args, procChance, procFlags, range, cd);

				}
				
				
			}
			// Attach must unroll into a flat format
			else if( type == FXCUpd$ATTACH ){
			
				list set = (list)to + llJson2List(l2s(val, 0));
				if( oName == "_ENCH_" )
					set += fx$ATTACH_CLASSATT;
				fx += mkarr(set);
				
			}
			// If you use cooldown with an array as data, it is treated as a cooldown of a particular spell and is transpiled to fx$SPELL_COOLDOWN_MULTI
			else if( type == FXCUpd$COOLDOWN && llJsonValueType(l2s(val, 0), []) == JSON_ARRAY ){
				fx += mkarr((list)fx$SPELL_COOLDOWN_MULTI + (int)j(l2s(val, 0), 1) + (float)j(l2s(val, 0), 0));				
			}
			else if( to != FXCMAP_NONE ){
				fx += mkarr((list)to + val);
			}
		}
		
		str wrapper = "[0,0,0,0,["+
			"-1,"+
			"0,"+
			"\""+name+"\","+
			mkarr(fx)+","+
			"[],"+
			mkarr(events)+
		"]]";
		debugUncommon("Transpile: "+wrapper);
		//qd(wrapper);
		FX$run("", wrapper);
		
    }
    
    
    /*
        Removes a passive
    */
    else if( METHOD == PassivesMethod$rem ){
		// Legacy. Use PassivesMethod$set
		Passives$rem(LINK_THIS, method_arg(0));	// Rem has been realiased and uses set with an emtpy effects list
    }
    
    /*
        Returns a list of passive names
    */
    else if( METHOD == PassivesMethod$get ){

		fxPackageEach(pix,tb,
			
			if( (int)db4$fget(tb, fxPackage$DUR) == -1 )
				CB_DATA += llGetSubString(db4$fget(tb, fxPackage$NAME), 2, -1);
		
		)
        
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
