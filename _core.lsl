// We're not using tokens because listeners are limited by party
#define DISREGARD_TOKEN
#define SupportcubeCfg$listenOverride 3912896

// PC_SALT is used to send data between players - Each player gets their own channel
#ifndef PC_SALT
#define PC_SALT 23916
#endif
#define GUI_CHAN(targ) playerChan(llGetOwnerKey(targ))+69 // Chan for rapid GUI calls
#define AOE_CHAN 0xBEAD

// Converts floats to ints and back with 2 decimal points
#define i2f(input) (input/100.)
#define f2i(input) (integer)(input*100)


// XOBJ root task macros, starting at -1000
#define TASK_PASSIVES_SET_ACTIVES -1000			// (arr)actives - Sent from got FXCompiler, sends active effects flattened array to be merged with passives  - Replaces PassivesMethod$setActive
#define TASK_FXC_PARSE -1001					// STRIDED - [(int)action(s), (int)PID, (int)stacks, (int)package_flags, (str)package_name, (arr)fx_objs, (int)timesnap, (var)additional]
	#define FXCPARSE$STRIDE 8 
	#define FXCPARSE$ACTION_RUN 0x1					// Var is 0
	#define FXCPARSE$ACTION_ADD 0x2					// Var is (float)duration
	#define FXCPARSE$ACTION_REM 0x4					// Var is (bool)overwrite
	#define FXCPARSE$ACTION_STACKS 0x8				// Var is (float)duration
/*
	Replaces 
	#define FXEvt$runEffect 1				// [(key)caster, (int)stacks, (arr)package, (int)id, (int)flags]
	#define FXEvt$effectAdded 2				// [(key)caster, (int)stacks, (arr)package, (int)id, (float)timesnap]
	#define FXEvt$effectRemoved 3			// [(key)caster, (int)stacks, (arr)package, (int)id, (bool)overwrite]
	#define FXEvt$effectStacksChanged 4		// [(key)caster, (int)stacks, (arr)package, (int)id, (float)timesnap]
*/
#define TASK_REFRESH_COMBAT -1002   		// void - Replaces StatusMethod$refreshCombat
#define TASK_FX -1003						// Contains FXCEevt$ values. Replaces PassivesEvt$data - All float types are shortened by f2i
#define TASK_MONSTER_SETTINGS -1004			// See got Monster Monster$updateSettings(settings)
#define TASK_OFFENSIVE_MODS -1005			// [(arr)[int casterID, float dmg_done_to_caster_id_mod]] | Sent as a root macro because PC handles in SpellAux, NPC handles in monster

// Include the XOBJ framework
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/libraries/XLS.lsl"

// Here you can also include xobj headers like:
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas Remoteloader.lsl"
#include "xobj_core/classes/jas AnimHandler.lsl"
#include "xobj_core/classes/jas Attached.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas Climb.lsl"
#include "xobj_core/classes/jas Primswim.lsl"
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas MaskAnim.lsl"
#include "xobj_core/classes/jas Soundspace.lsl"

#include "xobj_toonie/classes/ton MeshAnim.lsl"

#define key2int(k) ((int)("0x"+(str)k))

// Include all the project files
#include "./_lib_fx.lsl"
#include "./_lib_fx_macros.lsl"
#include "./classes/got Bridge.lsl"
#include "./classes/got NPCInt.lsl"
#include "./classes/got ThongMan.lsl"
#include "./classes/got FX.lsl"
#include "./classes/got FXCompiler.lsl"
#include "./classes/got Status.lsl"
#include "./classes/got SpellMan.lsl"
#include "./classes/got GUI.lsl"
#include "./classes/got Portal.lsl"
#include "./classes/got Projectile.lsl"
#include "./classes/got SpellFX.lsl"
#include "./classes/got NPCSpells.lsl"
#include "./classes/got LocalConf.lsl"
#include "./classes/got Monster.lsl"
#include "./classes/got Spawner.lsl"
#include "./classes/got Rape.lsl"
#include "./classes/got Alert.lsl"
#include "./classes/got SpellAux.lsl"
#include "./classes/got Trap.lsl"
#include "./classes/got SharedMedia.lsl"
#include "./classes/got Evts.lsl"
#include "./classes/got Level.lsl"
#include "./classes/got LevelAux.lsl"
#include "./classes/got Devtool.lsl"
#include "./classes/got Language.lsl"
#include "./classes/got Potions.lsl"
#include "./classes/got RootAux.lsl"
#include "./classes/got ModInstall.lsl"
#include "./classes/got Passives.lsl"
#include "./classes/got LevelLoader.lsl"
#include "./classes/got LevelLite.lsl"
#include "./classes/got API.lsl"
#include "./classes/got LevelSpawner.lsl"
#include "./classes/got Weapon.lsl"
#include "./classes/got WeaponLoader.lsl"
#include "./classes/got Follower.lsl"
#include "./classes/got BuffVis.lsl"
#include "./classes/got BuffSpawn.lsl"
#include "./classes/got SpellVis.lsl"
#include "./classes/got LevelData.lsl"
#include "./classes/got Attached.lsl"
#include "./classes/got ClassAtt.lsl"
#include "./classes/got PlayerPoser.lsl"
#include "./classes/got PISpawner.lsl"




// Helper function to run code on all players. Requires players to be stored in a global list named PLAYERS
#define runOnPlayers(pkey, code) {integer i; for(i=0; i<llGetListLength(PLAYERS); i++){key pkey = llList2Key(PLAYERS, i); code}}
// Helper function to run code on all player HUDs. Requires players to be stored in a global list named PLAYER_HUDS
#define runOnHUDs(pkey, code) {integer i; for(i=0; i<llGetListLength(PLAYER_HUDS); i++){key pkey = llList2Key(PLAYER_HUDS, i); code}}


#include "got/classes/#ROOT.lsl"

// STD Methods
#define gotMethod$setHuds -1000 		// Updates party HUDs


#define SITE_URL "http://jasx.org/lsl/got/hud2/index.php"

#define INITIALIZED ((integer)db2$get("#ROOT", [RootShared$flags])&RootFlag$ini)

#define DEFAULT_DURABILITY 100.
#define DEFAULT_MANA 50.
#define DEFAULT_PAIN 25.
#define DEFAULT_AROUSAL 25.

#define GENITALS_PENIS 0x1
#define GENITALS_VAGINA 0x2
#define GENITALS_BREASTS 0x4

#define TEXTURE_PC "9505afb9-134d-61cf-b1de-4645ba9ffde2"
#define TEXTURE_COOP "41d10278-ce32-825f-d93c-4092e3064e1a"

#define MELEE_RANGE 3
#define MAX_RANGE 10

#define TEAM_NPC 0
#define TEAM_PC 1

#define RARITY_COMMON 100
#define RARITY_UNCOMMON 50
#define RARITY_RARE 20
#define RARITY_VERY_RARE 5
#define RARITY_LEGENDARY 1

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


// Parses a description into resources, status, fx, sex, team - Currently only supports resources for NPCs
// The if statement checks if this is a HUD which has a slightly different syntax
// _data[0] is the attached point, if attached, the syntax is a bit different
#define parseDesc(aggroTarg, resources, status, fx, sex, team, monsterflags) \
integer resources; integer status; integer fx; integer team; integer sex; integer monsterflags; \
{\
list _data = llGetObjectDetails(aggroTarg, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
resources = l2i(_split,2); \
status = l2i(_split,5); \
fx = l2i(_split,7); \
team = l2i(_split,1); \
monsterflags = l2i(_split, 6); \
if(l2i(_data, 0)){ \
	resources = l2i(_split, 0); \
	status = l2i(_split, 1); \
	fx = l2i(_split, 2); \
	sex = l2i(_split, 3); \
	team = l2i(_split, 4); \
	monsterflags = 0;\
}\
}

// Same as above but only gets sex
#define parseSex(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = 0; \
if(l2i(_data, 0)) \
	var = l2i(_split, 3);
	
// Same as above but only gets flags
#define parseFlags(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 5); \
if(l2i(_data, 0)) \
	var = l2i(_split, 1);
	
// Same as above but only gets team
#define parseTeam(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 1); \
if(l2i(_data, 0)) \
	var = l2i(_split, 4);
	
// Same as above but only gets FX flags
#define parseFxFlags(targ, var) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer var = l2i(_split, 7); \
if(l2i(_data, 0)) \
	var = l2i(_split, 2);
	
#define parseResources(targ, hp, mp, ars, pain) \
list _data = llGetObjectDetails(targ, [OBJECT_ATTACHED_POINT, OBJECT_DESC]); \
list _split = explode("$", l2s(_data, 1)); \
integer _n = l2i(_split,2); \
if( l2i(_data, 0) ) \
	_n = l2i(_split, 0); \
_split = splitResources(_n); \
float hp = l2f(_split, 0); \
float mp = l2f(_split, 1); \
float ars = l2f(_split, 2); \
float pain = l2f(_split, 3);

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


// Conversion for spells
/*

else if(script == "got NPCSpells"){
        if(evt == NPCSpellsEvt$SPELL_CAST_START)onSpellStart(l2i(data, 0), l2s(data, 2));
        else if(evt == NPCSpellsEvt$SPELL_CAST_FINISH)onSpellFinish(l2i(data, 0), l2s(data, 2));
        else if(evt == NPCSpellsEvt$SPELL_CAST_INTERRUPT)onSpellInterrupt(l2i(data, 0), l2s(data, 2));
        
    }


*/


