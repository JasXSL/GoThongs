#include "got/_core.lsl"
#include "../got FXCompiler_Shared.lsl"
integer TEAM = TEAM_PC;



// ID tag is the first 8 characters of the UUID
integer current_visual;

runEffect(integer pid, integer pflags, string pname, string fxobjs, int timesnap, key caster, int stacks){

	list resource_updates; // Updates for HP/Mana etc
	
	if(pflags&PF_DETRIMENTAL)
		Status$refreshCombat();
		

	list fxs = llJson2List(fxobjs);
    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        
		// Type
		integer t = llList2Integer(fx, 0);
		
        // Shared between PC/NPC, defined in got FXCompiler header file
		dumpFxInstants()
		
        else if(t == fx$DAMAGE_DURABILITY){
			resource_updates += SMBUR$buildDurability(-l2f(fx,1)*stacks, pname, l2i(fx,2));
		}
        else if(t == fx$AROUSE){
			resource_updates += SMBUR$buildArousal(l2f(fx,1)*stacks, pname, l2i(fx,2));
		}
        else if(t == fx$PAIN)
			resource_updates += SMBUR$buildPain(l2f(fx,1)*stacks, pname, l2i(fx,2));
        else if(t == fx$MANA)
			resource_updates += SMBUR$buildMana(l2f(fx,1)*stacks, pname, l2i(fx,2));
		
		else if( t == fx$CLASS_VIS )
			gotClassAtt$spellStart(l2s(fx,1), l2f(fx, 2));
		
		else if( t == fx$REDUCE_CD ){
			SpellMan$reduceCD(llDeleteSubList(fx, 0, 0));
		}
		
		else if( t == fx$LOOK_AT )
			llOwnerSay("@setrot:"+l2s(fx, 1)+"=force");
			
		
		else if( t == fx$DAMAGE_ARMOR )
			Status$damageArmor(LINK_ROOT, l2i(fx, 1));

		else if(t == fx$PUSH){
			vector z = llGetVel();
			vector apply = (vector)l2s(fx, 1)*llGetMass();//-<0,0,z.z>;
			llApplyImpulse(apply, FALSE);
		}
		
		else if( t == fx$HITFX ){
		
            ThongMan$hit(l2s(fx,1));
            // Also flags and stuff here
            integer flags = llList2Integer(fx,2);
            if( ~flags&fxhfFlag$NOSOUND ){
			
				list sounds = (["71224087-bce9-d63f-f582-ccba8bb21e85", "b78573df-e593-b717-301c-ed55e8ad4916", "1d724698-4223-d381-f38c-d9c86986684d"]);
                llTriggerSound(randElem(sounds), .5+llFrand(.5));
				
            }
			
            if( ~flags&fxhfFlag$NOANIM )
                AnimHandler$anim(mkarr((["got_takehit_highpri", "got_takehit"])), TRUE, 0, 0, 0);
			
			raiseEvent(FXCEvt$hitFX, mkarr(([l2s(fx, 1), l2i(fx, 2), caster])));
			
        }
        else if(t == fx$HUD_TEXT)
            runMethod((str)LINK_ROOT, "got Alert", AlertMethod$freetext, llList2List(fx, 1, -1), TNN);
        
        else if(t == fx$ANIM && !l2i(fx, 3))
			AnimHandler$anim(llList2String(fx, 1), llList2Integer(fx,2), 0, 0, l2i(fx, 3));
 
        else if(t == fx$INTERRUPT)
            SpellMan$interrupt(l2i(fx, 1));
        
        else if(t == fx$RESET_COOLDOWNS){
            SpellMan$resetCooldowns(l2i(fx,1), l2i(fx,2));
		}
        else if(t == fx$FORCE_SIT){
            string out = "@sit:"+l2s(fx,1)+"=force";
            if(llList2Integer(fx, 2))out+=",unsit=n";
            llOwnerSay(out);
        }
        else if(t == fx$ROT_TOWARDS){
			RLV$turnTowards(l2s(fx,1));
		}
		else if(t == fx$PARTICLES){
			ThongMan$particles(l2f(fx,1), llList2Integer(fx,2), llList2String(fx,3));
		}
		else if(t == fx$PULL && ~CACHE_FLAGS&fx$F_NO_PULL){
			if((vector)l2s(fx,1) == ZERO_VECTOR){
				raiseEvent(FXCEvt$pullEnd, "");
				llStopMoveToTarget();
			}else{
				raiseEvent(FXCEvt$pullStart, "");
				llSleep(.1);
				llMoveToTarget((vector)l2s(fx,1), llList2Float(fx,2));
				
			}
		}
		else if(t == fx$SPAWN_VFX){
			SpellFX$spawnInstant(mkarr(llDeleteSubList(fx,0,0)), llGetOwner());
		}
		else if(t == fx$ALERT)
			Alert$freetext(LINK_ROOT, l2s(fx,1), llList2Integer(fx,2), llList2Integer(fx, 3));
		else if(t == fx$CUBETASKS)
			RLV$cubeTask(llDeleteSubList(fx, 0, 0));
		else if(t == fx$REFRESH_SPRINT)
			RLV$setSprintPercent(LINK_ROOT, 1);
		
    }
	
    // Send updated hp/mana and stuff
    if( resource_updates )
		Status$batchUpdateResources(caster, resource_updates);
	
}

addEffect( integer pid, integer pflags, str pname, string fxobjs, int timesnap, float duration, key caster ){

    integer stacks = getStacks(pid, FALSE);
    list fxs = llJson2List(fxobjs);

	@fxContinue;
    while( fxs ){
	
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = l2i(fx, 0);
		fx = llDeleteSubList(fx, 0, 0);
        
        // These are defined in got FXCompiler header script, shared if statements such as flags and multipliers
		dumpFxAddsShared()
		
		// These are PC specific
		else if( t == fx$ANIM ){
		
			AnimHandler$anim(llList2String(fx, 0), llList2Integer(fx,1), 0, 0, l2i(fx,2));
			jump fxContinue;
			
        }
		else if( t == fx$THONG_VISUAL )
			fx = (list)mkarr(fx);
		
		else if( t == fx$CLASS_VIS ){
		
            gotClassAtt$spellStart(l2s(fx,0), l2f(fx, 1));
			jump fxContinue;
			
		}
		else if( t == fx$ATTACH ){
			
			Rape$addFXAttachments(fx);
			jump fxContinue;
			
		}
		
		else if( t == fx$STANCE ){
			WeaponLoader$fxStance(l2s(fx, 0), TRUE);
		}
		
		
		else if( t == fx$FORCE_SIT ){
		
            string out = "@sit:"+llList2String(fx, 0)+"=force";
            if( llList2Integer(fx, 1) )
				out+=",unsit=n";
            llOwnerSay(out);
			jump fxContinue;
			
        }
		else if( t == fx$LTB ){
			
			BuffVis$add(pid, l2s(fx, 0), l2s(fx,1));
			jump fxContinue;
			
		}
		
		// Default behavior
		addDFX( pid, t, fx );

    }

}

remEffect( integer pid, integer pflags, string pname, string fxobjs, integer timesnap, integer overwrite ){
    
	integer stacks = getStacks(pid, FALSE);
    list fxs = llJson2List(fxobjs);

	// Start by removing all dfxs
	remDFX( pid );
	
	while(llGetListLength(fxs)){
	
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
		fx = llDeleteSubList(fx, 0, 0);
        
		// These are things that should not be run if the FX was overwritten, only if it was removed
		if( !overwrite && t == fx$ANIM )
			AnimHandler$anim(llList2String(fx, 0), !llList2Integer(fx,1), 0, 0, 0);
		// Shared
		dumpFxRemsShared()
		
		// PC specific:
		else if( t == fx$CLASS_VIS )
			gotClassAtt$spellEnd(l2s(fx,0), -1);
		else if( t == fx$FORCE_SIT )
			llOwnerSay("@unsit=y,unsit=force");
		else if( t == fx$PULL ){
			raiseEvent(FXCEvt$pullEnd, "");
			llStopMoveToTarget();
		}
		else if( t == fx$STANCE ){
			WeaponLoader$fxStance(l2s(fx, 0), FALSE);
		}
		else if(t == fx$LTB)
			BuffVis$rem(pid);
		else if( t == fx$ATTACH )
			Rape$remFXAttachments(fx);

    }

}

// Compiles a list of SPELL_* for indexed spells, IE. Not spell_dmg_taken_multi
list spellModCompile(list input){

	integer i;
	list out = [1,1,1,1,1];		// Needs to match nr spells
	for( ; i<llGetListLength(input); i+=3 ){
	
        integer n = llList2Integer(input, i+1);	// nr Index
		float cur = llList2Float(out, n);					// current at index
		integer stacks = getStacks(dPid(l2i(input, i)), FALSE);
		cur *= (llList2Float(input, i+2)*stacks+1);
		out = llListReplaceList(out, [cur], n, n);
		
    }
	return out;
	
}

string cache_spellmods;

updateGame(){


    integer visual = dPid(llList2Integer(getDFXSlice(fx$THONG_VISUAL, 1), -2));
    if( current_visual != visual ){
        
		current_visual = visual;
        ThongMan$fxVisual(llJson2List(llList2String(getDFXSlice( fx$THONG_VISUAL, 1), -1)));
		
    }
	integer team = -1;
	list teamMod = getDFXSlice( fx$SET_TEAM, 1);
	if( teamMod )
		team = l2i(teamMod, -1);
		
	llSetBuoyancy(l2f(getDFXSlice( fx$GRAVITY, 1), -1));
	
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
	data = [];

	llMessageLinked(LINK_THIS, TASK_OFFENSIVE_MODS, mkarr(([
		mkarr(cMod(fx$DAMAGE_DONE_MULTI))
	])), "");
	
	// these work off of spell index
	string out = llList2Json(JSON_ARRAY, [
		mkarr(spellModCompile(getDFXSlice( fx$SPELL_DMG_DONE_MOD, 2 ))),
		mkarr(spellModCompile(getDFXSlice( fx$SPELL_MANACOST_MULTI, 2 ))),
		mkarr(spellModCompile(getDFXSlice( fx$SPELL_CASTTIME_MULTI, 2 ))),
		mkarr(spellModCompile(getDFXSlice( fx$SPELL_COOLDOWN_MULTI, 2 )))
	]);

	if( out != cache_spellmods ){

		cache_spellmods = out;
		raiseEvent(FXCEvt$spellMultipliers, out);
		
	}
	
	list conv;
	data = getDFXSlice( fx$CONVERSION, 1);
	for( i=0; i<count(data); i+=2 )
		conv+= llJson2List(l2s(data, i+1));
	
	integer hlt;
	data = getDFXSlice( fx$SPELL_HIGHLIGHT, 2);
	for( i=0; i<count(data); i+=3 ){
		if( l2i(data, i+2) <= getStacks(dPid(l2i(data, i)), TRUE) )
			hlt = hlt | (int)llPow(2,llList2Integer(data, i+1));
	}
	

	// These are the FXCUpd$ values
	Passives$setActive(([ 
		CACHE_FLAGS, 		// 00 FLAGS
		stat( fx$MANA_REGEN_MULTI ), 		// 01 MANA_REGEN
		100, 			// 02 DAMAGE_DONE (handled in TASK_OFFENSIVE_MODS)
		100, 			// 03 DAMAGE_TAKEN (handled in Status$spellModifiers)
		stat( fx$DODGE ), 		// 04 DODGE
		stat( fx$CASTTIME_MULTI ), 			// 05 CASTTIME
		stat( fx$COOLDOWN_MULTI ), 			// 06 COOLDOWN
		stat( fx$MANA_COST_MULTI ), 			// 07 MANA_COST
		stat( fx$CRIT_ADD ), 			// 08 CRIT
		stat( fx$PAIN_MULTI ), 			// 09 PAIN_MULTI
		stat( fx$AROUSAL_MULTI ),			// 10 AROUSAL_MULTI
		// These don't use f2i for now since these have no active effects, but if you add active effects at some point you should f2i them here and then i2f them in got Passives
		stat( fx$HP_ADD ),		// 11 HP_ADD
		stat( fx$HP_MULTI ),	// 12 HP_MULTI
		0,					// 13 MANA_ADD
		stat( fx$MANA_MULTI ),					// 14 MANA_MULTI
		0,					// 15 AROUSAL_ADD
		1,					// 16 AROUSAL_MULTI
		1,					// 17 PAIN_ADD
		1,					// 18 PAIN_MULTI
		1,					// 19 HP_REGEN
		1,					// 20 PAIN_REGEN
		1,					// 21 AROUSAL_REGEN
		hlt,				// 22 HIGHLIGHT_FLAGS
		100,			// 23 Healing taken mod
		1,					// 24 Movespeed (NPC only)
		stat( fx$HEALING_DONE_MULTI ),			// 25 Healing done mod
		team,				// 26 Team override
		stat( fx$BEFUDDLE ),		// 27 Befuddle
		mkarr(conv),		// 28 Conversions
		100,				// 29 Sprint fade (f2i)
		100,				// 30 Backstab mul (f2i)
		100,					// 31 Swim speed (f2i)
		f2i(l2f(getDFXSlice( fx$FOV, 1), -1)), // 32, FoV (f2i)
		stat( fx$PROC_BEN ),	// Beneficial proc chance
		stat( fx$PROC_DET )		// Detrimental proc chance
	])); 
}
#include "got/classes/packages/got FXCompiler.lsl"
