/*
	
	Requires the following functions:
	runEffect(integer pid, integer pflags, str pname, arr fxobjs, int timesnap, key sender)
	addEffect(integer pid, integer pflags, str pname, arr fxobjs, int timesnap, (float)duration)
	remEffect(integer pid, integer pflags, str pname, arr fxobjs, int timesnap, bool overwrite)
	
	// Stacks can be acquired through getStacks(PID)
	
	updateGame()
	
*/
list PLAYER_HUDS;
//#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

/*
	STACKS:
	[
		(int):
			0b0(1) no_stack_multiply
			0b0000000000000000(16) pid,
			0b00000000000000(14) stacks
	]

*/

// Cache proc chance beneficial/detrimental
float CPB = 1.0;
float CPD = 1.0;

list STACKS;
#define sGetStacks( n ) (n&0x3FFF);
#define sGetPid( n ) ((n>>14)&0xFFFF)
#define sGetIgnoreStacks( n ) ((n>>30)&1)	// Returns if stacks should be ignored
#define addStacks( stacks, pid, no_stack_multiply ) \
	STACKS += (stacks&0x3FFF|((pid&0xFFFF)<<14)|((no_stack_multiply>0)<<30));

#define removeStacks( pid ) \
	integer _sr; \
	for( ; _sr<count(STACKS) && count(STACKS); ++_sr ){ \
		integer n = l2i(STACKS, _sr); \
		if( sGetPid(n) == pid ){ \
			STACKS = llDeleteSubList(STACKS, _sr, _sr); \
			--_sr; \
		} \
	}
	
#define replaceStacks( pid, nr ) \
	integer _sr; \
	for( ; _sr<count(STACKS); ++_sr ){ \
		integer n = l2i(STACKS, _sr); \
		if( sGetPid(n) == pid ) \
			STACKS = llListReplaceList(STACKS, (list)((n&~0x3FFF)|(nr&0x3FFF)), _sr, _sr); \
	}
	
integer CACHE_FLAGS;		// Cache of FX flags, used for certain effects


#define onStackUpdate() //qd(mkarr(STACKS))
// updateGame is now run at the end of the package parser

// If absolute it set, it will return nr stacks regardless of PF_NO_STACK_MULTIPLY, used for proper spell icon stack count
integer getStacks( integer pid, integer absolute ){

	integer i;
	for( ; i<count(STACKS); ++i ){
		
		integer n = l2i(STACKS, i);
		if( 
			sGetPid(n) == pid && 
			( 
				!sGetIgnoreStacks(n) || 
				absolute
			)
		)return sGetStacks(n);
	}

	return 1;
	
}


default 
{
	#ifdef IS_NPC 
	state_entry(){
		
		if(llGetStartParameter())
			raiseEvent(evt$SCRIPT_INIT, "");
	}
	changed(integer change){
		if(change&(CHANGED_INVENTORY|CHANGED_ALLOWED_DROP)){
			spawnEffects();
		}
	}
	#else
	state_entry(){ PLAYER_HUDS = (list)((string)llGetKey()); }
	#endif
	
	link_message( integer link, integer nr, string s, key id ){
		
		if( nr == RESET_ALL )
			llResetScript();
		
		// Event handler
		if(nr == EVT_RAISED){
		
			int evt = (int)((str)id);
			list dta = llJson2List(s);
			str script = l2s(dta, 0);
			if( l2s(dta,0) == "got Status" && evt == StatusEvt$team )
				TEAM = l2i(dta,1);
				
			#ifdef NPC
			if( script == "got Portal" && evt == PortalEvt$playerHUDs )
				PLAYER_HUDS = llJson2List(l2s(dta, 1));
			#else
			if( script == "#ROOT" && evt == RootEvt$coop_hud ){
				
				PLAYER_HUDS = llListReplaceList(llJson2List(l2s(dta, 1)), (list)((str)llGetKey()), 0, 0);

			}
			#endif
			#ifdef USE_EVENTS
				onEvt( l2s(dta, 0), (int)((str)id), llJson2List(l2s(dta, 1)) );
			#endif
		}
		
		if( nr == TASK_FX ){
			
			list dta = llJson2List(s);
			CPB = i2f(l2i(dta, FXCUpd$PROC_BEN));
			CPD = i2f(l2i(dta, FXCUpd$PROC_DET));
			return;
			
		}

		if( nr != TASK_FXC_PARSE )
			return;
				
		
		integer actions;
		list input = llJson2List(s);
		if(input == [])return;
		while(input){
		
			integer action = l2i(input,0); 
			actions = actions|action;
			integer PID = l2i(input,1); 
			integer stacks = l2i(input, 2); 
			integer pflags = l2i(input,3); 
			string pname = l2s(input, 4); 
			string fx_objs = l2s(input, 5); 
			integer timesnap = l2i(input, 6);
			string additional = l2s(input, 7); 
			input = llDeleteSubList(input, 0, FXCPARSE$STRIDE-1); 
			
			// Stacks first
			if( action&FXCPARSE$ACTION_ADD ){
				integer s = stacks; 
				if( stacks < 1 )
					stacks=1;
				addStacks(stacks, PID, (pflags&PF_NO_STACK_MULTIPLY));
			}
			
			if( action&FXCPARSE$ACTION_RUN ) 
				runEffect(PID, pflags, pname, fx_objs, timesnap, id); 
			
			if( action&FXCPARSE$ACTION_ADD ){ 
			
				addEffect(PID, pflags, pname, fx_objs, timesnap, i2f((int)additional), id); 
				onStackUpdate(); 
				
			} 
			
			if( action&FXCPARSE$ACTION_REM ){ 
			
				remEffect(PID, pflags, pname, fx_objs, timesnap, (int)additional); 
				removeStacks(PID);
				
			} 
			
			if( action&FXCPARSE$ACTION_STACKS ){ 
			
				integer s = stacks; 
				if( s<1 )
					s = 1; 
				
				replaceStacks(PID, s);

				#ifdef IS_NPC
					NPCInt$stacksChanged(PID, timesnap, (int)(i2f((int)additional)*10), s); 
				#else
					Evts$stacksChanged(PID, timesnap, (int)(i2f((int)additional)*10), s); 
				#endif
				onStackUpdate(); 
							
			} 
		}
		
		if( actions&(FXCPARSE$ACTION_ADD|FXCPARSE$ACTION_REM|FXCPARSE$ACTION_STACKS))
			updateGame(); 
	}
	

}
