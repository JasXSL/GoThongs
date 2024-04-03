list TAG_CACHE;     // [(int)tag1...] - Speeds up tag conditions

// FX stuff
float DOD;			// Cache of dodge chance for speed purposes
integer FX_FLAGS;	// Cache of FX flags for speed purposes
integer STATUS;		// Cache of status flags

// Searches packages and returns a list of PIX
// Max can be used to limit nr of returned PIX. Usually 1. Use 0 for ALL
list find( list names, list senders, list tags, list pixs, list flags, integer max, int passives ){
    
    list out;
    fxPackageEach(i,table,
	
        integer stacks = (int)db4$fget(table, fxPackage$STACKS);
        // There is no data on this block
        if( !stacks )
            jump findContinue;
        
		// Ignore passives
		if( !passives ){
			float dur = (float)db4$fget(table, fxPackage$DUR);
			if( dur < 0 )
				jump findContinue;
		}
		
        // Find by pix
        if( l2i(pixs, 0) ){
			if( llListFindList(pixs, (list)i) == -1 )
				jump findContinue;
		}
        
        
        // Find by name
        if( l2s(names,0) != "" ){
			if( llListFindList(names, (list)db4$fget(table,fxPackage$NAME)) == -1 )
				jump findContinue;
		}
        
		
        integer x;
        
        if( l2i(flags, 0) ){
            
            integer fl = (int)db4$fget(table, fxPackage$FLAGS);
            for( ; x < count(flags); ++x ){
			
                integer inverse = l2i(flags,x) < 0;
                integer f = llAbs(l2i(flags, x));
                if(f && (
                    // Succeed if we don't have any of the flags
                    (inverse && !(fl&f)) || 
                    // Succeed we have any of the flags
                    (!inverse && (fl&f))
                )){
                    // Break because of success
                    x = 9001;
                }
				
            }

            if( x < 9000 )
                jump findContinue;
				
        }
        
        // Find at least one sender
        if( l2s(senders,0) != "" ){
			if( llListFindList(senders, (list)db4$fget(table, fxPackage$SENDER)) == -1 )
				jump findContinue;
		}
        
		if( l2i(tags, 0) ){
			// Find by tag
			list t = llJson2List(db4$fget(table, fxPackage$TAGS));
			for(x = 0; x < count(tags) && l2i(tags,0); x++){
				if( ~llListFindList(t, llList2List(tags, x,x)) )
					x = 9001;
			}
			if( x < 9001 )
				jump findContinue;
        }
		
        // Success!
        out += i;
		if( count(out) >= max && max )
			return out;
			
        @findContinue;
    )
    return out;
    
}
	

onEvt( string script, integer evt, list data ){

	// Extended events
    #ifdef FXConf$useEvtListener
    evtListener(script, evt, data);
    #endif
		
	// Beyond here is used to find package event bindings	
	// Find packages to scan (list of PIX)
	list packages = [];
	key dispeller;
	
	// If internal event, run on a specific pix by data
	
	// Check if the event should trigger on a single package by PIX
	// spell added, dodge, and package ran should be able to be triggered from other events than the pix that caused it, so are excluded
	// Ex: one event might want an event when another package is added by name
	if( script == "" && evt != INTEVENT_SPELL_ADDED && evt != INTEVENT_DODGE && evt != INTEVENT_PACKAGE_RAN ){
		
		if( evt == INTEVENT_DISPEL )
			dispeller = llList2String(data, 1);
		
		packages = data; // Data is the pix to run
		jump wasInternal;
		
	}
	
	// This was a generic event
	packages = getEventPackageIndexes(getEventPackageTable((str)evt, script));		// EVT_INDEX is stored as script_evtID
    @wasInternal;
	
	
	debugCommon("Found event packages: "+mkarr(packages)+">>"+getEventPackageTable((str)evt, script));

	int ts = timeSnap(); // Time in 10ths of a second
	vector pos = llGetPos();
	
	
	// Cycle through all packages that have this event
	integer i;
	for(; i < count(packages); ++i ){
		
		integer pix = l2i(packages, i);
		str table = getFxPackageTableByIndex(pix);
        str lastProcs = db4$fget(table, fxPackage$PROC);	// JSON object
		
		string sender = db4$fget(table, fxPackage$SENDER);
		list evts = llJson2List(db4$fget(table, fxPackage$EVTS));
		float range = llVecDist(llGetPos(), prPos(sender));
		
		integer ei;
		for( ; ei < count(evts); ++ei ){
		
			list evdata = llJson2List(l2s(evts, ei)); 	// Event array from package
			float chance = l2f(evdata, FXEVT_PROC_CHANCE);
			float maxRange = l2f(evdata, FXEVT_RANGE);
			int evFlags = l2i(evdata, FXEVT_FLAGS);
			int cd = (int)(l2f(evdata, FXEVT_COOLDOWN)*10);	// Cooldown is stored in seconds. Convert to 10th of a second for timesnap comparison.
			int lastProc = (int)j(lastProcs, ((str)ei));
			
			debugCommon("Script "+script+" "+mkarr(evdata));
			debugCommon(mkarr((list)
				(chance > 0 && llFrand(1.0) > chance) +
				(FX_FLAGS&fx$F_NO_PROCS && ~evFlags&FXEVT$PF_OVERRIDE_PROC_BLOCK) +
				(lastProc && ts-lastProc < cd) +
				(script != l2s(evdata, FXEVT_SCRIPT) )+
				(evt != l2i(evdata, FXEVT_TYPE))
			));
			
			// If proc chance was not successful. Then continue.
			if( 
				(chance > 0 && llFrand(1.0) > chance) ||
				(FX_FLAGS&fx$F_NO_PROCS && ~evFlags&FXEVT$PF_OVERRIDE_PROC_BLOCK) ||
				(lastProc && ts-lastProc < cd) ||
				script != l2s(evdata, FXEVT_SCRIPT) ||
				evt != l2i(evdata, FXEVT_TYPE)
			)jump evtNext;
			
			debugCommon("Accepted");
			// JSON array of parameters set in the package
			list against = llJson2List(l2s(evdata, FXEVT_PARAMS));

			// Iterate over parameters and make sure they validate with the event params we received
			integer i;
			for( ; i < count(against); ++i ){
				
				// Event data from package event
				list eva = explode("||", l2s(against, i));
				// From event
				string evtv = l2s(data, i);
				
				// Quick check
				if( (~llListFindList(eva, (list)evtv) && evtv != "") || l2s(eva, 0) == "" )
					jump vSuccess;
				
				// Deep check
				list_shift_each(eva, v,
				
					string f = llGetSubString(v, 0, 0);
					float evtF = (float)evtv;
					float packageF = (float)llGetSubString(v, 1, -1);
					
					if( 
						(f == ">" && evtF > packageF ) ||
						(f == "<" && evtF < packageF ) ||
						(f == "&" && (int)evtF&(int)packageF ) ||
						(f == "~" && ~(int)evtF&(int)packageF )
					)jump vSuccess;	// Continue
					
				)
				
			
				jump evtNext;			// Fail, go to the next event					
				@vSuccess;				// Continue
			}
			
			// We have validated that this event should be accepted, let's extract the wrapper
			str wrapper = l2s(evdata, FXEVT_WRAPPER);

			// CONSTANTS
			// We can use <index> and <-index> tags to replace with data from the event
			for( i=0; i < count(data); ++i ){
			
				wrapper = implode((str)(-l2f(data, i)), explode("<-"+(str)i+">", wrapper));
				wrapper = implode(l2s(data, i), explode("<"+(str)i+">", wrapper));
				
			}
			// Additional constants
			// <V> = Victim (llGetKey())
			wrapper = implode((str)llGetKey(), explode("<V>", wrapper));
			
			// Target flags
			integer targ = llList2Integer(evdata, FXEVT_TARG);
			integer maxtargs = llList2Integer(evdata, FXEVT_MAXTARGS);
			if( maxtargs == 0 )
				maxtargs = -1;

			int team = hud$status$team();
			
			lastProcs = llJsonSetValue(lastProcs, (list)((str)ei), (str)ts);
			
			#ifndef IS_NPC
			list targs;
			float mr = maxRange;	// max range
			#endif
			// 0 or lower uses an event value
			if( targ < 1 ){
			
				#ifdef IS_NPC
					FX$send(l2s(data, llAbs(targ)), sender, wrapper, team);
				#else
					targs += l2s(data, llAbs(targ));
				#endif
				
			}
			else{
			
				// AOE cannot be limited by nr, maxtargs is instead used as a way to limit distance
				if( targ&TARG_AOE ){
					
					#ifdef IS_NPC
						float r = maxtargs;	// Legacy AoE uses maxtargs as range
						if( maxRange > 0 )	// Setting dedicated maxRange will override
							r = maxRange;
						FX$aoe(r, llGetKey(), wrapper, team);
						maxtargs = 1000;
					#else
						if( maxRange <= 0 )
							mr = maxtargs;
						targs = (list)"AOE";
						maxtargs = 0;	// AoE will hit everybody including self
					#endif
											
				}
				
				// Run on self if victim or caster is us
				if( 
					maxtargs &&
					targ&TARG_VICTIM 
					#ifndef IS_NPC
					|| (targ&TARG_CASTER && sender == llGetOwner())
					#endif
				){
					#ifdef IS_NPC
						FX$run(sender, wrapper); 
					#else
						targs += llGetOwner();
					#endif
					--maxtargs;
				}
				
				
				// Run on dispeller (if dispel event)
				if( targ&TARG_DISPELLER && dispeller != "" && maxtargs != 0 && (maxRange <= 0 || llVecDist(pos, prPos(dispeller)) < maxRange) ){
					
					#ifdef IS_NPC
						if( dispeller == llGetKey() )
							FX$run(sender, wrapper);
						else 
							FX$send(dispeller, sender, wrapper, team);
					#else
						targs += (list)dispeller;
					#endif
					
					--maxtargs;
					
				}
				
				// Run on caster last
				if( 
					targ&TARG_CASTER && 
					maxtargs != 0 && 
					#ifndef IS_NPC
					sender != llGetOwner()&& 
					#endif
					(maxRange <= 0 || llVecDist(pos, prPos(sender)) < maxRange) 
				){
					
					#ifdef IS_NPC
						FX$send(sender, sender, wrapper, team); 
					#else
						targs += sender;
					#endif
					--maxtargs;
					
				}
			
			}
			
			
			// Players tunnel their procs through spellaux
			#ifndef IS_NPC
			if( targs )
				SpellAux$tunnel( wrapper, targs, mr, 0 );
			#endif
			
		
			
			// Used to skip to next part of loop
			@evtNext;
			
		}
		
		// Update cooldowns
		db4$freplace(table, fxPackage$PROC, lastProcs);
		
    }
	
	
	
}



// Validates a package before it can be accepted
// Package is an actual package, not the abridged version stored in PACKAGES
integer preCheck(key sender, list package, integer team){
	
	// Quick scan if we're dead or not
	integer flags = l2i(package, PACKAGE_FLAGS);
	if( 
		(~flags&PF_ALLOW_WHEN_DEAD && isDead() )
		#ifdef IS_INVUL_CHECK
		|| (flags&PF_DETRIMENTAL && IS_INVUL_CHECK())
		#endif
	){
		return FALSE;
	}
	// Conditions from the package
    list conds = llJson2List(l2s(package, PACKAGE_CONDS));
    
	// Min conditions that have to be met
	integer min = l2i(package, PACKAGE_MIN_CONDITIONS);
    // Require ALL if min is 0
	if( min == 0 )
		min = count(conds);
	
	// Nr conditions met, this value has to be at least min to validate
    integer successes;
	
	// If we validated enough conditions. This is used because it can be inverted if the condition is negative
    integer add = TRUE;
	
	// Tracks how many conditions we have looped through, used to break the loop if the remaining conditions aren't enough to meet min
    integer parsed;
	integer TEAM = hud$status$team();
	
    // loop through all conditions
	integer i;
	for(; i < count(conds); ++i ){
		
		list dta = llJson2List(l2s(conds, i));
		integer c = l2i(dta,0); 	// Condition ID, rest of condl is vars 
        dta = llDeleteSubList(dta,0,0);		// Vars

        integer inverse = c < 0;				// Should return TRUE if validation fails, otherwise false
        c = llAbs(c);
        
		// Built in conditions
        if( c == fx$COND_RANDOM )
			add = l2f(dta, 0) > llFrand(1.0);
			
        else if( c == fx$COND_HAS_PACKAGE_NAME || c == fx$COND_HAS_PACKAGE_TAG ){
		
            integer found;			
			// See if we have one of the package names stored in dta
            if( c == fx$COND_HAS_PACKAGE_NAME ){
				// find(list names, list senders, list tags, list pixs, list flags, integer max){
				found = count(find(dta, [],[],[],[], 1, FALSE)); // Fetches max 1
			}
			// See if we have a tag stored in dta
			else{
				integer t;
				for(; t < count(dta) && !found; ++t ){
					if( ~llListFindList(TAG_CACHE, [l2i(dta, t)]) )
						found = TRUE;
				}
            }
			
            // Not found, so add should be false
            if( !found )
				add = FALSE;
 
        }
		else if(c == fx$COND_SAME_TEAM){
			inverse = l2i(dta,0);
			add = (TEAM == team);
		}
		else if( c == fx$COND_NAME )
			add = (llGetObjectName() == l2s(dta, 0));
		
		else if( c == fx$COND_SAME_OWNER ){
			add = (llGetOwnerKey(sender) == llGetOwner());
		}
		else if( c == fx$COND_CASTER_ANGLE ){
		
			myAngZ(sender, ang)
			myAngX(sender, a)
			
			int n = -1;
			if( llGetAgentSize(sender) != ZERO_VECTOR ){
			
				parseMonsterFlags(sender, flags)
				n = flags;
				
			}
			
			// Use X angle if:
			if( 
				n == -1 || // Avatar
				n & Monster$RF_ANIMESH ||	// Animesh
				l2i(llGetObjectDetails(sender, [OBJECT_ATTACHED_POINT]),0) // Attached
			)ang = a;
			
			vector tpos = prPos(sender);
			vector gpos = llGetRootPosition();
			tpos.z = gpos.z;
			add = llFabs(ang) < l2f(dta, 0);
			
			if( llVecDist(tpos, gpos) < 0.5 || sender == llGetOwner() )
				add = !inverse;
		
		}
		else if( c == fx$COND_TEAM )
			add = ~llListFindList(dta, (list)TEAM);
		else if(c == fx$COND_SELF)
			add = (sender == llGetOwner());
		
		else if( c == fx$COND_CASTER_RANGE )
			add = llVecDist(llGetRootPosition(), prPos(sender)) < l2f(dta, 0);

		// User defined conditions
        else
			add = checkCondition(sender, c, dta, flags, team);
		
		// If we're inverse, then flip add
        if(inverse)
			add = !add;
				
		// Store successes
        successes += (add != FALSE);
		
		// We have reached the minimum
        if( successes >= min )
			return TRUE;
		
		// Increase nr parsed
        ++parsed;
		
		// If there aren't enough conditions left to generate enough successes, just bail
        if( successes+(min-parsed) < min )
			return FALSE;
			
    }
	// Output if we hit enough successes
    return successes>=min;
	
}



timerEvent(string id, string data){

    integer pix = (integer)llGetSubString(id, 2, -1);
	
	// Package has timed out
    if(llGetSubString(id, 0, 1) == "F_"){
		FX$rem(TRUE, "", 0, "", pix, FALSE, 0, 0, "", FALSE);
    }
	// Package should tick
    else if(llGetSubString(id, 0, 1) == "T_"){
	
		str table = getFxPackageTableByIndex(pix);
		string sender = db4$fget(table, fxPackage$SENDER);
		llMessageLinked(LINK_THIS, TASK_FXC_PARSE, mkarr((list)FXCPARSE$ACTION_RUN + pix), sender);
		onEvt("", INTEVENT_PACKAGE_RAN, (list)db4$fget(table, fxPackage$NAME));

    }
	
} 



default{

	// Only NPC needs to raise init event
	
	state_entry(){
		
		list keys = llLinksetDataFindKeys(gotTable$fxCompilerEvts+"-?\\d", 0,-1); 
		int i; 
		for(; i < count(keys); ++i ) 
			llLinksetDataDelete(l2s(keys, i));
		// Clear all the effects
		for( i = 0; i < gotTable$fxStart$length; ++i ){
			str table = getFxPackageTableByIndex(i);
			integer sub = 0;
			for(; sub < 20; ++sub )
				db4$delete(table, sub);
		}
		
		#ifdef IS_NPC
		if( llGetStartParameter() )
			raiseEvent(evt$SCRIPT_INIT, "");
		#endif	
		
	}
	
    
    timer(){ multiTimer([]); }
    
	// Update from database
	#define LM_PRE \
	if( nr == TASK_FX ){ \
		FX_FLAGS = (int)fx$getDurEffect(fxf$SET_FLAG); \
		DOD = 1.0-(float)fx$getDurEffect(fxf$DODGE); \
	}

	#include "xobj_core/_LM.lsl"

		// Prevent callbacks from being received
        if( method$isCallback )
			return;
	
		
		// This is the main input for adding an effect
        if( METHOD == FXMethod$run ){
			
			string sender = method_arg(0);						// UUID of FX sender
			
			// Convert "" and llGetKey() to owner
			if( sender == "" || sender == llGetKey() )
				sender = llGetOwner();

            list wrapper = llJson2List(method_arg(1));			// Open up the wrapper
			float range = llList2Float(PARAMS, 2);				// Max range for FX (if >0)
			integer team = llList2Integer(PARAMS, 3);			// Team defaults to NPC unless set
			int TEAM = hud$status$team();
			// Internal commands are always same team
			if( method$internal )
				team = TEAM;

			integer flags = llList2Integer(wrapper, 0);		// Wrapper flags
			if( flags&WF_ENEMY_ONLY && team == TEAM )
				return;
			
			integer min_objs = llList2Integer(wrapper,1);		// Min packages to add
            integer max_objs = llList2Integer(wrapper,2);		// Max packages to add
			wrapper = llDeleteSubList(wrapper, 0, 2);			// Now wrapper contains a stride of 2: (int)stacks_to_add, (arr)package

			#ifdef IS_NPC
				// RC is only needed for NPCs since NPCs can direct effects to players
				integer RC = TRUE;
				if( flags&WF_REQUIRE_LOS && id != "" ){
				
					list data = llGetObjectDetails(id, [OBJECT_POS, OBJECT_DESC]);
					vector pos = l2v(data, 0);
					if(llGetSubString(l2s(data, 1), 0, 2) == "$M$")
						pos+= <0,0,1>;
					list rc = llCastRay(llGetRootPosition()+<0,0,.5>, pos, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS, RC_DATA_FLAGS,RC_GET_ROOT_KEY]);
					if( llList2Integer(rc, -1) > 0 && l2k(rc, 0) != llGetKey() )
						RC = FALSE;
						
				}
			#endif
			
			// Quick flag check on the wrapper
			if(
				(~flags&WF_ALLOW_WHEN_DEAD && STATUS&StatusFlag$dead) || 
				(~flags&WF_ALLOW_WHEN_QUICKRAPE && FX_FLAGS&fx$F_QUICKRAPE && flags&WF_DETRIMENTAL) || 
				(~flags&WF_ALLOW_WHEN_RAPED && STATUS&StatusFlag$raped) ||
				(range > 0 && llVecDist(llGetRootPosition(), prPos(id))>range)
				#ifdef IS_NPC
				|| !RC
				#endif
			){
				CB_DATA = (list)FALSE;
			}
			
			// If a user defined invul function is defined
			#ifdef IS_INVUL_CHECK
			else if( flags&WF_DETRIMENTAL && IS_INVUL_CHECK() ){
				CB_DATA = (list)FALSE;
			}
			#endif
			// Check dodge
			else if( ~flags&WF_NO_DODGE && flags&WF_DETRIMENTAL && sender != llGetOwner() && llFrand(1.0) < DOD ){
				
				// If not NPC we should animate when we dodge
				#ifndef IS_NPC
				AnimHandler$anim("[\"got_dodge_active\",\"got_dodge_active_ub\"]", TRUE, 0, 0, 0);
				#endif
				llTriggerSound("2cd691be-46dc-ba05-9a08-ed4a8f48a976", .5);
				onEvt("", INTEVENT_DODGE, []);
				raiseEvent(FXEvt$dodge, sender);
				CB_DATA = (list)FALSE;
				
				
			}
			else{
			
				// The wrapper was accepted, so now we need to scan the packages
				list successful;	// [(int)nrStacks, (int)package_length]+packageData
				integer nSuc = 0;	// nr successful
				
				// Cycle through. Wrappers are now 2-stride [(int)stacks, (arr)package]
				integer i;
				for( ; i < count(wrapper); i += 2 ){
				
					list p = llJson2List(l2s(wrapper, i+1));			// Convert package to list, since preCheck would have to do that anyways
					// Run user defined function on it
					if( preCheck(sender, p, team) ){
					
						successful += (list)l2i(wrapper, i) + count(p) + p;
						++nSuc;
						
					}
					// If we have enough successful packages, stop
					if( nSuc >= max_objs && max_objs != 0 )
						i = count(wrapper);
					
				}
								
				// We don't have enough successful packages
				if( nSuc < min_objs || !nSuc )
					CB_DATA = (list)FALSE;
				// We have enough successful packages. Let's open them
				else{
				
					CB_DATA = (list)nSuc;		// Set a callback value of nr accepted packages
					
					// If we received a detrimental effect, refresh combat
					#ifndef IS_NPC
					if( flags&WF_DETRIMENTAL ){
					
						// Update combat since we received a detrimental effect
						Status$refreshCombat();
						// Attempt to target monster unless we already have a target
						if( hud$root$targ() == "" )
							Status$monster_attemptTarget(sender, false);

					}
					#endif
					
					// Raise event
					raiseEvent(FXEvt$wrapperSuccess, mkarr((list)id + ((flags&WF_DETRIMENTAL) > 0)));
					
					// Data to send to the FXCompiler
					list send = [];
					
					@reloop;	// Jump is not graceful but LSL doesn't fucking have continue;

					while( successful ){
						
						integer stacks = llList2Integer(successful, 0);
						// Min stacks is 1
						if( stacks == 0 )
							stacks = 1;
						
						list package = llList2List(successful, 2, 2+llList2Integer(successful,1)-1);
						successful = llDeleteSubList(successful, 0, 2+count(package)-1);
						
						float dur = llList2Float(package, PACKAGE_DUR);
						integer flags = llList2Integer(package, PACKAGE_FLAGS);
						string name = llList2String(package, PACKAGE_NAME);
						integer mstacks = llList2Integer(package, PACKAGE_MAX_STACKS); 
						
						if( mstacks == 0 )
							mstacks = 1;
						integer ts = timeSnap();
						
						integer pix;	// 1-indexed.
						string table;
												
						// Check if it already exists
						// Instant effects and passives skip this check. Passives because they are always removed first.
						if( dur > 0 ){
						
							// See if package exists already
							list s = (list)sender;
							// If full unique, it can add stacks regardless of sender
							if( flags&PF_FULL_UNIQUE )
								s = [];
							// find(list names, list senders, list tags, list pixs, list flags, integer max){
							list exists = find((list)name, s, [], [], [], 1, TRUE); // Fetch max 1. Include passives.
							
							if( exists ){
								
								pix = l2i(exists, 0);
								table = getFxPackageTableByIndex(pix);
								
								// Append time, allowing it to exceed the max duration
								if( flags & PF_STACK_TIME ){
									
									dur = dur + (float)db4$fget(table, fxPackage$DUR); 		// Extend the max duration
									dur -= (ts-(float)db4$fget(table, fxPackage$ADDED))/10.0; 	// Subtract the already elapsed time
									
								}
								
								// Cannibalize removes the old effect and replaces it with the new, adding stacks from the original
								if( flags & PF_CANNIBALIZE ){
									
									stacks += (int)db4$fget(table, fxPackage$STACKS);
									if( stacks > mstacks )
										stacks = mstacks;
									//raiseEvt, name, tag, sender, pix, overwrite, flags, count, dispeller, passive
									// For this rem to work you must assign a new pix
									FX$rem(FALSE, "", "", "", pix, FALSE, 0, 0, "", TRUE);
									pix = 0;
									
								}
								else{
									
									// Schedule a stack add instead
									// stacks, name, tag, sender, pix, runOnRem, flags, count, isDispel, duration, trig
									FX$addStacks(LINK_THIS, stacks, "", 0, "", pix, TRUE, 0, 1, FALSE, dur, flags&PF_TRIGGER_IMMEDIATE);
									jump reloop;	// Continue
								
								}
								
							}
						
						}
						
						// This is a new / instant package
						if( !pix ){
						
							// Make our own loop here because we want to find an EMPTY row
							integer pi = 1; 
							for(; pi <= gotTable$fxStart$length; ++pi ){
								
								string tb = getFxPackageTableByIndex(pi); /* pix is 1-indexed */
								if( db4$fget(tb, fxPackage$STACKS) == "" && db4$fget(tb, fxPackage$DUR) == "" ){
								
									table = tb;
									pix = pi;
									pi = 9000;	// Break
									
								}
								
							}
							
						}
						if( !pix ){
							llOwnerSay("Package storage full! Attempting to add "+mkarr(package));
							return;
						}
												
						// Write package to DB
						// Note: Instant packages are written too to reduce link message size
						db4$freplace(table, fxPackage$STACKS, stacks);
						db4$freplace(table, fxPackage$SENDER, sender);
						string d = (str)dur;
						if( !(int)dur )	// Empty string if not used. It speeds up the search above.
							d = "";
						db4$freplace(table, fxPackage$DUR, d);
						db4$freplace(table, fxPackage$FLAGS, flags);
						db4$freplace(table, fxPackage$NAME, name);
						db4$freplace(table, fxPackage$FXOBJS, l2s(package, PACKAGE_FXOBJS));
						db4$freplace(table, fxPackage$EVTS, l2s(package, PACKAGE_EVTS));
						db4$freplace(table, fxPackage$TAGS, l2s(package, PACKAGE_TAGS));
						db4$freplace(table, fxPackage$MAX_STACKS, mstacks);
						db4$freplace(table, fxPackage$ADDED, ts);
						db4$freplace(table, fxPackage$PROC, "{}");	// Set proc cooldowns to empty
						
						// Schedule a run for an instant effect
						if( (int)dur == 0 ){
						
							send += (list)FXCPARSE$ACTION_RUN + pix;
							onEvt("", INTEVENT_PACKAGE_RAN, (list)name); 
							jump reloop;
							
						}
						
						// Ticking effect
						float tick = llList2Float(package, PACKAGE_TICK);
						
						// Add to tag cache
						TAG_CACHE += llJson2List(l2s(package, PACKAGE_TAGS));
						
						
						// Set Fade timer
						if( dur > 0 )
							multiTimer(["F_"+(str)pix, 0, dur, FALSE]);
						// Set tick if needed
						if( tick > 0 )
							multiTimer(["T_"+(str)pix, 0, tick, TRUE]);

						// Send to fxCompiler
						integer actions = FXCPARSE$ACTION_ADD;
						if( flags&PF_TRIGGER_IMMEDIATE ){
							actions = actions|FXCPARSE$ACTION_RUN;
							onEvt("", INTEVENT_PACKAGE_RAN, (list)name);
						}
						
						send += (list)actions + pix;
						onEvt("", INTEVENT_ONADD, (list)pix);
						onEvt("", INTEVENT_SPELL_ADDED, (list)name); 
						
					}
					
				
				
					if( send )						
						llMessageLinked(LINK_THIS, TASK_FXC_PARSE, mkarr(send), sender);
					
					
				}
			}
			
			
        }
		
		// Remove an effect or add stacks
        if( METHOD == FXMethod$rem || METHOD == FXMethod$addStacks ){
		
			// raiseEvt, name, tag, sender, pix, runOnRem, flags, count, isDispel
            integer rEvent = (integer)method_arg(0); 	// also num_stacks for addStacks
            list names = llJson2List(method_arg(1));				// Name of package
            list tags = llJson2List(method_arg(2));				//
            list senders = llJson2List(method_arg(3));				//
            list pixs = llJson2List(method_arg(4));				//
			integer overwrite = l2i(PARAMS, 5); 				// If this is TRUE it's an overwrite and should not send the rem event
            list flags = llJson2List(l2s(PARAMS, 6));				// 
			integer amount = l2i(PARAMS, 7);			// Max nr to remove
			if( amount<1 )
				amount = -1;					// Set to -1 for all
			str dispeller = l2s(PARAMS, 8);				// Dispel event will be raised with this UUID
			float dur = l2f(PARAMS, 9);
			int trig = l2i(PARAMS, 10);
			
			int nr_affected = 0;
			
			int allowPassive = l2i(PARAMS, 9);	// $rem only
				
			// These are pixes
			// find(list names, list senders, list tags, list pixs, list flags, integer max){
			list find = find(names, senders, tags, pixs, flags, 0, allowPassive); // Fetch all viable
			
			// Jump since we can't have continues
			@delContinue;
			while( find != [] && (amount < 0 || nr_affected < amount)){
			
				integer pix = llList2Integer(find, 0);
				find = llDeleteSubList(find, 0, 0);
				str table = getFxPackageTableByIndex(pix);
								
				// UPDATE STACKS
				if( METHOD == FXMethod$addStacks ){
				
					integer stacks = (int)db4$fget(table, fxPackage$STACKS);			// Current stacks
					string pSender = db4$fget(table, fxPackage$SENDER);
					stacks += rEvent; 							// rEvent is num stacks to add or subtract in addStacks
					
					if( stacks <= 0 ){								// No stacks left, schedule a remove
					
						FX$rem(TRUE, "", 0, "", pix, overwrite, 0, -1, "", TRUE);
						jump delContinue;						// Continue
						
					}
					
					if( dur <= 0 )
						dur = (float)db4$fget(table, fxPackage$DUR);
						
					// Update stacks
					// Edit the stacknr
					integer max = (int)db4$fget(table, fxPackage$MAX_STACKS);
					if( stacks > max )
						stacks = max;
						
					// Update the table stacks
					db4$freplace(table, fxPackage$STACKS, stacks);
					
					// If adding stacks we need to reset the timer and duration as well
					if( rEvent >= 0 ){

						db4$freplace(table, fxPackage$ADDED, timeSnap());
						db4$freplace(table, fxPackage$DUR, dur);
						multiTimer(["F_"+(str)pix, "", dur, FALSE]);
						
					}
					
					int task = FXCPARSE$ACTION_STACKS;
					if( trig ){
					
						task = task|FXCPARSE$ACTION_RUN;
						onEvt("", INTEVENT_PACKAGE_RAN, (list)db4$fget(table, fxPackage$NAME));
						
					}
					
					// Send to FXCompiler
					llMessageLinked(LINK_THIS, TASK_FXC_PARSE, mkarr((list)task + pix), pSender);
					
					// If trigger immediate, we still need to run it
					onEvt("", INTEVENT_ONSTACKS, (list)pix + stacks);
					++nr_affected;
					
				}
				
				// DELETE
				else{
				
					// Raise dispel int-event
					if( (key)dispeller ){
						
						int flags = (int)db4$fget(table, fxPackage$FLAGS);
						
						// Undispelable
						if( flags & PF_NO_DISPEL )
							jump delContinue;
						
						onEvt("", INTEVENT_DISPEL, (list)pix + dispeller);
						
					}
					
					// Raise remove int-event if not a remove
					if( rEvent && !overwrite )
						onEvt("", INTEVENT_ONREMOVE, (list)pix);
					
					// Remove from tag cache
					list tags = llJson2List(db4$fget(table, fxPackage$TAGS));
					integer ti;
					for(; ti < count(tags); ++ti ){
					
						int tag = l2i(tags, ti);
						integer pos = llListFindList(TAG_CACHE, (list)tag);
						if( ~pos )
							TAG_CACHE = llDeleteSubList(TAG_CACHE, pos, pos);
						
					}
					// Unset timers
					multiTimer(["F_"+(str)pix]);
					multiTimer(["T_"+(str)pix]);
					
					db4$fdelete(table, fxPackage$DUR);	// Mark it as removed by got FX by removing duration

					// Tell FXCompiler, which does the second part of the db4 deleting.
					if( !overwrite )
						llMessageLinked(LINK_THIS, TASK_FXC_PARSE, mkarr((list)FXCPARSE$ACTION_REM + pix), "");
					++nr_affected;

				}
				
			}
			
			CB_DATA = (list)nr_affected;
			
        }
		
		
		
		// Lets external scripts check if we have tags. This should not be used within the HUD
        if(METHOD == FXMethod$hasTags){
		
			list tags = (list)method_arg(0);
			if( llJsonValueType(method_arg(0), []) == JSON_ARRAY )
				tags = llJson2List(method_arg(0));
				
			integer i; integer c = FALSE;
			for( ; i < count(tags) && !c; ++i){
			
				if( ~llListFindList(TAG_CACHE, (list)l2i(tags, i)) )
					c = TRUE;
				
			}
			CB_DATA = [c];
			
		}
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 

}
