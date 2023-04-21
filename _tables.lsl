#ifndef __tables
#define __tables

// DB4 table definitions.
// Sorted by linkset $ owner $ script / scriptSub
// Each linkset can have its own set starting from unicode 32
// You can create quick links with <linkset>$val


// (32) Constant index
#define hudTable$root db4$0				//
// (33) Variable index. Each row is a player UUID.
#define hudTable$rootPlayers db4$1
// (34) Variable index. Each row is a HUD UUID.
#define hudTable$rootHuds db4$2
// (35) Constant index
#define hudTable$bridge db4$3					// Bridge metadata is stored in this table
// (36) Constant index. Each index is a spell, starting with ability 5 (which is actually ability 0)
#define hudTable$bridgeSpells db4$4				// Spells are stored here indexed 0-4
// (37) Constant index. Each index is a spell.
#define hudTable$spellmanSpellsTemp db4$5		// (Written to by got SpellMan) Temp spells for spell overwrites
// (38) Variable index.
#define hudTable$evtsNpcNear db4$6			// Stores [(int)settings,(key)uuid] - Entry 0 is ALWAYS 0,llGetKey() and handled in #ROOT
// (39) Variable index. NOTE: Values 0-8 are handled in got Evts. Values 100+ in gui
#define hudTable$evtsSpellIcons db4$7		// Stores (int)packageID, (key)texture, (int)added(timesnap), (int)duration(10ths of second), (int)stacks, (int)flags - See got Evts
											// 0-7 is for effects the HUD owner is affected by
											// 100-107 is for effects your target is affected by
// (40) Status
#define hudTable$status db4$8	
// (41) Constant indexed (see got FXCompiler), 0+ values. FXCompiler Actives.
#define hudTable$fxCompilerActives db4$9
// (42) NPCInt - Constant index. See got NPCInt
#define hudTable$npcInt db4$10


// Portal tables
#define portalTable$portal db4$0			// Maintained by portal. Stores players etc.


#define hudTable$fxCompilerEvts db4$95		// (DEL char, no other table should start with this char) Used as a "single table". The keys are hudTable$fxCompilerEvts<evtType>_<scriptName> and values are [activesTableIndex0, activeTablesIndex1...]


// Note: The FX tables are the same in both PC and NPC
// (200-255 are reserved for spell packages. This means that max 55 spell packages can be active at any time)
// This is written to by got FX and deleted from got FXCompiler
#define hudTable$fxStart 199			// Note: this is 199 because PIX is 1-indexed for legacy reasons.
#define hudTable$fxStart$length 55

#endif

