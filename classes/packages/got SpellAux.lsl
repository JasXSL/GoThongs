#define PMATH_CONSTS _C
#define USE_EVENTS
#define IGNORE_CALLBACKS
#include "got/_core.lsl"

list _C;		// Math constants

integer TEAM = TEAM_PC;
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
#define difDmgMod() llPow(0.9, DIF)

integer DIF;	// difficulty

// Calculates bonus damage for particular spells
list SPDM = [-1,-1,-1,-1,-1];		// [rest, abil1, abil2...]

// Caching modifiers
float cHP = 100;
float cMP = 50;
float cAR;
float cPP;
int cCR;
float cMHP = 100;
float cMMP = 50;
float cArmor = 250;

int P_EVT;	// Stores event prim

list PLAYERS;

integer SF;			// Status flags

// FX
float dtmod = 1.0;		// Damage taken modifier from PASSIVE
float adtmod = 1.0;		// Damage taken modifier from ACTIVE (Only affects ALL damage taken mods, not spell damage taken or from a specific target)
float bfDmg = 1;		// Befuddle damage multiplier
float pdmod = 1;       // Damage done
float cmod = 0;
float cdmod = 1;		// Cooldown modifier
float hdmod = 1;		// Healing done mod
list dmod;				// int playerID, float amount
list mcm = [1,1,1,1,1];

float befuddle = 1;		// Chance to cast at a random target
float bsMul = 1;	// Additional damage when attacking from behind
integer fxFlags = 0;

#define pmod (1./count(PLAYERS))

/* Constants:
	$T0$	Target of spell (if not AoE) Only differs from _TA_ in self cast
	$TARG$	Target of wrapper
	$SELF$	Script owner
	$otI$	Integered version of original target
	$tI$	Same but for wrapper target
	$sI$	Same but for sender HUD
	$soI$	Same but for sender agent
*/
string t0;	// First target of a targeted spell

string runMath( string FX, integer index, key targ ){

	if( (str)targ == (str)LINK_ROOT )
		targ = llGetKey();
	
	FX = implode(targ, explode("$TARG$", FX));
	FX = implode(t0, explode("$T0$", FX));
	FX = implode((str)llGetKey(), explode("$SELF$", FX));
	
	// these can not be math vars because of float limitations
	FX = implode((str)((int)("0x"+t0)), explode("$otI$", FX));
	FX = implode((str)((int)("0x"+(str)targ)), explode("$tI$", FX));
	FX = implode((str)((int)("0x"+(str)llGetKey())), explode("$sI$", FX));
	FX = implode((str)((int)("0x"+(str)llGetOwner())), explode("$soI$", FX));
	

	// The character before gets removed, so use $$M$ if the math is not a whole string like "$MATH$algebra"
    list split = llParseString2List(FX, ["$MATH$","$M$"], []);
	parseDesc(targ, resources, status, fxf, sex, team, monsterflags, _a)
	list res = splitResources(resources);
	int ehp = (int)(l2f(res, 0)*100);
	
	
	float bsMul = 1;
	integer B = 0;
	rotation axis = llEuler2Rot(<0,PI_BY_TWO,0>);
	if( monsterflags & Monster$RF_ANIMESH )
		axis = ZERO_ROTATION;
	prAngle(targ, ang, axis)
		
	if((llFabs(ang)>PI_BY_TWO || fxFlags&fx$F_ALWAYS_BEHIND) && targ != ""){
		B = 1;
		bsMul = bsMul;
	}
	float spdmdm = llList2Float(SPDM, index);
	if(spdmdm == -1)
		spdmdm = 1;
	else if(spdmdm<0)
		spdmdm = 0;
		
	float dm = pdmod;
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
        "D", (dm*pmod*cCR*spdmdm*difDmgMod()*bsMul*bfDmg),
		// Raw multiplier not affected by team or difficulty
		"R", (dm*cCR*spdmdm*bsMul*bfDmg),
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
		// HEaling done multiplier
		"h", hdmod,
		"T", TEAM,
		"ar", cArmor,
		// random int between 0 and 2
		"nc", (int)llFrand(3),
		// HP/MP percent. Faster than using a formula
		"hpp", cHP/cMHP,
		"mpp", cMP/cMMP,
		
		"dtm", dtmod*adtmod,
		
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
		"ehp", ehp,				// enemy HP from 0 to 100
		// HUD target flags
		"tm", ( llVecDist(llGetRootPosition(), prPos(HUD_TARG)) < MELEE_RANGE || HUD_TARG == "1" )		// Melee range of the HUD target
		
		
    ];
	
	
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


	_C = [];
	//qd(implode("", split));
    return implode("", split);
}



onEvt(string script, integer evt, list data){

    if(script == "#ROOT" && evt == RootEvt$players)
        PLAYERS = data;
		
	else if( script == "#ROOT" && evt == RootEvt$targ )
        HUD_TARG = l2s(data,0);

	else if(script == "got Status" && evt == StatusEvt$flags)
        SF = llList2Integer(data,0);
	
	else if(script == "got Status" && evt == StatusEvt$difficulty){
		DIF = l2i(data, 0);
	}
	
	else if(script == "got Status" && evt == StatusEvt$resources){
	
		// [(float)dur, (float)max_dur, (float)mana, (float)max_mana, (float)arousal, (float)max_arousal, (float)pain, (float)max_pain, (float)hpPerc, (int)armor_pool] - PC only
		cAR = llList2Float(data, 4);
		cPP = llList2Float(data, 6);
		cMHP = l2f(data, 1);
		cHP = l2f(data, 0);
		cMP = l2f(data, 2);
		cMMP = l2f(data, 3);
		cArmor = l2i(data, 9);
		
	}
	else if(script == "got Status" && evt == StatusEvt$team)
		TEAM = l2i(data,0);
	
	else if(script == "got FXCompiler" && evt == FXCEvt$spellMultipliers){
		SPDM = llJson2List(llList2String(data,0));
		mcm = llJson2List(llList2String(data,1));
	}
	
	else if(script == "got SpellMan" && evt == SpellManEvt$recache){
		CACHE = [];

		integer i;
		for(i=0; i<5; i++){
			
			list d = llJson2List(db3$get(BridgeSpells$name+"_temp"+(str)i, []));
			if(d == [])
				d = llJson2List(db3$get(BridgeSpells$name+(str)i, []));
			
			CACHE+= llList2String(d, 2); // Wrapper
			CACHE+= llList2String(d, 9); // Selfcast
			CACHE+= llList2Float(d, 6); // Range
			CACHE+= llList2Integer(d, 5); // Flags

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
		if( llFrand(1) < befuddle-1 && (str)SPELL_TARGS != "AOE" && (count(SPELL_TARGS) > 1 || l2s(SPELL_TARGS, 0) != "1") ){
			
			vector rpos = llGetRootPosition();
			list players = llJson2List(llGetSubString(l2s(llGetLinkMedia(P_EVT, 0, (list)Evts$NEAR_DB_MEDIA), 0), 8, -1));
			list viable = (list)"";
			int i;
			for( ; i<count(players); i += 2 ){
			
				key t = l2s(players, i+1);
				smartHealDescParse(t, resources, status, fx, team)
				if( _attackableV(status, fx) && llVecDist(prPos(t), rpos ) < r )
					viable += t;
			
			}
			players = [];
			
			string targ = randElem(viable);
			if( targ == "" )
				SPELL_TARGS = (list)LINK_ROOT;
			else
				SPELL_TARGS = (list)targ;
			
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

	// Handle AOE
	if( (string)SPELL_TARGS == "AOE" ){
	
		wrapper = runMath(wrapper, index, "");
		FX$aoe(range, llGetKey(),  wrapper, TEAM);  
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

	state_entry(){
		PLAYERS = [(str)llGetOwner()];
		links_each( nr, name,
			
			if( name == Evts$PRIM_NAME )
				P_EVT = nr;
				
		)
	}

	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		pdmod = i2f(l2f(data, FXCUpd$DAMAGE_DONE)); \
		cmod = i2f(l2f(data, FXCUpd$CRIT))-1; \
		cdmod = i2f(l2f(data, FXCUpd$COOLDOWN)); \
		hdmod = i2f(l2f(data, FXCUpd$HEAL_DONE_MOD)); \
		fxFlags = l2i(data, FXCUpd$FLAGS);\
		befuddle = i2f(l2f(data, FXCUpd$BEFUDDLE));\
		bsMul = i2f(l2f(data,FXCUpd$BACKSTAB_MULTI)); \
		dtmod = i2f(l2f(data, FXCUpd$DAMAGE_TAKEN)); \
	} \
	else if( nr == TASK_OFFENSIVE_MODS ){ \
	\
		dmod = llJson2List(j(s, 0)); \
	\
	} \
	else if( nr ==  TASK_SPELL_MODS ){ \
		list l = llJson2List(j(s, 1)); /* Spell damage done mod */ \
		int pos = llListFindList(l, (list)0); \
		adtmod = 1;\
		if( ~pos )\
			adtmod = l2f(l, pos+1);\
	}

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

