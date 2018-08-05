#define PMATH_CONSTS _C
#define USE_EVENTS
#include "got/_core.lsl"

list _C;		// Math constants

integer TEAM = TEAM_PC;

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
float cCR;
float cMHP = 100;
float cMMP = 50;

list PLAYERS;

integer SF;			// Status flags

// FX
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

string runMath( string FX, integer index, key targ ){

	// The character before gets removed, so use $$M$ if the math is not a whole string like "$MATH$algebra"
    list split = llParseString2List(FX, ["$MATH$","$M$"], []);
	parseDesc(targ, resources, status, fxf, sex, team, monsterflags)
	int ehp = llRound((resources>>21&127) / 127.0 * 100);
	
	float bsMul = 1;
	integer B = 0;
	myAngZ(targ, ang)
	if((llFabs(ang)>PI_BY_TWO || fxFlags&fx$F_ALWAYS_BEHIND) && targ != ""){
		B = 1;
		bsMul = bsMul;
	}
	float spdmdm = llList2Float(SPDM, index);
	if(spdmdm == -1)
		spdmdm = 1;
	else if(spdmdm<0)
		spdmdm = 0;

	int melee_range;
	if( llVecDist(llGetPos(), prPos(targ)) < MELEE_RANGE || targ == "1" )
		melee_range = TRUE;
		
	float dm = pdmod;
	integer pos = llListFindList(dmod, (list)0);
	if( ~pos )
		dm = dm*l2f(dmod, pos+1);
	if( ~(pos = llListFindList(dmod, (list)key2int(targ))) )
		dm = dm*l2f(dmod, pos+1);

	_C = [
		// Damage done multiplier
        "D", (dm*pmod*cCR*spdmdm*difDmgMod()*bsMul),
		// Raw multiplier not affected by team or difficulty
		"R", (dm*cCR*spdmdm*bsMul),
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
		// Max HP
		"mhp", cMHP,
		// Current MP
		"mp", cMP,
		// Max MP
		"mmp", cMMP,
		// Current HP
		"hp", cHP,
		"m", melee_range,
		"ehp", ehp				// enemy HP from 0 to 100
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
		string out = (str)pandaMath(math);
		// Don't remove the point, since output should always be a float
		while( llGetSubString(out, -1, -1) == "0" )
			out = llDeleteSubString(out, -1, -1);
			
		// Remove the end char
        block = llGetSubString(block, q+1, -1);
		split = llListReplaceList(split, [(string)out+block], i, i);
		
    }

	_C = [];
    return llDumpList2String(split, "");
}

onEvt(string script, integer evt, list data){

    if(script == "#ROOT" && evt == RootEvt$players)
        PLAYERS = data;

	else if(script == "got Status" && evt == StatusEvt$flags)
        SF = llList2Integer(data,0);
	
	else if(script == "got Status" && evt == StatusEvt$difficulty){
		DIF = l2i(data, 0);
	}
	
	else if(script == "got Status" && evt == StatusEvt$resources){
		// [(float)dur, (float)max_dur, (float)mana, (float)max_mana, (float)arousal, (float)max_arousal, (float)pain, (float)max_pain] - PC only
		cAR = llList2Float(data, 4);
		cPP = llList2Float(data, 6);
		cMHP = l2f(data, 1);
		cHP = l2f(data, 0);
		cMP = l2f(data, 2);
		cMMP = l2f(data, 3);
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
    else if(script == "got SpellMan" && evt == SpellManEvt$complete){
		
		integer SPELL_CASTED = l2i(data, 0);                    // Spell casted index 0-4
        list SPELL_TARGS = llJson2List(l2s(data, 3));                    // Targets casted at
		
		
		integer flags = spellFlags(SPELL_CASTED);
		
		cCR = 1;
		if(llFrand(1)<cmod && ~flags&SpellMan$NO_CRITS){
		
			cCR = 2;
			llTriggerSound("e713ffed-c518-b1ed-fcde-166581c6ad17", .25);
			raiseEvent(SpellAuxEvt$crit, (str)SPELL_CASTED);
			
		}
		
		// RunMath should be done against certain targets for backstab to work

		// Handle AOE
		if((string)SPELL_TARGS == "AOE"){
		
			FX$aoe(spellRange(SPELL_CASTED), llGetKey(), runMath(spellWrapper(SPELL_CASTED),SPELL_CASTED, ""), TEAM);  
			SPELL_TARGS = [LINK_ROOT];
			
		}
		
		else if(llFrand(1) < befuddle-1){
			float r = spellRange(SPELL_CASTED);
			string targ = randElem(PLAYERS);
			if(targ == llGetOwner())
				SPELL_TARGS = [LINK_ROOT];
			else if(llVecDist(llGetPos(), prPos(targ)) < r){
				SPELL_TARGS = [targ];
			}
		}
		
		// Send effects and rez visuals
		if( (string)SPELL_TARGS != "AOE" ){
		
			integer i;
			for( ; i<count(SPELL_TARGS); ++i ){ 
				
				string val = l2s(SPELL_TARGS, i);
				if( val == llGetKey() || val == llGetOwner() )
					val = (str)LINK_ROOT;

				FX$send(val, llGetKey(), runMath(spellWrapper(SPELL_CASTED),SPELL_CASTED, val), TEAM);

			}
			
		}
		
		if( llStringLength(spellSelfcast(SPELL_CASTED)) > 2 )
			FX$run(llGetOwner(), runMath(spellSelfcast(SPELL_CASTED), SPELL_CASTED, l2s(SPELL_TARGS, 0)));
		
    }
	/*
    else if(script == "got SpellMan" && evt == SpellManEvt$interrupted){
        
    }
	*/
}




default
{
	state_entry(){
		PLAYERS = [(str)llGetOwner()];
		
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
	} \
	else if( nr == TASK_OFFENSIVE_MODS ){ \
	\
		dmod = llJson2List(j(s, 0)); \
	\
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
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

