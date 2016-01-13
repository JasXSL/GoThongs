#define USE_EVENTS
#define USE_SHARED [cls$name, "got Bridge", "#ROOT"]
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define saveFlags() db2$set([StatusShared$flags], (string)STATUS_FLAGS); raiseEvent(StatusEvt$flags, (string)STATUS_FLAGS)

#define maxDurability() (DEFAULT_DURABILITY*(1+(float)getBonusStat(STAT_DURABILITY)*.1))
#define maxMana() (DEFAULT_MANA*(1+(float)getBonusStat(STAT_MANA)*.1))
#define maxArousal() (DEFAULT_AROUSAL*(1+(float)getBonusStat(STAT_AROUSAL)*0.5))
#define maxPain() (DEFAULT_PAIN*(1+(float)getBonusStat(STAT_PAIN)*0.5))

#define TIMER_REGEN "a"
#define TIMER_BREAKFREE "b"
#define TIMER_INVUL "c"
#define TIMER_CLIMB_ROOT "d"

integer BFL;

#define BFL_CAM 2				// Cam is overridden
#define BFL_CLIMB_ROOT 4		// Ended climb, root for a bit
#define BFL_STATUS_QUEUE 0x10		// Send status on timeout
#define BFL_STATUS_SENT 0x20		// Status sent

// Cache
integer PRE_CONTS;
integer PRE_FLAGS;

// Constant
integer THONG_LEVEL = 1;
list BONUS_STATS = [];

#define SPSTRIDE 6
list SPELL_ICONS;   // [(int)PID, (key)texture, (str)desc, (int)added, (int)duration, (int)stacks]

// Effects
integer STATUS_FLAGS = 0; 
#define coop_player llList2Key(PLAYERS, 1)

integer GENITAL_FLAGS;

// FX
integer FXFLAGS = 0;
float fxModDmgTaken = 1;
float fxModManaRegen = 1;
float fxModArousalTaken = 1;
float fxModPainTaken = 1;

list SPELL_DMG_TAKEN_MOD;

// Resources
float DURABILITY = DEFAULT_DURABILITY;
float MANA = DEFAULT_MANA;
float AROUSAL = 0; 
float PAIN = 0;

list OUTPUT_STATUS_TO; 
list PLAYERS;

integer DIFFICULTY = 1;	// 
#define difMod() ((1.+(llPow(2, (float)DIFFICULTY*.7)+DIFFICULTY*4)*0.1)-0.4)



integer getBonusStat(integer stat){
    integer i; integer out;
    for(i=0; i<llGetListLength(BONUS_STATS); i++){
        if(llList2Integer(BONUS_STATS, i) == stat)out++;
    }
    return out;
}


        
toggleClothes(integer showGenitals){
    if(showGenitals){
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Bits");
    }else{
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Bits/Groin, 0");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Dressed/Groin, 0");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Underwear/Groin, 0");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Bits/Torso, 0");
    }
}
        

addDurability(float amount, string spellName, integer flags){
    if(STATUS_FLAGS&StatusFlag$dead || (BFL&BFL_CAM && amount<0))return;
    float pre = DURABILITY;
    amount*=spdmtm(spellName);
	
	
	if(flags&SMAFlag$IS_PERCENTAGE)
		amount*=maxDurability();
	
    if(amount<0){
        if(STATUS_FLAGS&StatusFlag$pained)amount*=1.5;
        amount*=fxModDmgTaken;
		amount*=difMod();
    }
    DURABILITY += amount;
    if(DURABILITY<=0){
		if(STATUS_FLAGS&StatusFlag$dead)return;
		// DEATH HANDLED HERE
        SpellMan$interrupt();
        DURABILITY = 0;
        STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;
        outputStats();
        raiseEvent(StatusEvt$dead, "1");
        AnimHandler$anim("got_loss", TRUE, 0);
        ThongMan$dead(TRUE);
        toggleClothes(TRUE);
		
		multiTimer([TIMER_BREAKFREE, "", 20, FALSE]);
		GUI$toggleLoadingBar((string)LINK_ROOT, TRUE, 20);

		Status$monster_rapeMe();
		Rape$activateTemplate();
    }else{
        if(DURABILITY > maxDurability())DURABILITY = maxDurability();
        if(STATUS_FLAGS&StatusFlag$dead){
			// REVIVED HANDLED HERE
			
			// Send to level here, counts as a loss
			
            STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
            raiseEvent(StatusEvt$dead, "0");
            Rape$end();
            AnimHandler$anim("got_loss", FALSE, 0);
            ThongMan$dead(FALSE);
            toggleClothes(FALSE);
			
			multiTimer([TIMER_BREAKFREE]);
			GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
			GUI$toggleQuit(FALSE);
        }
    }
    if(pre != DURABILITY){
        db2$set([StatusShared$dur], mkarr(([DURABILITY, maxDurability()])));
        outputStats();
    }
}
addMana(float amount, string spellName, integer flags){
    if(STATUS_FLAGS&StatusFlag$dead || (BFL&BFL_CAM && amount<0))return;
    float pre = MANA;
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE)
		amount*=maxDurability();
    
    MANA += amount;
    if(MANA<=0)MANA = 0;
    else if(MANA > maxMana())MANA = maxMana();
    
    if(pre != MANA){
        db2$set([StatusShared$mana], mkarr(([MANA, maxMana()])));
        outputStats();
		SpellAux$statusCache(MANA);
    }
}
addArousal(float amount, string spellName, integer flags){
    if(STATUS_FLAGS&StatusFlag$dead || (BFL&BFL_CAM && amount>0))return;
    float pre = AROUSAL;    
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE){
		amount*=maxArousal();
	}
    if(amount>0)amount*=fxModArousalTaken;
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
    

    if(pre != AROUSAL){
        db2$set([StatusShared$arousal], mkarr(([AROUSAL, maxArousal()])));
        outputStats();
        
    }
}
addPain(float amount, string spellName, integer flags){
    if(STATUS_FLAGS&StatusFlag$dead || (BFL&BFL_CAM && amount>0))return;
    float pre = PAIN;
    amount*=spdmtm(spellName);
	if(flags&SMAFlag$IS_PERCENTAGE){
		amount*=maxPain();
	}
		
    if(amount>0)amount*=fxModPainTaken;
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
    
    if(pre != PAIN){
        db2$set([StatusShared$pain], mkarr(([PAIN, maxPain()])));
        outputStats();
    }
        
    
    
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


onEvt(string script, integer evt, string data){
    if(script == "got FXCompiler"){
        if(evt == FXCEvt$update){
            FXFLAGS = (integer)jVal(data, [0]);
			
			integer divisor = 0;
			if(FXFLAGS&fx$F_BLURRED){
				divisor = 8;
			}
			llOwnerSay("@setdebug_renderresolutiondivisor:"+(string)divisor+"=force");
			
            fxModDmgTaken = (float)j(data, FXCUpd$DAMAGE_TAKEN);
            fxModManaRegen = (float)j(data, FXCUpd$MANA_REGEN);
			fxModPainTaken = (float)j(data,FXCUpd$PAIN_MULTI);
			fxModArousalTaken = (float)j(data,FXCUpd$AROUSAL_MULTI);
			
            outputStats();
        }
    }else if(script == "#ROOT"){
        if(evt == RootEvt$players){
            PLAYERS = llJson2List(data);
        }
        else if(evt == evt$TOUCH_START){
            if(~STATUS_FLAGS&StatusFlag$dead && ~STATUS_FLAGS&StatusFlag$raped)return;
            integer prim = (integer)j(data, 0);
            string ln = llGetLinkName(prim);
            if(ln == "QUIT"){
				// Quit button hit.
				Level$died();
                Status$fullregen();
            }
        }
        // Force update on targeting self, otherwise it requests
        else if(evt == RootEvt$targ && jVal(data, [0]) == llGetOwner())outputStats();
    }else if(script == "got SpellMan"){
        if(evt == SpellManEvt$cast || evt == SpellManEvt$interrupted || evt == SpellManEvt$complete){
            if(evt == SpellManEvt$cast){
                // At least 1 sec to count as a cast
                if((float)jVal(data, [0])<1)return;
                STATUS_FLAGS = STATUS_FLAGS|StatusFlag$casting;
            }
            else STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$casting;
            outputStats();
        }
    }else if(script == "got Bridge"){
        if(evt == BridgeEvt$data_change){
            data = db2$get("got Bridge", [BridgeShared$data]);
            BONUS_STATS = llJson2List(jVal(data, [1]));
            THONG_LEVEL = (integer)jVal(data, [2]);
			
        }
		else if(evt == BridgeEvt$userDataChanged){
			DIFFICULTY = (integer)j(data, 4);
		}
		else if(evt == BridgeEvt$thong_initialized)toggleClothes(FALSE);
        
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
            AnimHandler$anim("got_loss", FALSE, 0);
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
			integer f = (int)jVal(data,([1,0]));
			if(f&StatusClimbFlag$root_at_end){
				multiTimer([TIMER_CLIMB_ROOT, "", 1.5, FALSE]);
				BFL = BFL|BFL_CLIMB_ROOT;
			}
		}
		outputStats();
	}
	else if(script == "jas RLV" && (evt == RLVevt$cam_set || evt == RLVevt$cam_unset)){
		BFL = BFL&~BFL_CAM;
		if(evt == RLVevt$cam_set)BFL = BFL|BFL_CAM;
		outputStats();
	}
}

dumpStats(){
	if(BFL&BFL_STATUS_SENT){
		BFL = BFL|BFL_STATUS_QUEUE;
		return;
	}
	BFL = BFL|BFL_STATUS_SENT;
    multiTimer(["_", "", 1, FALSE]);
	
	GUI$myStatus(DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), STATUS_FLAGS, FXFLAGS);
    if(coop_player)
        GUI$status(coop_player, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), STATUS_FLAGS, FXFLAGS);
}

outputStats(){ 
    dumpStats();
	 
    integer controls = CONTROL_ML_LBUTTON|CONTROL_UP|CONTROL_DOWN;
    if(FXFLAGS&fx$F_STUNNED || BFL&BFL_CAM || (STATUS_FLAGS&(StatusFlag$dead|StatusFlag$climbing|StatusFlag$loading) && ~STATUS_FLAGS&StatusFlag$raped))
        controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
    if(FXFLAGS&fx$F_ROOTED || STATUS_FLAGS&(StatusFlag$casting|StatusFlag$swimming) || BFL&BFL_CLIMB_ROOT)
        controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT;
	if(FXFLAGS&fx$F_NOROT)
		controls = controls|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
	
    if(PRE_CONTS != controls){
        PRE_CONTS = controls;
        Root$statusControls(controls);
    }
    if(PRE_FLAGS != STATUS_FLAGS){
        integer c = StatusFlag$pained|StatusFlag$aroused;
		
		
        if((~PRE_FLAGS&c) == c && STATUS_FLAGS&c)
            AnimHandler$anim("got_pain", TRUE, 0);
        else if(PRE_FLAGS&c && (~STATUS_FLAGS&c) == c)
            AnimHandler$anim("got_pain", FALSE, 0);
        
        PRE_FLAGS = STATUS_FLAGS;
        saveFlags();
    }
}

timerEvent(string id, string data){
    if(id == TIMER_REGEN)
        addMana((maxMana()*.05)*fxModManaRegen, "", 0);
    else if(id == "_"){
		BFL = BFL&~BFL_STATUS_SENT;
		if(BFL&BFL_STATUS_QUEUE){
			BFL = BFL&~BFL_STATUS_QUEUE;
			dumpStats();
		}
		
    }else if(id == "OP"){
		integer i; list out;
		for(i=0; i<llGetListLength(SPELL_ICONS); i+=SPSTRIDE){
			out+= llDeleteSubList(llList2List(SPELL_ICONS, i, i+SPSTRIDE-1), 2, 2);
		}
		GUI$setMySpellTextures(out);
		if(coop_player)
			GUI$setSpellTextures(coop_player, out);
    }
	else if(id == TIMER_BREAKFREE){
		// Show breakfree button
		GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
		GUI$toggleQuit(TRUE);
	}
	else if(id == TIMER_INVUL){
		STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$invul;
		outputStats();
	}
	else if(id == TIMER_CLIMB_ROOT){
		BFL = BFL&~BFL_CLIMB_ROOT;
		outputStats();
	}
}
  

default 
{
    state_entry(){
		PLAYERS = [(string)llGetOwner()];
        db2$ini();
        outputStats();
        Status$fullregen();
        multiTimer([TIMER_REGEN, "", 2, TRUE]);
        llRegionSayTo(llGetOwner(), 1, "jasx.settings");
        toggleClothes(FALSE);
		llOwnerSay("@setdebug_RenderResolutionDivisor:0=force");
    }
    
    timer(){
        multiTimer([]);
    }
    
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
            SPELL_ICONS += [(integer)method_arg(0), (key)method_arg(1), (str)method_arg(2), (int)method_arg(3), (int)method_arg(4), (int)method_arg(5)];
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
            db2$set([StatusShared$sex], (string)GENITAL_FLAGS);
        }
		else if(METHOD == StatusMethod$stacksChanged){
			integer pid = (integer)method_arg(0);
            integer pos = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [pid]);
			if(pos == -1)return;
			
			SPELL_ICONS = llListReplaceList(SPELL_ICONS, [(int)method_arg(1),(int)method_arg(2),(int)method_arg(3)], pos*SPSTRIDE+3,pos*SPSTRIDE+5);
            //qd("Refreshing spell icons: "+mkarr(SPELL_ICONS));
			multiTimer(["OP", "", .1, FALSE]);
		}
    }
    
    if(METHOD == StatusMethod$addDurability)addDurability((float)method_arg(0), method_arg(2), (integer)method_arg(3));
    else if(METHOD == StatusMethod$addMana)addMana((float)method_arg(0), method_arg(1), (integer)method_arg(2));
    else if(METHOD == StatusMethod$addArousal)addArousal((float)method_arg(0), method_arg(1), (integer)method_arg(2));
    else if(METHOD == StatusMethod$addPain)addPain((float)method_arg(0), method_arg(1), (integer)method_arg(2));
    else if(METHOD == StatusMethod$setTargeting){
		outputStats();
		multiTimer(["OP", "", .2, FALSE]);
	}
    
    else if(METHOD == StatusMethod$fullregen){
		
        Rape$end();
        
		if(STATUS_FLAGS&StatusFlag$dead){
			STATUS_FLAGS = STATUS_FLAGS|StatusFlag$invul;
			outputStats();
			multiTimer([TIMER_INVUL,"", 6, FALSE]);
		}
        DURABILITY = maxDurability();
        MANA = maxMana();
        AROUSAL = 0;
        PAIN = 0;
        db2$set([StatusShared$dur], mkarr(([DURABILITY, maxDurability()])));
        db2$set([StatusShared$mana], mkarr(([MANA, maxMana()])));
        db2$set([StatusShared$arousal], mkarr(([AROUSAL, maxArousal()])));
        db2$set([StatusShared$pain], mkarr(([PAIN, maxPain()])));
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$raped;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$pained;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$aroused;
        raiseEvent(StatusEvt$dead, "0");
        
        AnimHandler$anim("got_loss", FALSE, 0);
        outputStats();
        ThongMan$dead(FALSE);
        toggleClothes(FALSE);
		
		
		
		// Clear rape stuff
		multiTimer([TIMER_BREAKFREE]);
		GUI$toggleLoadingBar((string)LINK_ROOT, FALSE, 0);
		GUI$toggleQuit(FALSE);
    }
    else if(METHOD == StatusMethod$get){
        CB_DATA = [STATUS_FLAGS, FXFLAGS, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), GENITAL_FLAGS];
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
	}
	else if(METHOD == StatusMethod$setDifficulty){ 
		// Difficulty can be -1 to just update your coop partner
		if(~(integer)method_arg(0)){
			DIFFICULTY = (integer)method_arg(0);
			if(DIFFICULTY < 0)DIFFICULTY = 0;
			if(DIFFICULTY > 5)DIFFICULTY = 5;
		}
		if((integer)method_arg(1)){Status$setDifficulty(coop_player, DIFFICULTY, FALSE);}
		else{
			// Other player changed difficulty. Set on server
			Bridge$setDifficulty(DIFFICULTY);
		}
		raiseEvent(StatusEvt$difficulty, mkarr([DIFFICULTY]));
		
		if(~(integer)method_arg(0)){
			list names = ["Casual", "Normal", "Hard", "Very Hard", "Brutal", "Bukakke"];
			Alert$freetext((string)LINK_THIS, "Difficulty set to "+llList2String(names, DIFFICULTY), TRUE, TRUE);
		}
	}

    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
