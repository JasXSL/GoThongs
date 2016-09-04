/*
	
	Requires the following functions:
	runEffect(integer pid, integer pflags, str pname, arr fxobjs, int timesnap, key sender)
	addEffect(integer pid, integer pflags, str pname, arr fxobjs, int timesnap, (float)duration)
	remEffect(integer pid, integer pflags, str pname, arr fxobjs, int timesnap, bool overwrite)
	
	// Stacks can be acquired through getStacks(PID)
	
	updateGame()
	
*/

//#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#define USE_EVENTS
#include "got/_core.lsl"

list STACKS;                // [id, stacks, flags]
#define STACKSTRIDE 3
integer CACHE_FLAGS;		// 
#define stacksIds() llList2ListStrided(STACKS, 0, -1, STACKSTRIDE)

#define onStackUpdate() //qd(mkarr(STACKS))
// updateGame is now run at the end of the package parser


onEvt(string script, integer evt, string data){
	if(script == "got Status" && evt == StatusEvt$team)
		TEAM = l2i(data, 0);
}

// If absolute it set, it will return nr stacks regardless of PF_NO_STACK_MULTIPLY, used for proper spell icon stack count
integer getStacks(integer pid, integer absolute){
	integer pos = llListFindList(stacksIds(), [pid]);
    if(~pos && (~llList2Integer(STACKS, pos*STACKSTRIDE+2)&PF_NO_STACK_MULTIPLY || absolute)){
		return llList2Integer(STACKS, pos*STACKSTRIDE+1);
	}
	return 1;
}

// Compiles a standard list like [PID, value] and returns a sum of the values multiplying by stacks for PID
float compileList(list input, integer pid_index, integer val_index, integer stride, integer multiply){
    float out = multiply;

    while(llGetListLength(input)){
        float v = llList2Float(input, val_index)*getStacks(llList2Integer(input, pid_index), FALSE);
		if(multiply)out*=v+1;
		else out+= v;
        input = llDeleteSubList(input, 0, stride-1);
    }
    return out;
}

// Adds or removes values from a standard list
list manageList(integer rem, list input, list data){
    integer PID = llList2Integer(data, 0);
    integer stride = llGetListLength(data);

    if(rem){
		integer exists = llListFindList(llList2ListStrided(input, 0, -1, stride), [PID]);
        input = llDeleteSubList(input, exists*stride, exists*stride+stride-1);
	}
    else
        input+=data;
    
    return input;
}

default 
{
	#ifdef IS_NPC
	state_entry(){
		if(llGetStartParameter())
			raiseEvent(evt$SCRIPT_INIT, "");
	}
	#endif
	
	link_message(integer link, integer nr, string s, key id){
		if(nr == RESET_ALL)llResetScript();
		if(nr != TASK_FXC_PARSE)return;
				
		
		list input = llJson2List(s);
		if(input == [])return;
		while(input){
			integer action = l2i(input,0); 
			integer PID = l2i(input,1); 
			integer stacks = l2i(input, 2); 
			integer pflags = l2i(input,3); 
			string pname = l2s(input, 4); 
			string fx_objs = l2s(input, 5); 
			integer timesnap = l2i(input, 6);
			string additional = l2s(input, 7); 
			input = llDeleteSubList(input, 0, FXCPARSE$STRIDE-1); 
			
			if(action&FXCPARSE$ACTION_RUN) 
				runEffect(PID, pflags, pname, fx_objs, timesnap, id); 
			
			if(action&FXCPARSE$ACTION_ADD){ 
				integer s = stacks; 
				if(stacks<1)stacks=1; 
				STACKS += [PID, stacks, pflags]; 
				addEffect(PID, pflags, pname, fx_objs, timesnap, i2f((int)additional)); 
				onStackUpdate(); 
			} 
			if(action&FXCPARSE$ACTION_REM){ 
				remEffect(PID, pflags, pname, fx_objs, timesnap, (int)additional); 
				integer sp = llListFindList(stacksIds(), [PID]); 
				if(~sp){ 
					STACKS = llDeleteSubList(STACKS, sp*STACKSTRIDE, sp*STACKSTRIDE+STACKSTRIDE-1); 
					onStackUpdate(); 
				} 
			} 
			if(action&FXCPARSE$ACTION_STACKS){ 
				integer s = stacks; 
				if(s<1)s = 1; 
				integer sp = llListFindList(stacksIds(), [PID]); 
				if(~sp){ 
					STACKS = llListReplaceList(STACKS, [s], sp*STACKSTRIDE+1, sp*STACKSTRIDE+1); 
					Status$stacksChanged(PID, timesnap, (int)(i2f((int)additional)*10), s); 
					onStackUpdate(); 
				} 
			} 
		}
		
		updateGame(); 
	}
	
    // XOBJ default LMs should be able to be bypassed
	/*
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
	
	
	/*
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;}

    

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
	*/
}
