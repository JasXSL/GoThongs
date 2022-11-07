list PLAYERS;
list PLAYER_HUDS;
#define USE_EVENTS
#include "got/_core.lsl"

integer BFL;
#define BFL_INSTALLING 0x1
#define BFL_CAM_SET 0x2
#define BFL_TIMER_SHEATHED 0x4

key MOD_TO_ACCEPT;
list MANIFEST;

int P_SFX;
int ARMOR = Status$FULL_ARMOR;			// Received from got Status
int FXF;			// FX Flags
int SF;				// Status flags

int ARMOR_SLOTS;	// Currently equipped slots in bits
#define getSlotEquipped(slot) (ARMOR_SLOTS&(1<<slot))

key VALIDATE;		// HTTP request to fetch manifest


// tCLT should be triggered: state entry, status flags changed, fx flags changed, armor changed

// Toggle clothes
tClt(){

	int vis = 0;
	int fxStripped = FXF&fx$F_SHOW_GENITALS || SF&(StatusFlag$dead|StatusFlag$raped);
	if( !fxStripped ){
		
		int i;
		for(; i<5; ++i ){
			
			if( Status$getArmorVal( ARMOR, i ) )
				vis = vis|(1<<i);
			
		}
		
	}


	integer lostArmor;
	list slots = ["head", "chest", "arms", "boots", "crotch"];
	int i;
	for(; i<5; ++i ){
		
		int cur = ARMOR_SLOTS&(1<<i);
		int set = vis & (1<<i);
		
		if( cur != set ){
			
			string folder = "dressed";
			if( !set )
				folder = "bits";
			llRegionSayTo(llGetOwner(), 1, "jasx.setclothes "+folder+"/"+l2s(slots, i));
			
			if( i == Status$armorSlot$GROIN ){
			
				if( set ){
					ThongMan$dead(FALSE, FALSE); 
				}
				else{
					ThongMan$dead(
						TRUE, 							// Hide thong
						!!(SF&StatusFlag$dead)	// But don't show particles or sound if this was an FX call
					);
				}
			}
			
			if( !set )
				lostArmor = i+1;
			
		}
	
	}
	
	ARMOR_SLOTS = vis;
	
	// Spawn armor rip
	
	if( lostArmor && !fxStripped ){
		
		list locs = [<0.1,0,.5>,<0.1,0,.25>,<0.0,.2,.4>,<0.1,0,-.45>,<0.1,0,0>];
		int slot = lostArmor-1;
		SpellFX$spawnInstantTarg(P_SFX, mkarr((list)"ArmorLost" + l2v(locs, slot)), llGetOwner());
		
	}
		
	
	/*
	// Show genitals
	integer show = (SF&(StatusFlag$dead|StatusFlag$raped)) || FXF&fx$F_SHOW_GENITALS;
	
    if(show && ~BFL&BFL_NAKED){
		BFL = BFL|BFL_NAKED;
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Bits");
		
    }
	
	else if(!show && BFL&BFL_NAKED){
		BFL = BFL&~BFL_NAKED;
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed");
		llSleep(1);
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Dressed/Groin, 0");
    }
	*/
	
}

cleanup(key id, integer manual){
	
	// Owner cleanup only
	if( id == llGetOwner() )
		Level$despawn(); 
	
	Portal$killAll(); 
	GUI$toggleObjectives((string)LINK_ROOT, FALSE); 
	Soundspace$reset();
	raiseEvent(RootAuxEvt$cleanup, (str)manual);
	if( manual )
		RLV$reset();			// Reset RLV locks and windlight on cleanup			
		
}

onEvt(string script, integer evt, list data){

	if( script == "#ROOT" && evt == RootEvt$players )
		PLAYERS = data;
	if( script == "#ROOT" && evt == RootEvt$coop_hud )
		PLAYER_HUDS = data;
		
	else if(script == "jas RLV"){
		if(evt == RLVevt$cam_set && ~BFL&BFL_CAM_SET){
			BFL = BFL|BFL_CAM_SET;
			if(llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK){
				llOwnerSay("@setcam_mode:thirdperson=force");
			}
		}
		else if(evt == RLVevt$cam_unset)BFL = BFL&~BFL_CAM_SET;
	}
	else if(script == "got Status" && evt == StatusEvt$flags){
		SF = l2i(data, 0);
		tClt();
	}
	else if(script == "got Status" && evt == StatusEvt$armor ){
		ARMOR = l2i(data, 0);
		tClt();
	}
	
	else if( script == "got Bridge" && evt == BridgeEvt$spawningLevel && l2s(data, 0) == "FINISHED" ){
		
		runOnPlayers(targ,
			Status$damageArmor(targ, -1000);
		)
		
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
		list LTB = llJson2List(l2s(MANIFEST, 8));
		list pvpScenes = llJson2List(l2s(MANIFEST, 9));
		

		
		if(
			!check(0, attachments, TRUE) ||
			!check(INVENTORY_OBJECT, levels, FALSE) ||
			!check(INVENTORY_ANIMATION, animations, FALSE) ||
			!check(INVENTORY_OBJECT, spell_effects, FALSE) ||
			!check(INVENTORY_OBJECT, monsters, FALSE) ||
			!check(INVENTORY_OBJECT, rapes, FALSE) ||
			!check(0, weapons, FALSE) ||
			!check(INVENTORY_OBJECT, LTB, FALSE) ||
			!check(INVENTORY_OBJECT, pvpScenes, FALSE)
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
		BuffVis$remInventory(LTB);
		gotPISpawner$remInventory(pvpScenes);
		
		
		
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
		list LTB = llJson2List(l2s(MANIFEST, 8));
		list pvpScenes = llJson2List(l2s(MANIFEST, 9));
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
			else if(name == "LTB" && LTB != [])
				llGiveInventoryList(lk, "", LTB);
			else if( name == "PlayerInteractions" && pvpScenes != [] )
				llGiveInventoryList(lk, "", pvpScenes);
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

default{

	state_entry(){
	
		purge();
		PLAYERS = [llGetOwner()];
		diagchan = llCeil(llFrand(0xFFFFFFF));
		memLim(2);
		llListen(3, "", llGetOwner(), "");
		llListen(diagchan, "", llGetOwner(), "");
        llListen(2, "", "", "");
		tClt();
		
		links_each( nr, name,
			if( name == "SpellFX" )
				P_SFX = nr;
		)
		
	}
	
	timer(){
		multiTimer([]);
	}
	
	listen(integer chan, string name, key id, string message){
		if(llGetOwnerKey(id) != llGetOwner())return;
		
		// Gesture commands
		if(chan == 3){ 
		
			// Party join
			if( ~llListFindList(["Join", "Accept", "Decline"], [message]) ) 
				Bridge$dialog(message); 
			
			// Space targeting
			else if( llGetSubString(message, 0, 5) == "switch" )
				Evts$cycleEnemy(llGetSubString(message, 6, -1) == "f"); 
			
			
			else if(llGetSubString(message, 0, 5) == "player"){
			
				integer n = (int)llGetSubString(message, 6, -1);
				if(n >= count(PLAYER_HUDS))
					return;
				Root$targetCoop(LINK_ROOT, l2s(PLAYER_HUDS, n));
				
			}
			
			else if(message == "reset"){resetAll();}
			

			else if(message == "potion")
				Potions$use((string)LINK_ROOT); 
			
			else if( message == "sheathe" && ~BFL&BFL_TIMER_SHEATHED ){
			
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
		if(assets)features+= (string)llGetListLength(assets)+" NPC Scenes";
		assets = llJson2List(llList2String(MANIFEST, 7));
		if(assets)features+= (string)llGetListLength(assets)+" Weapons";
		assets = llJson2List(llList2String(MANIFEST, 8));
		if(assets)features+= (string)llGetListLength(assets)+" LTB Visuals";
		assets = llJson2List(llList2String(MANIFEST, 9));
		if(assets)features+= (string)llGetListLength(assets)+" PVP Scenes";
		
		
		
		if(features == []){
			llOwnerSay("Invalid or empty mod data. Edit the got RootAux script for more info!");
			return;
		}
		llDialog(llGetOwner(), "Do you want to install files for the mod '"+llList2String(MANIFEST, 0)+"'? MAKE SURE YOU BACK UP YOUR HUD BEFORE INSTALLING A MOD! It will install the following items:\n- "+llDumpList2String(features, "\n- "), ["Accept", "Reject"], diagchan);
    }

	
	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		FXF = llList2Integer(data, 0); \
		tClt(); \
    } \
	
    #include "xobj_core/_LM.lsl"
    if(method$isCallback)
        return;

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
			VALIDATE = llHTTPRequest("https://jasx.org/lsl/got/app/manifest/?PUBKEY="+method_arg(0), [HTTP_BODY_MAXLENGTH, 0x2000], "");
			
		}
    }
	
	if(METHOD == RootAuxMethod$playSound){
		llPlaySound(method_arg(0), (float)method_arg(1));
	}
	else if(METHOD == RootAuxMethod$cleanup){
		if(id == "")
			id = llGetOwner();
		cleanup(id, l2i(PARAMS, 0));
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

