// Head
#if FXCOMPILER_SECTION == 0

// ID tag is the first 8 characters of the UUID
integer current_visual;
list thongVis;	// PIX of current effects that include thongMan visuals

#endif


// Run
#if FXCOMPILER_SECTION == 1

	list resource_updates; // Updates for HP/Mana etc
	int fxFlags = (int)fx$getDurEffect(fxf$SET_FLAG);

	// Shared between PC/NPC, defined in got FXCompiler header file
	dumpFxInstants()
	
	else if( 
		t == fx$DAMAGE_DURABILITY ||
		t == fx$AROUSE ||
		t == fx$PAIN ||
		t == fx$MANA
	){
		
		int f = l2i(fx, 1);
		int st = stacks;
		if( f&SMAFlag$NO_STACK_MULTI )
			st = 1;
		if(t == fx$DAMAGE_DURABILITY)
			resource_updates += SMBUR$buildDurability(-l2f(fx,0)*st, pname, f, l2f(fx, 2));
		else if(t == fx$AROUSE)
			resource_updates += SMBUR$buildArousal(l2f(fx,0)*st, pname, f);
		else if(t == fx$PAIN)
			resource_updates += SMBUR$buildPain(l2f(fx,0)*st, pname, f);
		else if(t == fx$MANA)
			resource_updates += SMBUR$buildMana(l2f(fx,0)*st, pname, f);
			
	}
	
	else if( t == fx$CLASS_VIS ){
		gotClassAtt$spellStart(l2s(fx,0), l2f(fx, 1), l2s(fx, 2));
	}
	
	else if( t == fx$REDUCE_CD ){
		SpellMan$reduceCD(fx);
	}
	
	else if( t == fx$LOOK_AT || t == fx$ROT_TOWARDS ){

		float r = l2f(fx, 0);
		vector vec = (vector)l2s(fx, 0);
		if( l2k(fx, 0) ){
			vec = prPos(l2k(fx, 0));
		}
		
		if( vec ){
			vec = vec-llGetRootPosition();
			vector fwd = vec * <0.0, 0.0, -llSin(PI_BY_TWO * 0.5), llCos(PI_BY_TWO * 0.5)>;
			fwd.z = 0.0;
			fwd = llVecNorm(fwd);
			vector left = fwd * <0.0, 0.0, llSin(PI_BY_TWO * 0.5), llCos(PI_BY_TWO * 0.5)>;
			rotation rot = llAxes2Rot(fwd, left, fwd % left);
			vector euler = -llRot2Euler(rot);
			r = euler.z;
		}
		llOwnerSay("@setrot:"+(string)r+"=force");
		
	}
	
	else if( t == fx$DAMAGE_ARMOR )
		Status$damageArmor(LINK_ROOT, l2i(fx, 0));

	else if( t == fx$PUSH ){
		vector z = llGetVel();
		vector apply = (vector)l2s(fx, 0)*llGetMass();//-<0,0,z.z>;
		llApplyImpulse(apply, FALSE);
	}
	
	else if( t == fx$HITFX ){
		
		// This is handled in rootaux
		str color = l2s(fx,0);
		int flags = l2i(fx,1);
		raiseEvent(FXCEvt$hitFX, mkarr((list)color + flags + caster));
		
	}
	else if( t == fx$HUD_TEXT )
		runMethod((str)LINK_ROOT, "got Alert", AlertMethod$freetext, fx, TNN);
	
	else if( t == fx$ANIM && !l2i(fx, 2) )
		AnimHandler$anim(l2s(fx, 0), l2i(fx,1), 0, l2f(fx,3), l2i(fx, 2));

	else if( t == fx$INTERRUPT )
		SpellMan$interrupt(l2i(fx, 0));
	
	else if( t == fx$RESET_COOLDOWNS ){
		SpellMan$resetCooldowns(l2i(fx,0), l2i(fx,1));
	}
	else if( t == fx$FORCE_SIT ){
	
		string out = "@sit:"+l2s(fx,0)+"=force";
		if( !l2i(fx, 1) )
			out+=",unsit=n";
		llOwnerSay(out);
		
	}
	else if( t == fx$PARTICLES ){
		ThongMan$particles(l2f(fx,0), llList2Integer(fx,1), llList2String(fx,2));
	}
	else if( t == fx$PULL && ~fxFlags&fx$F_NO_PULL ){
	
		vector pos = (vector)l2s(fx, 0);
		if( pos == ZERO_VECTOR ){
		
			raiseEvent(FXCEvt$pullEnd, "");
			llStopMoveToTarget();
			
		}else{
		
			raiseEvent(FXCEvt$pullStart, "");
			llSleep(.1);
			int fromSender = l2i(fx, 2);
			float speed = l2f(fx, 1);
			if( fromSender ){
			
				key c = caster;
				if( prAttachPoint(c) )
					c = llGetOwnerKey(c);
				vector r = llGetRootPosition();
				vector pp = prPos(c);
				pp.z = 0;
				rotation between = llRotBetween(<1,0,0>, llVecNorm(<r.x, r.y, 0>-pp));
				pos *= between;
				pos += r;
				
			}
			
			llMoveToTarget(pos, speed);
		}
		
	}
	else if( t == fx$SPAWN_VFX ){
		SpellFX$spawnInstant(mkarr(fx), llGetOwner());
	}
	else if( t == fx$ALERT )
		Alert$freetext(LINK_ROOT, l2s(fx,0), l2i(fx,1), l2i(fx, 2));
	else if( t == fx$CUBETASKS ){
		RLV$cubeTask(fx);
	}
	else if( t == fx$REFRESH_SPRINT ){
	
		if( l2f(fx, 0) == 0.0 )
			RLV$setSprintPercent(LINK_ROOT, 1);
		else
			RLV$addSprint(l2f(fx, 0));
			
	}
		
    // Send updated hp/mana and stuff
    if( resource_updates ){
		Status$batchUpdateResources(caster, resource_updates);
	}

#endif	


// Add
#if FXCOMPILER_SECTION == 2

    

	
	// These are PC specific
	if( t == fx$ANIM ){
		AnimHandler$anim(l2s(fx, 0), l2i(fx,1), 0, 0, l2i(fx,2));
	}
	else if( t == fx$THONG_VISUAL ){
		
		integer pos = llListFindList(thongVis, (list)pix);
		if( pos == -1 ){
		
			thongVis += pix;
			ThongMan$fxVisual(fx);
			
		}
		
	}
	
	else if( t == fx$CLASS_VIS ){
		gotClassAtt$spellStart(l2s(fx,0), l2f(fx, 1), l2s(fx, 2));
	}
	else if( t == fx$ATTACH ){
		Rape$addFXAttachments(fx);
	}
	else if( t == fx$STANCE ){
		WeaponLoader$fxStance(l2s(fx, 0), TRUE);
	}
	else if( t == fx$FORCE_SIT ){
	
		string out = "@sit:"+l2s(fx, 0)+"=force";
		if( l2i(fx, 1) )
			out+=",unsit=n";
		llOwnerSay(out);
		
	}
	else if( t == fx$LTB ){
		// Convert table back to an int
		BuffVis$add(llOrd(table, 0), l2s(fx, 0), l2s(fx,1));
	}


#endif

// Delete
#if FXCOMPILER_SECTION == 3

// Note: duration cannot be relied on here
	
	if( t == fx$ANIM ){
		AnimHandler$anim(l2s(fx, 0), !l2i(fx,1), 0, 0, 0);
	}
	else if( t == fx$CLASS_VIS ){
		gotClassAtt$spellEnd(l2s(fx,0), -1, 0);
	}
	else if( t == fx$FORCE_SIT ){
		llOwnerSay("@unsit=y,unsit=force");
	}
	else if( t == fx$PULL ){
		raiseEvent(FXCEvt$pullEnd, "");
		llStopMoveToTarget();
	}
	else if( t == fx$STANCE ){
		WeaponLoader$fxStance(l2s(fx, 0), FALSE);
	}
	else if(t == fx$LTB){
		BuffVis$rem(llOrd(table, 0));
	}
	else if( t == fx$ATTACH )
		Rape$remFXAttachments(fx);
	else if( t == fx$THONG_VISUAL ){
		
		integer pos = llListFindList(thongVis, (list)pix);
		if( ~pos )
			thongVis = llDeleteSubList(thongVis, pos, pos);
		list set;
		if( count(thongVis) ){
			// Need to get fx
			str tc = getFxPackageTableByIndex(l2i(thongVis, -1));
			list sub = llJson2List(db4$fget(table, fxPackage$FXOBJS));
			integer _s;
			for(; _s < count(sub); ++_s ){
				list _sd = llJson2List(l2s(sub, _s));
				if( l2i(_sd, 0) == fx$THONG_VISUAL )
					set = llDeleteSubList(_sd, 0, 0);
			}
		}
		ThongMan$fxVisual(set);
		
	}
	
#endif


