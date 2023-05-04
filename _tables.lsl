#ifndef __tables
#define __tables

// DB4 table definitions.
// Sorted by linkset $ owner $ script / scriptSub
// Each linkset can have its own set starting from unicode 32
// You can create quick links with <linkset>$val


// Event bindings for FX
#define gotTable$fxCompilerEvts db4$95		// (DEL char, no other table should start with this char) Used as a "single table". The keys are gotTable$fxCompilerEvts<evtType>_<scriptName> and values are [activesTableIndex0, activeTablesIndex1...]

// A full range
// Note: The FX tables are the same in both PC and NPC
// (200-255 are reserved for spell packages. This means that max 55 spell packages can be active at any time)
// This is written to by got FX and deleted from got FXCompiler
#define gotTable$fxStart 199			// Note: this is 199 because PIX is 1-indexed for legacy reasons.
#define gotTable$fxStart$length 55




// (32) Sequential index. Written to by got LevelAux, also read by got LevelLoader
#define gotTable$spawns db4$0 			// 
// (33) Level metadata. Non-indexed. Handled by multiple level scripts.
#define gotTable$meta db4$1
// (34) Variable index. Each row is a HUD UUID.
#define gotTable$rootHuds db4$2
// (35) Constant index
#define gotTable$bridge db4$3					// Bridge metadata is stored in this table
// (36) Constant index. Each index is a spell, starting with ability 5 (which is actually ability 0)
#define gotTable$bridgeSpells db4$4				// Spells are stored here indexed 0-4
// (37) Constant index. Each index is a spell.
#define gotTable$spellmanSpellsTemp db4$5		// (Written to by got SpellMan) Temp spells for spell overwrites
// (38) Variable index.
#define gotTable$evtsNpcNear db4$6			// Stores [(int)settings,(key)uuid] - Entry 0 is ALWAYS 0,llGetKey() and handled in #ROOT
// (39) Variable index. NOTE: Values 0-8 are handled in got Evts. Values 100+ in gui
#define gotTable$evtsSpellIcons db4$7		// Stores (int)packageID, (key)texture, (int)added(timesnap), (int)duration(10ths of second), (int)stacks, (int)flags - See got Evts
											// 0-7 is for effects the HUD owner is affected by
											// 100-107 is for effects your target is affected by
// (40) Status - Used by portal and HUD.
#define gotTable$status db4$8	
// (41) Constant indexed (see got FXCompiler), 0+ values. FXCompiler Actives.
#define gotTable$fxCompilerActives db4$9
// (42) NPCInt - Constant index. See got NPCInt
#define gotTable$npcInt db4$10
// (43) PrimSwim
#define gotTable$primSwim db4$11

// (44) Constant index. Handled by HUD ROOT.
#define gotTable$root db4$12

// (45) Variable index. Each row is a player UUID.
#define gotTable$rootPlayers db4$13

// (46)Maintained by portal. Stores players etc.
#define gotTable$portal db4$14

// (47) Maintained by got Monster
#define gotTable$monster db4$15


#endif

