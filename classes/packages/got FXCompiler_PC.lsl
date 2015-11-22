#include "got/_core.lsl"
#define stacksIds() llList2ListStrided(STACKS, 0, -1, 2)


list SET_FLAGS;             // [id, (int)data]
list UNSET_FLAGS;           // [id, (int)data]
list THONG_VISUALS;         // [id, (arr)data]
list MANA_REGEN_MULTI;      // [id, (float)multiplier]
list DAMAGE_TAKEN_MULTI;    // [id, (float)multiplier]
list DAMAGE_DONE_MULTI;     // [id, (float)multiplier]
list SPELL_DMG_TAKEN_MOD;   // [id, (str)spell, (float)multiplier]
list DODGE_MULTI;           // [id, (float)data]
list CASTTIME_MULTIPLIER;   // [id, (float)multiplier]
list COOLDOWN_MULTIPLIER;   // [id, (float)multiplier]
list MANA_COST_MULTIPLIER;  // [id, (float)multiplier]
list CRIT_MULTIPLIER;		// [id, (float)multiplier]

integer current_visual;

// Adds to a standard list where PID is the first element




runEffect(key caster, integer stacks, string package, integer pid){
    debugUncommon("FX ran: "+jVal(package, [PACKAGE_NAME]));
    //qd(package);
    list fxs = llJson2List(jVal(package, [PACKAGE_FXOBJS]));
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        string v = llList2String(fx, 1);
        
        // Shared between PC/NPC, defined in got FXCompiler header file
		dumpFxInstants()
		
        else if(t == fx$DAMAGE_DURABILITY)Status$addDurability(-(float)v*stacks, jVal(package, [PACKAGE_NAME]), llList2Integer(fx,2));
        else if(t == fx$AROUSE)Status$addArousal((float)v*stacks, jVal(package, [PACKAGE_NAME]));
        else if(t == fx$PAIN)Status$addPain((float)v*stacks, jVal(package, [PACKAGE_NAME]));
        else if(t == fx$MANA)Status$addMana((float)v*stacks, jVal(package, [PACKAGE_NAME]), llList2Integer(fx, 2));
        else if(t == fx$HITFX){
            ThongMan$hit(v);
            // Also flags and stuff here
            integer flags = llList2Integer(fx,2);
            if(~flags&fxhfFlag$NOSOUND){
                llTriggerSound(randElem((["71224087-bce9-d63f-f582-ccba8bb21e85", "b78573df-e593-b717-301c-ed55e8ad4916", "1d724698-4223-d381-f38c-d9c86986684d"])), .5+llFrand(.5));
            }
            if(~flags&fxhfFlag$NOANIM)
                AnimHandler$anim(mkarr((["got_takehit_highpri", "got_takehit"])), TRUE, 0);
        }
        else if(t == fx$HUD_TEXT)
            runMethod((string)LINK_ROOT, "got Alert", AlertMethod$freetext, llList2List(fx, 1, -1), TNN);
        
        else if(t == fx$ANIM)AnimHandler$anim(llList2String(fx, 1), llList2Integer(fx,2), 0);
 
        else if(t == fx$INTERRUPT)
            SpellMan$interrupt();
        
        else if(t == fx$RESET_COOLDOWNS)
            SpellMan$resetCooldowns((integer)v);
        else if(t == fx$FORCE_SIT){
            string out = "@sit:"+v+"=force";
            if(llList2Integer(fx, 2))out+=",unsit=n";
            llOwnerSay(out);
        }
        else if(t == fx$ROT_TOWARDS){
			RLV$turnTowards(v);
		}
		else if(t == fx$PARTICLES){
			ThongMan$particles((float)v, llList2Integer(fx,2), llList2String(fx,3));
		}
    }
    
    
}

addEffect(key caster, integer stacks, string package, integer pid){
    
    debugUncommon("FX Added: "+jVal(package, [PACKAGE_NAME]));
    list fxs = llJson2List(jVal(package, [PACKAGE_FXOBJS]));
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        
        // These are defined in got FXCompiler header script, shared if statements such as flags and multipliers
		dumpFxAddsShared()
		
		// These are PC specific
		
        else if(t == fx$THONG_VISUAL)
            THONG_VISUALS = manageList(FALSE, THONG_VISUALS, [pid, mkarr(llList2List(fx, 1, -1))]);

		else if(t == fx$ANIM)
			AnimHandler$anim(llList2String(fx, 1), llList2Integer(fx,2), 0);
        
        else if(t == fx$MANA_REGEN_MULTIPLIER)
            MANA_REGEN_MULTI = manageList(FALSE, MANA_REGEN_MULTI, [pid,llList2Float(fx, 1)]);
        
        else if(t == fx$MANA_COST_MULTIPLIER)
            MANA_COST_MULTIPLIER = manageList(FALSE, MANA_COST_MULTIPLIER, [pid,llList2Float(fx, 1)]);
            
        
        else if(t == fx$FORCE_SIT){
            string out = "@sit:"+llList2String(fx, 1)+"=force";
            if(llList2Integer(fx, 2))out+=",unsit=n";

            llOwnerSay(out);
        }
    }
    
    


    updateGame();
}

remEffect(key caster, integer stacks, string package, integer pid, integer overwrite){
    
    debugUncommon("FX removed: "+jVal(package, [PACKAGE_NAME])+" :: "+(string)pid);
    list fxs = llJson2List(jVal(package, [PACKAGE_FXOBJS]));
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        
		// These are things that should not be run if the FX was overwritten, only if it was removed
		if(!overwrite){
			if(t == fx$ANIM)AnimHandler$anim(llList2String(fx, 1), !llList2Integer(fx,2), 0); \
		}
		
		
		// Shared
		dumpFxRemsShared()
		// These are PC specific
		else if(t == fx$THONG_VISUAL)
            THONG_VISUALS = manageList(TRUE, THONG_VISUALS, [pid, 0]);
		else if(t == fx$MANA_REGEN_MULTIPLIER)
			MANA_REGEN_MULTI = manageList(TRUE, MANA_REGEN_MULTI, [pid, 0]);
        else if(t == fx$MANA_COST_MULTIPLIER)
            MANA_COST_MULTIPLIER = manageList(TRUE, MANA_COST_MULTIPLIER, [pid, 0]);
        
        else if(t == fx$FORCE_SIT)llOwnerSay("@unsit=y,unsit=force");
    }
    updateGame();
}





updateGame(){
    integer visual = llList2Integer(THONG_VISUALS, -2);
    
    integer flags;
    integer i;
    for(i=0; i<llGetListLength(SET_FLAGS); i+=2)flags = flags|llList2Integer(SET_FLAGS,i+1);
    for(i=0; i<llGetListLength(UNSET_FLAGS); i+=2)flags = flags&~llList2Integer(UNSET_FLAGS,i+1);
    
    
    if(current_visual != visual){
        current_visual = visual;
        ThongMan$fxVisual(llJson2List(llList2String(THONG_VISUALS, -1)));
    }
    
    
    float ddm = compileList(DAMAGE_DONE_MULTI, 0, 1, 2)+1;
    if(ddm<0)ddm = 0;
    
    float dtm = compileList(DAMAGE_TAKEN_MULTI, 0, 1, 2)+1;
    if(dtm<0)dtm = 0;
    
    float dodge = compileList(DODGE_MULTI, 0, 1, 2);
    
    float ctm = compileList(CASTTIME_MULTIPLIER, 0, 1, 2)+1;
    if(ctm<0)ctm = 0;
    
    float cdm = compileList(COOLDOWN_MULTIPLIER, 0, 1, 2)+1;
    if(cdm<.1)cdm = .1;
    
    float regen = compileList(MANA_REGEN_MULTI, 0, 1, 2)+1;
    if(regen<0)regen = 0;
    
    float mcm = compileList(MANA_COST_MULTIPLIER, 0, 1, 2)+1;
    if(mcm<0)mcm = 0;
	
    float cm = compileList(CRIT_MULTIPLIER, 0, 1, 2);
    if(cm<0)cm = 0;
    
    // Compile lists of spell specific modifiers
    list spdmtm; // SPELL_DMG_TAKEN_MOD - [(str)spellName, (float)dmgmod]
    for(i=0; i<llGetListLength(SPELL_DMG_TAKEN_MOD); i+=3){
        string n = llList2String(SPELL_DMG_TAKEN_MOD, i+1);
        integer pos = llListFindList(spdmtm, [n]);
        if(~pos)spdmtm = llListReplaceList(spdmtm, [llList2Float(spdmtm, pos+1)+llList2Float(SPELL_DMG_TAKEN_MOD, i+2)], pos+1, pos+1);
        else spdmtm+=[n, 1+llList2Float(SPELL_DMG_TAKEN_MOD, i+2)];
    }
    
    Status$spellModifiers(spdmtm);
    raiseEvent(FXCEvt$update, mkarr(([flags, regen, ddm, dtm, dodge, ctm, cdm, mcm, cm])));
}

#include "got/classes/packages/got FXCompiler.lsl"
