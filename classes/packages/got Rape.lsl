#define USE_EVENTS
#include "got/_core.lsl"

#define TIMER_BREAKFREE "a"

integer BFL;
#define BFL_RAPE_STARTED 1

list RAPE_ANIMS;
list RAPE_ATTACHMENTS;

integer STATUS_FLAGS;

// llListFindList for name works in this because it's the only string type
list FX_ATTACHMENTS;		// [(str)name, (key)id, (int)nr_attachments]	

updateFxAttachments(){
	integer i;
	for(i=0; i<count(FX_ATTACHMENTS); i+=3){
		if(llKey2Name(llList2Key(FX_ATTACHMENTS, i+1)) == ""){
			llRezAtRoot(llList2String(FX_ATTACHMENTS, i), llGetPos()-<0,0,3>, ZERO_VECTOR, ZERO_ROTATION, 1);
		}
	}
}


list TEMPLATES;

onEvt(string script, integer evt, list data){
	if(script == "got Status" && evt == StatusEvt$flags){
		STATUS_FLAGS = llList2Integer(data,0);
	}
}

default 
{
    // Timer event
    //timer(){multiTimer([]);}
    state_entry(){memLim(2);}
	
	object_rez(key id){
		str name = llKey2Name(id);
		integer pos = llListFindList(FX_ATTACHMENTS, [name]);
		if(~pos){
			FX_ATTACHMENTS = llListReplaceList(FX_ATTACHMENTS, [id], pos+1, pos+1);
		}
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
    
    if(method$isCallback){
        return;
    }
    
    if(method$internal){
        if(METHOD == RapeMethod$start && count(PARAMS) > 1){
		
            if(BFL&BFL_RAPE_STARTED || ~STATUS_FLAGS&StatusFlag$dead)return;
            
            BFL = BFL|BFL_RAPE_STARTED;
            
            RAPE_ANIMS = llJson2List(method_arg(0));
            RAPE_ATTACHMENTS = llJson2List(method_arg(1));
            list sounds = llJson2List(method_arg(2));
            
            integer i;
            for(i=0; i<llGetListLength(RAPE_ATTACHMENTS); i++){
                llRezAtRoot(llList2String(RAPE_ATTACHMENTS, i), llGetPos()-<0,0,2>, ZERO_VECTOR, ZERO_ROTATION, 1);
            }
            for(i=0; i<llGetListLength(RAPE_ANIMS); i++)
                AnimHandler$anim(llList2String(RAPE_ANIMS, i), TRUE, 0, 0);
            
            vector pos = llGetPos();
            vector ascale = llGetAgentSize(llGetOwner());
            list ray = llCastRay(pos, pos-<0,0,5>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);
            if(llList2Integer(ray,-1) == 1)
                pos = llList2Vector(ray, 1)+<0,0,ascale.z/2-.1>;
            
            
            rotation rot = llGetRootRotation();
            vector vrot = llRot2Euler(rot);
            vrot = <0,0,vrot.z>;
            
            RLV$cubeTask(([
                SupportcubeBuildTask(Supportcube$tSetPos, [pos]),
                SupportcubeBuildTask(Supportcube$tSetRot, [llEuler2Rot(vrot)]),
                SupportcubeBuildTask(Supportcube$tForceSit, [true])
            ]));
            

            raiseEvent(RapeEvt$onStart, "");
			
            
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
			list_shift_each(add, val,
				integer pos = llListFindList(FX_ATTACHMENTS, [val]);
				if(~pos){
					FX_ATTACHMENTS = llListReplaceList(FX_ATTACHMENTS, [llList2Integer(FX_ATTACHMENTS, pos+2)+1], pos+2, pos+2);
				}
				else{
					FX_ATTACHMENTS += ([val, NULL_KEY, 1]);
				}
			)
			
			updateFxAttachments();
		}
		else if(METHOD == RapeMethod$remFXAttachments){
			
			list rem = PARAMS;
			list_shift_each(rem, val,
				integer pos = llListFindList(FX_ATTACHMENTS, [val]);
				if(~pos){
					integer nr = llList2Integer(FX_ATTACHMENTS, pos+2)-1;
					if(nr <= 0){
						// Remove attachment
						Attached$removeTarg(llList2Key(FX_ATTACHMENTS, pos+1)); 
						FX_ATTACHMENTS = llDeleteSubList(FX_ATTACHMENTS, pos, pos+2);
					}else{
						FX_ATTACHMENTS = llListReplaceList(FX_ATTACHMENTS, [nr], pos+2, pos+2);
					}
				}
			)
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
        list_shift_each(RAPE_ANIMS, val,
            AnimHandler$anim(val, FALSE, 0, 0);
        )
        
        raiseEvent(RapeEvt$onEnd, "");
        
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

