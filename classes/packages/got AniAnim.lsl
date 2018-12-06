#define SCRIPT_ALIASES ["jas MaskAnim"]
#ifdef MaskAnimConf$remoteloadOnAttachedIni
    #define USE_EVENTS
#endif
#include "got/_core.lsl"

animKit( string base, integer start ){
    
    list viable = [];
    integer i;
    for(; i<llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
        string n = llGetInventoryName(INVENTORY_ANIMATION, i);
        list expl = explode("_",n);
        if( l2s(expl, 0) == base && count(expl) < 3 )
            viable += n;
    }
    
    if( !count(viable) )
        return;
        
    // Stop kit
    if( !start ){
        for( i=0; i<count(viable); ++i )
            anim(l2s(viable, i), FALSE);
        return;
    }
    
    string anim = randElem(viable);
    anim(anim, FALSE);
    anim(anim, TRUE);
	#ifdef MaskAnimConf$animStartEvent
	raiseEvent(MaskAnimEvt$onAnimStart, base);
	#endif
    
}

anim( string name, integer start ){
    
    if( llGetInventoryType(name) == INVENTORY_ANIMATION ){
        if( start )
            llStartObjectAnimation(name);
        else
            llStopObjectAnimation(name);
    }
    
    name += "_ub";
    if( llGetInventoryType(name) == INVENTORY_ANIMATION ){
        if( start )
            llStartObjectAnimation(name);
        else
            llStopObjectAnimation(name);
    }
	
	
        
    
}

#ifdef MaskAnimConf$remoteloadOnAttachedIni
onEvt(string script, integer evt, list data){
	if(script == "jas Attached" && evt == evt$SCRIPT_INIT){
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
	}
}
#endif

list FETCH_REQS;	// (str)anim, (float)time

default{
    
	#ifdef MaskAnimConf$remoteloadOnRez
	on_rez(integer start){
		llResetScript();
	}
	#endif
	
	
    state_entry(){
        raiseEvent(evt$SCRIPT_INIT, "");
		#ifdef MaskAnimConf$remoteloadOnRez
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
		#endif
    }
	
	changed( integer change ){
		
		if( change & CHANGED_INVENTORY ){
			
			integer i;
			for(; i<count(FETCH_REQS) && count(FETCH_REQS); i+=2 ){
				string anim = l2s(FETCH_REQS, 0);
				float time = l2f(FETCH_REQS, 1);
				
				if( time+5 > llGetTime() )
					llStartObjectAnimation(anim);
				
				FETCH_REQS = llDeleteSubList(FETCH_REQS, i, i+1);
				i -= 2;
			}
		
		}

	}
    
    #include "xobj_core/_LM.lsl"

        if(method$isCallback)return;
        
        if(METHOD == MaskAnimMethod$start){
            
            string anim = method_arg(0);
            integer restart = l2i(PARAMS, 1);
            if( restart )
                animKit(anim, FALSE);
            animKit(anim, TRUE);
            
        }
        else if(METHOD == MaskAnimMethod$stop){ 
            animKit(method_arg(0), FALSE);
        }
        else if( METHOD == MaskAnimMethod$emulateFrameEvent )
            raiseEvent(MaskAnimEvt$frame, method_arg(0));
			
		else if( METHOD == AniAnimMethod$customAnim ){
		
			
			integer i;
			for( i=0; i<count(FETCH_REQS) && FETCH_REQS != []; i+=2 ){
				if( l2f(FETCH_REQS, i+1)+4 < llGetTime() ){
					FETCH_REQS = llDeleteSubList(FETCH_REQS, i, i+1);
					i -= 2;
				}
			}
			
			string anim = method_arg(0);
			integer start = l2i(PARAMS, 1);
			integer exists = llGetInventoryType(anim) == INVENTORY_ANIMATION;
			if( exists ){
				
				llStopObjectAnimation(anim);
				if( start )
					llStartObjectAnimation(anim);
					
			}
			else if( start && llListFindList(FETCH_REQS, (list)anim) == -1 ){
					
				// Request from owner
				FETCH_REQS = FETCH_REQS + anim + llGetTime();
				AnimHandler$get(llGetOwner(), (list)anim);
				
			}
		
		}
        
        
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}
