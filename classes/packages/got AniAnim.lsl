#define USE_DB4
#define SCRIPT_ALIASES ["jas MaskAnim"]
#define USE_EVENTS

list IDLE_ANIMS;

#include "got/_core.lsl"

animKit( string base, integer start ){
    
    list viable = [];
    integer i;
	// This lets you do animName_1 animName_2 etc to pick one at random
    for(; i<llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
        string n = llGetInventoryName(INVENTORY_ANIMATION, i);
        list expl = explode("_",n);
        if( n == base || (l2s(expl, 0) == base && count(expl) < 3 ))
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
	raiseEvent(MaskAnimEvt$onAnimStart, mkarr((list)base+anim));
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

#define toggleIdleAnims( on ) \
	AniAnim$customAnim(LINK_THIS, mkarr(IDLE_ANIMS), on)


onEvt(string script, integer evt, list data){

	#ifdef MaskAnimConf$remoteloadOnAttachedIni
	if(script == "jas Attached" && evt == evt$SCRIPT_INIT){
	
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
		
	}
	#endif
	
	if( script == "got Portal" && evt == PortalEvt$desc_updated ){
		
		list_shift_each(data, block,
			
			list d = llJson2List(block);
			if( l2s(d, 0) == "IDL" )
				IDLE_ANIMS += llDeleteSubList(d, 0, 0);
		
		)
		
		toggleIdleAnims( TRUE );
		
	}
	
	if( script == "got Status" && evt == StatusEvt$monster_gotTarget && l2s(data, 0) != "" && IDLE_ANIMS != [] ){
		
		toggleIdleAnims( FALSE );
		IDLE_ANIMS = [];
		
	}
	
}


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
				
				if( llGetTime()-time < 5 )
					anim(anim, TRUE);
				
				FETCH_REQS = llDeleteSubList(FETCH_REQS, i, i+1);
				i -= 2;
			}
		
		}

	}
    
    #include "xobj_core/_LM.lsl"

        if(method$isCallback)return;
        
        if( METHOD == MaskAnimMethod$start ){
            
			string anim = method_arg(0);
            integer restart = l2i(PARAMS, 1);
			if( restart )
                animKit(anim, FALSE);
            animKit(anim, TRUE);
            
        }
        else if(METHOD == MaskAnimMethod$stop)
            animKit(method_arg(0), FALSE);
        
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
			
			list anims = llJson2List(method_arg(0));
			list_shift_each( anims, anim, 
			
				integer start = l2i(PARAMS, 1);
				integer exists = llGetInventoryType(anim) == INVENTORY_ANIMATION;
				if( exists ){
					
					anim(anim, FALSE);
					if( start )
						anim(anim, TRUE);
						
				}
				else if( start && llListFindList(FETCH_REQS, (list)anim) == -1 ){
						
					// Request from owner
					FETCH_REQS = FETCH_REQS + anim + llGetTime();
					AnimHandler$get(llGetOwner(), (list)anim);
					
				}
				
			)
		}
        
        
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}
