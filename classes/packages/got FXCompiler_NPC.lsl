#define IS_NPC
#include "got/_core.lsl"
integer TEAM = TEAM_NPC;

list SPEED_MULTI;			// [id, (float)multiplier]
list CACHE_SFX;				// [(float)time, (arr)data]Spell FX to spawn when received

// Spawn instant spell visuals that we have
spawnEffects(){
	
	integer i;
	for(i=0; i<count(CACHE_SFX) && CACHE_SFX != []; i+=2){
		float time = l2f(CACHE_SFX, i);
		list data = llJson2List(l2s(CACHE_SFX, i+1));
		integer exists = llGetInventoryType(l2s(data, 0)) == INVENTORY_OBJECT;
		// Allow 2 seconds
		if(time < llGetTime()-2 || exists){
			CACHE_SFX = llDeleteSubList(CACHE_SFX, i, i+1);
			i-=2;
		}
		
		if(exists){
			// Now we can spawn
            string name = llList2String(data, 0);
            vector pos_offset = (vector)llList2String(data, 1);
            rotation rot_offset = (rotation)llList2String(data, 2);
			integer flags = llList2Integer(data, 3);
			integer startParam = l2i(data, 4);
			if(startParam == 0)
				startParam = 1;
			
            boundsHeight(llGetKey(), b)
			pos_offset.z *= b;
			
            
			vector vrot = llRot2Euler(llGetRootRotation());
			if(~flags&SpellFXFlag$SPI_FULL_ROT)
				vrot = <0,0,-vrot.x>;
			rotation rot = llEuler2Rot(vrot);
			
			vector to = llGetRootPosition()+<0,0,b/2>+pos_offset*rot;
			
            llRezAtRoot(name, to, ZERO_VECTOR, llEuler2Rot(vrot)*rot_offset, startParam);
		}
	}
	
}

integer current_visual;

runEffect(integer pid, integer pflags, string pname, string fxobjs, int timesnap, key caster){ 
    
	integer stacks = getStacks(pid, FALSE);
	list resource_updates; // Updates for HP/Mana etc
	list fxs = llJson2List(fxobjs);
    fxobjs = "";
	
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
		
		else if(t == fx$SPAWN_VFX){
			CACHE_SFX += [llGetTime(), mkarr(llDeleteSubList(fx,0,0))];
			if(llGetInventoryType(l2s(fx, 1)) != INVENTORY_OBJECT){
				SpellFX$fetchInventory(l2s(fx,1));
			}
			spawnEffects();
		}
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
		else if(t == fx$LTB)
			BuffVis$addToMe(pid, l2s(fx, 1), l2s(fx,2));
		
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
		else if(t == fx$LTB)
			BuffVis$remFromMe(pid);
		
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
	
	integer team = -1;
	if(TEAM_MOD)
		team = l2i(TEAM_MOD, -1);
		
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
		1,					// (PC only)Healing done mod
		team,
		0,					// (unsupported)befuddle,
		0,					// (unsupported)conversion
		0					// (unsupported)sprint
		
	])), "");
}

#include "got/classes/packages/got FXCompiler.lsl"
