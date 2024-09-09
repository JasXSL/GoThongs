/*
	The purpose of FXCompiler is now to handle INSTANT effects. And effects that should send instant messages when added and/or removed. Such as animation. Everything else is handled by passives.
	

	- TASK_FXC_PARSE is now 2-stride, containing tasks as before, but now also pix. Pix can be converted to a table by using getFxPackageTableByIndex(pix) 
	- Pix is 1-indexed
	- run/add/rem effect should be fine to only run with a pix now
		
	Requires the following functions defined before this script:
	- Table is the table-ized version of pix through getFxPackageTableByIndex
	runEffect(str table)
	addEffect(str table)
	remEffect(str table)
		
*/
//#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#define USE_DB4
#include "got/_core.lsl"

list DEF;


#define FXCOMPILER_SECTION 0
#ifdef IS_NPC
	#include "./got FXCompiler_NPC.lsl"
#else
	#include "./got FXCompiler_PC.lsl"
#endif

#define onStateEntry() \
	DEF = fx$DEFAULTS; \
	int i; \
	for(; i < count(DEF); ++i ){ \
		if( l2i(DEF, i) != fx$NO_PASSIVE ){ \
			db4$replace(gotTable$fxCompilerActives, i, l2s(DEF, i)); \
		} \
	}

default{
	#ifdef IS_NPC 
	state_entry(){
		
		onStateEntry();
		
		if(llGetStartParameter())
			raiseEvent(evt$SCRIPT_INIT, "");
	}
	changed(integer change){
		if(change&(CHANGED_INVENTORY|CHANGED_ALLOWED_DROP)){
			spawnEffects();
		}
	}
	#else
	state_entry(){
		
		onStateEntry();
		
	}
	#endif
	
	link_message( integer link, integer nr, string s, key id ){
		
		if( nr == RESET_ALL )
			llResetScript();
		
		// Event handler
		#ifdef USE_EVENTS
		if(nr == EVT_RAISED){
		
			int evt = (int)((str)id);
			list dta = llJson2List(s);
			onEvt( l2s(dta, 0), (int)((str)id), llJson2List(l2s(dta, 1)) );
			
		}
		#endif
		
		if( nr != TASK_FXC_PARSE )
			return;
				
		list input = llJson2List(s);
		s = "";
		
		// Store changed passive types
		list fxTypes;		// FX types that need to be recompiled
		list defaults;		// Stores default values for fxType. Same index as fxTypes
		int gravChanged;
		int flagsChanged;
		int refreshCombat;
		int i;
				
		integer in;
		for(; in < count(input); in += 2 ){
			
			int action = l2i(input, in);
			int pix = l2i(input, in+1);
			str table = getFxPackageTableByIndex(pix);
			
			int team = status$team();
			int stacks = (int)db4$fget(table, fxPackage$STACKS);
			key caster = db4$fget(table, fxPackage$SENDER);
			str pname = db4$fget(table, fxPackage$NAME);
			int pflags = (int)db4$fget(table, fxPackage$FLAGS);
			list fxs = llJson2List(db4$fget(table, fxPackage$FXOBJS));
			
			
			if( pflags & PF_NO_STACK_MULTIPLY )
				stacks = 1;

			if( pflags & PF_DETRIMENTAL && action&(FXCPARSE$ACTION_ADD|FXCPARSE$ACTION_STACKS|FXCPARSE$ACTION_RUN) )
				refreshCombat = TRUE;
			
			// Add/Remove needs to update events
			if( action&(FXCPARSE$ACTION_ADD|FXCPARSE$ACTION_REM) ){
			
				list evts = llJson2List(db4$fget(table, fxPackage$EVTS));
				for( i = 0; i < count(evts); ++i ){
					
					str evt = l2s(evts, i);
					str eTable = getEventPackageTable(j(evt, FXEVT_TYPE), j(evt, FXEVT_SCRIPT));
					list cur = getEventPackageIndexes(eTable);
					int pos = llListFindList(cur, (list)pix);
					
					// Add to table
					if( action&FXCPARSE$ACTION_ADD && pos == -1 )
						cur += pix;
					// Remove from table
					if( action&FXCPARSE$ACTION_REM && ~pos )
						cur = llDeleteSubList(cur, pos, pos);
						
					if( cur )
						llLinksetDataWrite(eTable, mkarr(cur));
					else
						llLinksetDataDelete(eTable);
						
				}
				
			}
						
			// Iterate over the package FX
			for( i = 0; i < count(fxs); ++i ){
			
				list fx = llJson2List(llList2String(fxs,i));
				integer t = l2i(fx, 0);	// Effect type
				fx = llDeleteSubList(fx, 0, 0);
				int def = l2i(DEF, t);
				
				// Store information about changed passive types
				if( action & (FXCPARSE$ACTION_ADD|FXCPARSE$ACTION_REM|FXCPARSE$ACTION_STACKS) ){
				
					if( llListFindList(fxTypes, (list)t) == -1 && def != fx$NO_PASSIVE ){
					
						fxTypes += t;
						defaults += llList2List(DEF, t, t);
						if( t == fx$SET_FLAG || t == fx$UNSET_FLAG )
							flagsChanged = TRUE;
						else if( t == fx$GRAVITY )
							gravChanged = TRUE;
						
					}
					
				}
				
				if( action&FXCPARSE$ACTION_RUN ){
					
					#undef FXCOMPILER_SECTION
					#define FXCOMPILER_SECTION 1
					#ifdef IS_NPC
						#include "./got FXCompiler_NPC.lsl"
					#else
						#include "./got FXCompiler_PC.lsl"
					#endif
					
				}
				if( action&FXCPARSE$ACTION_ADD ){
					#undef FXCOMPILER_SECTION
					#define FXCOMPILER_SECTION 2
					#ifdef IS_NPC
						#include "./got FXCompiler_NPC.lsl"
					#else
						#include "./got FXCompiler_PC.lsl"
					#endif
					
				}
				if( action&FXCPARSE$ACTION_REM ){ 
				
					#undef FXCOMPILER_SECTION
					#define FXCOMPILER_SECTION 3
					#ifdef IS_NPC
						#include "./got FXCompiler_NPC.lsl"
					#else
						#include "./got FXCompiler_PC.lsl"
					#endif

				}
				
			}
			
			// Unlink instant effects and removed effects here.
			if( action&FXCPARSE$ACTION_REM || (int)db4$fget(table, fxPackage$DUR) == 0 ){
				db4$fdelete(table, fxPackage$STACKS);
			}

				
		}
		

		if( refreshCombat )
			Status$refreshCombat();
		
		// PASSIVES have changed and must be recompiled
		if( fxTypes != [] ){
					
			// Scan through packages and find changed variables
			fxPackageEach(pix,tb,
				
				list effects = llJson2List(db4$fget(tb, fxPackage$FXOBJS));
				int stacks = (int)db4$fget(tb, fxPackage$STACKS);
				int flags = (int)db4$fget(tb, fxPackage$FLAGS);
				int sender = key2int(db4$fget(tb, fxPackage$SENDER));
				if( flags & PF_NO_STACK_MULTIPLY )
					stacks = 1;
					
				// Loop through effect arrays
				integer fxi;
				for(; fxi < count(effects); ++fxi ){
					
					// See if we need to compile this type
					int type = (int)j(l2s(effects, fxi), 0);
					int pos = llListFindList(fxTypes, (list)type);
					// This type is being compiled
					if( ~pos ){
						
						list cur = llList2List(defaults, pos, pos);
						list add = llDeleteSubList(llJson2List(l2s(effects, fxi)), 0, 0);
						list out;
						
						// Concat JSON array types
						if( type == fx$CONVERSION )
							out = (list)mkarr(llJson2List(l2s(cur, 0)) + add);
						// Bitwise types
						else if( type == fx$SET_FLAG || type == fx$UNSET_FLAG ){
							out = (list)(l2i(cur,0)|l2i(add,0));
						}
						else if( type == fx$SPELL_HIGHLIGHT && stacks >= l2i(add, 1) ){
							out = (list)(l2i(cur,0)|(1<<l2i(add,0))); 
						}
						// Replace types
						else if( type == fx$FOV || type == fx$SET_TEAM || type == fx$REDIR_SPEECH )
							out = (list)add;
						// Integer additive types
						else if( type == fx$HP_ADD || type == fx$MANA_ADD || type == fx$MAX_AROUSAL_ADD || type == fx$MAX_PAIN_ADD )
							out = (list)(l2i(cur,0)+l2i(add,0)*stacks);
						// Float additive
						else if( type == fx$GRAVITY ){
							out = (list)(l2f(cur, 0)+l2f(add,0)*stacks);
						}
						// Inverse multiplicative types
						else if( type == fx$DODGE )
							out = (list)(l2f(cur,0)*(1.0-l2f(add,0)*stacks));
						// outputs [<casterInt>_<spellName>, (float)multi]
						else if( type == fx$SPELL_DMG_TAKEN_MOD ){
							
							str label = "0";	// Modify all packages with this name
							if( l2i(add, 2) )	// Modify only if the caster is the sender of this package
								label = (str)sender;
							label += "_"+l2s(add, 0); // Add the package name
							
							float val = 1.0+l2f(add,1)*stacks; // Make value multiplicative
							list c = llJson2List(l2s(cur, 0));
							int pos = llListFindList(c, (list)label);
							if( ~pos )
								c = llListReplaceList(c, (list)(l2f(c, pos+1)*val), pos+1, pos+1);
							else
								c += (list)label + val;
							out = (list)mkarr(c);
							
						}
						// Global and bycaster modifiers: [0(global),float globalMod,   key2int(uuid),float uuidMod...]
						else if( type == fx$DAMAGE_DONE_MULTI || type == fx$DAMAGE_TAKEN_MULTI || type == fx$HEALING_TAKEN_MULTI ){
						
							float multi = l2f(add, 0)*stacks;
							int targ = 0;
							if( l2i(add, 1) )
								targ = sender;
							
							list c = llJson2List(l2s(cur, 0));
							int pos = llListFindList(c, (list)targ);
							
							if( ~pos )
								c = llListReplaceList(c, (list)(l2f(c, pos+1)*(multi+1.0)), pos+1, pos+1);
							else
								c += (list)targ + (multi+1.0);
							out = (list)mkarr(c);
							
						}
						// Spell index modifiers [float abil4,float abil0, float abil1, float abil2, float abil3, float abil5]
						else if( type == fx$SPELL_DMG_DONE_MOD || type == fx$SPELL_MANACOST_MULTI || type == fx$SPELL_CASTTIME_MULTI || type == fx$SPELL_COOLDOWN_MULTI ){
							
							list c = llJson2List(l2s(cur, 0));
							int idx = l2i(add, 0);
							float val = (l2f(add, 1)*stacks+1.0)*l2f(c, idx);
							c = llListReplaceList(c, (list)val, idx, idx);
							out = (list)mkarr(c);
							
						}
						// Float multiplication
						else{
							
							// Multiplicative type
							out = (list)(l2f(cur,0)*(l2f(add,0)*stacks+1.0));
							
						}

						defaults = llListReplaceList(defaults, out, pos, pos);
						
						
					
					}
					
				}
				
			)
			
			// Update the actives table
			for( i = 0; i < count(fxTypes); ++i )
				db4$replace(gotTable$fxCompilerActives, l2i(fxTypes, i), l2s(defaults, i));
			
			if( flagsChanged )
				db4$freplace(
					gotTable$fxCompilerActives, 
					fxf$SET_FLAG,
					(int)fx$getDurEffect(fxf$SET_FLAG)&~(int)fx$getDurEffect(fxf$UNSET_FLAG)
				);
			
			if( gravChanged )
				llSetBuoyancy((float)fx$getDurEffect(fxf$GRAVITY));
			
			
			// Tell scripts what types have been updated
			llMessageLinked(LINK_SET, TASK_FX, mkarr(fxTypes), "");
			
			//qd("Types "+mkarr(fxTypes));
			//qd("Vals "+mkarr(defaults));
		}
	
	}


}
