#define IS_NPC
#include "got/_core.lsl"
integer TEAM = TEAM_NPC;

list SET_FLAGS;             // [id, (int)data]
list UNSET_FLAGS;           // [id, (int)data]
list DAMAGE_TAKEN_MULTI;    // [id, (int)multiplier]
list DAMAGE_DONE_MULTI;     // [id, (int)multiplier]
list SPELL_DMG_TAKEN_MOD;   // [id, (str)spell, (float)multiplier]
list DODGE_ADD;           	// [id, (float)data]
list CASTTIME_MULTI;   		// [id, (float)multiplier]
list COOLDOWN_MULTI;   		// [id, (float)multiplier]
list CRIT_ADD;				// [id, (float)multiplier]
list SPEED_MULTI;			// [id, (float)multiplier]
list HEAL_MOD;				// [id, (float)multi]


integer current_visual;

runEffect(integer pid, integer pflags, string pname, string fxobjs, int timesnap, key caster){ 
    
	integer stacks = getStacks(pid, FALSE);
	list resource_updates; // Updates for HP/Mana etc
	list fxs = llJson2List(fxobjs);
    
	
	while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
		
        integer t = llList2Integer(fx, 0);
		
		// Shared between PC/NPC, defined in got FXCompiler header file
		dumpFxInstants()
		
		// NPC Specific
        // Don't forget toMultiply by stacks
        
		else if(t == fx$DAMAGE_DURABILITY)
			resource_updates += SMBUR$buildDurabilityNPC(-l2f(fx,1)*stacks, pname, l2i(fx,2), caster);
        
		else if(t == fx$ANIM){
            if(llList2Integer(fx,2))MeshAnim$startAnim(llList2String(fx, 1));
            else MeshAnim$stopAnim(llList2String(fx, 1));
        }
        
        else if(t == fx$INTERRUPT)
            NPCSpells$interrupt();
			
        else if(t == fx$AGGRO)
            Status$monster_aggro(caster, l2f(fx,1));
        else if(t == fx$HITFX)
            Status$hitfx((string)LINK_ROOT);
        else if(t == fx$TAUNT)
			Status$monster_taunt(caster, l2i(fx,1));
    }
    
    if(resource_updates){
		// Send updated hp/mana and stuff
		Status$batchUpdateResources(resource_updates);
	}
}

addEffect(integer pid, integer pflags, str pname, string fxobjs, int timesnap, float duration){
    list fxs = llJson2List(fxobjs);
	integer stacks = getStacks(pid, FALSE);
	
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
		
		else if(t == fx$MOVE_SPEED){
			SPEED_MULTI = manageList(FALSE, SPEED_MULTI, [pid,llList2Float(fx, 1)]);
		}
		
    }
	
	
    
}

remEffect(integer pid, integer pflags, string pname, string fxobjs, integer timesnap, integer overwrite){
    list fxs = llJson2List(fxobjs);
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
        
		if(t == fx$MOVE_SPEED){
			SPEED_MULTI = manageList(TRUE, SPEED_MULTI, [pid,0]); 
		}
		
        // Shared are defined in the got FXCompiler header file
        dumpFxRemsShared()
        
    }
}

updateGame(){
    integer i;
    
    // Multiplicative
    float ddm = compileList(DAMAGE_DONE_MULTI, 0, 1, 2, TRUE);
    if(ddm<0)ddm = 0;
    
	// Multiplicative
    float dtm = compileList(DAMAGE_TAKEN_MULTI, 0, 1, 2, TRUE);
    if(dtm<0)dtm = 0;
    
	// ADDITIVE
    float dodge = compileList(DODGE_ADD, 0, 1, 2, FALSE);
    
	// Multiplicative
    float ctm = compileList(CASTTIME_MULTI, 0, 1, 2, TRUE);
    if(ctm<0)ctm = 0;
    
	// Multiplicative
    float cdm = compileList(COOLDOWN_MULTI, 0, 1, 2, TRUE);
    if(cdm<.1)cdm = .1;
	
	// Additive
	float cm = compileList(CRIT_ADD, 0, 1, 2, FALSE);
    if(cm<0)cm = 0;
	
	// Multiplicative
	float speed = compileList(SPEED_MULTI, 0, 1, 2, TRUE);
	if(speed<0)speed = 0;
    
	// Healing taken mod, multi
	float htm = compileList(HEAL_MOD, 0, 1, 2, TRUE);
    if(htm<0)htm = 0;

    // Compile lists of spell specific modifiers
    list spdmtm; // SPELL_DMG_TAKEN_MOD - [(str)spellName, (float)dmgmod]
    for(i=0; i<llGetListLength(SPELL_DMG_TAKEN_MOD); i+=3){
        string n = llList2String(SPELL_DMG_TAKEN_MOD, i+1);
        integer pos = llListFindList(spdmtm, [n]);
        if(~pos)spdmtm = llListReplaceList(spdmtm, [llList2Float(spdmtm, pos+1)+llList2Float(SPELL_DMG_TAKEN_MOD, i+2)], pos+1, pos+1);
        else spdmtm+=[n, 1+llList2Float(SPELL_DMG_TAKEN_MOD, i+2)];
    }
    
    Status$spellModifiers(spdmtm);     
	
	llMessageLinked(LINK_SET, TASK_FX, mkarr(([
		CACHE_FLAGS, 		// Flags
		0, 					// Mana regen
		f2i(ddm), 			// Damage done multiplier
		f2i(dtm), 			// Damage taken multiplier
		f2i(dodge), 		// Dodge add
		f2i(ctm), 			// Casttime multiplier
		f2i(cdm), 			// Cooldown multiplier
		0, 					// Mana cost multiplier
		f2i(cm), 			// Crit add
		0,					// Pain multi
		0,					// Arousal multi
		// PASSIVES (not used in this)
		0,0,				// HP add/multi
		0,0,				// Mana add/multi
		0,0,				// Arousal add/multi
		0,0,				// Pain add/multi
		0,0,0,				// HP/Pain/Arousal regen
		0,					// SPell highlights
		f2i(htm),				// Healing received mod
		f2i(speed),			// Movespeed multiplier
		1					// (PC only)Healing done mod
	])), "");
}

#include "got/classes/packages/got FXCompiler.lsl"
