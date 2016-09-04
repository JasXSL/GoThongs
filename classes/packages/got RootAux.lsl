list PLAYERS;
#define USE_EVENTS
#include "got/_core.lsl"

integer BFL;
#define BFL_INSTALLING 0x1
#define BFL_CAM_SET 0x2
#define BFL_TIMER_SHEATHED 0x4

key MOD_TO_ACCEPT;
list MANIFEST;

key VALIDATE;		// HTTP request to fetch manifest

onEvt(string script, integer evt, list data){
	if(script == "#ROOT" && evt == RootEvt$players){
		PLAYERS = data;
	}
	else if(script == "jas RLV"){
		if(evt == RLVevt$cam_set && ~BFL&BFL_CAM_SET){
			BFL = BFL|BFL_CAM_SET;
			if(llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK){
				llOwnerSay("@setcam_mode:thirdperson=force");
			}
		}
		else if(evt == RLVevt$cam_unset)BFL = BFL&~BFL_CAM_SET;
	}
}

integer diagchan;

// Function used on compile to make sure the manifest is proper
integer check(integer type, list items, integer disregard_modperms){
    integer i; integer success = TRUE;
    for(i=0; i<llGetListLength(items); i++){
        string itm = llList2String(items, i);
        
		// Missing asset generates a warning
		if(llGetInventoryType(itm) != type && type > 0){
            llOwnerSay("Warning: "+llList2String(items, i)+" is missing from inventory or incorrect type.");
        }
		
		// But improper perms are fatal
        else if(~llGetInventoryPermMask(itm, MASK_NEXT)&(PERM_COPY|PERM_MODIFY|PERM_TRANSFER) && !disregard_modperms){
            llOwnerSay("Fatal Error: "+llList2String(items, i)+" is not full perm!");
            success = FALSE;
        }   
    }
    return success;
}

timerEvent(string id, string data){

	// Assets should have been received from the installer
	if(id == "A"){
		
		// The assets should have been downloaded by now
		list attachments = llJson2List(llList2String(MANIFEST, 1)); // Attachments
		list levels = llJson2List(llList2String(MANIFEST, 2));
		list animations = llJson2List(llList2String(MANIFEST, 3));
		list spell_effects = llJson2List(llList2String(MANIFEST, 4));
		list monsters = llJson2List(llList2String(MANIFEST, 5));
		list rapes = llJson2List(llList2String(MANIFEST, 6));
		list weapons = llJson2List(llList2String(MANIFEST, 7));
		
		if(
			!check(0, attachments, TRUE) ||
			!check(INVENTORY_OBJECT, levels, FALSE) ||
			!check(INVENTORY_ANIMATION, animations, FALSE) ||
			!check(INVENTORY_OBJECT, spell_effects, FALSE) ||
			!check(INVENTORY_OBJECT, monsters, FALSE) ||
			!check(INVENTORY_OBJECT, rapes, FALSE) ||
			!check(INVENTORY_OBJECT, weapons, FALSE) 
		){
			// Something failed, stop
			return purge();
		}
		
		AnimHandler$remInventory(animations);
		SpellFX$remInventory(spell_effects);
		Spawner$remInventory(monsters);
		Rape$remInventory(rapes);
		LevelSpawner$remInventory(levels); 
		WeaponLoader$remInventory(weapons);
		
		llOwnerSay("Mod integrity checked! Finalizing install...");
		multiTimer(["B", "", 3, FALSE]);
		
		if(attachments)
			llGiveInventoryList(llGetOwner(), "GoT Modfiles > "+llList2String(MANIFEST, 0), attachments);

	}
	
	else if(id == "B"){
	
		list levels = llJson2List(llList2String(MANIFEST, 2));
		list animations = llJson2List(llList2String(MANIFEST, 3));
		list spell_effects = llJson2List(llList2String(MANIFEST, 4));
		list monsters = llJson2List(llList2String(MANIFEST, 5));
		list rapes = llJson2List(llList2String(MANIFEST, 6));
		list weapons = llJson2List(llList2String(MANIFEST, 7));
		MANIFEST = [];
		
		links_each(nr, name,
			key lk = llGetLinkKey(nr);
			if(name == "Anim" && animations != [])
				llGiveInventoryList(lk, "", animations);
			else if(name == "SpellFX" && spell_effects != [])
				llGiveInventoryList(lk, "", spell_effects);
			else if(name == "Monsters" && monsters != [])
				llGiveInventoryList(lk, "", monsters);
			else if(name == "Rapes" && rapes != [])
				llGiveInventoryList(lk, "", rapes);
			else if(name == "Levels" && levels != [])
				llGiveInventoryList(lk, "", levels);
			else if(name == "WEAPONS" && weapons != [])
				llGiveInventoryList(lk, "", weapons);
		)
		multiTimer(["C", "", 3, FALSE]);
	}
	
	// Clean up
	else if(id == "C"){
		purge();
		llOwnerSay("Mod installed!");
	}
	
	else if(id == "D")
		BFL = BFL&~BFL_TIMER_SHEATHED;
}

purge(){
	MANIFEST = [];
	integer i;
	for(i=0; i<llGetInventoryNumber(INVENTORY_ALL); i++){
		string n = llGetInventoryName(INVENTORY_ALL, i);
		if(n != llGetScriptName()){
			llRemoveInventory(n);
			i--;
		}
	}
	BFL = BFL&~BFL_INSTALLING;
}

default
{
	state_entry(){
		purge();
		diagchan = llCeil(llFrand(0xFFFFFFF));
		memLim(2);
		llListen(3, "", llGetOwner(), "");
		llListen(diagchan, "", llGetOwner(), "");
        llListen(2, "", "", "");
		
	}
	
	timer(){
		multiTimer([]);
	}
	
	listen(integer chan, string name, key id, string message){
		if(llGetOwnerKey(id) != llGetOwner())return;
		
		// Gesture commands
		if(chan == 3){ 
			if(message == "login"){
				Bridge$getToken(); 
			}			
			
			else if(message=="Join") 
				Bridge$dialog(message); 
				
			else if(message == "switch"){ 
				Evts$cycleEnemy(); 
			} 
			
			else if(message == "self"){ 
				Root$targetThis(llGetOwner(), TEXTURE_PC, TRUE, TEAM_PC);
			} 
			
			else if(message == "coop"){
				Root$targetThis(llList2Key(PLAYERS, 1), TEXTURE_COOP, TRUE, TEAM_PC);
			} 
			
			else if(message == "wipeCells"){ 
				Portal$killAll(); 
				GUI$toggleObjectives((string)LINK_ROOT, FALSE); 
				Level$despawn(); 
				Soundspace$reset();
				raiseEvent(RootAuxEvt$cleanup, "");
				RLV$reset();			// Reset RLV locks and windlight on cleanup
				
			} 
			
			else if(message == "reset"){resetAll();}
			
			else if(message == "continueQuest"){ 
				AMS$(ARoot$continueQuest); 
				Portal$killAll(); 
				Bridge$continueQuest();
			} 
			
			else if(llGetSubString(message, 0,10) =="difficulty:"){ 
				Status$setDifficulty((string)LINK_ROOT, (integer)llGetSubString(message,11,-1), TRUE); 
			} 
			
			else if(message == "potion"){ 
				Potions$use((string)LINK_ROOT); 
			} 
			
			else if(message == "sheathe" && ~BFL&BFL_TIMER_SHEATHED){
				BFL = BFL|BFL_TIMER_SHEATHED;
				WeaponLoader$toggleSheathe(LINK_SET, -1);
				multiTimer(["D", "", 3, FALSE]);
			}
			
			else  
				SpellMan$hotkey(message); 
				
			return; 
		} 
		
		// JasX HUD input
		if(chan == 2){ 
			if(llGetSubString(message, 0, 8) == "settings:"){
				integer sex = (int)j(llGetSubString(message, 9, -1), "sex");
				Status$setSex(sex); 
			}
			return; 
		} 
		
		// Install accept dialog
		if(chan == diagchan){
			if(message == "Accept" && MOD_TO_ACCEPT != "" && ~BFL&BFL_INSTALLING){
				llOwnerSay("Installing, please wait");
				BFL = BFL|BFL_INSTALLING;
				multiTimer(["A", "", 3, FALSE]);
				ModInstall$fetch(MOD_TO_ACCEPT);
			}
		}
		
	}
	
	http_response(key id, integer status, list meta, string body){
        
        if(id != VALIDATE)
            return;
            
        if(llJsonValueType(body, []) != JSON_OBJECT){
            qd("HTTP ERROR "+(str)status);
            qd(body);
            return;
        } 
        
        list data = llJson2List(j(body, "errors"));
        list_shift_each(data, val,
            qd(val);
        )
        
        MANIFEST = llJson2List(j(body, "data"));
        body = "";
        
        list features;
		list assets = llJson2List(llList2String(MANIFEST, 1));
		if(assets)features+= (string)llGetListLength(assets)+" Attachments";
		assets = llJson2List(llList2String(MANIFEST, 2));
		if(assets)features+= (string)llGetListLength(assets)+" Levels";
		assets = llJson2List(llList2String(MANIFEST, 3));
		if(assets)features+= (string)llGetListLength(assets)+" Animations";
		assets = llJson2List(llList2String(MANIFEST, 4));
		if(assets)features+= (string)llGetListLength(assets)+" Spell Effects";
		assets = llJson2List(llList2String(MANIFEST, 5));
		if(assets)features+= (string)llGetListLength(assets)+" Monsters";
		assets = llJson2List(llList2String(MANIFEST, 6));
		if(assets)features+= (string)llGetListLength(assets)+" Rapes";
		assets = llJson2List(llList2String(MANIFEST, 7));
		if(assets)features+= (string)llGetListLength(assets)+" Weapons";
		
		
		if(features == []){
			llOwnerSay("Invalid or empty mod data. Edit the got RootAux script for more info!");
			return;
		}
		llDialog(llGetOwner(), "Do you want to install files for the mod '"+llList2String(MANIFEST, 0)+"'? MAKE SURE YOU BACK UP YOUR HUD BEFORE INSTALLING A MOD! It will install the following items:\n- "+llDumpList2String(features, "\n- "), ["Accept", "Reject"], diagchan);
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
		if(METHOD == RootAuxMethod$prepareManifest){
			if(BFL&BFL_INSTALLING){
				llOwnerSay("A mod install is already in progress. Please try again once it finishes.");
				return;
			}
			if(!isset(method_arg(0))){
				llOwnerSay("Set the object description to your mod's public key. Edit the got RootAux script for more info.");
				return;
			}
			
			MOD_TO_ACCEPT = id;
			
			// Fetch manifest by pubkey
			VALIDATE = llHTTPRequest("http://jasx.org/lsl/got/app/manifest/?PUBKEY="+method_arg(0), [HTTP_BODY_MAXLENGTH, 0x2000], "");
			
		}
    }
	
	if(METHOD == RootAuxMethod$playSound){
		llPlaySound(method_arg(0), (float)method_arg(1));
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

