/*
	
	Requires the following functions:
	runEffect(key caster, integer stacks, string package, integer pid
	addEffect(key caster, integer stacks, string package, integer pid)
	remEffect(key caster, integer stacks, string package, integer pid, integer overwrite)
	updateGame()
	
*/

#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

list STACKS;                // [id, stacks]
integer CACHE_FLAGS;		// 

onEvt(string script, integer evt, string data){
    if(script == "got FX"){
        list d = llJson2List(data);
        if(evt == FXEvt$runEffect)
            runEffect(llList2String(d,0), llList2Integer(d,1), llList2String(d,2), llList2Integer(d,3));
        else if(evt == FXEvt$effectAdded){
			// Add to stacks
			STACKS += [llList2Integer(d,1), llList2Integer(d,3)];
            addEffect(llList2String(d,0), llList2Integer(d,1), llList2String(d,2), llList2Integer(d,3), llList2Integer(d,4));
        }
		else if(evt == FXEvt$effectRemoved){
            remEffect(llList2String(d,0), llList2Integer(d,1), llList2String(d,2), llList2Integer(d,3), llList2Integer(d,4));
			// Remove from stacks
			integer sp = llListFindList(stacksIds(), [llList2Integer(d, 3)]);
			if(~sp)STACKS = llDeleteSubList(STACKS, sp*2, sp*2+1);
		}
        else if(evt == FXEvt$effectStacksChanged){
			integer PID = llList2Integer(d,3);
			integer stacks = llList2Integer(d,1);
            integer sp = llListFindList(stacksIds(), [PID]);
			if(~sp)STACKS = llListReplaceList(STACKS, [stacks], sp*2+1, sp*2+1);
			integer time = llList2Integer(d,4);
			Status$stacksChanged(PID, time, (int)((float)j(llList2String(d,2),0)*10), stacks);
			
			updateGame();
        }
    }
}



// Compiles a standard list like [PID, value] and returns a sum of the values multiplying by stacks for PID
float compileList(list input, integer pid_index, integer val_index, integer stride){
    float out = 0;
    while(llGetListLength(input)){
        integer stacks = 1;
        integer pos = llListFindList(stacksIds(), [llList2Integer(input, pid_index)]);
        if(~pos)stacks = llList2Integer(STACKS, pos*2+1);
        out+= llList2Float(input, val_index)*stacks;
        input = llDeleteSubList(input, 0, stride-1);
    }
    return out;
}

// Adds or removes values from a standard list
list manageList(integer rem, list input, list data){
    integer PID = llList2Integer(data, 0);
    integer stride = llGetListLength(data);
    integer exists = llListFindList(llList2ListStrided(input, 0, -1, stride), [PID]);
    if(rem && ~exists)
        input = llDeleteSubList(input, exists*stride, exists*stride+stride-1);
    else if(!rem && exists == -1)
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
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }

    

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
