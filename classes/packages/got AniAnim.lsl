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
        if( 
			n == base || // Base always included
			(l2s(expl, 0) == base && count(expl) < 3 && (l2i(expl, -1) || l2s(expl, -1) == "0")) // Must end with a 0 or positive number to be a kit
		)viable += n;
			
    }
    if( !count(viable) )
        return;
        
    // Stop kit
    if( !start ){
        for( i=0; i<count(viable); ++i )
            anim(l2s(viable, i), FALSE, 0,0);
        return;
    }
    
    string anim = randElem(viable);
    anim(anim, FALSE, 0,0);
    anim(anim, TRUE, 0,0);
	#ifdef MaskAnimConf$animStartEvent
	raiseEvent(MaskAnimEvt$onAnimStart, mkarr((list)base+anim));
	#endif
	
    
}

anim( string name, integer start, integer flags, float duration ){
    
	int restart = flags & jasAnimHandler$animFlag$restart;
	//qd(mkarr((list)name + start + flags +duration));
    if( llGetInventoryType(name) == INVENTORY_ANIMATION ){
	
        if( start ){
			if( restart )
				objAnimOff(name);
            objAnimOn(name);
		}
        else
            objAnimOff(name);
			
    }
    
	string ub = name + "_ub";
    if( llGetInventoryType(ub) == INVENTORY_ANIMATION ){
        if( start ){
		
			if( restart )
				objAnimOff(ub);
            objAnimOn(ub);
			
		}
        else
            objAnimOff(ub);
    }
	
	multiTimer(["OFF_"+name]);
	multiTimer(["MOV_"+name]);
	
	if( start && duration > 0 ){
		
		multiTimer(["OFF_"+name, 0, duration, FALSE]); // off timer
		if( flags & jasAnimHandler$animFlag$stopOnMove )
			multiTimer(["MOV_"+name, 0, 1, TRUE]);
	
	}
    
}

timerEvent( string id, string data ){
	
	str start = llGetSubString(id, 0, 3);
	str tail = llGetSubString(id, 4, -1);
	if( start == "OFF_" ){
		anim(tail, FALSE, 0,0);
	}
	if( start == "MOV_" && llVecMag(llGetVel()) > 0.1 )
		anim(tail, FALSE, 0,0);

}

#define toggleIdleAnims( on ) \
	AniAnim$customAnim(LINK_THIS, mkarr(IDLE_ANIMS), on, 0,0, FALSE)


onEvt(string script, integer evt, list data){

	#ifdef MaskAnimConf$remoteloadOnAttachedIni
	if(script == "jas Attached" && evt == evt$SCRIPT_INIT){
	
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
		
	}
	#endif
	
	if( script == "got Portal" && evt == PortalEvt$desc_updated ){
		
		integer i;
		for(; i < count(data); ++i ){
			
			list d = llJson2List(l2s(data, i));
			if( l2s(d, 0) == "IDL" )
				IDLE_ANIMS += llDeleteSubList(d, 0, 0);
		
		}
		
		toggleIdleAnims( TRUE );
		
	}
	
	if( script == "got Status" && evt == StatusEvt$monster_gotTarget && l2s(data, 0) != "" && IDLE_ANIMS != [] ){
		
		toggleIdleAnims( FALSE );
		IDLE_ANIMS = [];
		
	}
	
}


#define FETCHREQ_STRIDE 4
list FETCH_REQS;	// (str)anim, (float)time, (int)flags, (float)dur 

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
	
	timer(){
		multiTimer([]);
	}
	
	changed( integer change ){
		
		if( change & CHANGED_INVENTORY ){
			
			integer i;
			for(; i < count(FETCH_REQS) && count(FETCH_REQS); i += FETCHREQ_STRIDE ){
			
				string anim = l2s(FETCH_REQS, i);
				float time = l2f(FETCH_REQS, i+1);
				
				if( llGetTime()-time < 5 )
					anim(
						anim, 
						TRUE, 
						l2i(FETCH_REQS, i+2), 	// Flags
						l2f(FETCH_REQS, i+3) 	// Duration
					);
				
				FETCH_REQS = llDeleteSubList(FETCH_REQS, i, i+FETCHREQ_STRIDE-1);
				i -= FETCHREQ_STRIDE;
				
			}
		
		}

	}
    
    #include "xobj_core/_LM.lsl"

        if(method$isCallback)return;
        
        if( METHOD == MaskAnimMethod$start ){
            
			string anim = method_arg(0);
            //integer restart = l2i(PARAMS, 1); // Restart is not used by AniAnim. It is legacy from MeshAnim
            animKit(anim, TRUE);
            
        }
        else if(METHOD == MaskAnimMethod$stop)
            animKit(method_arg(0), FALSE);
        
        else if( METHOD == MaskAnimMethod$emulateFrameEvent )
            raiseEvent(MaskAnimEvt$frame, method_arg(0));
			
		else if( METHOD == AniAnimMethod$customAnim ){
		
			
			integer i;
			// Ignore animations that have timed out
			for( ; i < count(FETCH_REQS) && FETCH_REQS != []; i += FETCHREQ_STRIDE ){
			
				if( l2f(FETCH_REQS, i+1)+4 < llGetTime() ){
					
					FETCH_REQS = llDeleteSubList(FETCH_REQS, i, i+FETCHREQ_STRIDE-1);
					i -= FETCHREQ_STRIDE;
					
				}
				
			}
			
			int mFlags = MonsterGet$runtimeFlags();
			int flags = l2i(PARAMS, i+2);
			int start = l2i(PARAMS, i+1);
			float duration = l2f(PARAMS, i+3);
			int humanoidOnly = l2i(PARAMS, i+4);
				
			// Anims can be a JSON array of multiple animations
			list anims = llJson2List(method_arg(0));
			
			if( flags & jasAnimHandler$animFlag$randomize && start )
				anims = (list)randElem(anims);
			
			for( i = 0; i < count(anims); ++i ){
				
				str anim = l2s(anims, i);
				if( !humanoidOnly || mFlags & Monster$RF_HUMANOID ){
				
					integer exists = llGetInventoryType(anim) == INVENTORY_ANIMATION;
					if( exists ){
						
						anim(anim, start>0, flags, duration);
							
					}
					else if( start && llListFindList(FETCH_REQS, (list)anim) == -1 ){
							
						// Request from owner
						FETCH_REQS = FETCH_REQS + anim + llGetTime() + flags + duration;
						AnimHandler$get(llGetOwner(), (list)anim);
						
					}
					
				}
				
			}
			
		}
        
        
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}
