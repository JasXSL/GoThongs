#ifndef _gotPassives
#define _gotPassives

/*
	Weaponprocs is the array value of PassivesMethod$set consisting of a 2-strided list of [(int)id, (var)val]
	see got FXCompiler header file for a list of attribute IDs
*/
#define PassivesMethod$set 1							// (str)name, (arr)[(int)attributeid1, (var)attributeval1...], flags - Sets a passive with name, attributeID is an FXCompiler id
#define PassivesMethod$rem 2							// (str)name - Removes a passive by name
#define PassivesMethod$get 3							// void - Returns a list of passives affecting the player


// When you add something here, make sure you also set it as a default in got Passives global var: list compiled_actives;
// Multipliers should actually be additive when setting them through passives. so .1 is 1.1x
//#define FXCEvt$update 1				// See _core TASK_FX - It has replaced this but still uses the same index
#define FXCUpd$ATTACH -3			// (arr)attachments - 
#define FXCUpd$PROC -2				// Special case used in got Passives, See the got Passives.lsl function buildProc() for data
#define FXCUpd$UNSET_FLAGS -1		// Special case only used when setting got Passives 
#define FXCUpd$FLAGS 0 				// (int)flags - Default 0
#define FXCUpd$MANA_REGEN 1			// (float)multiplier - Default 1
#define FXCUpd$DAMAGE_DONE 2		// (float)multiplier or [(float)multiplier, (bool)toCaster] - Default [0,1] - Compiles to [0,(float)global,key2int(uuid),(float)uuid_multi...]
#define FXCUpd$DAMAGE_TAKEN 3		// (float)multiplier or [(float)multiplier, (bool)byCaster] - Default [0,1] - Compiles to [0,(float)global,key2int(uuid),(float)uuid_multi...]
#define FXCUpd$DODGE 4				// (float)multiplier - Default 1 (got FX handles conversion). This is recalculated in HUD updates to represent chance of FAILING a dodge
#define FXCUpd$CASTTIME 5			// *(float)multiplier or [(float)multiplier, (int)idx(0=abil5, 1=abil0...)] - Default [1,1,1,1,1] - Compiles to [float abil5, float abil0...]
#define FXCUpd$COOLDOWN 6			// *(float)multiplier or [(float)multiplier, (int)idx(0=abil5, 1=abil0...)] - Default [1,1,1,1,1] - Compiles to [float abil5, float abil0...]
#define FXCUpd$MANACOST 7			// *(float)multiplier or [(float)multiplier, (int)idx(0=abil5, 1=abil0...)] - Default [1,1,1,1,1] - Compiles to [float abil5, float abil0...]
#define FXCUpd$CRIT 8				// (float)multiplier - Default 1 (got SpellAux handles conversion)

#define FXCUpd$PAIN_MULTI 9			// (float)multiplier - Default 1 - Pain taken
#define FXCUpd$AROUSAL_MULTI 10		// (float)multiplier - Default 1 - Arousal taken

// Mainly passives, multipliers are actually ADDitive so 0.1 would mean multiply by 1.1
#define FXCUpd$HP_ADD 11			// (int)hp - Default 0
#define FXCUpd$HP_MULTIPLIER 12		// (float)multiplier - Default 1
#define FXCUpd$MANA_ADD 13			// (int)mana - Default 0
#define FXCUpd$MANA_MULTIPLIER 14	// (float)multiplier - Default 1
#define FXCUpd$AROUSAL_ADD 15		// (int)arousal - Default 0
#define FXCUpd$AROUSAL_MULTIPLIER 16// (float)multiplier - Default 1
#define FXCUpd$PAIN_ADD 17			// (int)pain - Default 0
#define FXCUpd$PAIN_MULTIPLIER 18	// (float)multiplier - Default 1
#define FXCUpd$HP_REGEN 19			// (float)multiplier - Default 1 
#define FXCUpd$PAIN_REGEN 20		// (float)multiplier - Default 1
#define FXCUpd$AROUSAL_REGEN 21		// (float)multiplier - Default 1
#define FXCUpd$SPELL_HIGHLIGHTS 22	// (int)bitwise - A bitwise combination of 0x1 = rest, 0x2 abil1... to highlight
#define FXCUpd$HEAL_MOD 23			// (float)multiplier or [(float)multiplier, (bool)byCaster] - Default [0,1]. Increases healing received. - Compiles to [0,(float)global,key2int(uuid),(float)uuid_multi...]
#define FXCUpd$MOVESPEED 24			// (NPC)(float)multiplier - Default 1
#define FXCUpd$HEAL_DONE_MOD 25		// (PC) Increases healing done.
#define FXCUpd$TEAM 26				// (int)team
#define FXCUpd$BEFUDDLE 27			// (float)multiplier
#define FXCUpd$CONVERSION 28		// (arr)conversions - Converts damage types into another. See below
#define FXCUpd$SPRINT_FADE_MULTI 29	// (float)multiplier - Higher = faster regen speed
#define FXCUpd$BACKSTAB_MULTI 30	// (float)multiplier - Increases or lowers damage from behind
#define FXCUpd$SWIM_SPEED_MULTI 31	// (float)multiplier - Default 1
#define FXCUpd$FOV 32				// (float)field_of_view - 0 resets
#define FXCUpd$PROC_BEN 33			// (float)multi - Beneficial effect proc chance multiplier
#define FXCUpd$PROC_DET 34			// (float)multi - Detrimental effect proc chance multiplier
#define FXCUpd$HP_ARMOR_DMG_MULTI 35	// (float)multi - Increases or decreases the chance of taking armor damage from HP damage
#define FXCUpd$ARMOR_DMG_MULTI 36		// (float)multi - Increases or decreases armor damage taken in general
#define FXCUpd$QTE_MOD 37				// (PC)(float)divisor - Increases or decreases nr of clicks you have to do in a quick time event. -0.5 = half as many, 1 = twice as many
#define FXCUpd$COMBAT_HP_REGEN 38		// (float)multi - Allows HP regen to continue in combat. Default 1 (gets subtracted in got Status)

#define FXCUpd$SPELL_DMG_TAKEN_MOD 39	// *[(str)spellname, (float)multi=1, (bool)byCaster] - Default [] - Compiles to [key2int(caster) or 0=global,(str)spellname, (float)multi]
#define FXCUpd$SPELL_DMG_DONE_MOD 40	// *[(int)index, (float)multi=1] - Default [1,1,1,1,1] - Compiles to [abil5multi,abil0multi...]





#define Passives$TARG_SELF -1							// 
#define Passives$TARG_AOE -2							//
	
#define Passives$toFloat(val) ((float)val/100)			// Convert back to float

#define Passives$FLAG_REM_ON_CLEANUP 0x1				// Removes the passive on cleanup
#define Passives$FLAG_REM_ON_UNSIT 0x2					// Removes the passive when owner is not sitting

#define PassivesConst$MAX_PASSIVES 64					// Max passives a player can have

#define Passives$set(targ, name, passives, flags) runMethod((string)targ, "got Passives", PassivesMethod$set, [name, mkarr((list)passives), flags], TNN)
// Same as above but uses a string instead of a list
#define Passives$setString(targ, name, passives, flags) runMethod((string)targ, "got Passives", PassivesMethod$set, [name, passives, flags], TNN)

#define Passives$rem(targ, name) runMethod((string)targ, "got Passives", PassivesMethod$set, [name], TNN)
#define Passives$get(targ, callback) runMethod((string)targ, "got Passives", PassivesMethod$get, [], callback)
// Tell the HUD that active effects have changed
#define Passives$setActive(active) llMessageLinked(LINK_ROOT, TASK_PASSIVES_SET_ACTIVES, "", "")

//runMethod((string)LINK_ROOT, "got Passives", PassivesMethod$setActive, [mkarr(active)], TNN)


// Methods for building procs
// Supports
/*
    Targ is an index from event data
    Targ also supports:
    #define Passives$TARG_SELF -1
    #define Passives$TARG_AOE -2
*/
string Passives_buildTrigger(integer targ, string script, integer evt, list args, float range){
    return llList2Json(JSON_ARRAY, [targ, script, evt, mkarr(args), range]);
}

    // All triggers are evaluated and targets are added to a list to receive the effect.
    // Targets are unique
    // AOE requires TARG_SELF (-3 for both) if it should hit self as well
    
/*
[
    // Triggers
    [
        [
		(int)targ,
        (str)script,
        (int)evt,
        (arr)args,
		(float)range
		]...
    ],
    (int)max_targets,
    (float)proc_chance,
    (float)cooldown,
    (int)flags,
    (arr)wrapper
]
	Args are arguments that have to exactly match the events. You can use "" as a wildcard.

*/
#define Passives$procTriggers 0
	#define Passives$pt$targ 0
	#define Passives$pt$script 1
	#define Passives$pt$evt 2
	#define Passives$pt$args 3
	#define Passives$pt$range 4
#define Passives$procMaxTargets 1
#define Passives$procChance 2
#define Passives$procCooldown 3
#define Passives$procFlags 4
#define Passives$procWrapper 5


// Proc flags
#define Passives$PF_ON_COOLDOWN 0x1
#define Passives$PF_OVERRIDE_PROC_BLOCK 0x2				// Allow proc even if fx$NO_PROCS is set

string Passives_buildProc(list triggers, integer max_targets, float proc_chance, float cooldown, integer flags, string wrapper){
    return llList2Json(JSON_ARRAY, [
        mkarr(triggers),
        max_targets,
        proc_chance,
        cooldown,
        flags,
        wrapper
    ]);
}


#endif
