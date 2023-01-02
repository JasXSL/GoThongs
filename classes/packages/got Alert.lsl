#define USE_DB4
#include "got/_core.lsl"

#define TIMER_FADE "a"

list ALERTS;
integer P_ALERT;

integer BFL;
	#define BFL_FADING 0x1	// FADE has started
	

setText(float alpha){
    llSetLinkPrimitiveParamsFast(P_ALERT, [PRIM_TEXT, llDumpList2String(ALERTS, "\n"), <1,.25, .25>, alpha]);
}

timerEvent(string id, string data){
    if(id == TIMER_FADE){
		BFL = BFL|BFL_FADING;
		
        float alpha = (float)data-.025;
        setText(alpha);
        if(alpha <=0){
            ALERTS = [];
            return;
        }
        multiTimer([id, alpha, .05, FALSE]);
    }
}

alert(string text, integer ownerSay, string playSound){
	if(BFL&BFL_FADING)
		ALERTS = [];
		
    key sound = "";
	float vol = 0.25;
	
	key s = playSound;
	if(s)sound = s;
	else if((int)playSound == 1)sound = "09ba0e73-fcf6-ed22-e1a3-7fc600237711";
	else if((int)playSound == 2){
		text = "🏥 "+text;
		sound = "0596c6db-cc3e-e3e3-0f3b-b91e63f4e8b4";
		vol = 1;
		ALERTS = [];
	}
	if(sound)llPlaySound(sound, vol);
    if(ownerSay)llOwnerSay(text);
    ALERTS+=text;
    
	while(
		count(ALERTS)>3 || (
			llStringLength(implode("\n", ALERTS))>254 && 
			count(ALERTS)>1
		)
	){
		ALERTS = llDeleteSubList(ALERTS, 0, 0);
	}
    BFL = BFL&~BFL_FADING;
    setText(1);        
    multiTimer([TIMER_FADE, 1, llStringLength(text)*.05+2, FALSE]);
}

default
{
    state_entry()
    {
        memLim(1.5);
        links_each(nr, name,
            if(name == "ALERT")P_ALERT = nr;
        )
    }
    
    timer(){
        multiTimer([]);
    }
    
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
    
    // Internal means the method was sent from within the linkset
    if(method$internal){
        if(METHOD == AlertMethod$alert){
            string text = method_arg(0);
            integer id = (integer)text;
			if(SENDER_SCRIPT == "got SpellMan")text = llList2String(ASpellMan, id);
            else if(SENDER_SCRIPT == "#ROOT" || SENDER_SCRIPT == "got RootAux")text = llList2String(ARoot, id);
            else if(SENDER_SCRIPT == "got Bridge")text = llList2String(ABridge, id);
            if(text == ""){
				qd("Text missing for "+SENDER_SCRIPT+" : "+(string)id);
                return;
            }
			text = xme(text);
			
			alert(text, (integer)method_arg(1), method_arg(2));
        }
	}
    // Public code can be put here
	if(METHOD == AlertMethod$freetext){
		// Prevent RLV injection
		if(llGetSubString(method_arg(0), 0, 0) == "@")
			return;
		alert(method_arg(0), (integer)method_arg(1), method_arg(2));
	}

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

