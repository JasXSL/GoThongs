#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

/* This is the spell data cache */
list CACHE;                     // [(float)mana, (float)cooldown, (int)target_flags, (float)range, (float)casttime, (int)wrapperflags]
int GCD_FREE;    				// Spells that are freed from global cooldown        


#define CSTRIDE 6
float spellCost( list data, integer index ){
	float out = llList2Float(data, 0);
	if( out > 0 )
		out *= mcm*llList2Float(sp_mcm,index);
	return out;
}
#define spellCooldown(data, index) (llList2Float(data, 1)*cdm*llList2Float(sp_cdm,index))
#define spellTargets(data) llList2Integer(data, 2)
#define spellTargetsByIndex(index) llList2Integer(CACHE, index*CSTRIDE+2)
#define spellRange(data) llList2Float(data, 3)
#define spellCasttime(data, index) (llList2Float(data, 4)*ctm*llList2Float(sp_ctm,index))
#define spellWrapperFlags(data) llList2Integer(data, 5)


// Get a spell NR -1 to 3 data
#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)

/* Additional macros */
#define CDSTRIDE 4
// Should be sent after or more sets
#define pushCooldowns() SpellVis$setCooldowns(COOLDOWNS, f2i(llGetTime()))
// Sets the cooldown of the spell
#define setCooldown(index, intcd) COOLDOWNS = llListReplaceList(COOLDOWNS, [f2i(llGetTime()), f2i(intcd)], index*CDSTRIDE, index*CDSTRIDE+1); if(intcd){multiTimer(["CD_"+(string)index, "", intcd, FALSE]);}
// Sets the global cooldown of the spell. Spells off the global cooldown have their own "global" cooldown with the same time, but only for that spell
#define setGlobalCooldown(index, duration) COOLDOWNS = llListReplaceList(COOLDOWNS, [f2i(llGetTime()), f2i(duration)], index*CDSTRIDE+2, index*CDSTRIDE+3); multiTimer(["ICD_"+(string)index, "", duration, FALSE]);

// Returns a duration, may be negative
#define getCooldown(index) (i2f(l2i(COOLDOWNS, index*CDSTRIDE))+i2f(l2i(COOLDOWNS, index*CDSTRIDE+1))-llGetTime())
#define getGlobalCooldown(index) (i2f(l2i(COOLDOWNS, index*CDSTRIDE+2))+i2f(l2i(COOLDOWNS, index*CDSTRIDE+3))-llGetTime())
//#define pushCooldowns() integer _CD; list _CDS; for(_CD = 0; _CD<count(COOLDOWNS); ++_CD){_CDS+=f2i(l2f(COOLDOWNS, _CD));} SpellVis$setCooldowns(_CDS, llGetTime());
#define COOLDOWNS_DEFAULT [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]
list COOLDOWNS = COOLDOWNS_DEFAULT;            // (float)startTime0, (float)endTime0, (float)intcd_startTime, (float)internal_cd, startTime1, endTime1, internal_cd1... - 0 endTime means no cooldown
#define getGlobalCD() (GCD*cdm)

int S_CHD = 0;				// 4bit array of max charges
int S_CH = 0;				// 4bit array of current charges
#define setSpellCharges(index, charges) S_CH = ((S_CH&~(0xF<<(index*4)))|(charges<<(index*4)))
#define getSpellCharges(index) ((S_CH>>(index*4))&0xF)
#define getSpellMaxCharges(index) ((S_CHD>>(index*4))&0xF)
#define setSpellMaxCharges(index, charges) S_CHD = ((S_CHD&~(0xF<<(index*4)))|(charges<<(index*4)))

#define sendCharges() raiseEvent(SpellManEvt$charges, (str)S_CH);

// Standard spell input
// If castSpell is false, play interrupt sound
#define setQueue(index) if(QUEUE_SPELL != index){QUEUE_SPELL = index; SpellVis$setQueue(QUEUE_SPELL);}
#define clearQueue() QUEUE_SPELL = -1; BFL=BFL&~BFL_QUEUE_SELF_CAST; SpellVis$setQueue(QUEUE_SPELL)
#define startSpell(spell) if(castSpell(spell) == FALSE){llStopSound();llPlaySound("2967371a-f0ec-d8ad-4888-24b3f8f3365c", .2);clearQueue();}

// Global cooldown. Set by bridge.
float GCD = 1.5;

// FX
float cdm = 1;          // Cooldown mod
float ctm = 1;          // Casttime mod
float mcm = 1;          // Mana cost multiplier
integer fxflags;		
	// Index specific
list sp_mcm = [1,1,1,1,1];	// Mana cost
list sp_ctm = [1,1,1,1,1];	// Cast time
list sp_cdm = [1,1,1,1,1];	// Cooldown

#define canCastWhileMoving() (fxflags&fx$F_CAST_WHILE_MOVING || SPF&SpellMan$CASTABLE_WHILE_MOVING)


// Cache
int SPELL_WRAPPER_FLAGS;	// Casted spell's wrapper flags
int SPELL_CASTED;			// -1 to 3 of casted spell
int SPF;					// Casted spell's target flags

list SPELL_TARGS;				// List of targets to cast on
integer SPELL_ON_TARG = -1;		// A spell to queue when target is changed
float CACHE_CASTTIME = 0;
integer QUEUE_SPELL = -1;		// Spell to cast after finishing the current cast

// Calculated on spell start
float RANGE_ADD;
float HEIGHT_ADD;

key TARG_FOCUS;

integer BFL;
#define BFL_CASTING 1
#define BFL_START_CAST 2
#define BFL_CROUCH_HELD 0x8
#define BFL_QUEUE_SELF_CAST 0x10



// Checks line of sight, data is spelldata
bool visionCheck( list data ){

	string targ = llList2String(SPELL_TARGS, 0);
	if( targ != (string)LINK_ROOT && targ != "AOE" ){
	
		integer flags = spellTargets(data);
		vector pos = prPos(llList2String(SPELL_TARGS, 0));
		if( ~flags&TARG_REQUIRE_NO_FACING ){
		
			vector gpos = llGetRootPosition();
			prAngX(targ, ang);
			integer inRange = (llVecDist(pos, llGetRootPosition())<3 && llVecDist(<gpos.x,gpos.y,0>,<pos.x,pos.y,0>)<0.5);
			if(llFabs(ang)>PI_BY_TWO && !inRange){
				A$(ASpellMan$errTargInFront);
				SpellMan$interrupt(TRUE);
				return FALSE;
			}
		}
		
		list ray = llCastRay(llGetRootPosition()+<0,0,.5>, pos+<0,0,1+HEIGHT_ADD>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL, RC_DATA_FLAGS, RC_GET_ROOT_KEY]); 
		if(llList2Integer(ray, -1) == 1 && llList2Key(ray,0) != targ){ 
			A$(ASpellMan$errVisionObscured); 
			SpellMan$interrupt(TRUE); 
			return FALSE; 
		}
		
	}
	return TRUE;
	
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
                    SpellMan$interrupt(TRUE);
					
			// Selfcast key
            if(pressed&CONTROL_DOWN)
				BFL = BFL|BFL_CROUCH_HELD;            
        }
		else if(evt == evt$BUTTON_RELEASE){
			integer release = llList2Integer(data,0);
			if(release&CONTROL_DOWN)
				BFL = BFL&~BFL_CROUCH_HELD;    
		}
		
		else if( evt == RootEvt$focus )
			TARG_FOCUS = l2s(data, 0);
		
		
		// This is how spells are cast.
		else if(evt == evt$TOUCH_START){
            integer nr = llList2Integer(data,0);
            if(count(data) > 1){ 
				string ln = llGetLinkName(nr); 
                if( !startsWith(ln,"aol") )
					return;
                nr = (integer)llGetSubString(ln, -1, -1);
            }
            startSpell(nr);
        }

		// Update target cache
		else if( evt == RootEvt$targ && SPELL_ON_TARG != -1 ){
			startSpell(SPELL_ON_TARG);
		}

    }
}



// This attempts to start casting a spell
integer castSpell(integer nr){


	if( SPELL_ON_TARG == -1 && nr != QUEUE_SPELL )
		llPlaySound("31086022-7f9a-65d1-d1a7-05571b8ea0f2", .5);
    
	SPELL_ON_TARG = -1;
	// Play the click sound
	
	// Grab data from cache
    list data = nrToData(nr);
    // Grab spell flags
	SPF = spellTargets(data);
	int TEAM = hud$status$team();

	// BEFORE QUEUE
	// Check if I have enough mana BEFORE allowing a queue
    float cost = spellCost(data, nr);
    if( cost > hud$status$mana() ){
        A$(ASpellMan$errInsufficientMana);
        return FALSE;
    }
	
	// Cannot cast right now because of FX silence
    if(fxflags&fx$NOCAST || llGetAgentInfo(llGetOwner())&AGENT_SITTING || fxflags&fx$F_QUICKRAPE || SPF&SpellMan$HIDE){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }
	
    if( BFL&BFL_CASTING || !getSpellCharges(nr) || getGlobalCooldown(nr) > 0 ){
	
		// Queue the spell
		integer q = nr;
		if( nr == QUEUE_SPELL ){
		
			q = -1;
			BFL = BFL&~BFL_QUEUE_SELF_CAST;
			llPlaySound("691cc796-7ed6-3cab-d6a6-7534aa4f15a9", .5);
			
		}
		else if( BFL&BFL_CROUCH_HELD )
			BFL = BFL|BFL_QUEUE_SELF_CAST;
		
		setQueue(q);
		return -2;
		
	}
    
	
    
    // Cache the wrapper flags and check if player is pacified
    integer SPELL_WRAPPER_FLAGS = spellWrapperFlags(data);
    if( fxflags&fx$F_PACIFIED && SPELL_WRAPPER_FLAGS&WF_DETRIMENTAL ){
        A$(ASpellMan$errPacified);
        return FALSE;
    }

    

	SPELL_TARGS = [];
	// AoE overrides all other
	if( SPF & TARG_AOE ){
		SPELL_TARGS = ["AOE"];
	}
	// Self only
	else if( SPF == TARG_CASTER ){
		SPELL_TARGS = [LINK_ROOT];
	}
	// Gotta check target
	else{
	
		// Get key of our current target
		key targ = hud$root$targ();
		parseTeam(targ, team)
		
		
		
		// Check if we have a target
		integer noTarg = targ == "";
		// Shorten self target to ""
		if( targ == llGetOwner() || targ == llGetKey() )
			targ = ""; 
			
		if( 
			targ != "" && // target exists
			(
				// ~SPF&TARG_CASTER || // Not sure why this is here
				(BFL&(BFL_CROUCH_HELD|BFL_QUEUE_SELF_CAST)) == 0
			)
		){
			
			if( 
				// Friendly target allowed
				(
					SPF&TARG_PC && 
					team == TEAM
				) ||
				// Enemy target allowed
				(
					SPF&TARG_NPC &&
					team != TEAM
				)
			){
				SPELL_TARGS = [targ];
			}
		}
		// Focus target exists
		else if(
			BFL&(BFL_QUEUE_SELF_CAST|BFL_CROUCH_HELD) &&	// Target focus modifier set
			TARG_FOCUS != ""
		){
			
			int focusIsCaster = TARG_FOCUS == llGetOwner() || TARG_FOCUS == llGetKey();
			if( 
				(
					focusIsCaster && SPF&TARG_CASTER
				) ||
				(
					!focusIsCaster && SPF&TARG_PC &&			// Only friends can be focused 
					(team != TEAM || noTarg)	// Friendly target is ALWAYS focus, we can use the target for that instead
				)
			)SPELL_TARGS = [TARG_FOCUS];
		}

		// No targets passed filter, but this can target self, so auto self cast (using a green spell on enemy)
		if( SPF&TARG_CASTER && SPELL_TARGS == [] )
			SPELL_TARGS = [LINK_ROOT];
		// Already casting, but we can queue this?
		else if( SPF&TARG_NPC && targ == "" && SPELL_ON_TARG == -1 && SPELL_TARGS == [] )
			SPELL_TARGS = ["Q"];
		
	}
	
	// If I don't have a target and the spell requires one, try to grab one and cast on it
	if((string)SPELL_TARGS == "Q"){
		// Set a spell to cast when we get a target
		SPELL_ON_TARG = nr;
		multiTimer(["Q", "", 2, FALSE]);
		Evts$cycleEnemy(FALSE);
		return -2;
	}
	
	
    
	// No targets valid
    if(SPELL_TARGS == []){
        A$(ASpellMan$errInvalidTarget);
        return FALSE;
    }
    
	
    
	// If I'm raped or dead
	integer sf = hud$status$flags();
    if( sf&StatusFlags$noCast || (SPF&SpellMan$NO_SWIM && sf&StatusFlag$swimming) ){
        A$(ASpellMan$errCantCastNow);
        return FALSE;
    }
	
	// Need to cache hitbox data

	RANGE_ADD = 0;
	HEIGHT_ADD = 0;
	list at = llGetObjectDetails(l2s(SPELL_TARGS, 0), [OBJECT_DESC, OBJECT_ATTACHED_POINT]);
	if( !llList2Integer(at, 1) ){
	
		// This is an NPC, add range add
		list split = explode("$", l2s(at, 0));
		RANGE_ADD = l2f(split, 4)/10.;
		HEIGHT_ADD = l2f(split, 5)/10.;
		
	}

	// Run LOS check
    if( !visionCheck(data) )
		return FALSE;
    
    
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
            if((integer)val != LINK_ROOT)dist = llVecDist(llGetRootPosition(), prPos(val));
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
	if(casttime < 0)
		casttime = 0;
	clearQueue();
	
	// Set the current spell being cast
    SPELL_CASTED = nr;
    
    
	float gcd = getGlobalCD();
	if(gcd<0.5)
		gcd = 0.5;
	
		
    // This spell should set the global cooldown for all relevant spells
    if( ~SPF&SpellMan$NO_GCD ){
	
        integer i;
        for( i=0; i<5; i++ ){
		
			// If global cooldown is longer than any active cooldown
			if( ~GCD_FREE&(1<<i) )
				setGlobalCooldown(i, gcd);
			
        }

        multiTimer(["GCD", "", gcd, FALSE]);
		
    }
	// Set internal GCD for the spell
	else
		setGlobalCooldown(nr, gcd);

	// Cache the casttime
	CACHE_CASTTIME = casttime;
	if(casttime){
		// Only raise the start cast event on spells with a cast time
		list evData = [
			f2i(casttime), 
			mkarr(SPELL_TARGS),
			SPELL_CASTED,
			SPF
		];
		raiseEvent(SpellManEvt$cast, mkarr(evData));
        BFL = BFL|BFL_CASTING;					// Set casting
        BFL = BFL|BFL_START_CAST;				// Used to track when it should be interrupted on button press
        multiTimer(["SC", "", .25, FALSE]);
    
        //SpellAux$setCastedAbility(nr, casttime);
        multiTimer(["CAST", "", casttime, FALSE]);
    }
	// Immediately finish
    else 
		spellComplete();
	
	// Push cooldowns after looks better
	//if( ~SPF&SpellMan$NO_GCD )
	pushCooldowns();
	
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
	
		if( !visionCheck(data) )
			return;
		SpellFX$stopSound();
		
    }
    
	float gcd = getGlobalCD();
	if( gcd<0.5 )
		gcd = 0.5;
	
	// Send to AUX to finish the cast
	// Don't wipe CD if there's no cooldown on a non-gcd spell OR if casttime is less than global cooldown
	integer noWipe = ((tflags&SpellMan$NO_GCD && cooldown<=0) || CACHE_CASTTIME<gcd);
    //SpellAux$finishCast(SPELL_CASTED, mkarr(SPELL_TARGS), noWipe);
            
    
    // Consume mana
    if( cost != 0 )
		Status$batchUpdateResources("", SMBUR$buildMana(-cost, "", 0));
	
    // Set cooldown
    if( cooldown ){
	
		// Only first charge sets the cooldown to prevent resetting subsequent charges
		if( getSpellCharges(SPELL_CASTED) >= getSpellMaxCharges(SPELL_CASTED) ){
			setCooldown(SPELL_CASTED, cooldown);
		}
		
		// only spells with a cooldown can have charges
		setSpellCharges(SPELL_CASTED, getSpellCharges(SPELL_CASTED)-1);
		sendCharges();	// Charges need to be sent first to be shown properly
		
		
    }

    raiseEvent(SpellManEvt$complete, llList2Json(JSON_ARRAY, [
		SPELL_CASTED, 
		l2s(SPELL_TARGS,0), 
		(flags&WF_DETRIMENTAL)>0, 
		mkarr(SPELL_TARGS), 
		noWipe,
		f2i(CACHE_CASTTIME)
	]));
    spellEnd();
	
	// Cooldowns have to be pushed last
	if( cooldown )
		pushCooldowns();
		
}

// Run from both complete and interrupt
spellEnd(){

    list data;
    if( ~SPELL_CASTED )
		data = nrToData(SPELL_CASTED);
    
    BFL = BFL&~BFL_CASTING;
    BFL = BFL&~BFL_START_CAST;
    ThongMan$sound("",0, FALSE);
    
    
    //SpellAux$spellEnd();
    
    if(spellCasttime(data, SPELL_CASTED) > 0)
		ThongMan$particles(0, 1, "[]");
    
	
	// Cast queued spell if possible
	checkQueueCast();
	// Push cooldowns to make sure cast bars are cleared right
	pushCooldowns();
	
}

timerEvent(string id, string data){
    
	if( id == "CAST" )
		spellComplete();
    else if( id == "SC" )
        BFL = BFL&~BFL_START_CAST;
    else if( id == "GCD" ){
        
		checkQueueCast(); // Cast queue if possible
		
    }
	else if( id == "Q" )
		SPELL_ON_TARG = -1;
	else if( startsWith(id, "CD_") ){
		
		int idx = (int)llGetSubString(id, 3, -1);
		setSpellCharges(idx, getSpellCharges(idx)+1);
		if( getSpellCharges(idx) >= getSpellMaxCharges(idx) ){
			setSpellCharges(idx, getSpellMaxCharges(idx));
		}
		sendCharges();
		// Got another charge to load
		if( getSpellCharges(idx) < getSpellMaxCharges(idx) ){
			list d = nrToData(idx);
			setCooldown(idx, spellCooldown(d, idx));
			pushCooldowns();
		}
		
		checkQueueCast();
	}
	
	// Run a queue check by force OR A cooldown has finished and is not on GCD
	if(
		id == "CQ" ||
		startsWith(id, "ICD_") ||
		startsWith(id, "CD_")
	){
		if(
			QUEUE_SPELL == -1 ||
			!getSpellCharges(QUEUE_SPELL) ||
			BFL&BFL_CASTING ||
			getGlobalCooldown(QUEUE_SPELL) > 0		// Global cooldown is the only one that maaters, use charges instead for normal cd
		)return;
		if( !castSpell(QUEUE_SPELL) ){
			clearQueue();
		}
	}
}

default{

    // Timer event
    timer(){multiTimer([]);}
	    
    #define LM_PRE \
	if(nr == TASK_FX){ \
		ctm = (float)fx$getDurEffect(fxf$CASTTIME_MULTI); \
        cdm = (float)fx$getDurEffect(fxf$COOLDOWN_MULTI); \
        mcm = (float)fx$getDurEffect(fxf$MANA_COST_MULTI); \
        fxflags = (int)fx$getDurEffect(fxf$SET_FLAG); \
		sp_mcm = llJson2List(fx$getDurEffect(fxf$SPELL_MANACOST_MULTI)); \
		sp_ctm = llJson2List(fx$getDurEffect(fxf$SPELL_CASTTIME_MULTI)); \
		sp_cdm = llJson2List(fx$getDurEffect(fxf$SPELL_COOLDOWN_MULTI)); \
        if(BFL&BFL_CASTING){ \
            if(fxflags&fx$NOCAST)SpellMan$interrupt(TRUE); \
            else if(fxflags&fx$F_PACIFIED && SPELL_WRAPPER_FLAGS&WF_DETRIMENTAL) \
                SpellMan$interrupt(TRUE); \
        } \
	}
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        if(SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared)
            SpellMan$rebuildCache();
        return;
    }
	
	// Allow owner for debug
	if( METHOD == SpellManMethod$rebuildCache && method$byOwner ){
		CACHE = [];
		GCD_FREE = 0;
		COOLDOWNS = COOLDOWNS_DEFAULT;
		S_CHD = 0;	// Charges default
		
		//SpellAux$cache();
		raiseEvent(SpellManEvt$recache, "");
		
		GCD = (float)j(hud$bridge$thongData(), BSS$GCD);
		if( GCD <= 0 )
			GCD = 1.5;
		
		str tmpCh = hudTable$spellmanSpellsTemp;
		str ch = hudTable$bridgeSpells;
		integer i;
		for( ; i < 5; ++i ){
			
			list d = llJson2List(db4$get(tmpCh, i));
			if(d == [])
				d = llJson2List(db4$get(ch, i));
			
			
			if( (integer)llList2Integer(d,BSSAA$target_flags)&SpellMan$NO_GCD )
				GCD_FREE = GCD_FREE | (1<<i);
			
			CACHE+= llList2Float(d, BSSAA$mana);     // Cost
			CACHE+= llList2Float(d, BSSAA$cooldown);     // Cooldowns
			CACHE+= llList2Integer(d, BSSAA$target_flags);   // Targets
			CACHE+= llList2Float(d, BSSAA$range);     // Range
			CACHE+= llList2Float(d, BSSAA$casttime);     // Casttime
			CACHE+= (int)j(llList2String(d, BSSAA$fxwrapper), 0); // Detrimental
			int ch = l2i(d, BSSAA$charges);
			if( ch < 1 )
				ch = 1;
			setSpellMaxCharges(i, ch);
			
		}
		
		S_CH = S_CHD;	// Reset charges to max
		
	}
    
    // Internal means the method was sent from within the linkset
    if(method$internal){
        if(METHOD == SpellManMethod$hotkey){
            string dta = method_arg(0);
            
            integer spell = -1;
            if( llGetSubString(dta, 0, 4) == "abil_" )
				spell = (integer)llGetSubString(dta, 5, -1);
            if(~spell && spell<5)
                onEvt("#ROOT", evt$TOUCH_START, [spell]);
            
        }
        else if(METHOD == SpellManMethod$interrupt){
            if(~BFL&BFL_CASTING || (fxflags&fx$F_NO_INTERRUPT && !l2i(PARAMS, 0)))
				return;
            
			//SpellVis$stopCast(SPELL_CASTED);
            multiTimer(["CAST"]);

			raiseEvent(SpellManEvt$interrupted, mkarr(([SPELL_CASTED, f2i(CACHE_CASTTIME)])));
			A$(ASpellMan$interrupted);
			spellEnd();				
            SpellFX$startSound("6b050b67-295b-972d-113e-97bf21ccbb8f", .5, FALSE);
        }
        else if(METHOD == SpellManMethod$resetCooldowns){
		
            integer flags = (integer)method_arg(0);
			integer charges = (int)method_arg(1);
			if(!charges)
				charges = 1;
            integer i;
            for( i=0; i<flags; i++ ){
			
                if( flags&(1<<i) ){
				
					setSpellCharges(i, getSpellCharges(i)+charges);
					if( getSpellCharges(i) >= getSpellMaxCharges(i) ){
						
						setSpellCharges(i, getSpellMaxCharges(i));
						setCooldown(i, 0);
						
					}
					
                }
				
            }
			sendCharges();
			pushCooldowns();
			
        }
		else if( METHOD == SpellManMethod$reduceCD ){
			
			integer n = l2i(PARAMS, 0);
			float sec = l2f(PARAMS, 1);
			integer i;
			integer ch;
			for( i=0; i<5; ++i ){
				
				if( n&(1<<i) && getCooldown(i) > 0 ){
					
					float c = sec;
					@nextSpellCD;
					// This should be reduced
					COOLDOWNS = llListReplaceList(COOLDOWNS, (list)(l2i(COOLDOWNS, i*CDSTRIDE)-f2i(c)), i*CDSTRIDE, i*CDSTRIDE); 
					// There is cooldown remaining
					if( getCooldown(i) > 0 ){
						multiTimer(["CD_"+(string)i, "", getCooldown(i), FALSE]);
					}
					// Cooldown went negative or 0
					else{
					
						setSpellCharges(i, getSpellCharges(i)+1);
						// Charges are full
						if( getSpellCharges(i) >= getSpellMaxCharges(i) ){
						
							setSpellCharges(i, getSpellMaxCharges(i));
							setCooldown(i, 0);
							
						}
						// Charges are still not full so we need to reduce another cooldown
						else{
							// There are charges still needed
							c+=getCooldown(i);	// this will be negative now
							// Set a new cooldown
							setCooldown(i, i2f(l2i(COOLDOWNS, i*CDSTRIDE+1)));
							// Reduce it by time left
							jump nextSpellCD;						
						}
					}
					++ch;
				
				}
				
			}
			
			if( ch ){
				sendCharges();
				pushCooldowns();
			}
		}
		
    }
	
    if(METHOD == SpellManMethod$replace){
		
		int spell = l2i(PARAMS, 0)+1;	// (Argument uses -1 for ability 5)

		if( method_arg(1) == "" )
			db4$delete(hudTable$spellmanSpellsTemp, spell);
		else
			db4$replace(hudTable$spellmanSpellsTemp, spell, method_arg(1));
			
		if( l2i(PARAMS, 2) )
			SpellMan$rebuildCache();
			
	}
	
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
