#define USE_EVENTS
#define USE_SHARED [cls$name, "#ROOT", BridgeSpells$name, "got Status", "got Bridge"]
#include "got/_core.lsl"

/* This is the spell data cache */
list CACHE;                     // [(int)id, (arr)wrapper, (float)mana, (float)cooldown, (int)target_flags, (float)range, (float)casttime, (arr)fx, (arr)selfcastWrapper]
list GCD_FREE;    				// Spells that are freed from global cooldown        

#define CSTRIDE 6
#define spellCost(data) (llList2Float(data, 0)*mcm)
#define spellCooldown(data) (llList2Float(data, 1)*cdm)
#define spellTargets(data) llList2Integer(data, 2)
#define spellRange(data) llList2Float(data, 3)
#define spellCasttime(data) (llList2Float(data, 4)*ctm)
#define spellWrapperFlags(data) llList2Integer(data, 5)

// Get a spell NR -1 to 3 data
#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)

/* Additional macros */
#define spellOnCooldown(id) (~llListFindList(COOLDOWNS, [id]))
#define CDSTRIDE 2
list COOLDOWNS = [];            // (int)buttonID, (float)finish_time
#define getGlobalCD() (GCD*cdm)

// Standard spell input
// If castSpell is false, play interrupt sound
#define startSpell(spell) if(castSpell(spell) == FALSE){llStopSound();llPlaySound("2967371a-f0ec-d8ad-4888-24b3f8f3365c", .2);}


// Global cooldown. Set by bridge.
float GCD = 1.5;

// FX
float cdm = 1;          // Cooldown mod
float ctm = 1;          // Casttime mod
float mcm = 1;          // Mana cost multiplier
integer fxflags;		



// Cache
integer STATUS_FLAGS;			// Flags from status
integer SPELL_WRAPPER_FLAGS;	// Casted spell's wrapper flags
integer SPELL_CASTED;			// -1 to 3 of casted spell
list SPELL_TARGS;				// List of targets to cast on
key CACHE_ROOT_TARGET;			// Cache of the player's current target
integer QUEUE_SPELL = -2;		// A spell to queue when target is changed
float CACHE_CASTTIME = 0;

list PLAYERS;					// Me and coop player

integer BFL;
#define BFL_CASTING 1
#define BFL_START_CAST 2
#define BFL_GLOBAL_CD 0x4


// This is a code block that checks if a player is visible. Ret is an optional return value
#define CODE$VISION_CHECK(ret) \
string targ = llList2String(SPELL_TARGS, 0); \
if(targ != (string)LINK_ROOT && targ != "AOE"){ \
    integer flags = spellTargets(data); \
    if(~flags&TARG_REQUIRE_NO_FACING){ \
        prAngX(targ, ang); \
        if(llFabs(ang)>PI_BY_TWO){ \
            A$(ASpellMan$errTargInFront); \
            SpellMan$interrupt(); \
            return ret; \
        } \
    }\
    list bounds = llGetBoundingBox(llList2String(SPELL_TARGS, 0));\
    vector b = llList2Vector(bounds, 0)-llList2Vector(bounds,1); \
    float h = llFabs(b.z/2); \
    list ray = llCastRay(llGetPos()+<0,0,.5>, prPos(llList2String(SPELL_TARGS, 0))+<0,0,h>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]); \
    if(llList2Integer(ray, -1) == 1 && llList2Key(ray,0) != targ){ \
        A$(ASpellMan$errVisionObscured); \
        SpellMan$interrupt(); \
        return ret; \
    } \
}

// Default event handler
onEvt(string script, integer evt, string data){
    if(script == "#ROOT"){
        if(evt == evt$BUTTON_PRESS){
            integer pressed = (integer)data;
			
			// interrupt if casting and pressing an arrow key
            if(BFL&BFL_CASTING && ~BFL&BFL_START_CAST)
                if(pressed&(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT))
                    SpellMan$interrupt();
            
			// ON crouch, rest
            if(pressed&CONTROL_DOWN)
                startSpell(-1);
            
        }
		
		// This is how spells are cast.
		else if(evt == evt$TOUCH_START){
            string ln = llGetLinkName((integer)jVal(data, [0]));
            integer nr;
            if(llGetSubString(data, 0, 0) == ";"){
                nr = (integer)llGetSubString(data, 1, -1);
            }else{
                if(llGetSubString(ln, 0, 3) != "Abil")return;
                nr = (integer)llGetSubString(ln, -1, -1);
            }
            nr--;
            startSpell(nr);
        }
		
		// Set players
		else if(evt == RootEvt$players)
            PLAYERS = llJson2List(data);
			
		// Update target cache
		else if(evt == RootEvt$targ){
			CACHE_ROOT_TARGET = j(data,0);
			if(QUEUE_SPELL != -2){
				startSpell(QUEUE_SPELL);
			}
		}
        
    }
	
	// Cache FX flags
	else if(script == "got FXCompiler" && evt == FXCEvt$update){
        ctm = (float)j(data, FXCUpd$CASTTIME);
        cdm = (float)j(data, FXCUpd$COOLDOWN);
        mcm = (float)j(data, FXCUpd$MANACOST);
        fxflags = (integer)jVal(data, [0]);
        if(BFL&BFL_CASTING){
            if(fxflags&fx$NOCAST)SpellMan$interrupt();
            else if(fxflags&fx$F_PACIFIED && SPELL_WRAPPER_FLAGS&WF_DETRIMENTAL)
                SpellMan$interrupt();
        }
    }
	
	// Cache status flags
	else if(script == "got Status" && evt == StatusEvt$flags)STATUS_FLAGS = (integer)data;
}


// This is a macro that turns flags into targets
// Returns a list of targets or ["AOE"], or ["Q"] to queue on target change
#define flagsToTargets(targets, var) var = []; \
if(targets & TARG_AOE)var = ["AOE"]; \
else if(targets == TARG_CASTER)var = [LINK_ROOT]; \
else{ \
	key targ = CACHE_ROOT_TARGET;\
    if(targ == llGetOwner())targ = ""; \
    key coop = llList2Key(PLAYERS, 1); \
    if(isset(targ)){ \
        if(targets&TARG_PC && targ == coop)var = [targ]; \
        else if(targets&TARG_NPC && llListFindList(PLAYERS, [targ]) == -1)var = [targ]; \
    } \
    if(targets&TARG_CASTER && var == [])var = [LINK_ROOT]; \
	else if(targets&TARG_NPC && !isset(targ) && QUEUE_SPELL == -2){ \
		var = ["Q"];\
	}\
}

// This attempts to start casting a spell
integer castSpell(integer nr){
	if(QUEUE_SPELL == -2)llPlaySound("31086022-7f9a-65d1-d1a7-05571b8ea0f2", .5);
    QUEUE_SPELL = -2;
	// Play the click sound
    
	
	// Already casting
    if(BFL&BFL_CASTING){
        A$(ASpellMan$errCastInProgress);
        return FALSE;
    }
    
	// Grab data from cache
    list data;
    if(~nr)
        data = nrToData(nr);
    
	// Grab target flags
	integer spt = spellTargets(data);
	// Spell is on cooldown
    if(spellOnCooldown(nr) || (BFL&BFL_GLOBAL_CD && ~spt&SpellMan$NO_GCD)){
        A$(ASpellMan$errCantCastYet);
        return FALSE;
    }
	// Cannot cast right now because of FX silence
    if(fxflags&fx$NOCAST){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }
    
    // Cache the wrapper flags and check if player is pacified
    integer SPELL_WRAPPER_FLAGS = spellWrapperFlags(data);
    if(fxflags&fx$F_PACIFIED && SPELL_WRAPPER_FLAGS&WF_DETRIMENTAL){
        A$(ASpellMan$errPacified);
        return FALSE;
    }
    
	// Check if player is in a quickrape
    if(fxflags&fx$F_QUICKRAPE){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }
    
	// Default to self on rest
    SPELL_TARGS = [LINK_ROOT];
    if(~nr){
		// Not rest, so let's grab targets
		
        flagsToTargets(spt, SPELL_TARGS);
		
		// If I don't have a target and the spell requires one, try to grab one and cast on it
		if((string)SPELL_TARGS == "Q"){
			// Queue a spell
			QUEUE_SPELL = nr;
			multiTimer(["Q", "", 2, FALSE]);
			Evts$cycleEnemy();
			return -2;
		}
    }
	
	// No targets valid
    if(SPELL_TARGS == []){
        A$(ASpellMan$errInvalidTarget);
        return FALSE;
    }
    
	// Check if I have enough mane
    float cost = spellCost(data);
    if(cost>(float)db2$get("got Status", ([StatusShared$mana,0]))){
        A$(ASpellMan$errInsufficientMana);
        return FALSE;
    }
    
	// If I'm raped or dead
    if(STATUS_FLAGS&(StatusFlag$dead|StatusFlag$raped)){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }
	
	// Run LOS check
    CODE$VISION_CHECK(FALSE)
    
	
    
	// Check spell range
    float range = spellRange(data);
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
    
    // Grab the casttime and multiply it
    float casttime = spellCasttime(data);
    if(nr == -1)casttime = 1.5*ctm;
    
	
	// Set the current spell being cast
    SPELL_CASTED = nr;
    
    
    
    // Set global cooldown
    if(~spt&SpellMan$NO_GCD){
        integer CDS = 682;		// 2bit array default 1010101010 (each value is 2)
        
        integer i;
        for(i=0; i<5; i++){
            float cdt = 0;
            integer pos = llListFindList(COOLDOWNS, [i-1]);
            if(~pos)cdt = llList2Float(COOLDOWNS, pos+1);
            if(llList2Integer(GCD_FREE,i) || cdt-llGetTime()>getGlobalCD() || (i-1 == SPELL_CASTED && casttime>0)){
				CDS = remBitArr(CDS, i, 2);	// Set to 0 (leave unchanged)
			}
        }
        SpellAux$setGlobalCooldowns(getGlobalCD(), CDS);
        BFL = BFL|BFL_GLOBAL_CD;
        multiTimer(["GCD", "", getGlobalCD(), FALSE]);
    }
	
	// Cache the casttime
	CACHE_CASTTIME = casttime;
	if(casttime){
		// Only raise the start cast event on spells with a cast time
		raiseEvent(SpellManEvt$cast, "["+(string)casttime+"]");
        BFL = BFL|BFL_CASTING;
        BFL = BFL|BFL_START_CAST;
        multiTimer(["SC", "", .25, FALSE]);
    
        //SpellAux$setCastedAbility(nr, casttime);
        multiTimer(["CAST", "", casttime, FALSE]);
        
        SpellAux$startCast(SPELL_CASTED, casttime);
    }
	// Immediately finish
    else spellComplete();
	
    
    return TRUE;
}

spellComplete(){
	// Grab the data
	list data;
    if(~SPELL_CASTED)data = nrToData(SPELL_CASTED);
    float cooldown = spellCooldown(data);
	integer tflags = spellTargets(data);
	// Make sure LOS is proper unless it's instant cast
    if(CACHE_CASTTIME>0){
		CODE$VISION_CHECK()
		SpellFX$stopSound();
    }
    
	// Send to AUX to finish the cast
	// Don't wipe CD if there's no cooldown on a non-gcd spell OR if casttime is less than global cooldown
	integer noWipe = ((tflags&SpellMan$NO_GCD && cooldown<=0) || CACHE_CASTTIME<getGlobalCD());
    SpellAux$finishCast(SPELL_CASTED, mkarr(SPELL_TARGS), noWipe);
            
    // Set cooldown
    
    if(SPELL_CASTED == -1)cooldown = 10*cdm;
    else Status$addMana(-spellCost(data), "", false);
    
	
    if(cooldown){
		SpellAux$setCooldown(SPELL_CASTED, cooldown);
        if(llListFindList(COOLDOWNS, [SPELL_CASTED]) == -1)
			COOLDOWNS+=[SPELL_CASTED, llGetTime()+cooldown];
                
        multiTimer(["CD_"+(string)SPELL_CASTED, "", cooldown, FALSE]);
    }
	// If it's a casted spell on global cooldown and the casttime is less than global cooldown
    else if(CACHE_CASTTIME<getGlobalCD() && CACHE_CASTTIME>0 && ~tflags&SpellMan$NO_GCD)SpellAux$setCooldown(SPELL_CASTED, getGlobalCD()-CACHE_CASTTIME);
	//else GUI$stopCast(SPELL_CASTED);
	
	
    raiseEvent(SpellManEvt$complete, (string)SPELL_CASTED);
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
    
    if(spellCasttime(data)){
        ThongMan$particles(0, 1, "[]");
    }
}

timerEvent(string id, string data){
    if(id == "CAST")spellComplete();
    else if(llGetSubString(id,0,2) == "CD_"){
        integer rem = (integer)llGetSubString(id,3, -1);
        integer pos = llListFindList(COOLDOWNS, [rem]);
        if(~pos)COOLDOWNS = llDeleteSubList(COOLDOWNS, pos, pos+CDSTRIDE-1);
        
        if(~BFL&BFL_GLOBAL_CD)SpellAux$stopCast(rem);
    }
    else if(id == "SC")
        BFL = BFL&~BFL_START_CAST;
    else if(id == "GCD"){
        BFL = BFL&~BFL_GLOBAL_CD;
        integer CDS = 0;		// 0	- Each value is 0 (disregard)
        integer i;
        list c = llList2ListStrided(COOLDOWNS, 0, -1, CDSTRIDE);
        for(i=0; i<5; i++){
            if(llListFindList(COOLDOWNS, [i-1]) == -1 && (~BFL&BFL_CASTING|| i-1 != SPELL_CASTED)){
                CDS = setBitArr(CDS, 1, i, 2);	// set to 1 (wipe)
			}
        }
        SpellAux$setGlobalCooldowns(getGlobalCD(), CDS);
    }
	else if(id == "Q")QUEUE_SPELL = -2;
}



default 
{
    state_entry(){
        db2$ini();
    }
    
    // Timer event
    timer(){multiTimer([]);}
    
    
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
                onEvt("#ROOT", evt$TOUCH_START, ";"+(string)spell);
            
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
            GCD_FREE = [FALSE];
            list spells = llJson2List(db2$get(BridgeSpells$name, []));
            SpellAux$cache();
            PARAMS = "";
			
			GCD = (float)db2$get("got Bridge", ([BridgeShared$data, 2]));
			if(GCD<=0)GCD = 1.5;
			
            integer i;
            for(i=0; i<llGetListLength(spells); i++){
                list d = llJson2List(llList2String(spells, i));
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
                    integer n = i-1;
                    
                    integer pos = llListFindList(COOLDOWNS, [n]);
                    if(~pos)
                        COOLDOWNS = llDeleteSubList(COOLDOWNS, pos, pos+CDSTRIDE-1);
                    
                    SpellAux$stopCast(n);
                }
            }
        }
    }
    
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
