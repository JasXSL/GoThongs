#define SCRIPT_ALIASES ["got Level"]
#define USE_SHARED ["*"]
#define USE_EVENTS
#include "got/_core.lsl"
integer slave;

integer BFL;

#define BFL_LOADING 0x4
#define BFL_INI 0x8


onEvt(string script, integer evt, list data){
	
	if(script == "got Portal" && evt == evt$SCRIPT_INIT){
		LevelLoader$load(FALSE, "");
	}
	
	if( script == "got LevelLoader" && evt == LevelLoaderEvt$levelLoaded ){
	
		finishLoad();
		
	}
}

timerEvent(string id, string data){
	
	if(id == "LOAD_FINISH"){
		finishLoad();
	}

}

finishLoad(){
	
	BFL = BFL&~BFL_LOADING;
	raiseEvent(LevelLiteEvt$loaded, "");
	multiTimer(["LOAD_FINISH"]);

}

default
{
	state_entry(){
		memLim(1.5); 
		raiseEvent(evt$SCRIPT_INIT, "");
	}
	
	timer(){multiTimer([]);}
	
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
	if(method$isCallback){
        return;
    }
	
    if( METHOD == LevelMethod$load && method$byOwner ){
	
        integer debug = (integer)method_arg(0);
		string group = method_arg(1);
        raiseEvent(LevelLiteEvt$load, mkarr(([debug, group])));
		LevelLoader$load(debug, group);
		multiTimer(["LOAD_FINISH", 0, 90, FALSE]);
        return;
		
    }
	
	if( METHOD == LevelMethod$interact )
        raiseEvent(LevelLiteEvt$interact, mkarr((list)llGetOwnerKey(id)+PARAMS)); 
    
    else if( METHOD == LevelMethod$trigger )
        raiseEvent(LevelLiteEvt$trigger, mkarr(([method_arg(0), id, method_arg(1)])));   
    
    else if( METHOD == LevelMethod$idEvent ){
        
		list out = [id, method_arg(1), method_arg(2), method_arg(3)];
        integer evt = (integer)method_arg(0);
        return raiseEvent(evt, mkarr(out));
		
    }
	
	if( METHOD == LevelMethod$playerSceneDone )
		return raiseEvent(LevelEvt$playerSceneDone, mkarr((list)llKey2Name(id) + PARAMS));

	if(METHOD == LevelMethod$playerInteract)
		return raiseEvent(LevelEvt$playerInteract, mkarr((list)llGetOwnerKey(id)+PARAMS) );
	
	if( method$internal && METHOD == LevelMethod$raiseEvent )
		raiseEvent(l2i(PARAMS, 0), mkarr(llDeleteSubList(PARAMS, 0, 0)));
		
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

