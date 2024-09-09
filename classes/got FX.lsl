#ifndef _GotFX
#define _GotFX

/*

	You'll need a few functions.
	
	Run whenever a spell needs to check condition - Targ can also be "PC" and "NPC" in which case it's up to the developer to scan for those
		integer checkCondition(key caster, integer cond, list data){return TRUE;}
	
	Run when receiving an event to check if you are dead
		integer isDead(){}
	
	Events are run automatically on packages. They are then sent to evtListener where you can write your own onEvt actions if you want
		evtListener(string script, integer evt, string data){}
	
	
	The FX tango in game of thongs:
	
		1. FX wrapper is received and parsed in got FX.
		2. Conditions are checked in got FX and has an optional callback of (int)success with how many packages succeeded in being added.
		3. Useful package data is parsed, then stored in lsd (see fxPackage$* for the saved fields).
		4. got FX sends TASK_FXC_PARSE on RUN/ADD/REM/STACKS to got FXCompiler.
		5. got FXCompiler goes over the parsed data and forwards any actions to the appropriate scripts, as well as compiling duration effects into linkset data on table gotTable$fxCompilerActives. See _lib_fx for definitions of each index.
		6. got FXCompiler then sends TASK_FX with an array of changed values. Though you may as well read them every time the event is received to save memory.
		
	Passives:
		For legacy reasons. Passives are converted into actives and now handled by the fx system.
		
*/

// Package table index
// Packages are stored in tables between gotTable$fxStart and gotTable$fxStart+gotTable$fxStart$length
// Each table has the following constant index
/*
	PIX : Package index, an offset from gotTable$fxStart. Starts at 1.
	To check if a table has been deleted, duration must be 0 and stacks 0
	This is to prevent race conditions.
	got FXCompiler does not check anything, but removes the stack value.
	got FX checks both and removes the duration value
	
	Note that dur and stacks cannot be relied on for deleted packages in passives and fxcompiler
	
*/
#define fx$getDurEffect(fxfType) db4$fget(gotTable$fxCompilerActives, fxfType)


#define fxPackage$STACKS db4$0        	// int - Nr current stacks. MUST be 1 or more. Used to determine is a package exists or not on a table.
#define fxPackage$SENDER db4$1         	// key - Sender of package
#define fxPackage$DUR db4$2            	// float - Package duration. Used alongside stacks to check if a package still exists.
#define fxPackage$FLAGS db4$3          	// int - Package flags
#define fxPackage$NAME db4$4           	// str - Name of package
#define fxPackage$FXOBJS db4$5         	// arr - Effect objects
#define fxPackage$EVTS db4$6           	// arr - Events
#define fxPackage$TAGS db4$7           	// arr - Tags
#define fxPackage$MAX_STACKS db4$8     	// int - Max nr of stacks
#define fxPackage$ADDED db4$9          	// int - Timesnap of when it was added.

//#define fxPackage$PROC_CD db4$10		// int - Timesnap of how often one of the events can proc. Procs cooldowns are PER PACKAGE, use multiple packages if you want separate proc timers.
#define fxPackage$PROC db4$100         	// (obj){(str)idx : (int)timesnap} - Object of timesnaps of last procs for package events, or 0 if did not proc yet. 


// These are shared between fxcompiler (writes) and fx (reads)
#define getEventPackageTable(evt, script) gotTable$fxCompilerEvts+evt+"_"+script
#define getEventPackageIndexes(table) llJson2List(llLinksetDataRead(table))

// Gets a table by index offset from fxStart
#define getFxPackageTableByIndex(pix) llChar(gotTable$fxStart+pix)

// got FX checks both stacks and dur to see if a package is deleted
#define fxPackageEach(i,table,code) integer i = 1; for(; i <= gotTable$fxStart$length; ++i ){ \
    string table = getFxPackageTableByIndex(i); /* pix is 1-indexed */ \
    if( (int)db4$fget(table, fxPackage$STACKS) && (float)db4$fget(table, fxPackage$DUR) != 0 ){ \
        code \
    } \
}









#define FXMethod$run 1					// (key)sender, (obj)wrapper[, (float)range, (int)team] - Runs a package on a player - Callbacks nr of successful packages accepted
#define FXMethod$send FXMethod$run					// (Synonym for above)

#define FXMethod$refresh 2				// Runs a user defined refresh() function to check status updates etc
#define FXMethod$rem 3					// raiseEvt, name, tag, sender, pix, runOnRem, flags, maxRemove, dispellerUUID, allowPassive - Use "" to disregard a value. dispellerUUID is only needed if this was a dispel through a spell
										// name, tag, sender, pix can all be arrays as well which are ORed
										// if flags is an array, it gets ANDed, otherwise flags are ORed. If the flags value is negative, it is NOT. So -PF_DETRIMENTAL = benficial
#define FXMethod$setPCs 4				// (arr)pc_keys - Set PC keys on send to PC events
#define FXMethod$setNPCs 5				// (arr)pc_keys - Set NPC keys to send to on NPC events
#define FXMethod$hasTags 6				// (var)tag(s) - Callbacks TRUE/FALSE if the player has ANY of these tags
#define FXMethod$addStacks 7			// (int)stacks, name, tag, sender, pix, runOnRem, flags, maxNR, isDispel, duration, (int)trig - Adds x stacks to spells that match the filter. If duration is non-zero, it is also updated.


//#define FXEvt$runEffect 1				// [(key)caster, (int)stacks, (arr)package, (int)id, (int)flags]
//#define FXEvt$effectAdded 2				// [(key)caster, (int)stacks, (arr)package, (int)id, (float)timesnap]
//#define FXEvt$effectRemoved 3			// [(key)caster, (int)stacks, (arr)package, (int)id, (bool)overwrite]
//#define FXEvt$effectStacksChanged 4		// [(key)caster, (int)stacks, (arr)package, (int)id, (float)timesnap]
#define FXEvt$wrapperSuccess 5			// [(key)caster, (int)detrimental] - A wrapper was successfully added
#define FXEvt$dodge 6					// [(key)caster] - You dodged an attack


#define FX$send(target, sender, wrapper, team) runMethod(target, "got FX", FXMethod$run, ([sender, wrapper, 0, team]), TNN)
#define FX$sendCB(target, sender, wrapper, cb, team) runMethod(target, "got FX", FXMethod$run, ([sender, wrapper, 0, team]), cb)
#define FX$run(sender, wrapper) runMethod((string)LINK_ROOT, "got FX", FXMethod$run, (list)(sender)+(wrapper), TNN)
#define FX$refresh() runMethod((string)LINK_SET, "got FX", FXMethod$refresh, [], TNN)
#define FX$rem(raiseEvt, name, tag, sender, pix, runOnRem, flags, count, dispellerUUID, allowPassive) runMethod((string)LINK_SET, "got FX", FXMethod$rem, ([raiseEvt, name, tag, sender, pix, runOnRem, flags, count, dispellerUUID, allowPassive]), TNN)
#define FX$addStacks(targ, stacks, name, tag, sender, pix, runOnRem, flags, count, isDispel, duration, trig) runMethod((string)targ, "got FX", FXMethod$addStacks, ([stacks, name, tag, sender, pix, runOnRem, flags, count, isDispel, duration, trig]), TNN)

#define FX$remByNameCB(targ, name, cb) runMethod((string)targ, "got FX", FXMethod$rem, (list)0 + name + "" + "" + 0 + 0 + 0 + 0 + "" + FALSE, cb)
#define FX$aoe(range, sender, wrapper, team) runChanOmniMethod(AOE_CHAN, "got FX", FXMethod$run, (list)(sender) + (wrapper) + (range) + (team), TNN) 
// Tags can be a JSON array or a single tag
#define FX$hasTags(targ, tags, cb) runMethod(targ, "got FX", FXMethod$hasTags, (list)(tags), cb)

#ifndef fx$COND_HAS_PACKAGE_NAME
	#define fx$COND_HAS_PACKAGE_NAME 1			// [(str)name1, (str)name2...] - Recipient has a package with at least one of these names
#endif
#ifndef fx$COND_HAS_PACKAGE_TAG
	#define fx$COND_HAS_PACKAGE_TAG 2			// [(int)tag1, (int)tag2...] - Recipient has a package with a tag with at least one of these
#endif

//#define FXConf$useEvtListener
// Lets you use the evtListener(string script, integer evt, string data) to perform actions when an event is received

// Note, you'll probably want a sheet to keep track of FX types

// Wrapper is an array that contains the entire fx object
// Once the script receives a wrapper it's opened and the packages are cached if valid
// Note: if you add your own targ flags, use 65536 and greater values as this list might be extended
#define TARG_CASTER 1
#define TARG_VICTIM 2			// only used on events
#define TARG_PC 4				// Lazy name for players on your team. Used in spellMan
#define TARG_NPC 8				// Lazy name for players not on your team. Used in spellMan
#define TARG_DISPELLER 0x10
#define TARG_REQUIRE_NO_FACING 0x20
#define TARG_AOE 0x40			// Runs the effect as omni method at 10m max. When using this, maxtarg becomes range in meters
// A negative or 0 value will use that argument from the event

// packages is strided [(int)stacks, (arr)package...]
string FX_buildWrapper(integer wrapperflags, integer min_objs, integer max_objs, list packages){
    return llList2Json(JSON_ARRAY, [wrapperflags, min_objs, max_objs]+packages);
}

#define WF_DETRIMENTAL 0x1
#define WF_ALLOW_WHEN_DEAD 0x2
#define WF_ALLOW_WHEN_QUICKRAPE 0x4
#define WF_NO_DODGE 0x8
// 10 not used
#define WF_ALLOW_WHEN_RAPED 0x20	// 32
#define WF_REQUIRE_LOS 0x40			// 64
#define WF_ENEMY_ONLY 0x80			// 128 - Allow other team only


// Events are used to run additional wrappers on a target based on script events
// For internal events use "" as evscript
// Internal events are quick events restrained to this script
#define INTEVENT_ONREMOVE 1			// Data is [(int)pix]
#define INTEVENT_ONADD 2			// Data is [(int)pix] 
#define INTEVENT_ONSTACKS 3			// Data is [(int)pix, (int)nrStacks]
#define INTEVENT_SPELL_ADDED 4		// Data is [(str)name] - Raised whenever a duration spell is added, along with the name. You can use params to check if a name has been added to verify the event
#define INTEVENT_DISPEL 5			// Data is [(int)pix, (key)dispeller]
#define INTEVENT_DODGE 6			// Data is void  - Event raised when dodged
#define INTEVENT_PACKAGE_RAN 7		// data is [(str)name] - Raised when a package is ran immediately or through ticks etc

/*
	
	Some notes on events:
	Currently the first param will be compared to the entire JSON data string of the event. This could be improved.
	JSON_INVALID or "" indexes in params will be treated as wild cards
	
	Wrapper constants:
		<0> <1>... are replaced with the event value of that index. If the argument is numerical you can also use <-0> <-1> etc to inverse that argument.
		<V> Key of the object that contains the FX that processes the event
		
	You can use a target less or equal to 0 to use a parameter from the event as target
	You can add || in a param for OR, ex: FX_buildEvent(SpellManEvt$complete, "got SpellMan", TARG_VICTIM, 1, wrap, ["2||3"]) spell 2 OR 3 cast
*/
#define FXEVT_TYPE 0
#define FXEVT_SCRIPT 1
#define FXEVT_TARG 2
#define FXEVT_MAXTARGS 3
#define FXEVT_WRAPPER 4
#define FXEVT_PARAMS 5		// Params that should match the event params. See above for special characters.
#define FXEVT_PROC_CHANCE 6	// 
#define FXEVT_FLAGS 7
#define FXEVT_RANGE 8		// Max range of targets. For legacy reasons AoE can use maxtargs as range.
#define FXEVT_COOLDOWN 9	// cooldown in seconds. 0.1 second resolution

#define FXEVT$PF_OVERRIDE_PROC_BLOCK 0x2	// Allow it even when fx$NO_PROCS is set

#define fx$buildEvent( evtype, evscript, targ, maxtargets, wrapper, params, procChance, flags, range, cooldown) \
	mkarr(([evtype, evscript, targ, maxtargets, wrapper, params, procChance, flags, range, cooldown]))

string FX_buildEvent( integer evtype, string evscript, integer targ, integer maxtargets, string wrapper, list params, float procChance, int flags, float range, float cooldown ){
    return fx$buildEvent(evtype, evscript, targ, maxtargets, wrapper, mkarr(params), procChance, flags, range, cooldown);
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
#define PF_CANNIBALIZE 0x2				// Removes any matching existing spell and adds its stacks
#define PF_EVENT_ON_OVERWRITE 0x4		// Raises the removal event even when overwritten. Only works together with PF_CANNIBALIZE
#define PF_ALLOW_WHEN_DEAD 0x8			// 
#define PF_ALLOW_WHEN_QUICKRAPE 0x10	// 16
#define PF_NO_STACK_MULTIPLY 0x20		// 32 Don't multiply the value by nr stacks
#define PF_FULL_UNIQUE 0x40				// 64 Only allow one no matter the sender. Exclusive with PF_NOT_UNIQUE
#define PF_TRIGGER_IMMEDIATE 0x80		// 128 Runs as an instant effect once when it's added
#define PF_NO_DISPEL 0x100				// 256
#define PF_STACK_TIME 0x200				// 512 Adds time to any existing spell instead of resetting to max time
#define PF_FULL_VIS 0x400				// 1024 Show to all targeters regardless of who added it

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

string FX_buildPackage( 
	float dur, integer flags, string name, list fxobjs, list conditions, list evts, list tags, integer fxMinConditions, integer stacks, float tick 
){
    return llList2Json(JSON_ARRAY, [dur, flags, name, llList2Json(JSON_ARRAY, fxobjs),llList2Json(JSON_ARRAY, conditions),llList2Json(JSON_ARRAY, evts), llList2Json(JSON_ARRAY, tags), fxMinConditions, stacks, tick]);
}

// Helper function for shortening package strings
list FX_fround(float input){
    if((float)llRound(input) != input)return [input];
    return [llRound(input)];
}





#endif

