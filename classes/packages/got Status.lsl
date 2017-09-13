#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define saveFlags() \
if(STATUS_FLAGS_PRE != STATUS_FLAGS){ \
	raiseEvent(StatusEvt$flags, llList2Json(JSON_ARRAY, [STATUS_FLAGS, STATUS_FLAGS_PRE])); \
	STATUS_FLAGS_PRE = STATUS_FLAGS; \
}	

#define maxDurability() ((DEFAULT_DURABILITY+fxModMaxHpNr)*fxModMaxHpPerc)
#define maxMana() ((DEFAULT_MANA+fxModMaxManaNr)*fxModMaxManaPerc)
#define maxArousal() ((DEFAULT_AROUSAL+fxModMaxArousalNr)*fxModMaxArousalPerc)
#define maxPain() ((DEFAULT_PAIN+fxModMaxPainNr)*fxModMaxPainPerc)

#define TIMER_REGEN "a"
#define TIMER_BREAKFREE "b"
#define TIMER_INVUL "c"
#define TIMER_CLIMB_ROOT "d"
#define TIMER_COMBAT "e"
#define TIMER_COOP_BREAKFREE "f"

#define updateCombatTimer() multiTimer([TIMER_COMBAT, "", StatusConst$COMBAT_DURATION, FALSE])

integer BFL = 1;
#define BFL_NAKED 1				// 
//#define BFL_CAM 2				// Cam is overridden
#define BFL_CLIMB_ROOT 4		// Ended climb, root for a bit
#define BFL_STATUS_QUEUE 0x10		// Send status on timeout
#define BFL_STATUS_SENT 0x20		// Status sent
#define BFL_AVAILABLE_BREAKFREE 0x40

#define BFL_QTE 0x100			// In a quicktime event

// Cache
integer PRE_CONTS;
integer PRE_FLAGS;

integer TEAM_DEFAULT = TEAM_PC;			// This is the team set by the HUD itself, can be overridden by fxTeam
integer TEAM = TEAM_PC; 				// This is team out

// Constant
integer THONG_LEVEL = 1;

#define SPSTRIDE 6
list SPELL_ICONS;   // [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks]

// Effects
integer STATUS_FLAGS = 0; 
integer STATUS_FLAGS_PRE = 0;
#define coop_player llList2Key(PLAYERS, 1)

integer GENITAL_FLAGS;

// FX
integer FXFLAGS = 0;
float fxModDmgTaken = 1;
float fxModManaRegen = 1;
float fxModArousalTaken = 1;
float fxModPainTaken = 1;
float fxModHealingTaken = 1;
float fxHpRegen = 1;
float fxPainRegen = 1;
float fxArousalRegen = 1;

float fxModMaxHpPerc = 1;
integer fxModMaxHpNr = 0;
float fxModMaxManaPerc = 1;
integer fxModMaxManaNr = 0;
float fxModMaxArousalPerc = 1;
integer fxModMaxArousalNr = 0;
float fxModMaxPainPerc = 1;
integer fxModMaxPainNr = 0;

list fxConversions; // See got FXCompiler.lsl

integer fxTeam = -1;

key ROOT_LEVEL;
integer CHALLENGE_MODE;
#define isChallenge() (llKey2Name(ROOT_LEVEL) != "" && CHALLENGE_MODE)

list SPELL_DMG_TAKEN_MOD; 

// Resources
float DURABILITY = DEFAULT_DURABILITY;
float MANA = DEFAULT_MANA;
float AROUSAL = 0; 
float PAIN = 0;

list OUTPUT_STATUS_TO; 
list PLAYERS;
list TARGETING;

integer DIFFICULTY = 1;	// 
#define difMod() ((1.+(llPow(2, (float)DIFFICULTY*.7)+DIFFICULTY*3)*0.1)-0.4)


        
toggleClothes(){
	// Show genitals
	integer show = (STATUS_FLAGS&(StatusFlag$dead|StatusFlag$raped)) || FXFLAGS&fx$F_SHOW_GENITALS;
	
    if(show && ~BFL&BFL_NAKED){
		BFL = BFL|BFL_NAKED;
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Bits");
		ThongMan$dead(
			TRUE, 							// Hide thong
			!(FXFLAGS&fx$F_SHOW_GENITALS)	// But don't show particles or sound if this was an FX call
		);
    }else if(!show && BFL&BFL_NAKED){
		BFL = BFL&~BFL_NAKED;
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed");
		llSleep(1);
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Dressed/Groin, 0");
		ThongMan$dead(FALSE, FALSE); 
    }
}

// Returns conversion effects of a FXC$CONVERSION_* type
float runConversions(integer type, float amount){
	integer i; float out = 1;
	integer isDetrimental = (
		(amount < 0 && ~llListFindList([FXC$CONVERSION_HP, FXC$CONVERSION_MANA], [type])) ||
		(amount > 0 && ~llListFindList([FXC$CONVERSION_PAIN, FXC$CONVERSION_AROUSAL], [type]))
	);
	
	list conversions = [FXC$CONVERSION_HP,FXC$CONVERSION_MANA,FXC$CONVERSION_AROUSAL,FXC$CONVERSION_PAIN];
	list resources = [0,0,0,0];
	
	
	for(i=0; i<count(fxConversions); ++i){
		integer conv = l2i(fxConversions, i);
		integer d = FXC$conversionNonDetrimental(conv);
		
		if(FXC$conversionFrom(conv) == type && ((!isDetrimental && d) || (isDetrimental && !d))){
			float mag = FXC$conversionPerc(conv)/100.;
			integer b = FXC$conversionTo(conv);
			if(!FXC$conversionDontReduce(conv))
				out*= 1-mag;
			
			float amt = amount*mag;
			
			// Flips amt
			if(FXC$conversionInverse(conv))
				amt = -amt;
			
			integer ndx = llListFindList(conversions, [b]);
			resources = llListReplaceList(resources, [l2f(resources, ndx)+amt], ndx, ndx);
		}
	}
	
	
	if(l2f(resources, 0))
		addDurability(l2f(resources,0), "", 0, FALSE, TRUE);
	if(l2f(resources, 1))
		addMana(l2f(resources, 1), "", 0, TRUE);
	if(l2f(resources, 2))
		addArousal(-l2f(resources, 2), "", 0, TRUE);
	if(l2f(resources, 3))
		addPain(-l2f(resources, 3), "", 0, TRUE);	
	
	return out;
}
        
// Returns TRUE if changed
integer addDurability(float amount, string spellName, integer flags, integer isRegen, integer ignoreConversion){

    if(STATUS_FLAGS&StatusFlag$dead || (STATUS_FLAGS&StatusFlag$cutscene && amount<0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC))return FALSE;
    float pre = DURABILITY;
    amount*=spdmtm(spellName);
	
	if(flags&SMAFlag$IS_PERCENTAGE)
		amount*=maxDurability();
	
    else if(amount<0){
        if(STATUS_FLAGS&StatusFlag$pained)amount*=1.1;
        amount*=fxModDmgTaken;
		amount*=difMod();
		raiseEvent(StatusEvt$hurt, llRound(amount));
		updateCombatTimer();
    }
	else if(!isRegen)
		amount*= fxModHealingTaken;
		
	// Run conversions
	if(!ignoreConversion && !isRegen && ~flags&SMAFlag$IS_PERCENTAGE){
		amount *= runConversions(FXC$CONVERSION_HP, amount);
	}
    DURABILITY += amount;
    if(DURABILITY<=0){
		DURABILITY = 0;
		
		// Death was prevented by fx$F_NO_DEATH
		if(FXFLAGS&fx$F_NO_DEATH){
			if(pre != DURABILITY)
				raiseEvent(StatusEvt$death_hit, "");
		}
		else
			onDeath();
			
		
    }else{
        if(DURABILITY > maxDurability())DURABILITY = maxDurability();
        if(STATUS_FLAGS&StatusFlag$dead){
			// REVIVED HANDLED HERE
			
			// Send to level here, counts as a loss
			
            STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
			STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$raped;
			STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$coopBreakfree;
			
            raiseEvent(StatusEvt$dead, 0);
            Rape$end();
            AnimHandler$anim("got_loss", FALSE, 0, 0);
            toggleClothes();
			
			
			multiTimer([TIMER_BREAKFREE]);
			GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
			GUI$toggleQuit(FALSE);
        }
    }
	
	
	
	return pre != DURABILITY;
}
integer addMana(float amount, string spellName, integer flags, integer ignoreConversion){
    if(STATUS_FLAGS&StatusFlag$dead || (STATUS_FLAGS&StatusFlag$cutscene && amount<0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC))return FALSE;
    float pre = MANA;
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE)
		amount*=maxMana();
    
	// Run conversions
	else if(!ignoreConversion)
		amount*=runConversions(FXC$CONVERSION_MANA, amount);	
		
    MANA += amount;
    if(MANA<=0)MANA = 0;
    else if(MANA > maxMana())MANA = maxMana();
	return pre != MANA;
}

integer addArousal(float amount, string spellName, integer flags, integer ignoreConversion){
    if(STATUS_FLAGS&StatusFlag$dead || (STATUS_FLAGS&StatusFlag$cutscene && amount>0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC))return FALSE;
    float pre = AROUSAL;    
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE){
		amount*=maxArousal();
	}
    else if(amount>0)amount*=fxModArousalTaken;
	
	// Run conversions
	if(!ignoreConversion)
		amount*=runConversions(FXC$CONVERSION_AROUSAL, amount);
	
    AROUSAL += amount;
    if(AROUSAL<=0)AROUSAL = 0;
    
	if(AROUSAL >= maxArousal()){
        AROUSAL = maxArousal();
        if(~STATUS_FLAGS&StatusFlag$aroused){
            STATUS_FLAGS = STATUS_FLAGS|StatusFlag$aroused;
            llTriggerSound("d573fb93-d83e-c877-740f-6c28498668b8", 1);
        }
    }else if(STATUS_FLAGS&StatusFlag$aroused)
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$aroused;
    
	return pre != AROUSAL;
}

integer addPain(float amount, string spellName, integer flags, integer ignoreConversion){
    if(STATUS_FLAGS&StatusFlag$dead || (STATUS_FLAGS&StatusFlag$cutscene && amount>0 && ~flags&SMAFlag$OVERRIDE_CINEMATIC))return FALSE;
    float pre = PAIN;
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE){
		amount*=maxPain();
	}
		
    else if(amount>0)amount*=fxModPainTaken;
    
	// Run conversions
	if(!ignoreConversion && ~flags&SMAFlag$IS_PERCENTAGE)
		amount*=runConversions(FXC$CONVERSION_PAIN, amount);	
	
	PAIN += amount;
    if(PAIN<=0)PAIN = 0;
    
	if(PAIN >= maxPain()){
        PAIN = maxPain();
        if(~STATUS_FLAGS&StatusFlag$pained){
            STATUS_FLAGS = STATUS_FLAGS|StatusFlag$pained;
            llTriggerSound("4db10248-1e18-63d7-b9d5-01c6c0d8a880", 1);
        }
    }else if(STATUS_FLAGS&StatusFlag$pained)
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$pained;

    return pre != PAIN;
}

float spdmtm(string spellName){
    if(!isset(spellName))return 1;
    integer i;
    for(i=0; i<llGetListLength(SPELL_DMG_TAKEN_MOD); i+=2){
        if(llList2String(SPELL_DMG_TAKEN_MOD, i) == spellName){
            float nr = llList2Float(SPELL_DMG_TAKEN_MOD, i+1);
            if(nr <0)return 0;
            return nr;
        }
    }
    return 1;
}


onDeath(){

	// Player died
	if(STATUS_FLAGS&StatusFlag$dead)return;
	// DEATH HANDLED HERE
	SpellMan$interrupt(TRUE);
	STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;
	BFL = BFL&~BFL_AVAILABLE_BREAKFREE;
	
	Level$died();
	
	outputStats();
	raiseEvent(StatusEvt$dead, 1);
	AnimHandler$anim("got_loss", TRUE, 0, 0);
	
	toggleClothes();
	
	float dur = 20;
	if(isChallenge()){
		dur = 90;
		if(STATUS_FLAGS & StatusFlag$boss_fight)
			dur = 0;
		else
			multiTimer([TIMER_COOP_BREAKFREE, "", 20, FALSE]);
	}
	if(dur){
		multiTimer([TIMER_BREAKFREE, "", dur, FALSE]);
		GUI$toggleLoadingBar((string)LINK_ROOT, TRUE, dur);
	}
	Status$monster_rapeMe();
	Rape$activateTemplate();

}

onEvt(string script, integer evt, list data){
    if(script == "#ROOT"){
        if(evt == RootEvt$players){
            PLAYERS = data;
        }
        else if(evt == evt$TOUCH_START){
            if(~STATUS_FLAGS&StatusFlag$dead && ~STATUS_FLAGS&StatusFlag$raped)return;
            integer prim = llList2Integer(data, 0);
            string ln = llGetLinkName(prim);
            if(ln == "QUIT"){
                Status$fullregen();
            }
        }
		else if(evt == RootEvt$level){
			ROOT_LEVEL = llList2String(data, 0);
			CHALLENGE_MODE = l2i(data, 1);
		}
		else if(evt == evt$BUTTON_PRESS && l2i(data, 0)&CONTROL_UP && BFL&BFL_AVAILABLE_BREAKFREE && STATUS_FLAGS&StatusFlag$dead){
			Status$fullregen();
		}
        // Force update on targeting self, otherwise it requests
        else if(evt == RootEvt$targ && llList2Key(data, 0) == llGetOwner())outputStats();
    }else if(script == "got SpellMan"){
        if(evt == SpellManEvt$cast || evt == SpellManEvt$interrupted || evt == SpellManEvt$complete){
            if(evt == SpellManEvt$cast){
                // At least 1 sec to count as a cast
                if(i2f(llList2Float(data, 0))<1)return;
                STATUS_FLAGS = STATUS_FLAGS|StatusFlag$casting;
            }
            else STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$casting;
            outputStats();
        }
    }else if(script == "got Bridge"){
		if(evt == BridgeEvt$userDataChanged){
			Status$setDifficulty(l2i(data, 4));
		}
		else if(evt == BridgeEvt$thong_initialized)
			toggleClothes();
        
    }
	
    else if(script == "got Rape"){
        if(evt == RapeEvt$onStart || evt == RapeEvt$onEnd){
            if(evt == RapeEvt$onStart){
                STATUS_FLAGS = STATUS_FLAGS|StatusFlag$raped;
                outputStats();
            }
            else{
				if(~STATUS_FLAGS&StatusFlag$raped)return;			// Prevent recursion
                STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$raped; 
				Status$fullregen();
            }
            AnimHandler$anim("got_loss", FALSE, 0, 0);
        }
    }
	else if(script == "jas Primswim"){
		if(evt == PrimswimEvt$onWaterEnter){
			
			STATUS_FLAGS = STATUS_FLAGS|StatusFlag$swimming;
		}
		else if(evt == PrimswimEvt$onWaterExit){
			STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$swimming;
			
		}
		outputStats();
	}
	else if(script == "jas Climb"){
		if(evt == ClimbEvt$start){
			STATUS_FLAGS = STATUS_FLAGS|StatusFlag$climbing;
		}
		else if(evt == ClimbEvt$end){
			STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$climbing;
			integer f = (int)j(llList2String(data,1), 0);
			if(f&StatusClimbFlag$root_at_end){
				multiTimer([TIMER_CLIMB_ROOT, "", 1.5, FALSE]);
				BFL = BFL|BFL_CLIMB_ROOT;
			}
		}
		outputStats();
	}
	else if(script == "jas RLV" && (evt == RLVevt$cam_set || evt == RLVevt$cam_unset)){
		
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$cutscene;
		if(evt == RLVevt$cam_set)STATUS_FLAGS = STATUS_FLAGS|StatusFlag$cutscene;
		outputStats();
	}
	else if(script == "got Evts" && evt == EvtsEvt$QTE){
		BFL = BFL&~BFL_QTE;
		if(l2i(data, 0)){
			BFL = BFL|BFL_QTE;
		}

		outputStats();
	}
}



outputStats(){ 

	
	// Check team
	integer t = fxTeam;
	
	if(t == -1)
		t = TEAM_DEFAULT;
		
	integer pre = TEAM;

	// GUI
	// Status is on cooldown and team has not changed
	if(BFL&BFL_STATUS_SENT && pre == t){
		// We need to output status once the timer fades
		BFL = BFL|BFL_STATUS_QUEUE;
	}
	else{
		raiseEvent(StatusEvt$resources, llList2Json(JSON_ARRAY,[
			(int)DURABILITY, (int)maxDurability(), 
			(int)MANA, (int)maxMana(), 
			(int)AROUSAL, (int)maxArousal(), 
			(int)PAIN,(int)maxPain(),
			DURABILITY/maxDurability()
		]));

		BFL = BFL|BFL_STATUS_SENT;
		multiTimer(["_", "", 0.25, FALSE]);
	}
	
	// Always keep description up to date
	if(DURABILITY>maxDurability())
		DURABILITY = maxDurability();
	if(MANA>maxMana())
		DURABILITY = maxDurability();
		
	// int is 0000000 << 21 hp_perc, 0000000 << 14 mana_perc, 0000000 << 7 arousal_perc, 0000000 pain_perc 
	string data = (string)(
		(llRound(DURABILITY/maxDurability()*127)<<21) |
		(llRound(MANA/maxMana()*127)<<14) |
		(llRound(AROUSAL/maxArousal()*127)<<7) |
		llRound(PAIN/maxPain()*127)
	);
	llSetObjectDesc(data+"$"+(str)STATUS_FLAGS+"$"+(str)FXFLAGS+"$"+(str)GENITAL_FLAGS+"$"+(str)t);
	
	// Team change goes after because we need to update description first
	if(pre != t){
		TEAM = t;
		
		raiseEvent(StatusEvt$team, TEAM);
		runOnPlayers(targ,
			if(targ == llGetOwner())
				targ = (str)LINK_ROOT;
			Root$forceRefresh(targ, llGetKey());
		)
	}
	
	
    integer controls = CONTROL_ML_LBUTTON|CONTROL_UP|CONTROL_DOWN;
    if(FXFLAGS&fx$F_STUNNED || BFL&BFL_QTE || (STATUS_FLAGS&(StatusFlag$dead|StatusFlag$climbing|StatusFlag$loading|StatusFlag$cutscene) && ~STATUS_FLAGS&StatusFlag$raped)){
        controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
	}
    if(FXFLAGS&fx$F_ROOTED || (STATUS_FLAGS&(StatusFlag$casting|StatusFlag$swimming) && ~FXFLAGS&fx$F_CAST_WHILE_MOVING) || BFL&BFL_CLIMB_ROOT){
		controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT;
	}
	if(FXFLAGS&fx$F_NOROT){
		controls = controls|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
	}
	
	
    if(PRE_CONTS != controls){
        PRE_CONTS = controls;
        Root$statusControls(controls);
    }
    if(PRE_FLAGS != STATUS_FLAGS){
        PRE_FLAGS = STATUS_FLAGS;
        saveFlags();
    }
}

timerEvent(string id, string data){
	
    if(id == TIMER_REGEN){
		integer inCombat = (STATUS_FLAGS&StatusFlags$combatLocked)>0;
		
		integer ainfo = llGetAgentInfo(llGetOwner());

		#define DEF_MANA_REGEN 0.025
		#define DEF_HP_REGEN 0.015
		#define DEF_PAIN_REGEN 0.05
		#define DEF_AROUSAL_REGEN 0.05
		
		integer n; // Used to only update if values have changed
		
		float add = (maxMana()*DEF_MANA_REGEN)*fxModManaRegen;
        if(add>0)
			n += addMana(add, "", 0, TRUE);
		
		// The following only regenerate out of combat
		if(inCombat){
			if(n)outputStats();
			return;
		}
		
		if(DEF_HP_REGEN*fxHpRegen>0)
			n += addDurability(fxHpRegen*DEF_HP_REGEN, "", SMAFlag$IS_PERCENTAGE, TRUE, TRUE);
		if(DEF_PAIN_REGEN*fxPainRegen>0)
			n += addPain(-fxPainRegen*DEF_PAIN_REGEN, "", SMAFlag$IS_PERCENTAGE, TRUE);
		if(DEF_AROUSAL_REGEN*fxArousalRegen>0)
			n += addArousal(-fxArousalRegen*DEF_AROUSAL_REGEN, "", SMAFlag$IS_PERCENTAGE, TRUE);
		
		if(n)
			outputStats();
	}
    else if(id == "_"){
		BFL = BFL&~BFL_STATUS_SENT;
		if(BFL&BFL_STATUS_QUEUE){
			BFL = BFL&~BFL_STATUS_QUEUE;
			outputStats();
		}
		
    }else if(id == "OP"){
		integer i; list out;
		for(i=0; i<llGetListLength(SPELL_ICONS); i+=SPSTRIDE){
			out+= llDeleteSubList(llList2List(SPELL_ICONS, i, i+SPSTRIDE-1), 2, 2);
		}
		string s = llDumpList2String(out,",");
		GUI$setMySpellTextures(out);
		list p = TARGETING;
		list_shift_each(p, val, 
			GUI$setSpellTextures(val, s);
		)
    }
	else if(id == TIMER_BREAKFREE){
		// Show breakfree button
		GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
		GUI$toggleQuit(TRUE);
		BFL = BFL|BFL_AVAILABLE_BREAKFREE;
	}
	else if(id == TIMER_INVUL){
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$invul;
		outputStats();
	}
	else if(id == TIMER_CLIMB_ROOT){
		BFL = BFL&~BFL_CLIMB_ROOT;
		outputStats();
	}
	else if(id == TIMER_COMBAT){
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$combat;
		saveFlags();
	}
	else if(id == TIMER_COOP_BREAKFREE){
		llRezAtRoot("BreakFree", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
		STATUS_FLAGS = STATUS_FLAGS|StatusFlag$coopBreakfree;
		saveFlags();
	}
}


default 
{
    state_entry(){
		PLAYERS = [(string)llGetOwner()];
        outputStats();
        Status$fullregen();
        multiTimer([TIMER_REGEN, "", 1, TRUE]);
        llRegionSayTo(llGetOwner(), 1, "jasx.settings");
        toggleClothes();
		llOwnerSay("@setdebug_RenderResolutionDivisor:0=force");
    }
    
    timer(){
        multiTimer([]);
    }
    
	#define LM_PRE \
	if(nr == TASK_REFRESH_COMBAT){ \
		integer combat = STATUS_FLAGS&StatusFlag$combat; \
		STATUS_FLAGS = STATUS_FLAGS|StatusFlag$combat; \
		updateCombatTimer(); \
		if(!combat)saveFlags(); \
	} \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
        integer pre = FXFLAGS; \
		FXFLAGS = llList2Integer(data, 0); \
		\
		integer divisor = 0; \
		if(FXFLAGS&fx$F_BLURRED){ \
			divisor = 8; \
		} \
		if((pre&fx$F_BLURRED) != (FXFLAGS&fx$F_BLURRED)){ \
			llOwnerSay("@setdebug_renderresolutiondivisor:"+(string)divisor+"=force"); \
		}\
		\
        fxModDmgTaken = i2f(l2f(data, FXCUpd$DAMAGE_TAKEN)); \
        fxModManaRegen = i2f(l2f(data, FXCUpd$MANA_REGEN)); \
		 \
		fxModPainTaken = i2f(l2f(data,FXCUpd$PAIN_MULTI)); \
		fxModArousalTaken = i2f(l2f(data,FXCUpd$AROUSAL_MULTI)); \
		 \
		float maxhppre = maxDurability(); \
		float perc = DURABILITY/maxhppre; \
		fxModMaxHpPerc = i2f(l2f(data, FXCUpd$HP_MULTIPLIER)); \
		fxModMaxHpNr = llList2Integer(data, FXCUpd$HP_ADD); \
		fxModMaxManaPerc = i2f(l2f(data, FXCUpd$MANA_MULTIPLIER)); \
		fxModMaxManaNr = llList2Integer(data, FXCUpd$MANA_ADD); \
		fxModMaxArousalPerc = i2f(l2f(data, FXCUpd$AROUSAL_MULTIPLIER)); \
		fxModMaxArousalNr = llList2Integer(data, FXCUpd$AROUSAL_ADD); \
		fxModMaxPainPerc = i2f(l2f(data, FXCUpd$PAIN_MULTIPLIER)); \
		fxModMaxPainNr = llList2Integer(data, FXCUpd$PAIN_ADD); \
		fxHpRegen = i2f(l2f(data, FXCUpd$HP_REGEN)); \
		fxPainRegen = i2f(l2f(data, FXCUpd$PAIN_REGEN)); \
		fxArousalRegen = i2f(l2f(data, FXCUpd$AROUSAL_REGEN)); \
		fxModHealingTaken = i2f(l2f(data, FXCUpd$HEAL_MOD)); \
		fxTeam = l2i(data, FXCUpd$TEAM); \
		fxConversions = llJson2List(l2s(data, FXCUpd$CONVERSION)); \
		if(maxhppre != maxDurability()){ DURABILITY = maxDurability()*perc;}\
        outputStats(); \
		toggleClothes(); \
    } \
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl"  
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }
    
    if(id == ""){
        if(METHOD == StatusMethod$addTextureDesc){
			// [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks]
            SPELL_ICONS += [
				// PID
				(integer)method_arg(0), 
				// Texture
				(key)method_arg(1), 
				// Desc
				(str)method_arg(2), 
				// Added
				(int)method_arg(3), 
				// Duration
				(int)method_arg(4), 
				// Stacks
				(int)method_arg(5)
			];
			multiTimer(["OP", "", .1, FALSE]);
        }
        else if(METHOD == StatusMethod$remTextureDesc){
            integer pid = (integer)method_arg(0);
            integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
			if(pos == -1)return;
			
            SPELL_ICONS = llDeleteSubList(SPELL_ICONS, pos*SPSTRIDE, pos*SPSTRIDE+SPSTRIDE-1);
            multiTimer(["OP", "", .1, FALSE]);
        }
        else if(METHOD == StatusMethod$setSex){
            GENITAL_FLAGS = (integer)method_arg(0);
			raiseEvent(StatusEvt$genitals, GENITAL_FLAGS);
        }
		else if(METHOD == StatusMethod$stacksChanged){
			integer pid = (integer)method_arg(0);
            integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
			if(pos == -1)return;
			
			SPELL_ICONS = llListReplaceList(SPELL_ICONS, [(int)method_arg(1),(int)method_arg(2),(int)method_arg(3)], pos*SPSTRIDE+3,pos*SPSTRIDE+5);
			multiTimer(["OP", "", .1, FALSE]);
		}
		else if(METHOD == StatusMethod$setDifficulty){
			
			integer pre = DIFFICULTY;
			DIFFICULTY = llList2Integer(PARAMS, 0);
			raiseEvent(StatusEvt$difficulty, DIFFICULTY);
			
			if(DIFFICULTY != pre){
				list names = [
					xme(XLS(([XLS_EN, "Casual"]))), 
					xme(XLS(([XLS_EN, "Normal"]))), 
					xme(XLS(([XLS_EN, "Hard"]))), 
					xme(XLS(([XLS_EN, "Very Hard"]))), 
					xme(XLS(([XLS_EN, "Brutal"]))), 
					xme(XLS(([XLS_EN, "Bukakke"])))
				];
				
				Alert$freetext(LINK_THIS, XLS(([
					XLS_EN, "Difficulty set to "+llList2String(names, DIFFICULTY)
				])), TRUE, TRUE);
			}
		
		}
    }

	if(METHOD == StatusMethod$debug && method$byOwner){
		qd(
			"HP: "+(str)DURABILITY+"/"+(str)maxDurability()+" | "+
			"Mana: "+(str)MANA+"/"+(str)maxMana()+" | "+
			"Ars: "+(str)AROUSAL+"/"+(str)maxArousal()+" | "+
			"Pain: "+(str)PAIN+"/"+(str)maxPain()
		);
	}
	
	if(METHOD == StatusMethod$kill){
		DURABILITY = 0;
		onDeath();
	}
	
	if(METHOD == StatusMethod$batchUpdateResources){
		while(PARAMS){
			integer type = l2i(PARAMS, 0);
			integer len = l2i(PARAMS, 1);

			list data = llList2List(PARAMS, 2, 2+len-1);		// See SMBUR$* at got Status
			PARAMS = llDeleteSubList(PARAMS, 0, 2+len-1);
			float amount = i2f(llList2Float(data, 0));	
			string name = l2s(data, 1);					// Spell name
			integer flags = l2i(data, 2);				// Spell flags
						
			// Apply
			if(type == SMBUR$durability)
				addDurability(amount, name, flags, FALSE, FALSE);
			else if(type == SMBUR$mana)
				addMana(amount, name, flags, FALSE);
			else if(type == SMBUR$arousal)
				addArousal(amount, name, flags, FALSE);
			else if(type == SMBUR$pain)
				addPain(amount, name, flags, FALSE);
		}
		outputStats();
	}
	
    else if(METHOD == StatusMethod$setTargeting){
		integer on = llList2Integer(PARAMS, 0);
		integer pos = llListFindList(TARGETING, [(str)id]);
		if(on && pos == -1 && llListFindList(PLAYERS, [(str)id]) == -1){
			TARGETING += (str)id;
		}else if(!on && ~pos){
			TARGETING = llDeleteSubList(TARGETING, pos, pos);
		}
		integer i;
		for(i=0; i<llGetListLength(TARGETING) && TARGETING != []; i++){
			if(llKey2Name(llList2String(TARGETING, i)) == ""){
				TARGETING = llDeleteSubList(TARGETING, i, i);
				i--;
			}
		}
		outputStats();
		multiTimer(["OP", "", .2, FALSE]);
	}
    
    else if(
		METHOD == StatusMethod$fullregen || 
		(METHOD == StatusMethod$coopInteract && STATUS_FLAGS&StatusFlag$coopBreakfree)
	){
				
		integer ignoreInvul = l2i(PARAMS, 0);
        Rape$end();
        
		if(STATUS_FLAGS&StatusFlag$dead && ! ignoreInvul){
			STATUS_FLAGS = STATUS_FLAGS|StatusFlag$invul;
			outputStats();
			multiTimer([TIMER_INVUL,"", 6, FALSE]);
		}
        DURABILITY = maxDurability();
        MANA = maxMana();
        AROUSAL = 0;
        PAIN = 0;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$raped;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$pained;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$aroused;
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$coopBreakfree;
        raiseEvent(StatusEvt$dead, 0);
        
        AnimHandler$anim("got_loss", FALSE, 0, 0);
        outputStats();
        toggleClothes();
		
		
		
		// Clear rape stuff
		multiTimer([TIMER_BREAKFREE]);
		GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
		GUI$toggleQuit(FALSE);
    }
    else if(METHOD == StatusMethod$get){
        CB_DATA = [STATUS_FLAGS, FXFLAGS, floor(DURABILITY/maxDurability()*100), floor(MANA/maxMana()*100), floor(AROUSAL/maxArousal()*100), floor(PAIN/maxPain()*100), GENITAL_FLAGS, TEAM];
    }
    else if(METHOD == StatusMethod$spellModifiers){
        SPELL_DMG_TAKEN_MOD = llJson2List(method_arg(0));
    }
    else if(METHOD == StatusMethod$getTextureDesc){
        if(id == "")id = llGetOwner();
		
		integer pid = (integer)method_arg(0);
        integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
        if(pos == -1)return;
		
		llRegionSayTo(llGetOwnerKey(id), 0, llList2String(SPELL_ICONS, pos*SPSTRIDE+2));
    }
    else if(METHOD == StatusMethod$outputStats)
        outputStats();
    else if(METHOD == StatusMethod$loading){
		integer loading = (integer)method_arg(0);
		integer pre = STATUS_FLAGS;
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$loading;
		if(loading)STATUS_FLAGS = STATUS_FLAGS|StatusFlag$loading;
		if(pre != STATUS_FLAGS){
			integer divisor = 0;
			if(loading)divisor = 6;
			llOwnerSay("@setdebug_RenderResolutionDivisor:"+(string)divisor+"=force");
			outputStats();
		}
		raiseEvent(StatusEvt$loading_level, id);
	}
	else if(METHOD == StatusMethod$debugOut){
		llOwnerSay(mkarr(([maxDurability(), maxMana(), maxArousal(), maxPain()])));
	}
	else if(METHOD == StatusMethod$toggleBossFight){
		integer on = (int)method_arg(0);
		if((on && STATUS_FLAGS&StatusFlag$boss_fight) || (!on&&~STATUS_FLAGS&StatusFlag$boss_fight))return;
		if(on){
			STATUS_FLAGS = STATUS_FLAGS | StatusFlag$boss_fight;
		}
		else{
			STATUS_FLAGS = STATUS_FLAGS &~ StatusFlag$boss_fight;
			/*
			if(STATUS_FLAGS & StatusFlag$dead)
				Status$fullregen();
			*/
		}
		saveFlags();
	}
    else if(METHOD == StatusMethod$setTeam){
		TEAM_DEFAULT = llList2Integer(PARAMS, 0);
		outputStats();
	} 
	
	if(METHOD == StatusMethod$coopInteract)
		raiseEvent(StatusEvt$interacted, (str)id);
	
	
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
