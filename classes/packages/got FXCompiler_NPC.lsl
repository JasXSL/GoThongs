#define IS_NPC
#include "got/_core.lsl"
#define stacksIds() llList2ListStrided(STACKS, 0, -1, 2)

list SET_FLAGS;             // [id, (int)data]
list UNSET_FLAGS;           // [id, (int)data]
list DAMAGE_TAKEN_MULTI;    // [id, (int)multiplier]
list DAMAGE_DONE_MULTI;     // [id, (int)multiplier]
list SPELL_DMG_TAKEN_MOD;   // [id, (str)spell, (float)multiplier]
list DODGE_MULTI;           // [id, (float)data]
list CASTTIME_MULTIPLIER;   // [id, (float)multiplier]
list COOLDOWN_MULTIPLIER;   // [id, (float)multiplier]
list CRIT_MULTIPLIER;		// [id, (float)multiplier]

integer current_visual;

runEffect(key caster, integer stacks, string package, integer pid){
    debugUncommon("FX ran: "+jVal(package, [PACKAGE_NAME]));
    list fxs = llJson2List(jVal(package, [PACKAGE_FXOBJS]));
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        string v = llList2String(fx, 1);
		
		// Shared between PC/NPC, defined in got FXCompiler header file
		dumpFxInstants()
		
		// NPC Specific
        // Don't forget toMultiply by stacks
        
		else if(t == fx$DAMAGE_DURABILITY)
			Status$addHP(-(float)v*stacks, caster, jVal(package, [PACKAGE_NAME]), llList2Integer(fx,2));
        
		else if(t == fx$ANIM){
            if(llList2Integer(fx,2))MeshAnim$startAnim(llList2String(fx, 1));
            else MeshAnim$stopAnim(llList2String(fx, 1));
        }
        
        
        else if(t == fx$INTERRUPT)
            NPCSpells$interrupt();
			
        else if(t == fx$AGGRO)
            Status$monster_aggro(llGetOwnerKey(caster), (float)v);
        else if(t == fx$HITFX)
            Status$hitfx((string)LINK_ROOT);
        
    }
    
    
}

addEffect(key caster, integer stacks, string package, integer pid){
    debugUncommon("FX Added: "+jVal(package, [PACKAGE_NAME]));
    
    list fxs = llJson2List(jVal(package, [PACKAGE_FXOBJS]));
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        
        // Don't forget to multiply by stacks
        dumpFxAddsShared()
        
        // These are NPC specific 
        else if(t == fx$ANIM){
            if(llList2Integer(fx,2))MeshAnim$startAnim(llList2String(fx, 1));
            else MeshAnim$stopAnim(llList2String(fx, 1));
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
        
        if(!overwrite){
            if(t == fx$ANIM){
                if(!llList2Integer(fx,2))MeshAnim$startAnim(llList2String(fx, 1));
                else MeshAnim$stopAnim(llList2String(fx, 1));
            }
        }
        
        // Shared are defined in the got FXCompiler header file
        dumpFxRemsShared()
        
    }
    updateGame();
}

updateGame(){
    integer flags;
    integer i;
    for(i=0; i<llGetListLength(SET_FLAGS); i+=2)flags = flags|llList2Integer(SET_FLAGS,i+1);
    for(i=0; i<llGetListLength(UNSET_FLAGS); i+=2)flags = flags&~llList2Integer(UNSET_FLAGS,i+1);
    
    
    float ddm = compileList(DAMAGE_DONE_MULTI, 0, 1, 2)+1;
    if(ddm<0)ddm = 0;
    
    float dtm = compileList(DAMAGE_TAKEN_MULTI, 0, 1, 2)+1;
    if(dtm<0)dtm = 0;
    
    float dodge = compileList(DODGE_MULTI, 0, 1, 2);
    
    float ctm = compileList(CASTTIME_MULTIPLIER, 0, 1, 2)+1;
    if(ctm<0)ctm = 0;
    
    float cdm = compileList(COOLDOWN_MULTIPLIER, 0, 1, 2)+1;
    if(cdm<.1)cdm = .1;
	
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
    raiseEvent(FXCEvt$update, mkarr(([flags, 0, ddm, dtm, dodge, ctm, cdm, cm])));
}

#include "got/classes/packages/got FXCompiler.lsl"
