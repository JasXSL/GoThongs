/*
    Enter your mod public key
    You can see yours at the game of thongs website mod section
    Don't forget to build the manifest by clicking setup manifest.
*/
#define SCRIPT_IS_ROOT
#define ALLOW_USER_DEBUG 1
#include "got/_core.lsl"

#define PUBKEY llGetObjectDesc()
#define text(txt) llSetText(txt, <.5,.8,1>, 1)

string get_type_info(integer inputInteger){
	
	if(inputInteger == -1)
		return "ANY";

    else if(inputInteger == INVENTORY_TEXTURE)
        return "INVENTORY_TEXTURE";
 
    else if (inputInteger == INVENTORY_SOUND)
        return "INVENTORY_SOUND";
 
    else if (inputInteger == INVENTORY_LANDMARK)
        return "INVENTORY_LANDMARK";
 
    else if (inputInteger == INVENTORY_CLOTHING)
        return "INVENTORY_CLOTHING";
 
    else if (inputInteger == INVENTORY_OBJECT)
        return "INVENTORY_OBJECT";
 
    else if (inputInteger == INVENTORY_NOTECARD)
        return "INVENTORY_NOTECARD";
 
    else if (inputInteger == INVENTORY_SCRIPT)
        return "INVENTORY_SCRIPT";
 
    else if (inputInteger == INVENTORY_BODYPART)
        return "INVENTORY_BODYPART";
 
    else if (inputInteger == INVENTORY_ANIMATION)
        return "INVENTORY_ANIMATION";
 
    else if (inputInteger == INVENTORY_GESTURE)
        return "INVENTORY_GESTURE";
 
//  else
        return "MISSING";
}

// Function used on compile to make sure the manifest is proper
integer check(integer type, list items, integer disregard_modperms){
    integer i; integer success = TRUE;
    for(i=0; i<llGetListLength(items); i++){
        string itm = llList2String(items, i);
        integer it = llGetInventoryType(itm);
        if((it != type && type != -1) || it == INVENTORY_NONE){

            llOwnerSay("ERROR: "+llList2String(items, i)+" is missing from inventory or incorrect type. Got "+
                get_type_info(it)+
                ". Expected "+get_type_info(type)
            );
            
            success = FALSE;
        }
        else if(~llGetInventoryPermMask(itm, MASK_NEXT)&(PERM_COPY|PERM_TRANSFER) && !disregard_modperms){
            llOwnerSay("ERROR: "+llList2String(items, i)+" is not full perm!");
            success = FALSE;
        }   
    }
    return success;
}

key VALIDATE;

default
{
    on_rez(integer mew){llResetScript();}
    state_entry()
    {
		if(llGetStartParameter()){
		
			text("Validating");
			VALIDATE = llHTTPRequest("http://jasx.org/lsl/got/app/manifest/?PUBKEY="+PUBKEY, [HTTP_BODY_MAXLENGTH, 8192], "");
			initiateListen();
			
		}
		else{
			
			list exp = explode("_",llGetObjectDesc());
			if(l2s(exp,1) == "BETA"){
				llRegionSayTo(llGetOwner(), 0, "!!WARNING!! This installer is set to use BETA. Don't forget to remove _BETA from description before you redistribute it.");
				llPlaySound("b08f8409-0ae1-da6a-91a8-297ba8c2a495", 1);
			}
			
			text("Initializing, make sure you are wearing the HUD.");
			integer pin = llFloor(llFrand(0xFFFFFFF));
			llSetRemoteScriptAccessPin(pin);
			Remoteloader$load(llGetScriptName(), pin, 1);
			
		}
		
		
    }

    
    http_response(key id, integer status, list meta, string body){
        
        if(id != VALIDATE)
            return;
            
        if(llJsonValueType(body, []) != JSON_OBJECT){
            text("HTTP ERROR "+(str)status);
            qd(body);
            return;
        } 
        
        list data = llJson2List(j(body, "errors"));
        list_shift_each(data, val,
            qd(val);
        )
        
        list MANIFEST = llJson2List(j(body, "data"));
        body = "";
        
        
        integer s = (
            check(-1, llJson2List(llList2String(MANIFEST, 1)), TRUE) && // Attachments
            check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 2)), FALSE) && 	// Levels
            check(INVENTORY_ANIMATION, llJson2List(llList2String(MANIFEST, 3)), FALSE) && // Animations
            check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 4)), FALSE) && 	// SpellFX
            check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 5)), FALSE) && 	// Monsters
            check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 6)), FALSE) && 	// Rapes
			check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 7)), FALSE) && 	// Weapons
			check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 8)), FALSE) &&	// LTB
			check(INVENTORY_OBJECT, llJson2List(llList2String(MANIFEST, 9)), FALSE)		// PVP Poses
        );
        if(!s){
			text("Error found.\nTouch to override.");
            llOwnerSay("An error was found. You might be able to play, but should make sure you have the latest mod version. Touch the box if you want to install anyway.");
        }
        else{
            RootAux$prepareManifest(PUBKEY);
        }
        
    }
    
    #define LISTEN_LIMIT_FREETEXT if(llGetOwnerKey(id) != llGetOwner())return;
    #include "xobj_core/_LISTEN.lsl"
    
    touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
		text("Attempting install");
        RootAux$prepareManifest(PUBKEY);
    }
    
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
    
    if(method$byOwner){
        if(METHOD == ModInstallMethod$fetch){
            list send = [];
            integer i;
            for(i=0; i<llGetInventoryNumber(INVENTORY_ALL); i++){
                string n = llGetInventoryName(INVENTORY_ALL, i);
                if(n != llGetScriptName()){
                    send+= n;
                }
            }
            llGiveInventoryList(id,"", send);
			text("Content sent!");
        }
		if(METHOD == ModInstallMethod$reset){
			text("Initializing...");
			llResetScript();
		
		}
		
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

