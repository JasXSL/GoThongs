#ifndef _GOT_CORE
#define _GOT_CORE

#include "xobj_core/libraries/lazyPandaLib.lsl"

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
#define TASK_SPELL_VIS -1006				// [(int)spellIndex, (arr)targets] SpellAux handles rezzed spell visuals because of befuddle
#define TASK_SPELL_MODS -1007				// (arr)spell_dmg_taken_mod, dmg_taken_mod, healing_Taken_mod


// Include the XOBJ framework
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/libraries/XLS.lsl"
#include "./lib_sounds.lsl"
#include "./lib_particles.lsl"

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
#include "./classes/got AniAnim.lsl"
#include "./classes/got AnimeshScene.lsl"




// Helper function to run code on all players. Requires players to be stored in a global list named PLAYERS
#define runOnPlayers(pkey, code) {integer i; for(i=0; i<llGetListLength(PLAYERS); i++){key pkey = llList2Key(PLAYERS, i); code}}
// Helper function to run code on all player HUDs. Requires players to be stored in a global list named PLAYER_HUDS
#define runOnHUDs(pkey, code) {integer i; for(i=0; i<llGetListLength(PLAYER_HUDS); i++){key pkey = llList2Key(PLAYER_HUDS, i); code}}


#include "got/classes/#ROOT.lsl"

// STD Methods
#define gotMethod$setHuds -1000 		// Updates party HUDs


#define SITE_URL "https://jasx.org/lsl/got/hud2/index.php"

#define DEFAULT_DURABILITY 100.
#define DEFAULT_MANA 50.
#define DEFAULT_PAIN 25.
#define DEFAULT_AROUSAL 25.

#define GENITALS_PENIS 0x1
#define GENITALS_VAGINA 0x2
#define GENITALS_BREASTS 0x4

#define ROLE_DPS 0
#define ROLE_TANK 1
#define ROLE_HEALER 2

// Converts to a flag for bitwise operation
#define role2flag( role ) \
	(1<<role)
	

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

#include "./tools.lsl"

// Conversion for spells
/*

else if(script == "got NPCSpells"){
        if(evt == NPCSpellsEvt$SPELL_CAST_START)onSpellStart(l2i(data, 0), l2s(data, 2));
        else if(evt == NPCSpellsEvt$SPELL_CAST_FINISH)onSpellFinish(l2i(data, 0), l2s(data, 2));
        else if(evt == NPCSpellsEvt$SPELL_CAST_INTERRUPT)onSpellInterrupt(l2i(data, 0), l2s(data, 2));
        
    }


*/


#endif
