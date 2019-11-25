#ifndef _gotTools
#define _gotTools

// Default reject types for raycast
#define RC_DEFAULT (list)RC_REJECT_TYPES + (RC_REJECT_AGENTS|RC_REJECT_PHYSICAL)

// trigger random squish
#define squishSound() llTriggerSound(randElem((list)"72d65db8-31fe-375b-8716-89e3963fbf7d"+"90b0ec1a-d5d2-3e18-ed0d-c5fb7c6885fd"+"f9194db3-9606-2264-3cde-765430179069"), llFrand(0.25)+0.25)

#define got$BREAST_JIGGLES (list)\
	"breast_double_slap_slower" + \
	"breast_right_slap" + \
	"breast_double_slap_long" + \
	"breast_double_slap_left" + \
	"breast_left_slap" + \
	"breast_double_slap"

#define getRandomBreastJiggle() \
	l2s(got$BREAST_JIGGLES, llFloor(llFrand(6)))

#define triggerBreastJiggle( targ ) AnimHandler$targAnim(targ, l2s((list)got$BREAST_JIGGLES, llFloor(llFrand(6))), true)

#define triggerBreastJiggleSided( targ ) AnimHandler$targAnim(targ, l2s((list)\
	"breast_right_slap" + \
	"breast_left_slap" \
, llFloor(llFrand(2))), true)

#define triggerBreastJiggleDouble( targ ) AnimHandler$targAnim(targ, l2s((list)\
	"breast_double_slap_slower" + \
	"breast_double_slap_long" + \
	"breast_double_slap_left" + \
	"breast_double_slap" \
, llFloor(llFrand(4))), true)

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



// Parses a description into resources, status, fx, sex, team - Currently only supports resources for NPCs
// The if statement checks if this is a HUD which has a slightly different syntax
// _data[0] is the attached point, if attached, the syntax is a bit different
// monsterFlags is userSettings for PC
#define parseDesc(aggroTarg, resources, status, fx, sex, team, monsterflags, armor) \
integer resources; integer status; integer fx; integer team; integer sex; integer monsterflags; int armor; \
{\
list _data = llGetObjectDetails(aggroTarg, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
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

// For got FXCompiler.lsl
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
	if( l2i(_data, 0) )
		return TRUE;
	list _split = explode("$", l2s(_data, 1));
	if( l2i(_split, 6) & Monster$RF_HUMANOID )
		return TRUE;
	return FALSE;
}

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

#define _attackableData( status, fx ) \
		(!(fx&fx$UNVIABLE) && !(status&StatusFlags$NON_VIABLE))

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

string rarityToName(integer rarity){
	list r = [RARITY_LEGENDARY, "Legendary", RARITY_VERY_RARE, "Very Rare", RARITY_RARE, "Rare", RARITY_UNCOMMON, "Uncommon"];
	integer i;
	for(i=0; i<llGetListLength(r); i+=2){
		if(rarity<=llList2Integer(r, i))return llList2String(r, i+1);
	}
	return "Common";
}

rotation NormRot(rotation Q)
{
    float MagQ = llSqrt(Q.x*Q.x + Q.y*Q.y +Q.z*Q.z + Q.s*Q.s);
    return <Q.x/MagQ, Q.y/MagQ, Q.z/MagQ, Q.s/MagQ>;
}

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

