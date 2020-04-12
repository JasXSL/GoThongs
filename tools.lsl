#ifndef _gotTools
#define _gotTools

// Default reject types for raycast
#define RC_DEFAULT (list)RC_REJECT_TYPES + (RC_REJECT_AGENTS|RC_REJECT_PHYSICAL)


// List of built in breast jiggle animations
#define got$BREAST_JIGGLES (list)\
	"breast_double_slap_slower" + \
	"breast_right_slap" + \
	"breast_double_slap_long" + \
	"breast_double_slap_left" + \
	"breast_left_slap" + \
	"breast_double_slap"
	
#define got$BUTT_JIGGLES (list) \
	"buttslap"+ \
	"buttslap_long"
	
// Gets a random from above
#define getRandomBreastJiggle() \
	l2s(got$BREAST_JIGGLES, llFloor(llFrand(6)))

// Triggers a breast jiggle on a target
#define triggerBreastJiggle( targ ) AnimHandler$targAnim(targ, l2s((list)got$BREAST_JIGGLES, llFloor(llFrand(6))), true)

// Trigger a breast jiggle on a target but only for one breast
#define triggerBreastJiggleSided( targ ) AnimHandler$targAnim(targ, l2s((list)\
	"breast_right_slap" + \
	"breast_left_slap" \
, llFloor(llFrand(2))), true)

// Trigger a breast jiggle on a target but only for both breasts
#define triggerBreastJiggleDouble( targ ) AnimHandler$targAnim(targ, l2s((list)\
	"breast_double_slap_slower" + \
	"breast_double_slap_long" + \
	"breast_double_slap_left" + \
	"breast_double_slap" \
, llFloor(llFrand(4))), true)

// Trigger a breast "stretch" animation
#define triggerBreastStretch( targ ) AnimHandler$targAnim(targ, l2s((list) \
	"breast_stretch_left" + \
	"breast_stretch_right" \
, llFloor(llFrand(2))), true)


// GOLD FUNCTIONS
// Converts an integer of copper into [(int)gold, (int)silver, (int)copper]
#define toGSC(copper) [ \
	floor((float)copper/100), \
	floor((float)copper/10)-(floor((float)copper/100)*10), \
	copper-floor((float)copper/10)*10 \
]

// Turns a value in copper to a readable text of gold/silver/copper
string toGSCReadable( integer copper ){
	
	list gsc = toGSC(copper);
	list out;
	if( l2i(gsc, 0) )
		out+= l2s(gsc, 0)+" Gold";
	if( l2i(gsc, 1) )
		out+= l2s(gsc, 1)+" Silver";
	if( l2i(gsc, 2) )
		out+= l2s(gsc, 2)+" Copper";
	
	return implode(", ", out);
	
}


// Converts a Z forward rotation to an X forward rotation for old monster scripts to new monster scripts
/* 
	#define NormRot got_n2r
	#define llLookAt(a,b,c) xLookAt(a)
*/
rotation got_n2r( rotation Q ){

	vector v = llRot2Euler(Q);
	Q = llEuler2Rot(<0,0,-v.x>);
	float MagQ = llSqrt(Q.x*Q.x + Q.y*Q.y +Q.z*Q.z + Q.s*Q.s);
    return <Q.x/MagQ, Q.y/MagQ, Q.z/MagQ, Q.s/MagQ>;

}



// Parses a HUD/Monster description into resources, status, fx, sex, team - Currently only supports resources for NPCs
// The if statement checks if this is a HUD which has a slightly different syntax
// _data[0] is the attached point, if attached, the syntax is a bit different
// monsterFlags is userSettings for PC
/*
	targ : key UUID of HUD or NPCs you want to get info about
	resources : int variable name to create and store resources data in (use parseResources to turn it into a list of floats)
	status : int variable name to create and store status flags
	team : int variable name to create and store team in
	sex : int variable name to create and store sex flags in (see GENITALS_* in _core.lsl)
	monsterflags : int variable name to create and store monster runtime flags in. When used on a PC, these are the settings flags from got Bridge.lsl
	armor : int variable name to create and store armor data in (use Status$splitArmor, see got Status.lsl for more info)
*/
#define parseDesc(targ, resources, status, fx, sex, team, monsterflags, armor) \
integer resources; integer status; integer fx; integer team; integer sex; integer monsterflags; int armor; \
{\
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
resources = l2i(_split,StatusDesc$npc$RESOURCES); \
status = l2i(_split,StatusDesc$npc$STATUS); \
fx = l2i(_split,StatusDesc$npc$FX); \
team = l2i(_split,StatusDesc$npc$TEAM); \
monsterflags = l2i(_split, StatusDesc$npc$MONSTERFLAGS); \
sex = l2i(_split,StatusDesc$npc$SEX); \
armor = 0; \
if(l2i(_data, 0)){ /* HUD */ \
	resources = l2i(_split, StatusDesc$pc$RESOURCES); \
	status = l2i(_split, StatusDesc$pc$STATUS); \
	fx = l2i(_split, StatusDesc$pc$FX); \
	sex = l2i(_split, StatusDesc$pc$SEX); \
	team = l2i(_split, StatusDesc$pc$TEAM); \
	monsterflags = l2i(_split,StatusDesc$pc$SETTINGS);\
	armor = l2i(_split,StatusDesc$pc$ARMOR); \
}\
}


// Gets range add and height add. For avatars hAdd is a negative float you can add to their position to get their feet
#define parseMonsterOffsets(targ, rAdd, hAdd) \
float rAdd; float hAdd; \
{\
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
if( !l2i(_data, 0) ){ \
	rAdd = l2f(_split,StatusDesc$npc$RANGE_ADD)/10; \
	hAdd = l2f(_split,StatusDesc$npc$HEIGHT_ADD)/10; \
}else{	\
	vector ascale = llGetAgentSize(llGetOwnerKey(targ)); \
	hAdd = -ascale.z/2; \
} \
}



// For got FXCompiler.lsl
// Parses the data needed to compare players for a smart heal
#define smartHealDescParse(targ, resources, status, fx, team) \
	integer resources; integer status; integer fx; integer team;  \
	list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
	list _split = explode("$", l2s(_data, 1));  \
	resources = l2i(_split, 0); \
	status = l2i(_split, 1); \
	fx = l2i(_split, 2);  \
	team = l2i(_split, 4);


// Same as above but only gets sex
#define parseSex(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 9); \
if(l2i(_data, 0)) \
	var = l2i(_split, 3);

// class role is stored in sex flags using bits 16 & 17
#define getRoleFromSex( sex ) \
	((sex>>16)&3)
	
#define parseArmor(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = 0; \
if(l2i(_data, 0)) \
	var = l2i(_split, 6);
	
// Same as above but only gets flags
#define parseFlags(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 6); \
if(l2i(_data, 0)) \
	var = l2i(_split, 1);
	
// Same as above but only gets team
#define parseTeam(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 2); \
if(l2i(_data, 0)) \
	var = l2i(_split, 4);
	
// Same as above but only gets FX flags
#define parseFxFlags(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 8); \
if(l2i(_data, 0)) \
	var = l2i(_split, 2);
	
#define parseMonsterFlags(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 7); 

#define parsePCSettingFlags(targ, var) \
list _split = explode("$", l2s(llGetObjectDetails(targ, (list)OBJECT_DESC), 0)); \
integer var = l2i(_split, 5); 
	
#define parseResources(targ, hp, mp, ars, pain) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer _n = l2i(_split,3); \
if( l2i(_data, 0) ) \
	_n = l2i(_split, 0); \
_split = splitResources(_n); \
float hp = l2f(_split, 0); \
float mp = l2f(_split, 1); \
float ars = l2f(_split, 2); \
float pain = l2f(_split, 3);

// Checks if NPC or PC is humanoid
integer targetIsHumanoid( key targ ){
	list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]);
	// Attachments always count as humanoid
	if( l2i(_data, 0) || llGetAgentSize(targ) != ZERO_VECTOR )
		return TRUE;
	list _split = explode("$", l2s(_data, 1));
	if( l2i(_split, 6) & Monster$RF_HUMANOID )
		return TRUE;
	return FALSE;
}

// Attempts to get height of a target regardless of if it's an NPC or PC
float getTargetHeight( key t ){
	
	if( prAttachPoint(t) )
		t = llGetOwnerKey(t);
	vector as = llGetAgentSize(t);
    if( as )
		return as.z;
		
	boundsHeight(t, b)
	
	parseDesc(t, resources, status, fx, sex, team, monsterflags, armor)
	if( monsterflags & Monster$RF_ANIMESH  )
		b /= 2;
	return b;
	
}

// Takes in status/fx flags (generally pulled from one of the desc functions above) and checks if it can be attacked
#define _attackableData( status, fx ) \
		(!(fx&fx$UNVIABLE) && !(status&StatusFlags$NON_VIABLE))

// Same as above but checks by UUID. Should work on monsters as well
int _attackableHUD(key HUD){
	list _data = llGetObjectDetails(HUD, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); 
	list _split = explode("$", l2s(_data, 1)); 
	integer status = l2i(_split, 5); 
	integer fx = l2i(_split, 7);
	if(l2i(_data, 0)){
		status = l2i(_split, 1);
		fx = l2i(_split, 2);
	}
	return _attackableV(status, fx);
}
	

// Returns an array of hp, mana, arousal, pain
#define splitResources(n) [(n>>21&127) / 127.0, (n>>14&127) / 127.0, (n>>7&127) / 127.0, (n&127) / 127.0]

// I think this is legacy code, I don't think it's used anywhere.
string rarityToName(integer rarity){
	list r = [RARITY_LEGENDARY, "Legendary", RARITY_VERY_RARE, "Very Rare", RARITY_RARE, "Rare", RARITY_UNCOMMON, "Uncommon"];
	integer i;
	for(i=0; i<llGetListLength(r); i+=2){
		if(rarity<=llList2Integer(r, i))return llList2String(r, i+1);
	}
	return "Common";
}

// Normalizes a rotation
rotation NormRot(rotation Q){
    float MagQ = llSqrt(Q.x*Q.x + Q.y*Q.y +Q.z*Q.z + Q.s*Q.s);
    return <Q.x/MagQ, Q.y/MagQ, Q.z/MagQ, Q.s/MagQ>;
}

// Might be legacy, not sure if it's used anywhere.
string statsToText(list stats){
	list out = [];
	list n = STAT_NAMES;
	list_shift_each(stats, val, 
		string nm = llList2String(n, (integer)val);
		integer pos = llListFindList(out, [nm]);
		if(~pos)out = llListReplaceList(out, [llList2Integer(out,pos+1)+1], pos+1, pos+1);
		else out+=([nm,1]);
	)
	string ret = "";
	integer i;
	for(i=0; i<llGetListLength(out); i+=2){
		ret+=llList2String(out, i);
		if(llList2Integer(out, i+1)>1)ret+=" x"+llList2String(out, i+1);
		ret+=" ";
	}
	return ret;
}

#endif

