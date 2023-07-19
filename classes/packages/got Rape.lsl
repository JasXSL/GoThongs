#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

#define TIMER_BREAKFREE "a"

integer BFL;
#define BFL_RAPE_STARTED 1
#define BFL_INIT 0x2
#define BFL_CD 0x4

list RAPE_ANIMS;
list RAPE_ATTACHMENTS;
list RAPE_REZZED;

// llListFindList for name works in this because it's the only string type
#define FXASTRIDE 4
list FX_ATTACHMENTS;		// [(str)name, (key)id, (int)nr_attachments, (int)flags]
bool REM_CLASS_ATTACH; 		// Do not attach things with the fx$ATTACH_CLASSATT flag

updateFxAttachments(){

	if( ~BFL&BFL_INIT || BFL&BFL_CD )
		return;
	
	integer sets;
	integer i;
	for( ; i < count(FX_ATTACHMENTS); i += FXASTRIDE ){
		
		int flags = l2i(FX_ATTACHMENTS, i+3);
		
		if( 
			(~flags & fx$ATTACH_CLASSATT || !REM_CLASS_ATTACH) && 
			llKey2Name(llList2Key(FX_ATTACHMENTS, i+1)) == "" && 
			llGetInventoryType(l2s(FX_ATTACHMENTS, i)) == INVENTORY_OBJECT 
		){
			++sets;
			_portal_spawn_std(l2s(FX_ATTACHMENTS, i), llGetRootPosition()-<0,0,3>, ZERO_ROTATION, <0,0,-3>, FALSE, FALSE, FALSE);
		}
		
	}
	
	if( sets ){
		
		BFL = BFL|BFL_CD;
		multiTimer(["CD", 0, 10, FALSE]);
	
	}
	
}

timerEvent(string id, string data){

	if( id == "CD" ){
		
		BFL = BFL&~BFL_CD;
		updateFxAttachments();
		
	}
	if( id == "ATC" )
		updateFxAttachments();
		
}


list TEMPLATES;

onEvt(string script, integer evt, list data){

	if( script == "got Bridge" && evt == BridgeEvt$thong_initialized ){
	
		BFL = BFL|BFL_INIT;
		updateFxAttachments();
		
	}
	
}


onFxChanged( list chTypes ){
	
	if( llListFindList(chTypes, (list)fx$SET_FLAG) == -1 )
		return;
	
	int rem = (int)fx$getDurEffect(fxf$SET_FLAG) & fx$F_NO_CLASS_ATTACH;
	if( rem != REM_CLASS_ATTACH ){
		
		REM_CLASS_ATTACH = rem;
		
		// Remove. Add is automatic,
		if( rem ){
		
			int i;
			for(; i < count(FX_ATTACHMENTS); i += FXASTRIDE ){
			
				int f = l2i(FX_ATTACHMENTS, i+3);
				if( f & fx$ATTACH_CLASSATT )
					Attached$removeTarg(l2k(FX_ATTACHMENTS, i+1)); 
					
			}
		
		}
		
		
	}
	

}

default {
	
	on_rez( integer bap ){
		BFL = BFL&~BFL_INIT;
	}

    // Timer event
    //timer(){multiTimer([]);}
    state_entry(){
	
		multiTimer(["ATC", "", 5, TRUE]);
		llListen(jasAttached$INI_CHAN, "", "", "INI");
		
	}
	
	timer(){multiTimer([]);}
	
	listen( integer chan, string name, key id, string message ){
		idOwnerCheck
	
		integer pos = llListFindList(FX_ATTACHMENTS, (list)name);
		if( ~pos )
			FX_ATTACHMENTS = llListReplaceList(FX_ATTACHMENTS, [id], pos+1, pos+1);
		
	}
	
	#define LM_PRE \
		if( nr == TASK_FX ){ onFxChanged(llJson2List(s)); }
	
	
    
    // This is the standard linkmessages
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
    
    if(method$internal){
	
        if( METHOD == RapeMethod$start && count(PARAMS) > 1 ){
		

            if( BFL&BFL_RAPE_STARTED || ~hud$status$flags()&StatusFlag$dead )
				return;
            
            BFL = BFL|BFL_RAPE_STARTED;
            
            RAPE_ANIMS = llJson2List(method_arg(0));
            RAPE_ATTACHMENTS = llJson2List(method_arg(1));
            RAPE_REZZED = llJson2List(method_arg(2));
			//list sounds = llJson2List(method_arg(2));
			
			vector pos = llGetRootPosition();
            vector ascale = llGetAgentSize(llGetOwner());
            
            integer i;
            for( ; i<llGetListLength(RAPE_ATTACHMENTS); i++ )
                llRezAtRoot(llList2String(RAPE_ATTACHMENTS, i), pos-<0,0,2>, ZERO_VECTOR, ZERO_ROTATION, 1);
            
            for( i=0; i<llGetListLength(RAPE_ANIMS); i++ )
                AnimHandler$anim(llList2String(RAPE_ANIMS, i), TRUE, 0, 0, 0);
				
			for( i=0; i<llGetListLength(RAPE_REZZED); i++ )
				_portal_spawn_std( 
					llList2String(RAPE_REZZED, i), 
					pos-<0,0,ascale.z/2>, 
					ZERO_ROTATION, 
					ZERO_VECTOR, 
					FALSE, 
					FALSE, 
					TRUE
				);
            
            
            list ray = llCastRay(pos, pos-<0,0,5>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
            if(llList2Integer(ray,-1) == 1)
                pos = llList2Vector(ray, 1)+<0,0,ascale.z/2-.1>;
            
            
            rotation rot = llGetRootRotation();
            vector vrot = llRot2Euler(rot);
            vrot = <0,0,vrot.z>;
            
			RLV$cubeTask(([
				SupportcubeBuildTask(Supportcube$tSetPos, [pos]),
				SupportcubeBuildTask(Supportcube$tSetRot, [llEuler2Rot(vrot)]),
				SupportcubeBuildTask(Supportcube$tForceSit, [!count(RAPE_REZZED)])
			]));
		
            raiseEvent(RapeEvt$onStart, mkarr(PARAMS));
			
            
        }else if(METHOD == RapeMethod$remInventory){
			list assets = llJson2List(method_arg(0));
			list_shift_each(assets, val,
				if(llGetInventoryType(val) == INVENTORY_OBJECT){
					llRemoveInventory(val);
				}
			)
		}
		
		else if(METHOD == RapeMethod$addFXAttachments){
		
			list add = PARAMS;
			
			integer flags;
			// If last is an integer then that is used as flags
			if( llGetListEntryType(add, -1) == TYPE_INTEGER ){
			
				flags = l2i(add, -1);
				add = llDeleteSubList(add, -1, -1);
				
			}
			
			//qd(mkarr(PARAMS));
			
			integer i;
			for(; i < count(add); ++i ){
			
				string val = l2s(add, i);
				integer pos = llListFindList(FX_ATTACHMENTS, [val]);
				// Add 1 to usage
				if( ~pos ){
					FX_ATTACHMENTS = llListReplaceList(FX_ATTACHMENTS, [l2i(FX_ATTACHMENTS, pos+2)+1], pos+2, pos+2);
				}
				// Add new entry
				else{
					FX_ATTACHMENTS += (list)val + NULL_KEY + 1 + flags;
				}
				
			}
			//qd(mkarr(FX_ATTACHMENTS));
			updateFxAttachments();
			
		}
		else if(METHOD == RapeMethod$remFXAttachments){
			
			list rem = PARAMS;
			integer i;
			for(; i < count(rem); ++i ){
			
				str val = l2s(rem, i);
				integer pos = llListFindList(FX_ATTACHMENTS, [val]);
				if( ~pos ){
				
					integer nr = l2i(FX_ATTACHMENTS, pos+2)-1;
					if(nr <= 0){
						// Remove attachment
						Attached$removeTarg(l2k(FX_ATTACHMENTS, pos+1)); 
						FX_ATTACHMENTS = llDeleteSubList(FX_ATTACHMENTS, pos, pos+FXASTRIDE-1);
					}else{
						// Subtract from nr
						FX_ATTACHMENTS = llListReplaceList(FX_ATTACHMENTS, [nr], pos+2, pos+2);
					}
					
				}
				
			}
			
			updateFxAttachments();
		}
		
		else if(METHOD == RapeMethod$activateTemplate){
		
			if(llGetListLength(TEMPLATES))
				Bridge$fetchRape((str)LINK_ROOT, randElem(TEMPLATES));
				
		}
    }
    
    if(method$byOwner){
        if(METHOD == RapeMethod$assetSpawned && ~BFL&BFL_RAPE_STARTED && llListFindList(FX_ATTACHMENTS, [llKey2Name(id)]) == -1){
			Attached$removeTarg(id); 
		}
    }
    
    if(METHOD == RapeMethod$end){ 
	
        BFL = BFL&~BFL_RAPE_STARTED;
        
		integer i;
		for(i=0; i<llGetListLength(RAPE_ATTACHMENTS); i++){
			string val = llList2String(RAPE_ATTACHMENTS, i);
            Attached$remove(val);
		}
		
		for( i=0; i<llGetListLength(RAPE_REZZED); i++ )
            gotAnimeshScene$killByName(l2s(RAPE_REZZED, i));
					
		
        list_shift_each(RAPE_ANIMS, val,
            AnimHandler$anim(val, FALSE, 0, 0, 0);
        )
        
        raiseEvent(RapeEvt$onEnd, "");
        llOwnerSay("@unsit=y");
        RLV$cubeTask([
            SupportcubeBuildTask(Supportcube$tForceUnsit, [])
        ]);
    }
	else if(METHOD == RapeMethod$setTemplates){
		TEMPLATES = PARAMS;
	}
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

