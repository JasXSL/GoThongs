// We're not using tokens because listeners are limited by party
#define DISREGARD_TOKEN
#define SupportcubeCfg$listenOverride 3912896

// PC_SALT is used to send data between players - Each player gets their own channel
#define PC_SALT 23916
#define GUI_CHAN(targ) playerChan(llGetOwnerKey(targ))+69 // Chan for rapid GUI calls

// Include the XOBJ framework
#include "xobj_core/_ROOT.lsl"
// Here you can also include xobj headers like:
#include "xobj_core/classes/jas Dialog.lsl"
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas Remoteloader.lsl"
#include "xobj_core/classes/jas AnimHandler.lsl"
#include "xobj_core/classes/jas Attached.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas Climb.lsl"
#include "xobj_core/classes/jas Primswim.lsl"
#include "xobj_core/classes/jas Interact.lsl"


#include "xobj_toonie/classes/ton MeshAnim.lsl"



// Include all the project files
#include "./_lib_fx.lsl"

#include "./classes/got Bridge.lsl"
#include "./classes/got ThongMan.lsl"
#include "./classes/got FX.lsl"
#include "./classes/got FXCompiler.lsl"
#include "./classes/got Status.lsl"
#include "./classes/got Game.lsl"
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


#include "got/classes/#ROOT.lsl"

#define SITE_URL "http://jasx.org/lsl/got/hud/index.php"

#define INITIALIZED ((integer)db2$get("#ROOT", [RootShared$flags])&RootFlag$ini)

#define DEFAULT_DURABILITY 100.
#define DEFAULT_MANA 50.
#define DEFAULT_PAIN 25.
#define DEFAULT_AROUSAL 25.


#define TEXTURE_PC "9505afb9-134d-61cf-b1de-4645ba9ffde2"
#define TEXTURE_COOP "41d10278-ce32-825f-d93c-4092e3064e1a"


#define STAT_DURABILITY 0
#define STAT_MANA 1
#define STAT_AROUSAL 2
#define STAT_PAIN 3
#define STAT_DAMAGE 4
#define STAT_DODGE 5

#define RARITY_COMMON 100
#define RARITY_UNCOMMON 50
#define RARITY_RARE 20
#define RARITY_VERY_RARE 5
#define RARITY_LEGENDARY 1

string rarityToName(integer rarity){
	list r = [RARITY_LEGENDARY, "Legendary", RARITY_VERY_RARE, "Very Rare", RARITY_RARE, "Rare", RARITY_UNCOMMON, "Uncommon"];
	integer i;
	for(i=0; i<llGetListLength(r); i+=2){
		if(rarity<=llList2Integer(r, i))return llList2String(r, i+1);
	}
	return "Common";
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


