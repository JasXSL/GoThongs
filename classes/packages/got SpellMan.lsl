#define USE_EVENTS
#include "got/_core.lsl"

/* This is the spell data cache */
list CACHE;                     // [(int)id, (arr)wrapper, (float)mana, (float)cooldown, (int)target_flags, (float)range, (float)casttime, (arr)fx, (arr)selfcastWrapper]
list GCD_FREE;    				// Spells that are freed from global cooldown        

integer TEAM = TEAM_PC;

#define CSTRIDE 6
#define spellCost(data, index) (llList2Float(data, 0)*mcm*llList2Float(sp_mcm,index))
#define spellCooldown(data, index) (llList2Float(data, 1)*cdm*llList2Float(sp_cdm,index))
#define spellTargets(data) llList2Integer(data, 2)
#define spellRange(data) llList2Float(data, 3)
#define spellCasttime(data, index) (llList2Float(data, 4)*ctm*llList2Float(sp_ctm,index))
#define spellWrapperFlags(data) llList2Integer(data, 5)


// Get a spell NR -1 to 3 data
#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)

/* Additional macros */
#define onCooldown(id) (~llListFindList(COOLDOWNS, [id]))
#define CDSTRIDE 2
list COOLDOWNS = [];            // (int)buttonID, (float)finish_time
#define getGlobalCD() (GCD*cdm)

// Standard spell input
// If castSpell is false, play interrupt sound
#define setQueue(index) if(QUEUE_SPELL != index){QUEUE_SPELL = index; SpellAux$setQueue(QUEUE_SPELL);}
#define clearQueue() QUEUE_SPELL = -1; BFL=BFL&~BFL_QUEUE_SELF_CAST; SpellAux$setQueue(QUEUE_SPELL)
#define startSpell(spell) if(castSpell(spell) == FALSE){llStopSound();llPlaySound("2967371a-f0ec-d8ad-4888-24b3f8f3365c", .2);clearQueue();}

// Recaches the team of the active target
#define recacheTarget() CACHE_ROOT_TARGET = l2k(data,0); CACHE_ROOT_TARGET_TEAM = l2i(data,2)


// Global cooldown. Set by bridge.
float GCD = 1.5;
float GCD_ENDS; 	// Script time when global cooldown ends

// FX
float cdm = 1;          // Cooldown mod
float ctm = 1;          // Casttime mod
float mcm = 1;          // Mana cost multiplier
integer fxflags;		
	// Index specific
list sp_mcm = [1,1,1,1,1];	// Mana cost
list sp_ctm = [1,1,1,1,1];	// Cast time
list sp_cdm = [1,1,1,1,1];	// Cooldown

#define canCastWhileMoving() (fxflags&fx$F_CAST_WHILE_MOVING)


// Cache
integer STATUS_FLAGS;			// Flags from status
integer SPELL_WRAPPER_FLAGS;	// Casted spell's wrapper flags
integer SPELL_CASTED;			// -1 to 3 of casted spell
list SPELL_TARGS;				// List of targets to cast on
key CACHE_ROOT_TARGET;			// Cache of the player's current target
integer CACHE_ROOT_TARGET_TEAM;	// Team of target
integer SPELL_ON_TARG = -1;		// A spell to queue when target is changed
float CACHE_CASTTIME = 0;
integer QUEUE_SPELL = -1;		// Spell to cast after finishing the current cast
float CACHE_MANA;
float RANGE_ADD;
float HEIGHT_ADD;

list PLAYERS;					// Me and coop player

integer BFL;
#define BFL_CASTING 1
#define BFL_START_CAST 2
#define BFL_GLOBAL_CD 0x4
#define BFL_CROUCH_HELD 0x8
#define BFL_QUEUE_SELF_CAST 0x10



// This is a code block that checks if a player is visible. Ret is an optional return value
#define CODE$VISION_CHECK(ret) \
string targ = llList2String(SPELL_TARGS, 0); \
if(targ != (string)LINK_ROOT && targ != "AOE"){ \
    integer flags = spellTargets(data); \
	vector pos = prPos(llList2String(SPELL_TARGS, 0));\
    if(~flags&TARG_REQUIRE_NO_FACING){ \
		vector gpos = llGetPos();\
        prAngX(targ, ang); \
		integer inRange = (llVecDist(pos, llGetPos())<3 && llVecDist(<gpos.x,gpos.y,0>,<pos.x,pos.y,0>)<0.5);\
        if(llFabs(ang)>PI_BY_TWO && !inRange){ \
            A$(ASpellMan$errTargInFront); \
            SpellMan$interrupt(); \
            return ret; \
        } \
    }\
    list ray = llCastRay(llGetPos()+<0,0,.5>, pos+<0,0,1+HEIGHT_ADD>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL, RC_DATA_FLAGS, RC_GET_ROOT_KEY]); \
    if(llList2Integer(ray, -1) == 1 && llList2Key(ray,0) != targ){ \
        A$(ASpellMan$errVisionObscured); \
        SpellMan$interrupt(); \
        return ret; \
    } \
}
/*
	list bounds = llGetBoundingBox(llList2String(SPELL_TARGS, 0));\
    vector b = llList2Vector(bounds, 0)-llList2Vector(bounds,1); \
    float h = llFabs(b.z/2); \
*/

// Default event handler
onEvt(string script, integer evt, list data){
    if(script == "#ROOT"){
        if(evt == evt$BUTTON_PRESS){
			integer pressed = llList2Integer(data,0);
			
			// interrupt if casting and pressing an arrow key
            if(BFL&BFL_CASTING && ~BFL&BFL_START_CAST && !canCastWhileMoving())
                if(pressed&(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT))
                    SpellMan$interrupt();
					
			// Selfcast key
            if(pressed&CONTROL_DOWN)
				BFL = BFL|BFL_CROUCH_HELD;            
        }
		else if(evt == evt$BUTTON_RELEASE){
			integer release = llList2Integer(data,0);
			if(release&CONTROL_DOWN)
				BFL = BFL&~BFL_CROUCH_HELD;    
		}
		
		// This is how spells are cast.
		else if(evt == evt$TOUCH_START){
            integer nr = llList2Integer(data,0);
            if(count(data) > 1){ 
				string ln = llGetLinkName(nr); 
                if(llGetSubString(ln, 0, 3) != "Abil")return;
                nr = (integer)llGetSubString(ln, -1, -1);
            }
            startSpell(nr);
        }
		
		// Set players
		else if(evt == RootEvt$players)
            PLAYERS = data;
			
		// Update target cache
		else if(evt == RootEvt$targ){
			recacheTarget();
			if(SPELL_ON_TARG != -1){
				startSpell(SPELL_ON_TARG);
			}
			
			RANGE_ADD = 0;
			list data = llGetObjectDetails(CACHE_ROOT_TARGET, [OBJECT_DESC, OBJECT_ATTACHED_POINT]);
			if(!llList2Integer(data, 1)){
				// This is an NPC, add range add
				list split = explode("$", l2s(data, 0));
				RANGE_ADD = l2f(split, 3)/10;
				HEIGHT_ADD = l2f(split, 4)/10;
			}
			
			
			
		}

    }
	
	else if(script == "got FXCompiler" && evt == FXCEvt$spellMultipliers){
		sp_mcm = llJson2List(llList2String(data,1));
		sp_ctm = llJson2List(llList2String(data,2));
		sp_cdm = llJson2List(llList2String(data,3));
	}

	// Cache status flags
	else if(script == "got Status"){
		if(evt == StatusEvt$flags)
			STATUS_FLAGS = llList2Integer(data,0);
		else if(evt == StatusEvt$dead)
			COOLDOWNS = [];
		else if(evt == StatusEvt$resources){
			CACHE_MANA = llList2Float(data, 2);
		}
		else if(evt == StatusEvt$team){
			TEAM = l2i(data,0);
			recacheTarget();
		}
	}
}


// This is a macro that turns flags into targets
// Returns a list of targets or ["AOE"], or ["Q"] to queue on target change

#define flagsToTargets(targets, var) var = []; \
if(targets & TARG_AOE)var = ["AOE"]; \
else if(targets == TARG_CASTER)var = [LINK_ROOT]; \
else{ \
	key targ = CACHE_ROOT_TARGET;\
    if(targ == llGetOwner())targ = ""; \
    if(isset(targ) && (~targets&TARG_CASTER || (BFL&(BFL_CROUCH_HELD|BFL_QUEUE_SELF_CAST)) == 0)){ \
        if(targets&TARG_PC && CACHE_ROOT_TARGET_TEAM == TEAM)var = [targ]; \
        else if( \
			targets&TARG_NPC && \
			CACHE_ROOT_TARGET_TEAM != TEAM \
		){ \
			var = [targ]; \
		}\
    } \
    else if(BFL&(BFL_QUEUE_SELF_CAST|BFL_CROUCH_HELD) && count(PLAYERS) > 1 && targets&TARG_PC && ~targets&TARG_NPC && CACHE_ROOT_TARGET_TEAM != TEAM){ \
		var = [l2k(PLAYERS, 1)];\
	} \
	if(targets&TARG_CASTER && var == [])var = [LINK_ROOT]; \
	else if(targets&TARG_NPC && !isset(targ) && SPELL_ON_TARG == -1){ \
		var = ["Q"];\
	}\
}

// This attempts to start casting a spell
integer castSpell(integer nr){
	if(SPELL_ON_TARG == -1 && nr != QUEUE_SPELL)llPlaySound("31086022-7f9a-65d1-d1a7-05571b8ea0f2", .5);
    SPELL_ON_TARG = -1;
	// Play the click sound
	
	// Grab data from cache
    list data = nrToData(nr);
    // Grab target flags
	integer spt = spellTargets(data);
	

// BEFORE QUEUE
	// Check if I have enough mana BEFORE allowing a queue
    float cost = spellCost(data, nr);
    if(cost>CACHE_MANA){
        A$(ASpellMan$errInsufficientMana);
        return FALSE;
    }
	
	// Cannot cast right now because of FX silence
    if(fxflags&fx$NOCAST || llGetAgentInfo(llGetOwner())&AGENT_SITTING || fxflags&fx$F_QUICKRAPE){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }
	
    if(BFL&BFL_CASTING || onCooldown(nr) || (BFL&BFL_GLOBAL_CD && ~spt&SpellMan$NO_GCD)){
		// Queue the spell
		integer q = nr;
		if(nr == QUEUE_SPELL){
			q = -1;
			BFL = BFL&~BFL_QUEUE_SELF_CAST;
			llPlaySound("691cc796-7ed6-3cab-d6a6-7534aa4f15a9", .5);
		}
		else if(BFL&BFL_CROUCH_HELD){
			BFL = BFL|BFL_QUEUE_SELF_CAST;
		}
		setQueue(q);
		return -2;
	}
    
	
    
    // Cache the wrapper flags and check if player is pacified
    integer SPELL_WRAPPER_FLAGS = spellWrapperFlags(data);
    if(fxflags&fx$F_PACIFIED && SPELL_WRAPPER_FLAGS&WF_DETRIMENTAL){
        A$(ASpellMan$errPacified);
        return FALSE;
    }

    
	// Grab targets
	flagsToTargets(spt, SPELL_TARGS);
	
	// If I don't have a target and the spell requires one, try to grab one and cast on it
	if((string)SPELL_TARGS == "Q"){
		// Set a spell to cast when we get a target
		SPELL_ON_TARG = nr;
		multiTimer(["Q", "", 2, FALSE]);
		Evts$cycleEnemy();
		return -2;
	}
	
	
    
	// No targets valid
    if(SPELL_TARGS == []){
        A$(ASpellMan$errInvalidTarget);
        return FALSE;
    }
    
	
    
	// If I'm raped or dead
    if(STATUS_FLAGS&StatusFlags$noCast || (spt&SpellMan$NO_SWIM && STATUS_FLAGS&StatusFlag$swimming)){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }


	// Run LOS check
    CODE$VISION_CHECK(FALSE)
    
    
	// Check spell range
    float range = spellRange(data)+RANGE_ADD;
	
	// Max range is 10m for single target. AoE distance is handled by SpellAux
	if(range > 10)
		range = 10;
    
	integer hits = 0;
    integer i;
    for(i=0; i<llGetListLength(SPELL_TARGS) && !hits; i++){
        string val = llList2String(SPELL_TARGS, i); 
        if(val == "AOE")hits = TRUE;
        else{
            float dist = 0; 
            if((integer)val != LINK_ROOT)dist = llVecDist(llGetPos(), prPos(val));
            if(dist <= range)hits++;
        }
    }
    
	// Nobody in range
    if(hits == 0){
        A$(ASpellMan$errOutOfRange);
        return FALSE;
    }
	
	
	// SUCCESS
    // Grab the casttime and multiply it
    float casttime = spellCasttime(data, nr);
	clearQueue();
	
	// Set the current spell being cast
    SPELL_CASTED = nr;
    
    
    
    // Set global cooldown
    if(~spt&SpellMan$NO_GCD){
        integer CDS = 682;		// 2bit array default 1010101010 (each value is 2)
        
		float gcd = getGlobalCD();
		if(gcd<0.5)gcd = 0.5;
		
        integer i;
        for(i=0; i<5; i++){
            float cdt = 0;
            integer pos = llListFindList(COOLDOWNS, [i]);
            if(~pos)cdt = llList2Float(COOLDOWNS, pos+1);
			
			if(llList2Integer(GCD_FREE,i) || cdt-llGetTime()>gcd || (i == SPELL_CASTED && casttime>0)){
				CDS = remBitArr(CDS, i, 2);	// Set to 0 (leave unchanged)
			}
        }
        SpellAux$setGlobalCooldowns(gcd, CDS);
        BFL = BFL|BFL_GLOBAL_CD;
		GCD_ENDS = llGetTime()+gcd;
        multiTimer(["GCD", "", gcd, FALSE]);
    }
	
	// Cache the casttime
	CACHE_CASTTIME = casttime;
	if(casttime){
		// Only raise the start cast event on spells with a cast time
		raiseEvent(SpellManEvt$cast, f2i(casttime));
        BFL = BFL|BFL_CASTING;					// Set casting
        BFL = BFL|BFL_START_CAST;				// Used to track when it should be interrupted on button press
        multiTimer(["SC", "", .25, FALSE]);
    
        //SpellAux$setCastedAbility(nr, casttime);
        multiTimer(["CAST", "", casttime, FALSE]);
        
        SpellAux$startCast(SPELL_CASTED, casttime);
    }
	// Immediately finish
    else spellComplete();
	
    
    return TRUE;
}

// Checks if we can cast the current queued item, if so, starts a cast
#define checkQueueCast() multiTimer(["CQ", "", .01, FALSE])


spellComplete(){
	// Grab the data
	list data = nrToData(SPELL_CASTED);
    float cooldown = spellCooldown(data, SPELL_CASTED);
	integer tflags = spellTargets(data);
	float cost = spellCost(data, SPELL_CASTED);
	integer flags = spellWrapperFlags(data);
	
	Status$refreshCombat();
	
	// Make sure LOS is proper unless it's instant cast
    if(CACHE_CASTTIME>0){
		CODE$VISION_CHECK()
		SpellFX$stopSound();
    }
    
	float gcd = getGlobalCD();
	if(gcd<0.5)gcd = 0.5;
	
	// Send to AUX to finish the cast
	// Don't wipe CD if there's no cooldown on a non-gcd spell OR if casttime is less than global cooldown
	integer noWipe = ((tflags&SpellMan$NO_GCD && cooldown<=0) || CACHE_CASTTIME<gcd);
    SpellAux$finishCast(SPELL_CASTED, mkarr(SPELL_TARGS), noWipe);
            
    
    // Consume mana
    if(cost != 0)
		Status$batchUpdateResources(SMBUR$buildMana(-cost, "", 0));
	
    // Set cooldown
    if(cooldown){
		SpellAux$setCooldown(SPELL_CASTED, cooldown);
        if(llListFindList(COOLDOWNS, [SPELL_CASTED]) == -1)
			COOLDOWNS+=[SPELL_CASTED, llGetTime()+cooldown];
                
        multiTimer(["CD_"+(string)SPELL_CASTED, "", cooldown, FALSE]);
    }
	// If it's a casted spell on global cooldown and the casttime is less than global cooldown
    else if(CACHE_CASTTIME<gcd && CACHE_CASTTIME>0 && ~tflags&SpellMan$NO_GCD)
		SpellAux$setCooldown(SPELL_CASTED, gcd-CACHE_CASTTIME);
		
    raiseEvent(SpellManEvt$complete, llList2Json(JSON_ARRAY, [SPELL_CASTED, l2s(SPELL_TARGS,0)]));
    spellEnd();
}

// Run from both complete and interrupt
spellEnd(){
    list data;
    if(~SPELL_CASTED)data = nrToData(SPELL_CASTED);
    
    BFL = BFL&~BFL_CASTING;
    BFL = BFL&~BFL_START_CAST;
    ThongMan$loopSound("",0);
    
    
    SpellAux$spellEnd();
    
    if(spellCasttime(data, SPELL_CASTED)){
        ThongMan$particles(0, 1, "[]");
    }
	
	// Cast queued spell if possible
	checkQueueCast();
}

timerEvent(string id, string data){
    if(id == "CAST")spellComplete();
    else if(llGetSubString(id,0,2) == "CD_"){
        integer rem = (integer)llGetSubString(id,3, -1);
        integer pos = llListFindList(COOLDOWNS, [rem]);
        if(~pos)COOLDOWNS = llDeleteSubList(COOLDOWNS, pos, pos+CDSTRIDE-1);
        if(~BFL&BFL_GLOBAL_CD)SpellAux$stopCast(rem);
		checkQueueCast();
    }
    else if(id == "SC")
        BFL = BFL&~BFL_START_CAST;
    else if(id == "GCD"){
        BFL = BFL&~BFL_GLOBAL_CD;
        integer CDS = 0;		// 0	- Each value is 0 (disregard)
        integer i;
        list c = llList2ListStrided(COOLDOWNS, 0, -1, CDSTRIDE);
        for(i=0; i<5; i++){
            if(llListFindList(COOLDOWNS, [i]) == -1 && (~BFL&BFL_CASTING|| i != SPELL_CASTED)){
                CDS = setBitArr(CDS, 1, i, 2);	// set to 1 (wipe)
			}
        }
		float gcd = getGlobalCD();
		if(gcd<.5)gcd = .5;
        SpellAux$setGlobalCooldowns(gcd, CDS);
		
		checkQueueCast(); // Cast queue if possible
    }
	else if(id == "Q")SPELL_ON_TARG = -1;
	else if(id == "CQ"){
		if(
			QUEUE_SPELL == -1 ||
			onCooldown(QUEUE_SPELL) ||
			BFL&(BFL_GLOBAL_CD|BFL_CASTING)
		)return;
		castSpell(QUEUE_SPELL);
	}
}



default 
{
    // Timer event
    timer(){multiTimer([]);}
    
    #define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		ctm = i2f(l2f(data, FXCUpd$CASTTIME)); \
        cdm = i2f(l2f(data, FXCUpd$COOLDOWN)); \
        mcm = i2f(l2f(data, FXCUpd$MANACOST)); \
        fxflags = llList2Integer(data, FXCUpd$FLAGS); \
        if(BFL&BFL_CASTING){ \
            if(fxflags&fx$NOCAST)SpellMan$interrupt(); \
            else if(fxflags&fx$F_PACIFIED && SPELL_WRAPPER_FLAGS&WF_DETRIMENTAL) \
                SpellMan$interrupt(); \
        } \
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
        if(SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared)
            SpellMan$rebuildCache();
        return;
    }
    
    // Internal means the method was sent from within the linkset
    if(method$internal){
        if(METHOD == SpellManMethod$hotkey){
            string dta = method_arg(0);
            
            integer spell = -1;
            if(llGetSubString(dta, 0, 4) == "abil_")spell = (integer)llGetSubString(dta, 5, -1);
            if(~spell && spell<5)
                onEvt("#ROOT", evt$TOUCH_START, [spell]);
            
        }
        else if(METHOD == SpellManMethod$interrupt){
            if(BFL&BFL_CASTING){
                SpellAux$stopCast(SPELL_CASTED);
                multiTimer(["CAST"]);
                integer casting = BFL&BFL_CASTING;
                if(casting){
                    raiseEvent(SpellManEvt$interrupted, "");
                    A$(ASpellMan$interrupted);
                }
                spellEnd();
                if(casting)
                    SpellFX$startSound("6b050b67-295b-972d-113e-97bf21ccbb8f", .5, FALSE);
            }
        }
        else if(METHOD == SpellManMethod$rebuildCache){
			CACHE = [];
            GCD_FREE = [];
            PARAMS = [];
			
            SpellAux$cache();
            		
			GCD = (float)db3$get("got Bridge", ([BridgeShared$data, 2]));
			if(GCD<=0)GCD = 1.5;
			
            integer i;
            for(i=0; i<5; i++){
			    list d = llJson2List(db3$get(BridgeSpells$name+(str)i, []));
                if((integer)llList2Integer(d,5)&SpellMan$NO_GCD)GCD_FREE += TRUE;
                else GCD_FREE+=FALSE;
                
                CACHE+= llList2Float(d, 3);     // Cost
                CACHE+= llList2Float(d, 4);     // Cooldowns
                CACHE+= llList2Integer(d, 5);   // Targets
                CACHE+= llList2Float(d, 6);     // Range
                CACHE+= llList2Float(d, 7);     // Casttime
                CACHE+= (integer)jVal(llList2String(d, 2), [0]); // Detrimental
            }
		}
        else if(METHOD == SpellManMethod$resetCooldowns){
            integer flags = (integer)method_arg(0);
            integer i;
            for(i=0; i<flags; i++){
                if(flags&(integer)llPow(2,i)){
                    integer pos = llListFindList(COOLDOWNS, [i]);
                    if(~pos)
                        COOLDOWNS = llDeleteSubList(COOLDOWNS, pos, pos+CDSTRIDE-1);
                    
                    SpellAux$stopCast(i);
                }
            }
        }
    }
	
	// Owner only below here
	if(!method$byOwner)return;
    if(METHOD == SpellManMethod$replace){
		DB3$setOther(BridgeSpells$name+(str)((int)method_arg(0)+1), [], method_arg(1));
		SpellMan$rebuildCache();
	}
	
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
