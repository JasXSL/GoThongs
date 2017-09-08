
#include "got/_core.lsl"
integer TEAM = TEAM_PC;




list THONG_VISUALS;         // [id, (arr)data]
list MANA_REGEN_MULTI;      // [id, (float)multiplier]
list MANA_COST_MULTI;  // [id, (float)multiplier]
list AROUSAL_MULTI;	// [id, (float)multiplier]
list PAIN_MULTI;		// [id, (float)multiplier]
list SPELL_DMG_DONE_MOD;	// [id, (int)index, (float)multiplier]

list SPELL_MANACOST_MULTI;	// [id, (int)index, (float)multiplier]
list SPELL_CASTTIME_MULTI;	// [id, (int)index, (float)multiplier]
list SPELL_COOLDOWN_MULTI;	// [id, (int)index, (float)multiplier]
list SPELL_HIGHLIGHTS; 		// [id, (int)index]
list HEAL_DONE_MOD;			// [id, (float)multi] - Healing done (need to mutliply by h in the spell)
list BEFUDDLE; 				// [id, (float)chanceMulti]
list CONVERSIONS;			// [id, (arr)conversions]
list HP_ADD;				// [id, (float)add]
list GRAVITY;				// [id, (float)set]

integer current_visual;

runEffect(integer pid, integer pflags, string pname, string fxobjs, int timesnap, key caster){
	integer stacks = getStacks(pid, FALSE);
	
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
		
		else if(t == fx$SPAWN_MONSTER){
			
			vector rot = llRot2Euler(llGetRot());
			rotation r = llEuler2Rot(<0,0,rot.z>);
			list ray = llCastRay(llGetPos(), llGetPos()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
			vector pos = llList2Vector(ray, 1);
			if(pos == ZERO_VECTOR){
				vector ascale = llGetAgentSize(llGetOwner());
				pos = llGetPos()-<0,0,ascale.z/2>;
			}

			Spawner$spawnInt(l2s(fx, 1), pos+((vector)l2s(fx, 2)*r), llEuler2Rot(<0,PI_BY_TWO,0>)*(rotation)l2s(fx,3)*r, l2s(fx,4), FALSE, TRUE, "");
			
		}

		else if(t == fx$PUSH){
			vector z = llGetVel();
			vector apply = (vector)l2s(fx, 1)*llGetMass();//-<0,0,z.z>;
			llApplyImpulse(apply, FALSE);
		}
		
		else if(t == fx$HITFX){
            ThongMan$hit(l2s(fx,1));
            // Also flags and stuff here
            integer flags = llList2Integer(fx,2);
            if(~flags&fxhfFlag$NOSOUND){
				list sounds = (["71224087-bce9-d63f-f582-ccba8bb21e85", "b78573df-e593-b717-301c-ed55e8ad4916", "1d724698-4223-d381-f38c-d9c86986684d"]);
                llTriggerSound(randElem(sounds), .5+llFrand(.5));
            }
            if(~flags&fxhfFlag$NOANIM)
                AnimHandler$anim(mkarr((["got_takehit_highpri", "got_takehit"])), TRUE, 0, 0);
			raiseEvent(FXCEvt$hitFX, mkarr(llDeleteSubList(fx,0,0)));
        }
        else if(t == fx$HUD_TEXT)
            runMethod((str)LINK_ROOT, "got Alert", AlertMethod$freetext, llList2List(fx, 1, -1), TNN);
        
        else if(t == fx$ANIM)AnimHandler$anim(llList2String(fx, 1), llList2Integer(fx,2), 0, 0);
 
        else if(t == fx$INTERRUPT)
            SpellMan$interrupt(l2i(fx, 1));
        
        else if(t == fx$RESET_COOLDOWNS){
            SpellMan$resetCooldowns(l2i(fx,1));
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
    
    if(resource_updates){
		// Send updated hp/mana and stuff
		Status$batchUpdateResources(resource_updates);
	}
}

addEffect(integer pid, integer pflags, str pname, string fxobjs, int timesnap, float duration){
    integer stacks = getStacks(pid, FALSE);
    list fxs = llJson2List(fxobjs);

    while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        
        // These are defined in got FXCompiler header script, shared if statements such as flags and multipliers
		dumpFxAddsShared()
		
		// These are PC specific
		
        else if(t == fx$THONG_VISUAL)
            THONG_VISUALS = manageList(FALSE, THONG_VISUALS, [pid, mkarr(llList2List(fx, 1, -1))]);

		else if(t == fx$ANIM){
			AnimHandler$anim(llList2String(fx, 1), llList2Integer(fx,2), 0, 0);
        }
        else if(t == fx$MANA_REGEN_MULTI)
            MANA_REGEN_MULTI = manageList(FALSE, MANA_REGEN_MULTI, [pid,llList2Float(fx, 1)]);
        
        else if(t == fx$MANA_COST_MULTI)
            MANA_COST_MULTI = manageList(FALSE, MANA_COST_MULTI, [pid,llList2Float(fx, 1)]);
        
		else if(t == fx$AROUSAL_MULTI)
            AROUSAL_MULTI = manageList(FALSE, AROUSAL_MULTI, [pid,llList2Float(fx, 1)]);
			
        else if(t == fx$PAIN_MULTI)
            PAIN_MULTI = manageList(FALSE, PAIN_MULTI, [pid,llList2Float(fx, 1)]);
        
		else if(t == fx$GRAVITY)
            GRAVITY = manageList(FALSE, GRAVITY, [pid,llList2Float(fx, 1)]);
        
		
		
		else if(t == fx$SPELL_DMG_DONE_MOD){
			SPELL_DMG_DONE_MOD = manageList(FALSE, SPELL_DMG_DONE_MOD, [pid,llList2Integer(fx,1), llList2Float(fx, 2)]);
        }
        else if(t == fx$FORCE_SIT){
            string out = "@sit:"+llList2String(fx, 1)+"=force";
            if(llList2Integer(fx, 2))out+=",unsit=n";

            llOwnerSay(out);
        }
		else if(t == fx$SPELL_MANACOST_MULTI)
			SPELL_MANACOST_MULTI = manageList(FALSE, SPELL_MANACOST_MULTI, [pid,llList2Integer(fx,1), llList2Float(fx, 2)]);
		else if(t == fx$SPELL_CASTTIME_MULTI)
			SPELL_CASTTIME_MULTI = manageList(FALSE, SPELL_CASTTIME_MULTI, [pid,llList2Integer(fx,1), llList2Float(fx, 2)]);
		else if(t == fx$SPELL_COOLDOWN_MULTI)
			SPELL_COOLDOWN_MULTI = manageList(FALSE, SPELL_COOLDOWN_MULTI, [pid,llList2Integer(fx,1), llList2Float(fx, 2)]);
		else if(t == fx$HEALING_DONE_MULTI)
			HEAL_DONE_MOD = manageList(FALSE, HEAL_DONE_MOD, [pid, llList2Float(fx, 1)]);
		
		else if(t == fx$SPELL_HIGHLIGHT){
			SPELL_HIGHLIGHTS = manageList(FALSE, SPELL_HIGHLIGHTS, [pid,llList2Integer(fx,1)]);
		}
		
		else if(t == fx$ATTACH){
			Rape$addFXAttachments(llList2List(fx, 1, -1));
		}
		
		else if(t == fx$BEFUDDLE){
			BEFUDDLE = manageList(FALSE, BEFUDDLE, [pid, l2f(fx, 1)]);
		}
		else if(t == fx$HP_ADD)
			HP_ADD = manageList(FALSE, HP_ADD, [pid, l2f(fx, 1)]);
		
		
		
		else if(t == fx$CONVERSION)
			CONVERSIONS = manageList(FALSE, CONVERSIONS, [pid,mkarr(llDeleteSubList(fx, 0, 0))]);
		else if(t == fx$LTB)
			BuffVis$add(pid, l2s(fx, 1), l2s(fx,2));
    }

}

remEffect(integer pid, integer pflags, string pname, string fxobjs, integer timesnap, integer overwrite){
    integer stacks = getStacks(pid, FALSE);
	
    list fxs = llJson2List(fxobjs);
    
	while(llGetListLength(fxs)){
        list fx = llJson2List(llList2String(fxs,0));
        fxs = llDeleteSubList(fxs,0,0);
        integer t = llList2Integer(fx, 0);
        
		// These are things that should not be run if the FX was overwritten, only if it was removed
		if(!overwrite){
			if(t == fx$ANIM)AnimHandler$anim(llList2String(fx, 1), !llList2Integer(fx,2), 0, 0);
		}
		
		
		// Shared
		dumpFxRemsShared()
		// These are PC specific
		else if(t == fx$THONG_VISUAL)
            THONG_VISUALS = manageList(TRUE, THONG_VISUALS, [pid, 0]);
		else if(t == fx$MANA_REGEN_MULTI)
			MANA_REGEN_MULTI = manageList(TRUE, MANA_REGEN_MULTI, [pid, 0]);
        else if(t == fx$MANA_COST_MULTI)
            MANA_COST_MULTI = manageList(TRUE, MANA_COST_MULTI, [pid, 0]);
        else if(t == fx$AROUSAL_MULTI)
            AROUSAL_MULTI = manageList(TRUE, AROUSAL_MULTI, [pid, 0]);
        else if(t == fx$PAIN_MULTI)
            PAIN_MULTI = manageList(TRUE, PAIN_MULTI, [pid, 0]);
        else if(t == fx$SPELL_DMG_DONE_MOD)
			SPELL_DMG_DONE_MOD = manageList(TRUE, SPELL_DMG_DONE_MOD, [pid, 0, 0]);
		
        else if(t == fx$FORCE_SIT)llOwnerSay("@unsit=y,unsit=force");
		else if(t == fx$PULL){
			raiseEvent(FXCEvt$pullEnd, "");
			llStopMoveToTarget();
		}
		else if(t == fx$ATTACH)
			Rape$remFXAttachments(llList2List(fx, 1, -1));
		else if(t == fx$SPELL_MANACOST_MULTI) 
			SPELL_MANACOST_MULTI = manageList(TRUE, SPELL_MANACOST_MULTI, [pid, 0, 0]); 
		else if(t == fx$SPELL_CASTTIME_MULTI) 
			SPELL_CASTTIME_MULTI = manageList(TRUE, SPELL_CASTTIME_MULTI, [pid, 0, 0]); 
		else if(t == fx$SPELL_COOLDOWN_MULTI) 
			SPELL_COOLDOWN_MULTI = manageList(TRUE, SPELL_COOLDOWN_MULTI, [pid, 0, 0]); 
		else if(t == fx$SPELL_HIGHLIGHT){
			SPELL_HIGHLIGHTS = manageList(TRUE, SPELL_HIGHLIGHTS, [pid,0]);
		}
		else if(t == fx$HEALING_DONE_MULTI)
			HEAL_DONE_MOD = manageList(TRUE, HEAL_DONE_MOD, [pid, 0]);
		else if(t == fx$GRAVITY)
			GRAVITY = manageList(TRUE, GRAVITY, [pid, 0]);
		
		else if(t == fx$BEFUDDLE){
			BEFUDDLE = manageList(TRUE, BEFUDDLE, [pid, 0]);
		}
		
		else if(t == fx$CONVERSION)
			CONVERSIONS = manageList(TRUE, CONVERSIONS, [pid,0]);
		else if(t == fx$LTB)
			BuffVis$rem(pid);
		else if(t == fx$HP_ADD)
			HP_ADD = manageList(TRUE, HP_ADD, [pid, 0]);
		
    }
}

// Compiles a list of SPELL_* for indexed spells, IE. Not spell_dmg_taken_multi
list spellModCompile(list input){
	integer i;
	list out = [1,1,1,1,1];		// Needs to match nr spells
	for(i=0; i<llGetListLength(input); i+=3){
        integer n = llList2Integer(input, i+1);	// nr Index
		float cur = llList2Float(out, n);					// current at index
		integer stacks = getStacks(llList2Integer(input, i), FALSE);
		cur *= (llList2Float(input, i+2)*stacks+1);
		out = llListReplaceList(out, [cur], n, n);
    }
	return out;
}

string cache_spellmods;

updateGame(){
    integer visual = llList2Integer(THONG_VISUALS, -2);
    
    integer i;
    
    
    if(current_visual != visual){
        current_visual = visual;
        ThongMan$fxVisual(llJson2List(llList2String(THONG_VISUALS, -1)));
    }
    
	
    
	// Multiplicative
    float ddm = compileList(DAMAGE_DONE_MULTI, 0, 1, 2, TRUE);
    
	// Multiplicative
    float dtm = compileList(DAMAGE_TAKEN_MULTI, 0, 1, 2, TRUE);
    
	// Additive
    float dodge = compileList(DODGE_ADD, 0, 1, 2, FALSE);
    
	// Multiplicative
    float ctm = compileList(CASTTIME_MULTI, 0, 1, 2, TRUE);
    
	// Multiplicative
    float cdm = compileList(COOLDOWN_MULTI, 0, 1, 2, TRUE);
    
	// Multiplicative
    float regen = compileList(MANA_REGEN_MULTI, 0, 1, 2, TRUE);
    
	// Multiplicative
    float mcm = compileList(MANA_COST_MULTI, 0, 1, 2, TRUE);
	
	// Additive
    float cm = compileList(CRIT_ADD, 0, 1, 2, FALSE);
    if(cm<0)cm = 0;
	
	// Multiplicative
	float pm = compileList(PAIN_MULTI, 0, 1, 2, TRUE);
	
	// Multiplicative
	float am = compileList(AROUSAL_MULTI, 0, 1, 2, TRUE);
	
	// Healing taken mod, multi
	float htm = compileList(HEAL_MOD, 0, 1, 2, TRUE);
	
	// Healing done mod, multi
	float hdm = compileList(HEAL_DONE_MOD, 0, 1, 2, TRUE);
	
	// Befuddle mod, multi
	float befuddle = compileList(BEFUDDLE, 0, 1, 2, TRUE);
	
	float hp_add = compileList(HP_ADD, 0,1,2,FALSE);
	
	integer team = -1;
	if(TEAM_MOD)
		team = l2i(TEAM_MOD, -1);
		
	float grav = 0;
	if(GRAVITY)
		grav = l2f(GRAVITY, -1);
	llSetBuoyancy(grav);
	
    // Compile lists of spell specific modifiers
    list spdmtm; // SPELL_DMG_TAKEN_MOD - [(str)spellName, (float)dmgmod]
    for(i=0; i<llGetListLength(SPELL_DMG_TAKEN_MOD); i+=3){
		integer stacks = getStacks(llList2Integer(SPELL_DMG_TAKEN_MOD, i), FALSE);
        string n = llList2String(SPELL_DMG_TAKEN_MOD, i+1);
        integer pos = llListFindList(spdmtm, [n]);
        if(~pos)spdmtm = llListReplaceList(spdmtm, [llList2Float(spdmtm, pos+1)+llList2Float(SPELL_DMG_TAKEN_MOD, i+2)*stacks], pos+1, pos+1);
        else spdmtm+=[n, 1+llList2Float(SPELL_DMG_TAKEN_MOD, i+2)*stacks];
    }
	
    list spdmdm = spellModCompile(SPELL_DMG_DONE_MOD); 		// SPELL_DMG_DONE_MOD - [(float)rest, (float)abil1...]
    list spmcm = spellModCompile(SPELL_MANACOST_MULTI); 	// 
	list spctm = spellModCompile(SPELL_CASTTIME_MULTI); 	// 
	list spcdm = spellModCompile(SPELL_COOLDOWN_MULTI); 	// 
	
	string out = llList2Json(JSON_ARRAY, [
		mkarr(spdmdm),
		mkarr(spmcm),
		mkarr(spctm),
		mkarr(spcdm)
	]);
	//qd(out);
	
	if(out != cache_spellmods){
		cache_spellmods = out;
		raiseEvent(FXCEvt$spellMultipliers, out);
	}
	
	list conv;
	for(i=0; i<count(CONVERSIONS); i+=2)
		conv+= llJson2List(l2s(CONVERSIONS, i+1));
	
	//qd("Out: "+mkarr(spdmdm));
	
    Status$spellModifiers(spdmtm); 
	
	integer hlt;
	for(i=0; i<count(SPELL_HIGHLIGHTS); i+=2)
		hlt = hlt | (int)llPow(2,llList2Integer(SPELL_HIGHLIGHTS, i+1));
	
	// These are the FXCUpd$ values
	Passives$setActive(([ 
		CACHE_FLAGS, 		// 00 FLAGS
		f2i(regen), 		// 01 MANA_REGEN
		f2i(ddm), 			// 02 DAMAGE_DONE
		f2i(dtm), 			// 03 DAMAGE_TAKEN
		f2i(dodge), 		// 04 DODGE
		f2i(ctm), 			// 05 CASTTIME
		f2i(cdm), 			// 06 COOLDOWN
		f2i(mcm), 			// 07 MANA_COST
		f2i(cm), 			// 08 CRIT
		f2i(pm), 			// 09 PAIN_MULTI
		f2i(am),			// 10 AROUSAL_MULTI
		// These don't use f2i for now since these have no active effects, but if you add active effects at some point you should f2i them here and then i2f them in got Passives
		f2i(hp_add),		// 11 HP_ADD
		1,					// 12 HP_MULTI
		0,					// 13 MANA_ADD
		1,					// 14 MANA_MULTI
		0,					// 15 AROUSAL_ADD
		1,					// 16 AROUSAL_MULTI
		1,					// 17 PAIN_ADD
		1,					// 18 PAIN_MULTI
		1,					// 19 HP_REGEN
		1,					// 20 PAIN_REGEN
		1,					// 21 AROUSAL_REGEN
		hlt,				// 22 HIGHLIGHT_FLAGS
		f2i(htm),			// 23 Healing taken mod
		1,					// 24 Movespeed (NPC only)
		f2i(hdm),			// 25 Healing done mod
		team,				// 26 Team override
		f2i(befuddle),		// 27 Befuddle
		mkarr(conv),		// 28 Conversions
		f2i(1.0),			// 29 Sprint fade
		f2i(1.0)			// 30 Backstab mul
	])); 
}
#include "got/classes/packages/got FXCompiler.lsl"
