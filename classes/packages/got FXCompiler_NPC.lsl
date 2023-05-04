// Head
#if FXCOMPILER_SECTION == 0
list CACHE_SFX;				// [(float)time, (arr)data]Spell FX to spawn when received
integer current_visual;
// Spawn instant spell visuals that we have
spawnEffects(){
	
	integer i;
	for( ; i<count(CACHE_SFX) && count(CACHE_SFX); i+=2 ){
	
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
			string sp = l2s(data, 4);
			integer startParam = (int)sp;
			
			// Startparam should become an integerlized version of our key
			if( sp == "$aoeI$" )
				startParam = (int)("0x"+(str)llGetKey());
				
			if(startParam == 0)
				startParam = 1;
				
			key targ = llGetKey();	// Person to target the fx with

			// Person to spawn the item from
			key t = llGetKey();
			if( flags & SpellFXFlag$SPI_SPAWN_FROM_CASTER )
				t = llGetOwner();
			
			float zOffset = pos_offset.z;
			pos_offset.z = 0;
				
			if( flags&SpellFXFlag$SPI_IGNORE_HEIGHT )
				zOffset = 0;
				
			if( flags&SpellFXFlag$SPI_TARG_IN_REZ )
				startParam = (int)("0x"+llGetSubString((str)targ,0,7));
			
            
			vector vrot = llRot2Euler(prRot(t));
			if( ~flags&SpellFXFlag$SPI_FULL_ROT )
				vrot = <0,0,-vrot.x>;
			rotation rot = llEuler2Rot(vrot);
			
			vector to = getTargetPosOffset(t, zOffset+0.5)+pos_offset*rot;
						
            llRezAtRoot(name, to, ZERO_VECTOR, llEuler2Rot(vrot)*rot_offset, startParam);
			
		}
	}
	
}

onSettings(list settings){ 
	integer flagsChanged;
	while(settings){
		integer idx = l2i(settings, 0);
		list dta = llList2List(settings, 1, 1);
		settings = llDeleteSubList(settings, 0, 1);
		if( idx == MLC$hover_height )
			hoverHeight = l2f(dta, 0);
		
	}
	
	// Limits
	if(speed<=0)
		speed = 1;

}

#define LM_PRE \
	if(nr == TASK_MONSTER_SETTINGS){\
		onSettings(llJson2List(s)); \
	}\

#endif


// Run
#if FXCOMPILER_SECTION == 1

	list resource_updates; // Updates for HP/Mana etc

	// Shared between PC/NPC, defined in got FXCompiler header file
	dumpFxInstants()
	
	// NPC Specific
	// Don't forget toMultiply by stacks
	else if( t == fx$DAMAGE_DURABILITY ){
		
		int st = stacks;
		if( l2i(fx,1)&SMAFlag$NO_STACK_MULTI )
			st = 1;
		resource_updates += SMBUR$buildDurability(-l2f(fx,0)*stacks, pname, l2i(fx,1), l2f(fx, 2));
		
	}
	else if( t == fx$ANIM && !l2i(fx, 2) ){
	
		if( llGetInventoryType("got AniAnim") == INVENTORY_SCRIPT && !l2i(fx, 2) )
			AniAnim$customAnim(LINK_THIS, 
				l2s(fx,0), 	// Name
				l2i(fx,1), 	// Start
				l2i(fx,3), 	// flags
				l2i(fx,4), 	// duration
				TRUE		// prevent non-humanoid
			);
		else if( l2i(fx,1) )
			MeshAnim$startAnim(l2s(fx, 0));
		else 
			MeshAnim$stopAnim(l2s(fx, 0));
			
	}
	
	else if( t == fx$INTERRUPT )
		NPCSpells$interrupt(l2i(fx, 0));
		
	else if( t == fx$AGGRO )
		Status$monster_aggro(caster, l2f(fx,0));
	
	else if( t == fx$HITFX )
		NPCInt$hitfx((string)LINK_ROOT);
	
	else if( t == fx$TAUNT )
		Status$monster_taunt(caster, l2i(fx,0));
	
	else if( t == fx$SPAWN_VFX ){
		
		CACHE_SFX += (list)llGetTime() + mkarr(fx);
		if( llGetInventoryType(l2s(fx, 0)) != INVENTORY_OBJECT )
			SpellFX$fetchInventory(l2s(fx,0));
		spawnEffects();
		
	}
	    
    if(resource_updates){
		// Send updated hp/mana and stuff
		Status$batchUpdateResources(caster, resource_updates);
	}
	
#endif


// Add
#if FXCOMPILER_SECTION == 2

	if( t == fx$ANIM ){
	
		if( llGetInventoryType("got AniAnim") == INVENTORY_SCRIPT )
			AniAnim$customAnim(
				LINK_THIS, 
				l2s(fx,0), // Name
				l2i(fx,1), // Start
				l2i(fx,3), // flags
				l2i(fx,4), // duration
				TRUE
			);
		else if( l2i(fx,1) )
			MeshAnim$startAnim(l2s(fx, 0));
		else 
			MeshAnim$stopAnim(l2s(fx, 0));
	
	}

	else if( t == fx$LTB ){
		BuffVis$addToMe(llOrd(table, 0), l2s(fx, 0), l2s(fx,1));
	}

#endif


// Delete
#if FXCOMPILER_SECTION == 3

	if(t == fx$ANIM){
		
		if( llGetInventoryType("got AniAnim") == INVENTORY_SCRIPT )
			AniAnim$customAnim(
				LINK_THIS,
				l2s(fx,0), // Name
				!l2i(fx,1), // Start
				l2i(fx,3), // flags
				l2i(fx,4), // duration
				FALSE		// prevent non humanoid
			);
		else if( !l2i(fx,2) )
			MeshAnim$startAnim(llList2String(fx, 0));
		else 
			MeshAnim$stopAnim(llList2String(fx, 0));
			
	}
	
	if( t == fx$LTB )
		BuffVis$remFromMe(llOrd(table, 0));
	
#endif



