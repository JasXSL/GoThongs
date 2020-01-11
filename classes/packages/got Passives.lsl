#define USE_EVENTS

#include "got/_core.lsl"

integer BFL;
#define BFL_SENT 0x1				// Recently sent
#define BFL_QUEUE_SEND 0x2			// Update on send cooldown finish

integer EVT_INDEX;		// Used to give events a unique ID
// Events we are listening to
// Len is total number of entries after len
list EVT_CACHE;			// (str)scriptName, (int)evt, (arr)evt_listener_IDs
#define CACHESTRIDE 3
// Stores the event listeners
list EVT_LISTENERS;		// (int)id, (arr)targs, (int)max_targs, (float)proc_chance, (float)cooldown, (int)flags, (arr)wrapper
#define EVTSTRIDE 7

integer CACHE_FLAGS;

list PASSIVES;
// Nr elements before the attributes
#define PASSIVES_PRESTRIDE 4
// (str)name, (arr)evt_listener_ids, (int)length, (int)flags, (int)attributeID, (float)attributeVal
list ATTACHMENTS; 			// [(str)passive, (arr)attachments]
list CACHE_ATTACHMENTS;		// Contains names of attachments

float CPC = 1;				// Chance proc chance multiplier passive

#define COMPILATION_STRIDE 2
list compiled_passives;     // Compiled passives [id, val, id2, val2...]
// This should correlate to the FXCUpd$ index
list compiled_actives = [
	0,	// 00 Flags - Int
	1,	// 01 Mana regen - Multi | i2f
	1,	// 02 Damge done - Multi | i2f
	1,	// 03 Damage taken - Multi | i2f
	1,	// 04 Dodge - Add | i2f
	1,	// 05 Casttime - Multi | i2f
	1,	// 06 Cooldown - Multi | i2f
	1,	// 07 Mana cost - Multi | i2f
	1,	// 08 Crit - Add | i2f
	1,	// 09 Pain - Multi | i2f
	1,	// 10 Arousal - Multi | i2f
	0,	// 11 HP add
	1,	// 12 HP multiplier
	0,	// 13 Mana add - int
	1,	// 14 Mana - Multiplier
	0,	// 15 Arousal add - int
	1,	// 16 Arousal - Multiplier
	0,	// 17 Pain add - int
	1,	// 18 Pain - Multiplier
	1,	// 19 HP Regen - Multi
	1,	// 20 Pain regen - Multi
	1,	// 21 Arousal regen - Multi
	0,	// 22 SPell highlights
	1,	// 23 Healing Received
	1,	// 24 Movespeed (NPC)
	1,	// 25 Healing done
	-1, // 26 Team
	1,	// 27 Befuddle
	"[]",  // 28 (arr)Conversion
	1,	// 29 Sprint fade multiplier
	1,	// 30 Backstab multiplier
	1,	// 31 FXCUpd$SWIM_SPEED_MULTI
	0,	// 32 FXCUpd$FOV
	1,	// 33 FXCUpd$PROC_BEN
	1	// 34 FXCUpd$PROC_DET
];      // Compiled actives defaults

/*
    Converts a name into a position
*/
integer findPassiveByName(string name){
    integer i;
    while(i<llGetListLength(PASSIVES)){
        if(llList2String(PASSIVES, i) == name)
            return i;
        i+=llList2Integer(PASSIVES, i+2)+PASSIVES_PRESTRIDE;
    }
    return -1;
}

// Macro this out
/*
outputDebug(string task){
	qd(task);
	qd("PASSIVES: "+mkarr(PASSIVES));
	qd("CACHE: "+mkarr(EVT_CACHE));
	qd("BINDS: "+mkarr(EVT_LISTENERS));
}
*/
#define outputDebug(task)

/*
    Removes a passive by name
*/
// Needs to remove procs and cache
integer removePassiveByName(string name){

    integer pos = findPassiveByName(name);
    if( pos == -1 )
		return false;
	
	// Remove event bindings
	list binds = llJson2List(l2s(PASSIVES, pos+1)); // Event bindings to remove
	
	list_shift_each(binds, id,
	
		integer n = (int)id;
		integer i;
		
		// Remove from storage
		// The ID will only occur once in this array
		for( ; i<count(EVT_LISTENERS) && count(EVT_LISTENERS); i+=EVTSTRIDE ){
		
			if( l2i(EVT_LISTENERS, i) == n ){
			
				EVT_LISTENERS = subarrDel(EVT_LISTENERS, i, EVTSTRIDE);
				i -= EVTSTRIDE;
				
			}
			
		}
		
		// Remove from index
		for(i=0; i<count(EVT_CACHE) && EVT_CACHE != []; i+=CACHESTRIDE){
		
			list p = llJson2List(l2s(EVT_CACHE, i+2));
			integer ps = llListFindList(p, [n]);
			if(~ps){
			
				p = llDeleteSubList(p, ps, ps);
				// There are still events bound to this
				if(p)
					EVT_CACHE = llListReplaceList(EVT_CACHE, [mkarr(p)], i+2, i+2);
				else{
					// There are no more events bound to this
					EVT_CACHE = subarrDel(EVT_CACHE, i, CACHESTRIDE);
					i-= CACHESTRIDE;
				}
				
			}
			
		}
		
	)
	
	// Remove attachments
	integer i;
	for(; i<count(ATTACHMENTS) && ATTACHMENTS != []; i+= 2){
		if(l2s(ATTACHMENTS, i) == name){
			ATTACHMENTS = llDeleteSubList(ATTACHMENTS, i, i+1);
			i-= 2;
		}
	}
	
	
	
	integer ln = llList2Integer(PASSIVES, pos+2);
	PASSIVES = subarrDel(PASSIVES, pos, ln+PASSIVES_PRESTRIDE);
	
	outputDebug("REM");
	
	return TRUE;

}

compilePassives(){

	// Values that should be added instead of multiplied
    list non_multi = FXCUpd$non_multi;
	list arrays = FXCUpd$arrays;
	
    list keys = [];         // Stores the attribute IDs
    list vals = [];         // Stores the attribute values
    integer i;
	
	int set_flags;
	int unset_flags;
	
		
	@continueCompilePassives;
    while( i < llGetListLength(PASSIVES) ){
	
        // Get the effects
		integer n = l2i(PASSIVES, i+2);
        list block = subarr(PASSIVES, i+PASSIVES_PRESTRIDE, n);
        i+=n+PASSIVES_PRESTRIDE;
        
		// No data. Not sure why.
		if( !n )
			jump continueCompilePassives;
		
		// Key value pairs of passives
        integer x;
        for( ; x<llGetListLength(block); x+=2 ){
		
            integer id = llList2Integer(block, x);
            float val = llList2Float(block, x+1);
            
			integer add = (~llListFindList(non_multi, [id])); // Check if we should add or multiply
			integer array = (~llListFindList(arrays, [id]));

            integer pos = llListFindList(keys, [id]);
            // The key already exists, add!
            if( ~pos ){
			
				float n = llList2Float(vals, pos);
				if( array ){
				
					vals = llListReplaceList(vals, [mkarr(
						llJson2List(l2s(block, x+1))+llJson2List(l2s(vals, pos))
					)], pos, pos);
					
				}
				else{
				
					if( id == FXCUpd$UNSET_FLAGS )
						unset_flags = unset_flags|(int)val;
					else if( id == FXCUpd$FLAGS )
						set_flags = set_flags|(int)val;
					else if( add )
						n += val;
					else
						n *= (1+val);
					
					
					vals = llListReplaceList(vals, [n], pos, pos);
					
				}
				
			}
            else{
			
				keys += id;
				// Type is an array, merge
				if(array)
					vals+= [mkarr(llJson2List(l2s(block, x+1)))];
					
				else{
					if(!add)val+=1;	// If something is a multiplier it should always start at 1
					vals += val;
				}
				
            }
        }
    }
	
    // These need to match compilation stride
    compiled_passives = [
		FXCUpd$FLAGS, set_flags&~unset_flags
	];
    for( i=0; i<llGetListLength(keys); ++i ){
	
        list v = llList2List(vals, i, i);
        // Flatten to integer if it doesn't have fractions
		if( 
			llGetListEntryType(v, 0) != TYPE_STRING && 
			llList2Float(v,0) == (float)llList2Integer(v,0) 
		)v = [llList2Integer(v,0)];
		
        compiled_passives+= [llList2Integer(keys, i)]+v;
		
    }
    
    output();
}


output(){

	if( BFL& BFL_SENT ){
	
		BFL = BFL|BFL_QUEUE_SEND; // Update once queue ends
		return;
		
	}
	BFL = BFL|BFL_SENT;
	ptSet("Q",.5,FALSE);
	
    // Output the same event as FXCEvt$update
    list output = compiled_actives;
	   
    integer set_flags = llList2Integer(output, FXCUpd$FLAGS);
	integer unset_flags;
	
    // Fields that should be treated as ints for shortening
    list INT_FIELDS = (list)
        FXCUpd$HP_ADD +
        FXCUpd$MANA_ADD +
        FXCUpd$AROUSAL_ADD +
        FXCUpd$PAIN_ADD +
		FXCUpd$SPELL_HIGHLIGHTS +
		FXCUpd$TEAM
    ;
    list non_multi = FXCUpd$non_multi; // Things that should be ADDed
	list arrays = FXCUpd$arrays;
	list overwrite = FXCUpd$overwrite;
	
    integer i;
    for( ; i<count(compiled_passives); i+=COMPILATION_STRIDE ){
	
		integer type = llList2Integer(compiled_passives, i);
        
        // Cache the flags first so unset_flags can properly override
        if( type == FXCUpd$FLAGS )
            set_flags = set_flags|llList2Integer(compiled_passives,i+1);
		// Update the unset_flags
        else if( type == FXCUpd$UNSET_FLAGS )
            unset_flags = unset_flags|llList2Integer(compiled_passives,i+1);			
		// Data in this is an array, we merge them
        else if( ~llListFindList(arrays, (list)type) )
			output = llListReplaceList(output, [mkarr(llJson2List(l2s(compiled_passives, i+1))+llJson2List(l2s(output,type)))], type, type);
		// do actual math
		else if( ~llListFindList(overwrite, (list)type) ){
		
			if( l2f(compiled_passives, i+1) != 0 )
				output = llListReplaceList(output, llList2List(compiled_passives, i+1, i+1), type, type);
				
		}	
		else{
		
			float val = llList2Float(compiled_passives, i+1)*llList2Float(output,type);
			
			if( ~llListFindList(non_multi, (list)type) )
				val = llList2Float(compiled_passives, i+1)+llList2Float(output,type);
            output = llListReplaceList(output, (list)val, type, type);
			
        }
		
    }

	// Shorten
	for( i=0; i<count(output); ++i ){
	
		if( llGetListEntryType(output, i) != TYPE_STRING ){
		
			float val = llList2Float(output, i);
			list v = [(int)val];
			if( !(~llListFindList(INT_FIELDS, (list)i)) )
				v = [f2i(val)];	
			
			output = llListReplaceList(output, v, i, i);
			
		}
		
	}
	
	// Scan attachments
	list att = []; 	// Contains all names
	list add = [];	// New names
	for(i=0; i<count(ATTACHMENTS); i+= 2){
		list a = llJson2List(l2s(ATTACHMENTS, i+1));
		list_shift_each(a, val,
			if(llListFindList(att, [val]) == -1){
				att+= val;
				if(llListFindList(CACHE_ATTACHMENTS, [val]) == -1)
					add += val;
			}
		)
	}
	// Find attachments to remove
	list rem;
	for(i=0; i<count(CACHE_ATTACHMENTS); ++i){
		// Attachment no longer found
		if(llListFindList(att, llList2List(CACHE_ATTACHMENTS, i, i)) == -1){
			rem += l2s(CACHE_ATTACHMENTS, i);
		}
	}
	CACHE_ATTACHMENTS = att;
	if(add)
		Rape$addFXAttachments(add);
	if(rem)
		Rape$remFXAttachments(rem);
	
    set_flags = set_flags&~unset_flags;
	
    output = llListReplaceList(output, [set_flags], FXCUpd$FLAGS, FXCUpd$FLAGS);
	CACHE_FLAGS = set_flags;
	
	CPC = i2f(l2i(output, FXCUpd$PROC_BEN));
	llMessageLinked(LINK_SET, TASK_FX, mkarr(output), "");
}


onEvt(string script, integer evt, list data){
    
    if(script == "got Bridge" && evt == BridgeEvt$userDataChanged){
        data = llJson2List(l2s(data, BSUD$WDATA));
		data = llJson2List(l2s(data, 2));
		Passives$set(LINK_THIS, "_WEAPON_", data, 0);				
		return;
    }
	
	// Remove passives that should be removed on cleanup
	else if(script == "got RootAux" && evt == RootAuxEvt$cleanup){
		integer i;
		@restartWipe;
		while(i<llGetListLength(PASSIVES)){
			// Get the effects
			string name = l2s(PASSIVES, i);
			integer n = l2i(PASSIVES, i+2);
			integer flags = l2i(PASSIVES, i+3);
			i+=n+PASSIVES_PRESTRIDE;
			
			if(flags&Passives$FLAG_REM_ON_CLEANUP){
				removePassiveByName(name);
				jump restartWipe;
			}
		}
		output();
		return;
	}
    
	// Procs here
	integer i;
	
	integer pos = llListFindList(EVT_CACHE, [script]);	// works because it is the only non-json string, and script names can't contain [
	if( pos == -1 )
		return;

	list ids = llJson2List(l2s(EVT_CACHE, pos+2));
	
	// Cycle events		
	integer x;
	for(; x<count(EVT_LISTENERS); x+= EVTSTRIDE){
	
		integer evtid = l2i(EVT_LISTENERS, x);
		// This event is in the index, this should never happen
		/*
		if( llListFindList(ids, [evtid]) == -1 )
			jump evtBreak; // Go to next event by jumping to the end of this for loop
		*/
		
		list targs = llJson2List(l2s(EVT_LISTENERS, x+1));
		integer max_targs = l2i(EVT_LISTENERS, x+2);
		float proc_chance = l2f(EVT_LISTENERS, x+3)*CPC;
		float cooldown = l2f(EVT_LISTENERS, x+4);
		integer flags = l2i(EVT_LISTENERS, x+5);
		
		list targsOut;
		string wrapper;
		float range;
		
		float proc = llFrand(1);

		// Check prerequisites first
		if(
			flags&Passives$PF_ON_COOLDOWN || 	// on cooldown
			proc>proc_chance || 				// random chance fail
			(CACHE_FLAGS&fx$NO_PROCS && ~flags&Passives$PF_OVERRIDE_PROC_BLOCK) // Procs are blocked right now
		)jump evtBreak; // Go to next event

		// Scan the next target
		@targNext;
		
		
		
		// Scan for all valid targets
		list_shift_each(targs, val,
		
			list t = llJson2List(val);						
			integer y;	// Iterator

			// This target should be checked against this event
			if( l2s(t, 1) != script || l2i(t, 2) != evt )
				jump targNext;
		
			// JSON array of parameters set in the proc
			list against = llJson2List(l2s(t,3));
			
			// Iterate over parameters and make sure they validate with the event params we received
			for( y = 0; y<llGetListLength(against); ++y ){
			
				// Event data from package event
				list acceptable = explode("||", llList2String(against, y));
				// Event data from event
				string var = llList2String(data, y);
				
				// EVAL the proc:
				
				// If the event condition at index is unset, or the var is literally the same, it is accepted
				// We only need to do deep inspection if the values are set and different to the event's
				if( l2s(acceptable,0) == "" || ~llListFindList(acceptable, [var]) )
					jump matchSuccess;	// continue
				
				
				// Check math
				list_shift_each(acceptable, v,
						
					string s = llGetSubString(v, 0, 0);
					float comp = (float)trim(llGetSubString(v, 1,-1));
					float c = (float)var;
					
					if( 
						(s == "<" && c < comp) ||			// Success if less than
						(s == ">" && c > comp) ||			// Success if greater than
						(s == "&" && (int)c&(int)comp) ||	// Success if bitwise is set
						(s == "~" && ~(int)c&(int)comp)		// Success if bitwise is not set
					)jump matchSuccess;						// Continue

				)

				// Nothing validated, the event is not applicable for this target
				jump targNext;
				
				
				@matchSuccess;
				
			}
			
			@acceptEvt;
			// SUCCESS, send to this target!
			
			
			// Set cooldown if needed
			if( ~flags&Passives$PF_ON_COOLDOWN && cooldown>0 ){
			
				EVT_LISTENERS = llListReplaceList(EVT_LISTENERS, [flags|Passives$PF_ON_COOLDOWN], x+5, x+5);
				flags = flags|Passives$PF_ON_COOLDOWN;
				ptSet("CD_"+(str)evtid, cooldown, FALSE);
				
			}
					
			// We have validated that this event should be accepted, let's extract the wrapper if it hasn't already been extracted for this event
			if( wrapper == "" ){
				
				wrapper = llList2String(EVT_LISTENERS, x+6);
				// We can use <index> and <-index> tags to replace with data from the event
				for( y=0; y<llGetListLength(data); ++y ){
				
					wrapper = implode((str)(-llList2Float(data, y)), explode("<-"+(str)y+">", wrapper));
					wrapper = implode(llList2String(data, y), explode("<"+(str)y+">", wrapper));
					
				}
				
				range = l2f(t, 4);
				
			}

			
			// Find the targets
			integer targFlag = l2i(t, 0);
			if( targFlag < 0 && llAbs(targFlag) & llAbs(Passives$TARG_SELF) )
				targsOut += SpellMan$CASTER;

			if( targFlag < 0 && llAbs(targFlag) & llAbs(Passives$TARG_AOE) )
				targsOut = (list)"AOE";
				//FX$aoe(max_targs/10., llGetKey(), wrapper, TEAM_PC);
			//}
			
			// Use target from event
			if( targFlag > -1 ){
				
				string t = l2s(data, targFlag);
				
				// Target is a link, so it is us
				if( strlen(t) != 36 )
					t = llGetKey();

				if( llVecDist(llGetRootPosition(), prPos(t))< range || range <= 0 )
					targsOut += (list)t;
			
			}

			// If we have sent to max targs, leave this event and go to the next
			if(max_targs > 0){
				--max_targs;
				if(max_targs)
					jump evtBreak;
			}
		)
		
		// Send and continue to the next bound event
		@evtBreak;
		
		if( count(targsOut) )
			SpellAux$tunnel( wrapper, targsOut, range, 0 );
		
	}


}



// Add or remove a proc



ptEvt(string id){

	// Send queue
	if( id == "Q" ){
	
		BFL = BFL&~BFL_SENT;
		if( BFL&BFL_QUEUE_SEND ){
		
			BFL = BFL&~BFL_QUEUE_SEND;
			output();
			
		}
		
	}
	
	else if(llGetSubString(id, 0,2) == "CD_"){
	
		integer n = (int)llGetSubString(id, 3, -1);
		// Take this one off CD
		integer i;
		for( ; i<llGetListLength(EVT_LISTENERS); i+=EVTSTRIDE ){
		
			if( l2i(EVT_LISTENERS, i) == n ){
			
				EVT_LISTENERS = llListReplaceList(EVT_LISTENERS, [l2i(EVT_LISTENERS, i+5)&~Passives$PF_ON_COOLDOWN], i+5, i+5);
				return;
				
			}
			
		}
		
	}
	
}


default{

    timer(){
	
		ptRefresh();
		
    }
    
	// Handle active effects
	#define LM_PRE \
	if(nr == TASK_PASSIVES_SET_ACTIVES){ \
		list set = llJson2List(s); \
        compiled_actives = [ \
			l2i(set, FXCUpd$FLAGS),			\
			i2f(l2f(set, FXCUpd$MANA_REGEN)),		\
			i2f(l2f(set, FXCUpd$DAMAGE_DONE)),		\
			i2f(l2f(set, 3)),		\
			i2f(l2f(set, 4)),		\
			i2f(l2f(set, 5)),		\
			i2f(l2f(set, 6)),		\
			i2f(l2f(set, 7)),		\
			i2f(l2f(set, 8)),		\
			i2f(l2f(set, 9)),		\
			i2f(l2f(set, 10)),		\
			\
			i2f(l2f(set, 11)),		\
			i2f(l2f(set, FXCUpd$HP_MULTIPLIER)),			\
			l2i(set, 13),			\
			i2f(l2f(set, FXCUpd$MANA_MULTIPLIER)),			\
			l2i(set, 15),			\
			l2f(set, 16),			\
			l2i(set, 17),			\
			l2f(set, 18),			\
			\
			l2f(set, 19),			\
			l2f(set, 20),			\
			l2f(set, 21),			\
			l2i(set, 22),			\
			i2f(l2f(set, 23)),		\
			l2f(set, 24),			\
			i2f(l2f(set, 25)),		\
			l2i(set, 26), 			\
			i2f(l2f(set,27)),		\
			l2s(set,28),				\
			i2f(l2i(set,FXCUpd$SPRINT_FADE_MULTI)),		\
			i2f(l2i(set,FXCUpd$BACKSTAB_MULTI)), \
			i2f(l2i(set,FXCUpd$SWIM_SPEED_MULTI)), \
			i2f(l2i(set,FXCUpd$FOV)), \
			i2f(l2i(set,FXCUpd$PROC_BEN)), \
			i2f(l2i(set,FXCUpd$PROC_DET)) \
		]; \
        output(); \
	}
	/*
		compiled_actives = [ \
			l2i(set, 0),			// Flags
			i2f(l2f(set, 1)),		// mana regen multi
			i2f(l2f(set, 2)),		// Damage done multi
			i2f(l2f(set, 3)),		// Damage taken multi
			i2f(l2f(set, 4)),		// Dodge add
			i2f(l2f(set, 5)),		// casttime multiplier
			i2f(l2f(set, 6)),		// Cooldown multiplier
			i2f(l2f(set, 7)),		// Manacost multiplier
			i2f(l2f(set, 8)),		// crit add
			i2f(l2f(set, 9)),		// Pain multiplier
			i2f(l2f(set, 10)),		// Arousal multiplier
			
			l2i(set, 11),			// HP add
			l2f(set, 12),			// HP Multi
			l2i(set, 13),			// Mana Add
			l2f(set, 14),			// Mana Multi
			l2i(set, 15),			// Arousal add
			l2f(set, 16),			// Arousal multi
			l2i(set, 17),			// Pain add
			l2f(set, 18),			// Pain multi
			
			l2f(set, 19),			// HP regen = 1
			l2f(set, 20),			// Pain regen = 1
			l2f(set, 21),			// Arousal regen = 1
			l2i(set, 22)			// Highlights
			l2f(set, 23)			// Healing received mod
			24						// Movespeed = 1
			25						// Healing done mod
			26						// Team = -1
			27						// Befuddle = 1
			28,						// Conversions = []
			29,						// Sprint fade = 1
			30,						// Backstab multi = 1
			31,						// Swim speed multi = 1
		]; \
	*/
	
    #include "xobj_core/_LM.lsl" 
    if(method$isCallback){
        return;
    }
    
    
    /*
        Adds a passive
    */
    if(METHOD == PassivesMethod$set){
	
        string name = method_arg(0);
		integer flags = l2i(PARAMS, 2);
		
        list effects = llJson2List(method_arg(1));
        if( effects == [] )
			return Passives$rem(LINK_THIS, name);
        // Find if passive exists and remove it
        removePassiveByName(name);
        
		
        // Go through the index
        if( (llGetListLength(effects)%2) == 1 )
			return llOwnerSay("Error: Passives have an uneven index: "+name);
        
		// IDs of effects added
		list added_effects;
		
		integer i;
		for( ; i<count(effects) && count(effects); i+=2 ){
		
			integer t = l2i(effects, i);
			if( t == FXCUpd$PROC ){
			
				list data = llJson2List(l2s(effects, i+1));
				EVT_INDEX++;
				added_effects+= EVT_INDEX;
				list triggers = llJson2List(l2s(data, 0));
				
				// Add a proc
				@checkTriggers;
				list_shift_each( triggers, val,
				
					list d = llJson2List(val);
					
					string script = l2s(d, 1);
					integer evt = l2i(d, 2);

					integer z;
					for( ; z<count(EVT_CACHE) && EVT_CACHE != []; z+= CACHESTRIDE ){
		
						if( l2s(EVT_CACHE, z) == script && l2i(EVT_CACHE, z+1) == evt ){
		
							// IDs currently bound to this
							list t = llJson2List(l2s(EVT_CACHE, z+2));
							// Check if this ID exists
							integer pos = llListFindList(t, [id]);

							// Add
							if( pos == -1 ){
							
								t+= id;
								EVT_CACHE = llListReplaceList(EVT_CACHE, [mkarr(t)], z+2, z+2);
								
							}
							jump checkTriggers; // return
			
						}
		
					}
	
					// We have looped through entirely. If we haven't yet found an exisiting event to add to, do so now
					EVT_CACHE += ([script, evt, mkarr([id])]);
					
				)

				EVT_LISTENERS += [
					EVT_INDEX,
					l2s(data, 0),	// Triggers
					l2i(data, 1),	// Max targs
					l2f(data, 2),	// Proc chance
					l2f(data, 3),	// cooldown
					l2i(data, 4),	// flags,
					l2s(data, 5)	// wrapper
				];

				
				effects = llDeleteSubList(effects, i, i+1);
				i-=2;
				
			}
			else if( t == FXCUpd$ATTACH )
				ATTACHMENTS += [name, l2s(effects, i+1)];
			
		}
		
		PASSIVES += (list)name + mkarr(added_effects) + llGetListLength(effects) + flags + effects;
		outputDebug("ADD");
		compilePassives();
		
    }
    
    
    /*
        Removes a passive
    */
    else if( METHOD == PassivesMethod$rem ){
	
        string name = method_arg(0);
        if( removePassiveByName(name) )
			compilePassives();
			
    }
    
    /*
        Returns a list of passive names
    */
    else if(METHOD == PassivesMethod$get){
        
        integer i;
        while(i<llGetListLength(PASSIVES)){
            CB_DATA += [llList2String(PASSIVES, i)];
            i+=llList2Integer(PASSIVES, i+2)+PASSIVES_PRESTRIDE;
        }
        
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
