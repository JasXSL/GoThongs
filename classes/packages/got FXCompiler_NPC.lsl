#define IS_NPC
#include "got/_core.lsl"
#include "../got FXCompiler_Shared.lsl"
integer TEAM = TEAM_NPC;

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
		Status$batchUpdateResources(caster, resource_updates);
	}
}

addEffect( integer pid, integer pflags, str pname, string fxobjs, int timesnap, float duration, key caster ){

    list fxs = llJson2List(fxobjs);
	integer stacks = getStacks(pid, FALSE);
	
	@fxContinue;
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
		fx = llDeleteSubList(fx, 0, 0);
        
        // Don't forget to multiply by stacks
        dumpFxAddsShared()
        
        // These are NPC specific 
        else if( t == fx$ANIM ){
		
            if( l2i(fx,1) )
				MeshAnim$startAnim(l2s(fx, 0));
            else 
				MeshAnim$stopAnim(l2s(fx, 0));
			jump fxContinue;
		
        }

		else if( t == fx$LTB ){
			
			BuffVis$addToMe(pid, l2s(fx, 1), l2s(fx,2));
			jump fxContinue;
			
		}
		
		// Default behavior
		addDFX( pid, t, fx );
		
    }
	
	
    
}

remEffect(integer pid, integer pflags, string pname, string fxobjs, integer timesnap, integer overwrite){

	remDFX( pid );
	
    list fxs = llJson2List(fxobjs);
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        
        if(!overwrite){
		
            if(t == fx$ANIM){
			
                if(!llList2Integer(fx,2))
					MeshAnim$startAnim(llList2String(fx, 1));
                else 
					MeshAnim$stopAnim(llList2String(fx, 1));
					
            }
			
        }
		else if(t == fx$LTB)
			BuffVis$remFromMe(pid);

        // Shared are defined in the got FXCompiler header file
        dumpFxRemsShared()
        
    }
}

updateGame(){

	integer team = -1;
	list teamMod = getDFXSlice( fx$SET_TEAM, 1);
	if( teamMod )
		team = l2i(teamMod, -1);

	// Compile lists of spell specific modifiers
    list spdmtm; // [(str)spellName, (int)playerID, (float)dmgmod]
	list data = getDFXSlice( fx$SPELL_DMG_TAKEN_MOD, 3 );
	integer i;
    for( ; i<count(data); i+=4 ){
	
		// First value is a bitwise combination, see DFX at FXCompiler_Shared
		int stacks = getStacks(dPid(l2i(data, i)), FALSE);
		// #3 is an integerlized version of the caster
		int caster = l2i(data, i+3);
		// #1 is the name of the spell
        string n = llList2String(data, i+1);
		// #2 is the float modifier
		
        integer pos = llListFindList(spdmtm, [n, caster]); // find spellName and caster, caster * is 0
        if(~pos)
			spdmtm = llListReplaceList(spdmtm, [llList2Float(spdmtm, pos+2)*(1+llList2Float(data, i+2))*stacks], pos+2, pos+2);
        else 
			spdmtm+=[n, caster, 1+llList2Float(data, i+2)*stacks];
			
    }
	Status$spellModifiers(
		spdmtm, 
		cMod(fx$DAMAGE_TAKEN_MULTI), 
		cMod(fx$HEALING_TAKEN_MULTI)
	); 
     
    llMessageLinked(LINK_THIS, TASK_OFFENSIVE_MODS, "["+implode(",", ([
		mkarr(cMod(fx$DAMAGE_DONE_MULTI))
	]))+"]", "");
	
	llMessageLinked(LINK_SET, TASK_FX, mkarr(([
		CACHE_FLAGS, 		// Flags
		0, 					// Mana regen
		100, 			// Damage done multiplier (handled in Status$spellModifiers)
		100, 			// Damage taken multiplier (handled in Status$spellModifiers)
		stat( fx$DODGE ), 		// Dodge add
		stat( fx$CASTTIME_MULTI ), 			// Casttime multiplier
		stat( fx$COOLDOWN_MULTI ), 			// Cooldown multiplier
		0, 					// Mana cost multiplier
		stat( fx$CRIT_ADD ), 			// Crit add
		0,					// Pain multi
		0,					// Arousal multi
		// PASSIVES (not used in this)
		stat( fx$HP_ADD ),			// HP add, Not yet implemented
		stat( fx$HP_MULTI ),		// HP multi, not yet implemented
		0,0,				// Mana add/multi
		0,0,				// Arousal add/multi
		0,0,				// Pain add/multi
		0,0,0,				// HP/Pain/Arousal regen
		0,					// SPell highlights
		100,				// Healing received mod (handled in Status$spellModifiers)
		stat( fx$MOVE_SPEED ),			// Movespeed multiplier
		1,					// (PC only)Healing done mod
		team,
		0,					// (unsupported)befuddle,
		0,					// (unsupported)conversion
		0,					// (unsupported)sprint
		0,					// (unsupported)backstab
		0					// (unsupported)swimspeed
	])), "");
}

#include "got/classes/packages/got FXCompiler.lsl"
