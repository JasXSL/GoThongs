list PLAYERS;
#define USE_EVENTS
#include "got/_core.lsl"

integer BFL;
#define BFL_INSTALLING 0x1
#define BFL_CAM_SET 0x2

key MOD_TO_ACCEPT;
list MANIFEST;

onEvt(string script, integer evt, string data){
	if(script == "#ROOT" && evt == RootEvt$players){
		PLAYERS = llJson2List(data);
	}
	else if(script == "jas RLV"){
		if(evt == RLVevt$cam_set && ~BFL&BFL_CAM_SET){
			BFL = BFL|BFL_CAM_SET;
			if(llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK)
				Alert$freetext((string)LINK_ROOT, "Cutscene started. Please exit mouselook!", FALSE, TRUE);
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
        if(llGetInventoryType(itm) != type){
            llOwnerSay("ERROR: "+llList2String(items, i)+" is missing from inventory or incorrect type.");
            success = FALSE;
        }
        else if(~llGetInventoryPermMask(itm, MASK_NEXT)&(PERM_COPY|PERM_MODIFY|PERM_TRANSFER) && !disregard_modperms){
            llOwnerSay("ERROR: "+llList2String(items, i)+" is not full perm!");
            success = FALSE;
        }   
    }
    return success;
}

timerEvent(string id, string data){
	if(id == "A"){
		
		// The assets should have been downloaded by now
		list attachments = llJson2List(llList2String(MANIFEST, 1)); // Attachments
		list levels = llJson2List(llList2String(MANIFEST, 2));
		list animations = llJson2List(llList2String(MANIFEST, 3));
		list spell_effects = llJson2List(llList2String(MANIFEST, 4));
		list monsters = llJson2List(llList2String(MANIFEST, 5));
		list rapes = llJson2List(llList2String(MANIFEST, 6));
		
		integer success = TRUE;
		if(!check(INVENTORY_OBJECT, attachments, TRUE))success = FALSE;
		if(!check(INVENTORY_OBJECT, levels, FALSE))success = FALSE;
		if(!check(INVENTORY_OBJECT, animations, FALSE))success = FALSE;
		if(!check(INVENTORY_OBJECT, spell_effects, FALSE))success = FALSE;
		if(!check(INVENTORY_OBJECT, monsters, FALSE))success = FALSE;
		if(!check(INVENTORY_OBJECT, rapes, FALSE))success = FALSE;
		
		if(!success)return purge();
		// Remove any existing mod assets
		
		AnimHandler$remInventory(animations);
		SpellFX$remInventory(spell_effects);
		Spawner$remInventory(monsters);
		Rape$remInventory(rapes);
		LevelSpawner$remInventory(levels); 
		
		llOwnerSay("Mod integrity checked! Finalizing install...");
		multiTimer(["B", "", 3, FALSE]);
		
		if(attachments)
			llGiveInventoryList(llGetOwner(), "GoT Modfiles | "+llList2String(MANIFEST, 0), attachments);

	}
	else if(id == "B"){
		list levels = llJson2List(llList2String(MANIFEST, 2));
		list animations = llJson2List(llList2String(MANIFEST, 3));
		list spell_effects = llJson2List(llList2String(MANIFEST, 4));
		list monsters = llJson2List(llList2String(MANIFEST, 5));
		list rapes = llJson2List(llList2String(MANIFEST, 6));
		
		links_each(nr, name,
			key lk = llGetLinkKey(nr);
			if(name == "Anim" && animations != [])llGiveInventoryList(lk, "", animations);
			else if(name == "SpellFX" && spell_effects != [])llGiveInventoryList(lk, "", spell_effects);
			else if(name == "Monsters" && monsters != [])llGiveInventoryList(lk, "", monsters);
			else if(name == "Rapes" && rapes != [])llGiveInventoryList(lk, "", rapes);
			else if(name == "Levels" && levels != [])llGiveInventoryList(lk, "", levels);
		)
		multiTimer(["C", "", 3, FALSE]);
	}
	else if(id == "C"){
		purge();
		llOwnerSay("Mod installed!");
	}
}

purge(){
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
				Root$targetThis(llGetOwner(), TEXTURE_PC, TRUE);
			} 
			else if(message == "coop"){
				Root$targetThis(llList2Key(PLAYERS, 1), TEXTURE_COOP, TRUE);
			} 
			else if(message == "wipeCells"){ 
				Portal$killAll(); 
				GUI$toggleObjectives((string)LINK_ROOT, FALSE); 
				Level$despawn(); 
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
			else  
				SpellMan$hotkey(message); 
			return; 
		} 
		if(chan == 2){ 
			if(llGetSubString(message, 0, 8) == "settings:") 
				Status$setSex((integer)jVal(llGetSubString(message, 9, -1), ["sex"])); 
			return; 
		} 
		if(chan == diagchan){
			if(message == "Accept" && MOD_TO_ACCEPT != "" && ~BFL&BFL_INSTALLING){
				llOwnerSay("Installing, please wait");
				BFL = BFL|BFL_INSTALLING;
				multiTimer(["A", "", 3, FALSE]);
				ModInstall$fetch(MOD_TO_ACCEPT);
			}
		}
		
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
			MOD_TO_ACCEPT = id;
			MANIFEST = llJson2List(method_arg(0));
			
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
			
			
			if(features == []){
				llOwnerSay("Can't install mod because it's empty!");
				return;
			}
			llDialog(llGetOwner(), "Do you want to install files for the mod '"+llList2String(MANIFEST, 0)+"'? MAKE SURE YOU BACK UP YOUR HUD BEFORE INSTALLING A MOD! It will install the following items:\n- "+llDumpList2String(features, "\n- "), ["Accept", "Reject"], diagchan);
		}
    }
	
	if(METHOD == RootAuxMethod$playSound){
		llPlaySound(method_arg(0), (float)method_arg(1));
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

