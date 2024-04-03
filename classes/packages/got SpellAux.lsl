#define USE_DB4
#define PMATH_CONSTS _C
#define USE_EVENTS
#define IGNORE_CALLBACKS
#include "got/_core.lsl"

list _C;		// Math constants

key HUD_TARG;

// Contains the fx data
#define CSTRIDE 4
// This is the actual spell data cached
list CACHE;
#define spellWrapper(spellnr) llList2String(CACHE, spellnr*CSTRIDE+0)
#define spellSelfcast(spellnr) llList2String(CACHE, spellnr*CSTRIDE+1)
#define spellRange(spellnr) llList2Float(CACHE, spellnr*CSTRIDE+2)
#define spellFlags(spellnr) llList2Integer(CACHE, spellnr*CSTRIDE+3)

#define nrToIndex(nr) nr*CSTRIDE
//#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)
#define difDmgMod() SpellAux$difficultyDamageDoneModifier( hud$status$difficulty() )

// Calculates bonus damage for particular spells
// Needs to match NUM_SPELLS in _core
list SPDM = [1,1,1,1,1,1];		// [abilt5, abil0, abil1...]

// FX
list dtmod = [0,1];		// Damage taken modifier from PASSIVE
float bfDmg = 1;		// Befuddle damage multiplier
float cmod = 0;
float cdmod = 1;		// Cooldown modifier
float hdmod = 1;		// Healing done mod
float cCR = 1.0;		// Crit multiplier this cast
list dmod;				// int playerID, float amount

float befuddle;			// Chance to cast at a random target
float bsMul = 1;	// Additional damage when attacking from behind
integer fxFlags = 0;

#define pmod (1./hud$root$numPlayers())

/* Constants:
	$T0$	Target of spell (if not AoE) Only differs from $TARG$ in self cast
	$TARG$	Target of wrapper
	$SELF$	Script owner
	$HT$	Active HUD-target.
	$otI$	Integered version of original target
	$tI$	Same but for wrapper target
	$sI$	Same but for sender HUD
	$soI$	Same but for sender agent
	$aoeI$	Used for AoE and replaced by the recipient on spellvis received
*/
string t0;	// First target of a targeted spell

string runMath( string FX, integer index, key targ ){

	if( (str)targ == (str)LINK_ROOT )
		targ = llGetKey();
	
	FX = implode(targ, explode("$TARG$", FX));
	FX = implode(t0, explode("$T0$", FX));
	FX = implode((str)llGetKey(), explode("$SELF$", FX));
	FX = implode((str)HUD_TARG, explode("$HT$", FX));
	
	// these can not be math vars because of float limitations
	FX = implode((str)((int)("0x"+t0)), explode("$otI$", FX));
	FX = implode((str)((int)("0x"+(str)targ)), explode("$tI$", FX));
	FX = implode((str)((int)("0x"+(str)llGetKey())), explode("$sI$", FX));
	FX = implode((str)((int)("0x"+(str)llGetOwner())), explode("$soI$", FX));
	
	// 
	float cAR = hud$status$arousal();
	float cPP = hud$status$pain();
	float cMHP = hud$status$maxHP();
	float cHP = hud$status$hp();
	float cMP = hud$status$mana();
	float cMMP = hud$status$maxMana();
	float cArmor = hud$status$armor();
	integer TEAM = hud$status$team();
	
	// The character before gets removed, so use $$M$ if the math is not a whole string like "$MATH$algebra"
    list split = llParseString2List(FX, ["$MATH$","$M$"], []);
	parseDesc(targ, resources, status, fxf, sex, team, monsterflags, _a, _b)
	list res = splitResources(resources);
	int ehp = (int)(l2f(res, 0)*100);
	int emp = (int)(l2f(res, 1)*100);
	int ear = (int)(l2f(res, 2)*100);
	int epa = (int)(l2f(res, 3)*100);
	
	float bsm = 1;
	integer B = 0;
	rotation axis = llEuler2Rot(<0,PI_BY_TWO,0>);
	
	if( monsterflags & Monster$RF_ANIMESH )
		axis = ZERO_ROTATION;
	myAng(targ, ang, axis) // check if I am behind target
		
	if( (llFabs(ang) > PI_BY_TWO || fxFlags&fx$F_ALWAYS_BEHIND) && targ != llGetKey() ){
		B = 1;
		bsm = bsMul;
	}
	float spdmdm = llList2Float(SPDM, index);
	if( spdmdm < 0 )
		spdmdm = 0;
		
	float dm = 1.0;
	integer pos = llListFindList(dmod, (list)0);
	if( ~pos )
		dm = dm*l2f(dmod, pos+1);
	if( ~(pos = llListFindList(dmod, (list)key2int(targ))) )
		dm = dm*l2f(dmod, pos+1);
		
	float targRange = llVecDist(llGetRootPosition(), prPos(targ));
	if( fxFlags&fx$F_SPELLS_MAX_RANGE )
		targRange = 10;


	_C = [
		// Damage done multiplier
        "D", (dm*pmod*cCR*spdmdm*difDmgMod()*bsm*bfDmg),
		// Raw multiplier not affected by team or difficulty
		"R", (dm*cCR*spdmdm*bsm*bfDmg),
		// Critical hit
		"C", cCR,
		// Points of arousal
		"A", cAR,
		// Points of pain
		"P", cPP,
		// Backstab boolean
		"B", B,
		// Cooldown modifier
		"H", cdmod,
		// Spell damage done mod for index, added into D
		"M", spdmdm,
		// Healing done multiplier
		"h", hdmod,
		"T", TEAM,
		"ar", cArmor,
		// random int between 0 and 2
		"nc", (int)llFrand(3),
		// HP/MP percent. Faster than using a formula
		"hpp", cHP/cMHP,
		"mpp", cMP/cMMP,
		
		"dtm", l2f(dtmod, 1),
		
		// Max HP
		"mhp", cMHP,
		// Current MP
		"mp", cMP,
		
		// Max MP
		"mmp", cMMP,
		// Current HP
		"hp", cHP,
		// note that for selfcast, these still reference the target of the nonself if one of those exist
		"m", (targRange < MELEE_RANGE || targ == "1" ),		// melee range of the spell target
		"r", targRange,										// Total range to target
		"ehp", ehp,				// target HP % from 0 to 100
		"emp", emp,				// target MP % from 0 to 100
		"ear", ear,				// target arousal % from 0 to 100
		"epa", epa,				// target pain % from 0 to 100
		
		// HUD target flags
		"tm", ( llVecDist(llGetRootPosition(), prPos(HUD_TARG)) < MELEE_RANGE || HUD_TARG == "1" )		// Melee range of the HUD target
		
		
    ];
	
	debugUncommon("IN>>"+FX);
	debugUncommon("Mods>>" + mkarr(_C));
	debugUncommon("R: dm="+(str)dm+" cCR="+(str)cCR+" spdmdm="+(str)spdmdm + " bsm="+(str)bsm + " bfdmg="+(str)bfDmg);
	
    integer i;
    for( i=1; i<llGetListLength(split); ++i ){
        
		// Shifts off the last character of the string prior to the $MATH$
		split = llListReplaceList(split, [
				llGetSubString(llList2String(split, i-1), 0, -2)
			], 
			i-1, i-1
		);
		// Get the math block
        string block = llList2String(split, i);
        // Get the end char
		integer q = llStringLength(llList2String(llParseString2List(block, ["\"","$"], []), 0));
        // JSON fix?
		string math = implode("/", explode("\\/", llGetSubString(block, 0, q-1)));

		// Run the math
		string out = l2s(pandaMath(math),0);
		
		// Not sure why below is needed, gonna test without /Jas
		// Don't remove the point, since output should always be a float
		while( llGetSubString(out, -1, -1) == "0" )
			out = llDeleteSubString(out, -1, -1);
		if( llGetSubString(out, -1, -1) == "." )
			out = llDeleteSubString(out, -1, -1);
			
		// Remove the end char
        block = llGetSubString(block, q+1, -1);
		split = llListReplaceList(split, [(string)out+block], i, i);
		
    }

	debugUncommon("Out>>"+implode("", split));
	_C = [];
	//qd(implode("", split));
    return implode("", split);
}



onEvt(string script, integer evt, list data){

	if( script == "#ROOT" && evt == RootEvt$targ )
        HUD_TARG = l2s(data,0);
	
	else if(script == "got SpellMan" && evt == SpellManEvt$recache){
		CACHE = [];
		
		str tmpCh = gotTable$spellmanSpellsTemp;
		str ch = gotTable$bridgeSpells;
		integer i;
		for( ; i < NUM_SPELLS; ++i ){
			
			list d = llJson2List(db4$get(tmpCh, i));
			if(d == [])
				d = llJson2List(db4$get(ch, i));
			
			CACHE+= llList2String(d, BSSAA$fxwrapper); // Wrapper
			CACHE+= llList2String(d, BSSAA$selfcast); // Selfcast
			CACHE+= llList2Float(d, BSSAA$range); // Range
			CACHE+= llList2Integer(d, BSSAA$target_flags); // Flags

		}
			
	}
	
	// Spell handlers
	/*
    else if(script == "got SpellMan" && evt == SpellManEvt$cast){
        
    }
	*/
    else if( script == "got SpellMan" && evt == SpellManEvt$complete ){
		
		integer SPELL_CASTED = l2i(data, 0);                    // Spell casted index 0-4
        list SPELL_TARGS = llJson2List(l2s(data, 3));           // Targets casted at
		
		integer flags = spellFlags(SPELL_CASTED);
		float r = spellRange(SPELL_CASTED);
		rollCrit(~flags&SpellMan$NO_CRITS, SPELL_CASTED);
		
		// Befuddle
		bfDmg = 1.0;
		if( llFrand(1) < befuddle && (str)SPELL_TARGS != "AOE" && (count(SPELL_TARGS) > 1 || l2s(SPELL_TARGS, 0) != "1") ){
			
			vector rpos = llGetRootPosition();
			list viable = (list)"";
			
			db4$each(gotTable$evtsNpcNear, index, row,
				
				key t = j(row, 1);
				if( t != llGetKey() ){
				
					smartHealDescParse(t, resources, status, fx, team)
					if( _attackableV(status, fx) && llVecDist(prPos(t), rpos ) < r )
						viable += t;
						
				}
				
			)
				
			string targ = randElem(viable);
			if( targ )
				SPELL_TARGS = (list)targ;
			else
				SPELL_TARGS = (list)LINK_ROOT;
				
			bfDmg = 0.5;
			
		}
		
		llMessageLinked(LINK_THIS, TASK_SPELL_VIS, llList2Json(JSON_ARRAY, (list)
			SPELL_CASTED + mkarr(SPELL_TARGS)
		), "");
		
		t0 = l2s(SPELL_TARGS, 0);	// original target is always the victim of the main spell, it's not overridden by self cast
		if( t0 == (str)LINK_ROOT )
			t0 = llGetKey();
		
		// RunMath should be done against certain targets for backstab to work
		applyWrapper(spellWrapper(SPELL_CASTED), SPELL_CASTED, SPELL_TARGS, r);
		
		// Self cast
		if( llStringLength(spellSelfcast(SPELL_CASTED)) > 2 ){
			applyWrapper( spellSelfcast(SPELL_CASTED), SPELL_CASTED, [llGetOwner()], r);
			//FX$run(llGetOwner(), runMath(wrapper, SPELL_CASTED, l2s(SPELL_TARGS, 0)));
		}

    }
	/*
    else if(script == "got SpellMan" && evt == SpellManEvt$interrupted){
        
    }
	*/
}

rollCrit( int allow, int spell ){

	cCR = 1;
	if( llFrand(1)<cmod && allow ){
	
		cCR = 2;
		llTriggerSound("e713ffed-c518-b1ed-fcde-166581c6ad17", .25);
		raiseEvent(SpellAuxEvt$crit, (str)spell);
		
	}
	
}

applyWrapper( string wrapper, int index, list SPELL_TARGS, float range ){

	integer TEAM = hud$status$team();
	
	// Handle AOE
	if( (string)SPELL_TARGS == "AOE" ){
	
		wrapper = runMath(wrapper, index, "");
		FX$aoe(range, llGetKey(), wrapper, TEAM);
		FX$run("", wrapper);
		SPELL_TARGS = (list)LINK_ROOT;
		return ;
		
	}

	// Send effects and rez visuals
	integer i;
	for( ; i<count(SPELL_TARGS); ++i ){ 
		
		string val = l2s(SPELL_TARGS, i);
		if( val == llGetKey() || val == llGetOwner() )
			val = (str)LINK_ROOT;
		
		FX$send(val, llGetKey(), runMath(wrapper,index, val), TEAM);

	}
	
}


default{

	#define LM_PRE \
	if(nr == TASK_FX){ \
		dmod = llJson2List(fx$getDurEffect(fxf$DAMAGE_DONE_MULTI)); \
		cmod = (float)fx$getDurEffect(fxf$CRIT_ADD)-1; \
		cdmod = (float)fx$getDurEffect(fxf$COOLDOWN_MULTI); \
		hdmod = (float)fx$getDurEffect(fxf$HEALING_DONE_MULTI); \
		fxFlags = (int)fx$getDurEffect(fxf$SET_FLAG);\
		befuddle = (float)fx$getDurEffect(fxf$BEFUDDLE)-1; \
		bsMul = (float)fx$getDurEffect(fxf$BACKSTAB_MULTI); \
		dtmod = llJson2List(fx$getDurEffect(fxf$DAMAGE_TAKEN_MULTI)); \
		SPDM = llJson2List(fx$getDurEffect(fxf$SPELL_DMG_DONE_MOD)); \
	} \


    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 

	// Tunnel from passives. You're probably looking for an event trigger instead of method
	if( METHOD == SpellAuxMethod$tunnel && method$internal ){
		
		rollCrit( l2i(PARAMS, 3)&SpellAux$tfAllowCrit, -1 );
		list targs = llJson2List(method_arg(1));
		t0 = l2s(targs, 0);
		//wrapper, (arr)targets, (float)range
		applyWrapper(method_arg(0), -1, targs, l2f(PARAMS, 2));
		
	}
    
	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

