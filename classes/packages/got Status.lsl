#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#define USE_DB4
#include "got/_core.lsl"

#define saveFlags() \
if( SFp != SF ){ \
	db4$freplace(gotTable$status, gotTable$status$flags, SF); \
	raiseEvent(StatusEvt$flags, llList2Json(JSON_ARRAY, [SF, SFp])); \
	SFp = SF; \
}	

// makes sure max is never lower than 1
float maxResource( float val ){
	if( val < 1 )
		return 1;
	return val;
}
#define maxHP() maxResource((DEFAULT_DURABILITY+fmMHn)*fmMH)
#define maxMana() maxResource((DEFAULT_MANA+fmMMn)*fmMM)
#define maxArousal() maxResource((DEFAULT_AROUSAL+fmMAn)*fmMA)
#define maxPain() maxResource((DEFAULT_PAIN+fmMPn)*fmMP)

#define TIMER_REGEN "a"
#define TIMER_BREAKFREE "b"
#define TIMER_INVUL "c"
#define TIMER_CLIMB_ROOT "d"
#define TIMER_COMBAT "e"
#define TIMER_COOP_BREAKFREE "f"
#define TIMER_MOUSELOOK "g"

#define TIME_SOFTLOCK 4		// Arousal/Pain softlock lasts 3 sec

#define updateCombatTimer() multiTimer([TIMER_COMBAT, 0, StatusConst$COMBAT_DURATION, FALSE])

integer BFL = 1;
#define BFL_CLIMB_ROOT 4		// Ended climb, root for a bit
#define BFL_STATUS_QUEUE 0x10		// Send status on timeout
#define BFL_STATUS_SENT 0x20		// Status sent
#define BFL_AVAILABLE_BREAKFREE 0x40
#define BFL_CHALLENGE_MODE 0x80
#define BFL_QTE 0x100			// In a quicktime event
#define BFL_SOFTLOCK_AROUSAL 0x200	// Arousal will not regenerate
#define BFL_SOFTLOCK_PAIN 0x400		// Pain will not regenerate
#define BFL_NO_BREAKFREE 0x800		// Not allowed to use the revive

int ARMOR = Status$FULL_ARMOR;				// Full armor
int A_ARM = 0;						// Currently targeted armor slot. Shuffled each armor break.

// Cache
integer PC;							// Pre constants

integer TEAM_D = TEAM_PC;			// This is the team set by the HUD itself, can be overridden by fxT
integer TEAM = TEAM_PC; 			// This is team out

// Constant
integer LV = 1;	// Player level

// Effects
integer SF = 0; 	// Status flags
integer SFp = 0;	// Sttus flags pre

int CF;			// Spell cast flags
integer GF;	// Genital flags

// FX
integer FXF = 0;				// FX flags
list fmDT;						// [int playerID, float amount] Damage taken modifier. 0 (index 1 for value) is from ALL sources.
float fmDTF = 1.0;				// Frontal damage taken modifier
float fmDTB = 1.0;				// Rear damage taken modifier
float fmMR = 1;					// mana regen
float fmAT = 1;					// Arousal taken
float fmPT = 1;					// Pain taken
float paHT = 1;					// Healing taken from passives
list fmHT;						// healing taken from actives [int playerID, float amount] From ACTIVE. 0 is from all sourcea and the all source value is always index 1
float fmHR = 1;					// HP regen
float cfmHR = 0.0;				// Combat HP regen multiplier
float fmPR = 1;					// Pain regen
float fmAR = 1;					// Arousal regen
float fmAC = 1;					// Armor damage taken from damage multiplier
float fmA = 1;					// Armor damage taken multiplier

float fmMH = 1;					// max health multiplier
integer fmMHn = 0;				// Max health adder
float fmMM = 1;					// max mana multiplier
integer fmMMn = 0;				// max mana adder
float fmMA = 1;					// max arousal multi
integer fmMAn = 0;				// max arousal adder
float fmMP = 1;					// max pain multiplier
integer fmMPn = 0;				// max pain adder


list fxC; // Conversions, see got FXCompiler.lsl

integer fxT = -1;	// FX team

key rLV;	// root level
#define isChallenge() (llKey2Name(rLV) != "" && BFL&BFL_CHALLENGE_MODE)

list SDTM; 	// Spell damage taken mod [(int)caster_(str)packageName, float multiplier] Caster of 0 packages by name from any source instead of a particular sender

// Resources
float HP = DEFAULT_DURABILITY;
float MANA = DEFAULT_MANA;
float AROUSAL = 0; 
float PAIN = 0;

list OST; 				// Output status to

int RO;			// Thong role
int US;			// Usersettings from bridge, see BSUD$SETTING_FLAGS
int TI;			// Thong class ID		
int TS;			// Thong spec index

integer DIF = 1;	// 
// old ((1.+(llPow(2, (float)DIF*.7)+DIF*3)*0.1)-0.462)

// Difficulty damage modifier
#define difMod() Status$difficultyDamageTakenModifier(DIF)


// Runs conversion
// Returns conversion effects of a FXC$CONVERSION_* type
float rCnv( integer ty, float am ){

	integer i; float out = 1;
	integer isDetrimental = (
		(am < 0 && ~llListFindList([FXC$CONVERSION_HP, FXC$CONVERSION_MANA], [ty])) ||
		(am > 0 && ~llListFindList([FXC$CONVERSION_PAIN, FXC$CONVERSION_AROUSAL], [ty]))
	);
	
	list conversions = [FXC$CONVERSION_HP,FXC$CONVERSION_MANA,FXC$CONVERSION_AROUSAL,FXC$CONVERSION_PAIN];
	list resources = [0,0,0,0];
	
	
	for(; i<count(fxC); ++i){
	
		integer conv = l2i(fxC, i);
		integer onDetri = !(FXC$conversionNonDetrimental(conv));
		
		if( 
			FXC$conversionFrom(conv) == ty && 
			onDetri == isDetrimental
		){
			
			float mag = FXC$conversionPerc(conv)/100.;
			integer b = FXC$conversionTo(conv);
			if(!FXC$conversionDontReduce(conv))
				out*= 1-mag;
			
			float amt = am*mag*FXC$conversionMultiplier(conv);
			
			// Flips amt
			if( FXC$conversionInverse(conv) )
				amt = -amt;
			
			integer ndx = llListFindList(conversions, [b]);
			resources = llListReplaceList(resources, [l2f(resources, ndx)+amt], ndx, ndx);
			
		}
	}
	
	if(l2f(resources, 0))
		aHP(l2f(resources,0), "", 0, FALSE, TRUE, "", 0);
	if(l2f(resources, 1))
		aMP(l2f(resources, 1), "", 0, TRUE, "");
	if(l2f(resources, 2))
		aAR(-l2f(resources, 2), "", 0, TRUE, "");
	if(l2f(resources, 3))
		aPP(-l2f(resources, 3), "", 0, TRUE, "");	
	
	return out;
}

// force lets you update the FX regardless of change
dArm( int amount, int force ){
	
	// Already stripped
	if( !ARMOR && amount > 0 && !force )
		return;
	
	int pre = ARMOR;
			
	while( amount != 0 ){
	
		int a = Status$getArmorVal(ARMOR, A_ARM);
		a -= amount;
		amount = 0;
		
		if( a <= 0 || a >= 50 ){
			
			amount = -a;
			if( a <= 0 )
				a = 0;
			else if( a >= 50 ){
				amount = -(a-50);
				a = 50;
			}
			Status$setArmorVal(ARMOR, A_ARM, a);
		
			// Randomize a new A_ARM
			list v; int i;
			for(; i<4; ++i ){	// 4 here because groin is last
			
				int n = Status$getArmorVal(ARMOR, i);
				if( ((n && a == 0) || (!n && a == 50)) && i != A_ARM )
					v += i;
					
			}
			
			A_ARM = l2i(v, llFloor(llFrand(count(v))));
			
			// None are viable
			if( !count(v) ){
				// Default to groin
				A_ARM = Status$armorSlot$GROIN;
				// But if armor was all full, pick any other
				if( a >= 50 )
					A_ARM = llFloor(llFrand(4));
			}
			
			
			// Break
			if( ARMOR >= Status$FULL_ARMOR || ARMOR <= 0 )
				amount = 0;
			
		}
		else
			Status$setArmorVal(ARMOR, A_ARM, a);
		
		
	
	}
	
	// Raise event
	/*
	qd(mkarr((list)
		Status$getArmorVal(ARMOR, Status$armorSlot$HEAD) +
		Status$getArmorVal(ARMOR, Status$armorSlot$CHEST) +
		Status$getArmorVal(ARMOR, Status$armorSlot$ARMS) +
		Status$getArmorVal(ARMOR, Status$armorSlot$BOOTS) +
		Status$getArmorVal(ARMOR, Status$armorSlot$GROIN)
	));
	*/
	
	// Dressed
	if( (!pre || force) && ARMOR )
		Passives$rem(LINK_THIS, "_SS_");
	// Stripped
	else if( (pre || force) && !ARMOR )
		Passives$set(LINK_THIS, "_SS_", 0 + fx$F_SHOW_GENITALS, 0);
		
		
	raiseEvent(StatusEvt$armor, (str)ARMOR);
	
}

// Returns TRUE if changed
// Adds HP: amount, spellName, flags, isRegen, is conversion
aHP( float am, string sn, integer fl, integer re, integer iCnv, key atkr, float stl ){

    if( 
		SF&StatusFlag$dead || 
		(SF&StatusFlag$cutscene && am<0 && ~fl&SMAFlag$OVERRIDE_CINEMATIC) 
	)return;
		
    float pre = HP;
	am*=spdmtm(sn, atkr);
	
	// Percentage is ALWAYS unmodified
	if( fl&SMAFlag$IS_PERCENTAGE )
		am*=maxHP();
	// Not percentage and not regen
    else if( !re ){
	
		int evt = StatusEvt$hurt;
		// Damage
		if( am < 0 ){
		
			// Damage taken multiplier
			if( ~fl & SMAFlag$ABSOLUTE ){
			
				float fmdt = 1;
				integer pos = llListFindList(llList2ListStrided(fmDT, 0,-1,2), (list)0);
				if( ~pos )
					fmdt *= l2f(fmDT, pos*2+1);
				if( key2int(atkr) && ~(pos = llListFindList(llList2ListStrided(fmDT, 0,-1,2), (list)key2int(atkr))) )
					fmdt *= l2f(fmDT, pos*2+1);

				am*= 
					(1+((SF&StatusFlag$pained)/StatusFlag$pained)*.1)*
					(1+((SF&StatusFlag$aroused)/StatusFlag$aroused)*.1)*
					(1+(FXF&fx$F_SHOW_GENITALS && ~FXF&fx$F_NO_NUDE_PENALTY)*.2)*
					fmdt*
					difMod()
				;
				// Positional damage modifier
				if( (fmDTF != 1.0 || fmDTB != 1.0) && llKey2Name(atkr) != "" ){
					
					prAngX(atkr, ang)
					ang = llFabs(ang);
					if( ang < PI_BY_TWO )
						am *= fmDTF;
					else
						am *= fmDTB;
				
				}
				
			}

			updateCombatTimer();
			
			// Armor damage
			float mod = fmAC*fmA;
			if( mod > 0 && am < 0 ){
			
				float ARMOR_PER_DMG = 10.0/mod;	// every 10 points of damage reduces armor by 1
				int aDmg = 
					llFloor(llFabs(am)/ARMOR_PER_DMG) + 
					(llFrand(1) < llFabs((am-llFloor(am/ARMOR_PER_DMG))/ARMOR_PER_DMG))
				;
				dArm(aDmg, FALSE);
					
			}
			
			Status$handleLifeSteal(am, stl, atkr)
			
		}
		// Healing
		else{
			
			if( ~fl & SMAFlag$ABSOLUTE ){
			
				// Healing taken multiplier
				float fmht = 1;
				integer pos = llListFindList(llList2ListStrided(fmHT, 0,-1,2), (list)0);
				if( ~pos )
					fmht *= l2f(fmHT, pos*2+1);
				if( ~(pos = llListFindList(llList2ListStrided(fmHT, 0,-1,2), (list)key2int(atkr))) )
					fmht *= l2f(fmHT, pos*2+1);

				am*= fmht;
				
			}
			evt = StatusEvt$healed;
			
		}
		
		// Run conversions
		if( !iCnv && ~fl&SMAFlag$IS_PERCENTAGE )
			am *= rCnv(FXC$CONVERSION_HP, am);
			
		raiseEvent(evt, mkarr((list)am + sn));
			
		
    }

	
    HP += am;
	
	
    if( HP <= 0 ){
	
		HP = 0;
		
		// Death was prevented by fx$F_NO_DEATH
		if( FXF&fx$F_NO_DEATH ){
			if(pre != HP)
				raiseEvent(StatusEvt$death_hit, "");
		}
		else
			onDeath( "", atkr );
			
		
    }else{
	
        if( HP > maxHP() )
			HP = maxHP();
        
		if( SF&StatusFlag$dead ){
			// REVIVED HANDLED HERE
			
			// Send to level here, counts as a loss
			
            SF = SF&~StatusFlag$dead;
			SF = SF&~StatusFlag$raped;
			SF = SF&~StatusFlag$coopBreakfree;
			
			
            raiseEvent(StatusEvt$dead, 0);
			gotClassAtt$dead(0);
            Rape$end();
            AnimHandler$anim("got_loss", FALSE, 0, 0, 0);
			
			multiTimer([TIMER_BREAKFREE]);
			GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
			GUI$toggleQuit(FALSE);
			OS(TRUE);
			
        }
		
    }

}

// add MP
aMP( float am, string sn, integer flags, integer iCnv, key atkr ){

    if( 
		SF&StatusFlag$dead || 
		(SF&StatusFlag$cutscene && am<0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC) 
	)return;
	
	float in = am;
    float pre = MANA;
    am*=spdmtm(sn, atkr);
	if( flags&SMAFlag$IS_PERCENTAGE )
		am*=maxMana();
	// Run conversions
	else if( !iCnv )
		am*=rCnv(FXC$CONVERSION_MANA, am);

	MANA += am;
    if( MANA<=0 )
		MANA = 0;
    else if( MANA > maxMana() )
		MANA = maxMana();
		
	
}

// Add arousal
aAR( float am, string sn, integer flags, integer iCnv, key atkr ){

    if( 
		SF&StatusFlag$dead || 
		(SF&StatusFlag$cutscene && am>0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC) 
	)return;
	
    float pre = AROUSAL;    
    am*=spdmtm(sn, atkr);
	
	if( flags&SMAFlag$IS_PERCENTAGE )
		am*=maxArousal();
    else if( am>0 )
		am*=fmAT;
	
	if( flags&SMAFlag$SOFTLOCK ){
		
		BFL = BFL|BFL_SOFTLOCK_AROUSAL;
		multiTimer(["SL:"+(str)BFL_SOFTLOCK_AROUSAL, 0, TIME_SOFTLOCK, 0]);
		
	}
	
	// Run conversions
	if(!iCnv)
		am*=rCnv(FXC$CONVERSION_AROUSAL, am);
	
	
    AROUSAL += am;
    if(AROUSAL<=0)AROUSAL = 0;
    
	if( AROUSAL >= maxArousal() ){
	
        AROUSAL = maxArousal();
        if(~SF&StatusFlag$aroused){
            SF = SF|StatusFlag$aroused;
            llTriggerSound("d573fb93-d83e-c877-740f-6c28498668b8", 1);
        }
		
    }
	else if( SF&StatusFlag$aroused )
        SF = SF&~StatusFlag$aroused;
    
}

// add Pain
aPP( float am, string sn, integer flags, integer iCnv, key atkr ){
    
	if(
		SF&StatusFlag$dead || 
		(SF&StatusFlag$cutscene && am>0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC)
	)return;
	
    float pre = PAIN;
    am*=spdmtm(sn, atkr);
	if( flags&SMAFlag$IS_PERCENTAGE )
		am*=maxPain();
    else if( am>0 )
		am*=fmPT;
		
	if( flags&SMAFlag$SOFTLOCK ){
		
		BFL = BFL|BFL_SOFTLOCK_PAIN;
		multiTimer(["SL:"+(str)BFL_SOFTLOCK_PAIN, 0, TIME_SOFTLOCK, 0]);
		
	}
    
	// Run conversions
	if(!iCnv && ~flags&SMAFlag$IS_PERCENTAGE)
		am*=rCnv(FXC$CONVERSION_PAIN, am);	
	
	PAIN += am;
    if(PAIN<=0)PAIN = 0;
    
	if(PAIN >= maxPain()){
        PAIN = maxPain();
        if(~SF&StatusFlag$pained){
            SF = SF|StatusFlag$pained;
            llTriggerSound("4db10248-1e18-63d7-b9d5-01c6c0d8a880", 1);
        }
    }else if(SF&StatusFlag$pained)
        SF = SF&~StatusFlag$pained;

}

// sn = package name, c = caster
float spdmtm( string sn, key c ){

    if( !isset(sn) )
		return 1;
    
	integer cn = key2int(c);
	str check = (str)cn+"_"+sn;
	str checkAll = "0_"+sn;
		
	float out = 1;
		
	integer i;
    for( ; i<llGetListLength(SDTM); i += 2 ){
		
		str n = l2s(SDTM, i);
        if( n == check || n == checkAll ){
            
			float nr = llList2Float(SDTM, i+1);
            if( nr <0 )
				return 0;
            out*= nr;
			
        }
		
    }
	
	return out;
	
}




onDeath( string customAnim, key killer ){

	// Player dead already
	if(SF&StatusFlag$dead)
		return;
	
	// DEATH HANDLED HERE
	SpellMan$interrupt(TRUE);
	SF = SF|StatusFlag$dead;
	BFL = BFL&~BFL_AVAILABLE_BREAKFREE;
	
	gotLevelData$died(killer);
	
	OS( TRUE );
	raiseEvent(StatusEvt$dead, 1);
	FX$rem(FALSE, "", "", "", 0, FALSE, PF_DETRIMENTAL, 0, "", FALSE); // Remove all deterimental effects
	gotClassAtt$dead(1);
	AnimHandler$anim("got_loss", TRUE, 0, 0, 0);
		
	float dur = 20;
	if( isChallenge() && hud$root$numPlayers() > 1 ){
	
		dur = 90;
		/*
		if(SF & StatusFlag$boss_fight)
			dur = 0;
		else
		*/
		multiTimer([TIMER_COOP_BREAKFREE, 0, 20, FALSE]);
			
	}
	if( BFL&BFL_NO_BREAKFREE )
		dur = 0;
	
	if(dur){
	
		multiTimer([TIMER_BREAKFREE, 0, dur, FALSE]);
		GUI$toggleLoadingBar((string)LINK_ROOT, TRUE, dur);
		
	}
	
	// If customAnim is set, use that
	if( customAnim ){
		Bridge$fetchRape((str)LINK_ROOT, customAnim);
		return;
	}
	
	// Otherwise fetch one
	NPCInt$rapeMe();
	Rape$activateTemplate();
	

}

onEvt( string script, integer evt, list data ){

    if(script == "#ROOT"){
	
        if( evt == evt$TOUCH_START ){
            
			if( ~SF&StatusFlag$dead && ~SF&StatusFlag$raped )
				return;
            integer prim = llList2Integer(data, 0);
            string ln = llGetLinkName(prim);
            if( ln == "QUIT" )
                Status$fullregen();
            
        }
		
		else if (evt == RootEvt$level ){
		
			rLV = llList2String(data, 0);
			BFL = BFL&~BFL_CHALLENGE_MODE;
			if( l2i(data, 1) )
				BFL = BFL|BFL_CHALLENGE_MODE;
			
		}
		/*
		else if( evt == evt$BUTTON_PRESS && l2i(data, 0)&CONTROL_UP && BFL&BFL_AVAILABLE_BREAKFREE && SF&StatusFlag$dead )
			Status$fullregen();
		*/
        // Force update on targeting self, otherwise it requests
        else if( evt == RootEvt$targ && llList2Key(data, 0) == llGetOwner() )
			OS( TRUE );
			
    }
	
	else if(script == "got SpellMan"){
	
        if(evt == SpellManEvt$cast || evt == SpellManEvt$interrupted || evt == SpellManEvt$complete){
		
            if(evt == SpellManEvt$cast){
			
                // At least 1 sec to count as a cast
                if( i2f(llList2Float(data, 0))<1 )
					return;
                SF = SF|StatusFlag$casting;
				CF = l2i(data, 3);	// cast flags
				
            }
            else 
				SF = SF&~StatusFlag$casting;
				
            OS(TRUE);
			
        }
		
    }
	
	else if( script == "got Bridge" && evt == BridgeEvt$userDataChanged ){
		
		data = llJson2List(hud$bridge$userData());
		Status$setDifficulty(l2i(data, BSUD$DIFFICULTY));
		RO = l2i(data, BSUD$THONG_ROLE);
		US = l2i(data, BSUD$SETTING_FLAGS);
		integer ts = l2i(data, BSUD$THONG_SPEC);
		if( TS != ts ){
			gotClassAtt$spec(ts);
		}
		TI = l2i(data, BSUD$THONG_CLASS_ID);
		TS = ts;
		
		OS(TRUE);
		
	}
		
	else if( script == "got Bridge" && evt == BridgeEvt$spawningLevel && l2s(data, 0) == "FINISHED" ){
		dArm(-1000, FALSE);
		OS(FALSE);
	}
	
    else if( script == "got Rape" ){
	
        if( evt == RapeEvt$onStart || evt == RapeEvt$onEnd ){
		
            if( evt == RapeEvt$onStart ){
			
                SF = SF|StatusFlag$raped;
                OS(TRUE);
				
            }
            else if( SF&StatusFlag$raped ){
			
                SF = SF&~StatusFlag$raped; 
				Status$fullregen();
				
            }
            AnimHandler$anim("got_loss", FALSE, 0, 0, 0);
        }
    }
	
	else if( script == "jas Primswim" ){
	
		if( evt == PrimswimEvt$onWaterEnter )
			SF = SF | StatusFlag$swimming;
		else if( evt == PrimswimEvt$onWaterExit )
			SF = SF & ~StatusFlag$swimming;
		OS( TRUE );
		
	}
	
	else if( script == "jas Climb" ){
	
		if( evt == ClimbEvt$start )
			SF = SF|StatusFlag$climbing;
		else if( evt == ClimbEvt$end ){
		
			SF = SF&~StatusFlag$climbing;
			integer f = (int)j(llList2String(data,1), 0);
			if( f&StatusClimbFlag$root_at_end ){
				
				multiTimer([TIMER_CLIMB_ROOT, 0, 1.5, FALSE]);
				BFL = BFL|BFL_CLIMB_ROOT;
				
			}
			
		}
		OS(TRUE);
		
	}
	
	else if(script == "jas RLV" && (evt == RLVevt$cam_set || evt == RLVevt$cam_unset)){
		
		SF = SF&~StatusFlag$cutscene;
		if( evt == RLVevt$cam_set )
			SF = SF|StatusFlag$cutscene;
		OS(TRUE);
		
	}
	
	else if( script == "got Evts" && evt == EvtsEvt$QTE ){
	
		BFL = BFL&~BFL_QTE;
		if(l2i(data, 0))
			BFL = BFL|BFL_QTE;
		OS(TRUE);
		
	}
}



float cH;		// cache Health
float cM;		// cache Mana
float cA;		// cache Arousal
float cP;		// cache Pain
integer cC;		// cache Clothes (armor)
integer cD;		// Cache difficulty

// output stats
// ic = ignore cache check
OS( int ic ){ 

	if( !ic && cH == HP && cM == MANA && cA == AROUSAL && cP == PAIN && cC == ARMOR && SFp == SF && DIF == cD )
		return;

	//qd(mkarr((list)ic + (cH==HP) + (cM==MANA) + (cA==AROUSAL) + (cP==PAIN) + (cC==ARMOR) + (SFp==SF) + (DIF==cD)));
	
	cH = HP;
	cM = MANA;
	cA = AROUSAL;
	cP = PAIN;
	cC = ARMOR;
	cD = DIF;
	
	// Check team
	integer t = fxT;
	
	if(t == -1)
		t = TEAM_D;
		
	integer pre = TEAM;
	integer armTot = (ARMOR&0x3F)+((ARMOR>>6)&0x3F)+((ARMOR>>12)&0x3F)+((ARMOR>>18)&0x3F)+((ARMOR>>24)&0x3F);

	// GUI
	// Status is on cooldown and team has not changed
	if(BFL&BFL_STATUS_SENT && pre == t){
		// We need to output status once the timer fades
		BFL = BFL|BFL_STATUS_QUEUE;
	}
	else{
	
		// Needs to stay because of legacy reasons
		raiseEvent(StatusEvt$resources, llList2Json(JSON_ARRAY,[
			(int)HP, (int)maxHP(), 
			(int)MANA, (int)maxMana(), 
			(int)AROUSAL, (int)maxArousal(), 
			(int)PAIN,(int)maxPain(),
			HP/maxHP(),
			armTot	// Total points of armor
		]));
		
		BFL = BFL|BFL_STATUS_SENT;
		multiTimer(["_", 0, 0.25, FALSE]);
	}
	
	
		
	// int is 0000000 << 21 hp_perc, 0000000 << 14 mana_perc, 0000000 << 7 arousal_perc, 0000000 pain_perc 
	string data = (string)(
		(llRound(HP/maxHP()*127)<<21) |
		(llRound(MANA/maxMana()*127)<<14) |
		(llRound(AROUSAL/maxArousal()*127)<<7) |
		llRound(PAIN/maxPain()*127)
	);
	integer a = ARMOR;
	if( FXF & fx$F_SHOW_GENITALS )
		a = 0;
	llSetObjectDesc(
		data+"$"+
		(str)SF+"$"+
		(str)FXF+"$"+
		(str)(GF|(RO<<16)|(DIF<<18))+"$"+
		(str)t+"$"+
		(str)US+"$"+
		(str)a+"$"+
		(str)(TS|((TI&0xFFFF)<<4))
	);
	
	// Team change goes after because we need to update description first
	if( pre != t ){
		TEAM = t;
		
		db4$freplace(gotTable$status, gotTable$status$team, TEAM);
		raiseEvent(StatusEvt$team, TEAM);
		runOnDbPlayers(i, targ,
			
			if( targ == llGetOwner() )
				targ = (str)LINK_ROOT;
			Root$forceRefresh(targ, llGetKey());
			
		)
		
	}
	
	
    integer controls = CONTROL_ML_LBUTTON|CONTROL_UP|CONTROL_DOWN;
    if( FXF&fx$F_STUNNED || BFL&BFL_QTE || (SF&(StatusFlag$dead|StatusFlag$climbing|StatusFlag$loading|StatusFlag$cutscene) && ~SF&StatusFlag$raped) )
        controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
	
    if( FXF&fx$F_ROOTED || SF&StatusFlag$swimming || (SF&StatusFlag$casting && ~FXF&fx$F_CAST_WHILE_MOVING && ~CF&SpellMan$CASTABLE_WHILE_MOVING && StatusFlag$casting) || BFL&BFL_CLIMB_ROOT )
		controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT;
	
	if( FXF&fx$F_NOROT )
		controls = controls|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
	
    if( PC != controls ){
	
        PC = controls;
        Root$statusControls(controls);
		
    }
	
    saveFlags();

	// We also need to update LSD
	string tS = gotTable$status;
	db4$freplace(tS, gotTable$status$hp, HP);
	db4$freplace(tS, gotTable$status$mana, MANA);
	db4$freplace(tS, gotTable$status$arousal, AROUSAL);
	db4$freplace(tS, gotTable$status$pain, PAIN);
	db4$freplace(tS, gotTable$status$maxHp, maxHP());
	db4$freplace(tS, gotTable$status$maxMana, maxMana());
	db4$freplace(tS, gotTable$status$maxArousal, maxArousal());
	db4$freplace(tS, gotTable$status$maxPain, maxPain());
	db4$freplace(tS, gotTable$status$armor, armTot);
	
}

timerEvent( string id, string data ){
	
    if(id == TIMER_REGEN){
		integer inCombat = (SF&StatusFlags$combatLocked)>0;
		
		integer ainfo = llGetAgentInfo(llGetOwner());

		#define DEF_MANA_REGEN 0.025
		#define DEF_HP_REGEN 0.015
		#define DEF_PAIN_REGEN 0.05
		#define DEF_AROUSAL_REGEN 0.05
		
		integer n; // Used to only update if values have changed
			
		float add = (maxMana()*DEF_MANA_REGEN)*fmMR;
        if( add > 0 && MANA < maxMana() )
			aMP(add, "", 0, FALSE, llGetOwner());
		
		// The following only regenerate out of combat
		if( ( !inCombat || cfmHR > 0 ) && DEF_HP_REGEN*fmHR>0 && HP < maxHP() ){
		
			float r = fmHR;
			if( inCombat )
				r *= cfmHR;
			aHP(r*DEF_HP_REGEN, "", SMAFlag$IS_PERCENTAGE, TRUE, TRUE, llGetOwner(), 0);
			
		}
		if( !inCombat && DEF_PAIN_REGEN*fmPR>0 && ~BFL&BFL_SOFTLOCK_PAIN && PAIN > 0 )
			aPP(-fmPR*DEF_PAIN_REGEN, "", SMAFlag$IS_PERCENTAGE, TRUE, llGetOwner());
		if( !inCombat && DEF_AROUSAL_REGEN*fmAR>0 && ~BFL&BFL_SOFTLOCK_AROUSAL && AROUSAL > 0 )
			aAR(-fmAR*DEF_AROUSAL_REGEN, "", SMAFlag$IS_PERCENTAGE, TRUE, llGetOwner());
		
		
		OS(FALSE);
		
	}
    else if(id == "_"){
	
		BFL = BFL&~BFL_STATUS_SENT;
		if(BFL&BFL_STATUS_QUEUE){
		
			BFL = BFL&~BFL_STATUS_QUEUE;
			OS(TRUE);
			
		}
		
    }
	else if(id == TIMER_BREAKFREE){
		// Show breakfree button
		GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
		GUI$toggleQuit(TRUE);
		BFL = BFL|BFL_AVAILABLE_BREAKFREE;
	}
	else if(id == TIMER_INVUL){
	
		SF = SF&~StatusFlag$invul;
		OS( TRUE );
		
	}
	else if( id == TIMER_CLIMB_ROOT ){
	
		BFL = BFL&~BFL_CLIMB_ROOT;
		OS( TRUE );
		
	}
	else if(id == TIMER_COMBAT){
	
		SF = SF&~StatusFlag$combat;
		OS(false);
		
	}
	else if( id == TIMER_COOP_BREAKFREE ){
	
		llRezAtRoot("BreakFree", llGetRootPosition(), ZERO_VECTOR, ZERO_ROTATION, 1);
		SF = SF|StatusFlag$coopBreakfree;
		OS(false);
		
	}
	
	else if( id == TIMER_MOUSELOOK )
		llOwnerSay("@setcam_mode:mouselook=force");

	else if( startsWith(id, "SL:") )
		BFL = BFL&~(int)llGetSubString(id, 3, -1);
	
}


default {

    state_entry(){
	
        Status$fullregen();
		db4$freplace(gotTable$status, gotTable$status$team, TEAM);	// Set initial value
        multiTimer([TIMER_REGEN, 0, 1, TRUE]);
		llOwnerSay("@setdebug_RenderResolutionDivisor:0=force");
		A_ARM = floor(llFrand(4));	// 0-3
		OS( TRUE );
		
		//runOmniMethod("got NPCInt", NPCIntMethod$rapeMe, [], TNN);
        
    }
    
    timer(){
		multiTimer([]);
    }
    
	#define LM_PRE \
	if( nr == TASK_REFRESH_COMBAT ){ \
		integer combat = SF&StatusFlag$combat; \
		SF = SF|StatusFlag$combat; \
		updateCombatTimer(); \
		if(!combat){ \
			saveFlags(); \
		} \
	} \
	\
	if( nr == TASK_FX ){ \
        integer pre = FXF; \
		FXF = (int)fx$getDurEffect(fxf$SET_FLAG); \
		/* \
		if( (pre&fx$F_BLURRED) != (FXF&fx$F_BLURRED) ){ \
			integer divisor = 0; \
			if( FXF&fx$F_BLURRED ) \
				divisor = 2; \
			llOwnerSay("@setdebug_renderresolutiondivisor:"+(string)divisor+"=force"); \
		}\
		*/ \
		if( (pre&fx$F_FORCE_MOUSELOOK) != (FXF&fx$F_FORCE_MOUSELOOK) ){\
			multiTimer([TIMER_MOUSELOOK, 0, (float)((FXF&fx$F_FORCE_MOUSELOOK)>0)/10, TRUE]); \
		}\
        fmDT = llJson2List(fx$getDurEffect(fxf$DAMAGE_TAKEN_MULTI)); \
		fmDTF = (float)fx$getDurEffect(fxf$DAMAGE_TAKEN_FRONT); \
		fmDTB = (float)fx$getDurEffect(fxf$DAMAGE_TAKEN_BEHIND); \
        fmMR = (float)fx$getDurEffect(fxf$MANA_REGEN_MULTI); \
		fmPT = (float)fx$getDurEffect(fxf$PAIN_MULTI); \
		fmAT = (float)fx$getDurEffect(fxf$AROUSAL_MULTI); \
		float perc = HP/maxHP(); \
		float mperc = MANA/maxMana(); \
		fmMH = (float)fx$getDurEffect(fxf$HP_MULTI); \
		fmMHn = (int)fx$getDurEffect(fxf$HP_ADD); \
		fmMM = (float)fx$getDurEffect(fxf$MANA_MULTI); \
		fmMMn = (int)fx$getDurEffect(fxf$MANA_ADD); \
		fmMA = (float)fx$getDurEffect(fxf$MAX_AROUSAL_MULTI); \
		fmMAn = (int)fx$getDurEffect(fxf$MAX_AROUSAL_ADD); \
		fmMP = (float)fx$getDurEffect(fxf$MAX_PAIN_MULTI); \
		fmMPn = (int)fx$getDurEffect(fxf$MAX_PAIN_ADD); \
		fmHR = (float)fx$getDurEffect(fxf$HP_REGEN_MULTI); \
		cfmHR = (float)fx$getDurEffect(fxf$COMBAT_HP_REGEN)-1.0;\
		fmPR = (float)fx$getDurEffect(fxf$PAIN_REGEN_MULTI); \
		fmAR = (float)fx$getDurEffect(fxf$AROUSAL_REGEN_MULTI); \
		fmHT = llJson2List(fx$getDurEffect(fxf$HEALING_TAKEN_MULTI)); \
		fmAC = (float)fx$getDurEffect(fxf$HP_ARMOR_DMG_MULTI); \
		fmA = (float)fx$getDurEffect(fxf$ARMOR_DMG_MULTI); \
		fxT = (int)fx$getDurEffect(fxf$SET_TEAM); \
		fxC = llJson2List(fx$getDurEffect(fxf$CONVERSION)); \
		HP = maxHP()*perc; \
		SDTM = llJson2List(fx$getDurEffect(fxf$SPELL_DMG_TAKEN_MOD)); \
		MANA = maxMana()*mperc; \
        OS( TRUE ); \
    }

    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl"  
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }
    
    if(id == ""){
        
		if(METHOD == StatusMethod$setDifficulty){
			
			integer pre = DIF;
			DIF = llList2Integer(PARAMS, 0);
			db4$freplace(gotTable$status, gotTable$status$difficulty, DIF);
			raiseEvent(StatusEvt$difficulty, DIF);
			
			if(DIF != pre){
			
				list names = [
					"Casual", 
					"Normal", 
					"Hard", 
					"Very Hard", 
					"Brutal", 
					"Bukakke"
				];
				
				Alert$freetext(LINK_THIS, "Difficulty set to "+llList2String(names, DIF), TRUE, TRUE);
				OS(FALSE);
				
			}
		
		}
		else if(METHOD == StatusMethod$setSex){

            GF = l2i(PARAMS, 0)&(GENITALS_VAGINA|GENITALS_BREASTS|GENITALS_PENIS);
			OS(TRUE);
			db4$freplace(gotTable$status, gotTable$status$genitals, GF);
			raiseEvent(StatusEvt$genitals, GF);
			
        }
		
    }

	if( METHOD == StatusMethod$kill && ~SF&StatusFlag$dead ){
	
		HP = 0;
		onDeath( method_arg(0), id );
		
	}
	
	if(METHOD == StatusMethod$batchUpdateResources){
	
		string attacker = method_arg(0);
		PARAMS = llDeleteSubList(PARAMS, 0, 0);
		while(PARAMS){
		
			integer type = l2i(PARAMS, 0);
			integer len = l2i(PARAMS, 1);

			list data = llList2List(PARAMS, 2, 2+len-1);		// See SMBUR$* at got Status
			PARAMS = llDeleteSubList(PARAMS, 0, 2+len-1);
			float am = i2f(llList2Float(data, 0));	
			string name = l2s(data, 1);					// Spell name
			integer flags = l2i(data, 2);				// Spell flags
			float steal = l2f(data, 3);					// Life steal

			// Apply
			if(type == SMBUR$durability)
				aHP(am, name, flags, FALSE, FALSE, attacker, steal);
			else if(type == SMBUR$mana)
				aMP(am, name, flags, FALSE, attacker);
			else if(type == SMBUR$arousal)
				aAR(am, name, flags, FALSE, attacker);
			else if(type == SMBUR$pain)
				aPP(am, name, flags, FALSE, attacker);
		}
		OS( FALSE );
		
	}
	
    else if(
		METHOD == StatusMethod$fullregen || 
		(METHOD == StatusMethod$coopInteract && SF&StatusFlag$coopBreakfree)
	){
		
		int ignoreInvul = METHOD == StatusMethod$fullregen && l2i(PARAMS, 0);
        Rape$end();
        
		if( SF&StatusFlag$dead && ! ignoreInvul ){
		
			SF = SF|StatusFlag$invul;
			OS(TRUE);
			multiTimer([TIMER_INVUL, 0, 6, FALSE]);
			
		}
		
        HP = maxHP();
        MANA = maxMana();
        AROUSAL = 0;
        PAIN = 0;
        SF = SF&~StatusFlag$dead;
        SF = SF&~StatusFlag$raped;
        SF = SF&~StatusFlag$pained;
        SF = SF&~StatusFlag$aroused;
		SF = SF&~StatusFlag$coopBreakfree;
        raiseEvent(StatusEvt$dead, 0);
		gotClassAtt$dead(0);
        
        AnimHandler$anim("got_loss", FALSE, 0, 0, 0);
        OS(TRUE);
		
		
		// Clear rape stuff
		multiTimer([TIMER_BREAKFREE]);
		GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
		GUI$toggleQuit(FALSE);
    }
    else if(METHOD == StatusMethod$get){
        CB_DATA = [SF, FXF, floor(HP/maxHP()*100), floor(MANA/maxMana()*100), floor(AROUSAL/maxArousal()*100), floor(PAIN/maxPain()*100), GF, TEAM];
    }
	
    else if(METHOD == StatusMethod$outputStats)
        OS(TRUE);
		
    else if(METHOD == StatusMethod$loading){
	
		integer loading = (integer)method_arg(0);
		integer pre = SF;
		SF = SF&~StatusFlag$loading;
		if( loading )
			SF = SF|StatusFlag$loading;
		
		if( pre != SF ){
		
			integer divisor = 0;
			if( loading )
				divisor = 6;
			llOwnerSay("@setdebug_RenderResolutionDivisor:"+(string)divisor+"=force");
			OS(TRUE);
			
		}
		raiseEvent(StatusEvt$loading_level, id);
		
	}
	
	else if( METHOD == StatusMethod$playerSceneDone && SF&StatusFlag$dead )
		AnimHandler$anim("got_loss", TRUE, 0, 0, 0);
		
		
	else if( METHOD == StatusMethod$toggleBossFight ){
		
		integer on = (int)method_arg(0);
		if( 
			(on && SF&StatusFlag$boss_fight) || 
			(!on&&~SF&StatusFlag$boss_fight) 
		)return;
		
		if( on )
			SF = SF | StatusFlag$boss_fight;
		
		else{
			SF = SF &~ StatusFlag$boss_fight;
			/*
			if(SF & StatusFlag$dead)
				Status$fullregen();
			*/
		}
		saveFlags();
	}
	else if( METHOD == StatusMethod$setArmor ){
		
		ARMOR = l2i(PARAMS, 0);
		dArm(0, TRUE);
		OS(TRUE);
	
	}
	
    else if(METHOD == StatusMethod$setTeam){
	
		TEAM_D = llList2Integer(PARAMS, 0);
		OS(TRUE);
		
	} 
	
	else if( METHOD == StatusMethod$toggleBreakfree ){
		
		BFL = BFL&~BFL_NO_BREAKFREE;
		if( !l2i(PARAMS, 0) )
			BFL = BFL|BFL_NO_BREAKFREE;
		
	}
	
	if( METHOD == StatusMethod$damageArmor ){
	
		integer a = (int)l2i(PARAMS, 0);
		// Modifier
		if( a > 0 ){
			float amt = a*fmA;
			a = floor(amt);
			if( llFrand(1) < amt-a)
				++a;
		}
		
		dArm( a, FALSE );
		OS(FALSE);
		
	}
	if(METHOD == StatusMethod$coopInteract)
		raiseEvent(StatusEvt$interacted, (str)id);
	
	
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
