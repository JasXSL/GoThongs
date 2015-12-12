/*

	You'll need a few functions.
	
	Run whenever a spell needs to check condition - Targ can also be "PC" and "NPC" in which case it's up to the developer to scan for those
		integer checkCondition(key caster, integer cond, list data){return TRUE;}
	
	Run when receiving an event to check if you are dead
		integer isDead(){}
	
	Events are run automatically on packages. They are then sent to evtListener where you can write your own onEvt actions if you want
		evtListener(string script, integer evt, string data){}
	
	
*/

#define FXMethod$run 1					// (key)sender, (obj)wrapper[, (float)range] - Runs a package on a player
#define FXMethod$send FXMethod$run					// (Synonym for above)

#define FXMethod$refresh 2				// Runs a user defined refresh() function to check status updates etc
#define FXMethod$rem 3					// raiseEvt, name, tag, sender, pid, runOnRem, flags, isDispel, maxNR - Use "" to disregard a value
										// if sender is prefixed with ! it will remove everyone BUT that attacker
#define FXMethod$setPCs 4				// (arr)pc_keys - Set PC keys on send to PC events
#define FXMethod$setNPCs 5				// (arr)pc_keys - Set NPC keys to send to on NPC events
#define FXMethod$hasTags 6				// (var)tag(s) - Callbacks TRUE/FALSE if the player has ANY of these tags


#define FXEvt$runEffect 1				// [(key)caster, (int)stacks, (arr)package, (int)id, (int)flags]
#define FXEvt$effectAdded 2				// [(key)caster, (int)stacks, (arr)package, (int)id]
#define FXEvt$effectRemoved 3			// [(key)caster, (int)stacks, (arr)package, (int)id, (bool)overwrite]
#define FXEvt$effectStacksChanged 4		// [(key)caster, (int)stacks, (arr)package, (int)id]


#define FX$send(target, sender, wrapper) runMethod(target, "got FX", FXMethod$run, ([sender, wrapper]), TNN)
#define FX$sendCB(target, sender, wrapper, cb) runMethod(target, "got FX", FXMethod$run, ([sender, wrapper]), cb)
#define FX$run(sender, wrapper) runMethod((string)LINK_SET, "got FX", FXMethod$run, ([sender, wrapper]), TNN)
#define FX$refresh() runMethod((string)LINK_SET, "got FX", FXMethod$refresh, [], TNN)
#define FX$rem(raiseEvt, name, tag, sender, pid, runOnRem, flags, count, isDispel) runMethod((string)LINK_SET, "got FX", FXMethod$rem, ([raiseEvt, name, tag, sender, pid, runOnRem, flags, count, isDispel]), TNN)
#define FX$aoe(targ, range, sender, wrapper) runLimitMethod(targ, "got FX", FXMethod$run, ([sender, wrapper, range]), TNN, range)
#define FX$hasTags(targ, tags, cb) runMethod(targ, "got FX", FXMethod$hasTags, [tags], cb)

#ifndef fx$COND_HAS_PACKAGE_NAME
	#define fx$COND_HAS_PACKAGE_NAME 1			// [(str)name1, (str)name2...] - Recipient has a package with at least one of these names
#endif
#ifndef fx$COND_HAS_PACKAGE_TAG
	#define fx$COND_HAS_PACKAGE_TAG 2			// [(int)tag1, (int)tag2...] - Recipient has a tackage with a tag with at least one of these
#endif

//#define FXConf$useEvtListener
// Lets you use the evtListener(string script, integer evt, string data) to perform actions when an event is received
//#define FXConf$useShared "a"
// Lets you save the spell packages as a shared array. It will likely risk overflowing if you add more than a handful of spells.
// If saved, shared will be the strided array [(int)pid, (key)caster, (arr)package, (int)stacks]


	
	
// Note, you'll probably want a sheet to keep track of FX types

// Wrapper is an array that contains the entire fx object
// Once the script receives a wrapper it's opened and the packages are cached if valid
// Note: if you add your own targ flags, use 65536 and greater values as this list might be extended
#define TARG_CASTER 1
#define TARG_VICTIM 2			// only used on events
#define TARG_PC 4
#define TARG_NPC 8
#define TARG_DISPELLER 0x10
#define TARG_REQUIRE_NO_FACING 0x20
#define TARG_AOE 0x40			// Runs the effect as omni method at 10m max

// packages is strided [(int)stacks, (arr)package...]
string FX_buildWrapper(integer wrapperflags, integer min_objs, integer max_objs, list packages){
    return llList2Json(JSON_ARRAY, [wrapperflags, min_objs, max_objs]+packages);
}

#define WF_DETRIMENTAL 0x1
#define WF_ALLOW_WHEN_DEAD 0x2
#define WF_ALLOW_WHEN_QUICKRAPE 0x4
#define WF_NO_DODGE 0x8
#define WF_ALLOW_WHEN_RAPED 0x20
#define WF_REQUIRE_LOS 0x40

// Events are used to run additional wrappers on a target based on script events
// For internal events use "" as evscript
// Internal events are quick events restrained to this script
#define INTEVENT_ONREMOVE 1			// Data is PID -
#define INTEVENT_ONADD 2			// Data is package - 
#define INTEVENT_ONSTACKS 3			// Data is package - Params: [(int)nrStacks]
#define INTEVENT_SPELL_ADDED 4		// name - Raised whenever a duration spell is added, along with the name. You can use params to check if a name has been added to verify the event
#define INTEVENT_DISPEL 5			// Data is [PID, (key)dispeller]

string FX_buildEvent(integer evtype, string evscript, integer targ, integer maxtargets, string wrapper, list params){
    return llList2Json(JSON_ARRAY, [evtype, evscript, targ, maxtargets, wrapper, mkarr(params)]);
}

// FX are packages containing info about a specific effect. You'll likely want to write your own sheet of various effects
string FX_buildFX(integer id, list params){
    return llList2Json(JSON_ARRAY, [id]+params);
}


// Conditions should also be added to your FX sheet. Conditions will be checked in the checkCondition(key caster, key targ, integer cond, list cond_data) function
string FX_buildCondition(integer cond, list vars){
    return llList2Json(JSON_ARRAY, [cond]+vars);
}


// Packages are the effect objects bound to an FX wrapper. A wrapper can contain multiple packages, and a package can contain multiple fx objects
// These are general package flags
#define PF_DETRIMENTAL 0x1            	// Package is detrimental.
#define PF_NOT_UNIQUE 0x2				// Allows multiple effects with the same name
#define PF_EVENT_ON_OVERWRITE 0x4		// Raises the removal event even when overwritten. Only works together with PF_UNIQUE
#define PF_ALLOW_WHEN_DEAD 0x8			// 
#define PF_ALLOW_WHEN_QUICKRAPE 0x10	// 

#define PF_FULL_UNIQUE 0x40				// Only allow one no matter the sender. Exclusive with PF_NOT_UNIQUE
#define PF_TRIGGER_IMMEDIATE 0x80		// Runs as an instant effect once when it's added

// an integer PID gets added on the end when added to FX

#define PACKAGE_DUR 0
#define PACKAGE_FLAGS 1
#define PACKAGE_NAME 2
#define PACKAGE_FXOBJS 3
#define PACKAGE_CONDS 4
#define PACKAGE_EVTS 5
#define PACKAGE_TAGS 6
#define PACKAGE_MIN_CONDITIONS 7	// 0 = ALL
#define PACKAGE_MAX_STACKS 8			// 
#define PACKAGE_TICK 9

string FX_buildPackage(float dur, integer flags, string name, list fxobjs, list conditions, list evts, list tags, integer fxMinConditions, integer stacks, float tick){
    return llList2Json(JSON_ARRAY, [dur, flags, name, llList2Json(JSON_ARRAY, fxobjs),llList2Json(JSON_ARRAY, conditions),llList2Json(JSON_ARRAY, evts), llList2Json(JSON_ARRAY, tags), fxMinConditions, stacks, tick]);
}

// Helper function for shortening package strings
list FX_fround(float input){
    if((float)llRound(input) != input)return [input];
    return [llRound(input)];
}



