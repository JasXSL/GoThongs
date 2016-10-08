/*
	Weaponprocs is the array value of PassivesMethod$set consisting of a 2-strided list of [(int)id, (var)val]
	see got FXCompiler header file for a list of attribute IDs
*/
#define PassivesMethod$set 1							// (str)name, (arr)[(int)attributeid1, (var)attributeval1...] - Sets a passive with name, attributeID is an FXCompiler id
#define PassivesMethod$rem 2							// (str)name - Removes a passive by name
#define PassivesMethod$get 3							// void - Returns a list of passives affecting the player


#define Passives$TARG_SELF -1
#define Passives$TARG_AOE -2							//
	
#define Passives$toFloat(val) ((float)val/100)			// Convert back to float

#define Passives$FLAG_REM_ON_CLEANUP 0x1				// Removes the passive on cleanup

#define Passives$set(targ, name, passives, flags) runMethod((string)targ, "got Passives", PassivesMethod$set, [name, mkarr(passives), flags], TNN)
#define Passives$rem(targ, name) runMethod((string)targ, "got Passives", PassivesMethod$rem, [name], TNN)
#define Passives$get(targ, callback) runMethod((string)targ, "got Passives", PassivesMethod$get, [], callback)
#define Passives$setActive(active) llMessageLinked(LINK_ROOT, TASK_PASSIVES_SET_ACTIVES, mkarr(active), "")
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
    // AOE requires TARG_SELF if it should hit self as well
    
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
*/
// Proc flags
#define Passives$PF_ON_COOLDOWN 0x1

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
