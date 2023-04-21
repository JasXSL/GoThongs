#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"


integer STATUS; // Flags from got Status

integer BFL = 0x1;
#define BFL_SHEATHED 0x1		// Weapon sheathed
#define BFL_LOADED 0x2
#define BFL_INIT 0x4			// HUD initialized

integer WFLAGS;
#define WFLAG_UNSHEATHABLE 0x8
// Thong flags
integer TFLAGS;
#define TFLAG_NO_WEAPONS 0x8

string RHAND;
key RHAND_ATT;

string LHAND;
key LHAND_ATT;

float W_SCALE = 1;

list W_SOUNDS;


#define unsheatable (WFLAGS&WFLAG_UNSHEATHABLE || TFLAGS&TFLAG_NO_WEAPONS)

// FX
integer FX_FLAGS;
list FXS;			// Fx Stances

// 
vector W_MAINHAND_POS;
vector W_BACK_MAINHAND_POS;
vector W_OFFHAND_POS;
vector W_BACK_OFFHAND_POS;
integer W_MAINHAND_SLOT;
integer W_OFFHAND_SLOT;
rotation W_MAINHAND_ROT;
rotation W_OFFHAND_ROT;
rotation W_BACK_MAINHAND_ROT;
rotation W_BACK_OFFHAND_ROT;
int W_MAINHAND_BACK_SLOT;
int W_OFFHAND_BACK_SLOT;

string CLASS_STANCE;
list SPELL_STANCES = ["","","","",""];		// Stance overrides after casting spells
list SPELL_FLAGS = [0,0,0,0,0];
int LAST_SPELL_CAST = -1;
#define getSpellStance() l2s(SPELL_STANCES, LAST_SPELL_CAST)
string STANCE;
list ANIM_SET;

rotation BACK_DEFAULT_ROT = <0.00000, 0.00000, 0.53730, 0.84339>;
vector BACK_DEFAULT_POS = <-0.11448, -0.37465, -0.04116>;
rotation BACK_OH_DEFAULT_ROT = <0.00000, 0.00000, 0.84339, 0.53730>;
vector BACK_OH_DEFAULT_POS = <0.11448, -0.37465, -0.04116>;

vector CUSTOM_BACK_DEFAULT_POS;
vector CUSTOM_BACK_OH_DEFAULT_POS;

string IDLE_ANIM;	// Active idle anim

#define animExists( anim ) llGetInventoryType(anim) == INVENTORY_ANIMATION


updateStance(){

	// Lowest to highest priority
	string anim = "stance_fists";
	if( STANCE != "" && !unsheatable && ~BFL&BFL_SHEATHED )
		anim = STANCE;
	if( CLASS_STANCE )
		anim = CLASS_STANCE;
	if( getSpellStance() != "" && ~LAST_SPELL_CAST )
		anim = getSpellStance();
	if( LAST_SPELL_CAST == -1 && l2s(SPELL_STANCES, 1) != "" )
		anim = l2s(SPELL_STANCES, 1);
	
	str ao = "{}";	// Stacks all AO entries together
	int i;
	for(; i<count(FXS); ++i ){
		
		str val = l2s(FXS, i);
		// Normal stance overrides get added as the standing
		if( llJsonValueType(val, []) != JSON_OBJECT )
			ao = llJsonSetValue(ao, (list)"Standing", val);
		else{
		
			list l = llJson2List(val);
			int x;
			for( ; x<count(l); x = x+2 )
				ao = llJsonSetValue(ao, llList2List(l, x, x), l2s(l, x+1));
			
		}
		
	}
	
	//if( BFL&BFL_STANCE )
	//	anim = "";
	if( ~STATUS&StatusFlag$combat ){
		
		anim = "";
		
		
	}
	
	// in combat
	if( ~STATUS&StatusFlag$combat && llGetInventoryType(STANCE+"_idle") && ~BFL&BFL_SHEATHED && ~FX_FLAGS&fx$F_DISARM ){
		
		string an = STANCE+"_idle";
		if( IDLE_ANIM != an ){
		
			if( IDLE_ANIM != "" && animExists(IDLE_ANIM) )
				llStopAnimation(IDLE_ANIM);
			IDLE_ANIM = an;
			if( animExists(IDLE_ANIM) )
				llStartAnimation(an);
		
		}
	
	}
	// Out of combat
	else if( IDLE_ANIM ){
		
		if( animExists(IDLE_ANIM) )
			llStopAnimation(IDLE_ANIM);
		IDLE_ANIM = "";
		
	}
		
	gotClassAtt$stance(anim);

	// Animations
	integer p = llGetPermissions()&PERMISSION_OVERRIDE_ANIMATIONS;
	if( !p )
		return;
	
	// Go through AO overrides
	list aoList = llJson2List(ao);
	for( i=0; i<count(aoList); i += 2 ){
		
		str k = l2s(aoList, i);
		str v = l2s(aoList, i+1);
		
		// If standing is set, let it be handled by the default stand handler
		if( k == "Standing" )
			anim = v;
		else
			llSetAnimationOverride(k, v);

	}

	if( anim != "" ){
		llSetAnimationOverride( "Standing", anim );
	}
	else
		llResetAnimationOverride("Standing");
	
}

onCombatEntered(){
	
	updateStance();
	
}

onCombatExited(){

	updateStance();

}

onEvt(string script, integer evt, list data){
    
	if( script == "got Bridge" && evt == BridgeEvt$thong_initialized )
		multiTimer(["INI", 0, 4, FALSE]);
		
    if( script == "got Bridge" && evt == BridgeEvt$userDataChanged )
        loadWeapon(llJson2List(hud$bridge$userData()));   
    // thong data changed
    else if(script == "got Bridge" && evt == BridgeEvt$data_change){
		
		TFLAGS = (int)j(
			hud$bridge$thongData(),
			BSS$FLAGS
		);
		reloadWeapon();
		
	}
	
	if( script == "got SpellMan" && evt == SpellManEvt$complete ){
		
		int pre = LAST_SPELL_CAST;
		LAST_SPELL_CAST = l2i(data, 0);
		if( getSpellStance() != l2s(SPELL_STANCES, pre) )
			updateStance();
			
		if( l2i(SPELL_FLAGS, LAST_SPELL_CAST)&SpellMan$DRAW_WEAPON && BFL&BFL_SHEATHED )
			WeaponLoader$toggleSheathe(LINK_THIS, STATUS&StatusFlag$combat);
			
	}

    if(script == "got Status" && evt == StatusEvt$flags){
	
        integer pre = STATUS;
        STATUS = l2i(data, 0);
		// Rape ended
        if( pre&StatusFlag$dead && ~STATUS&StatusFlag$dead )
            spawnWeapons();
        // Remove weapons
		if( ~pre&StatusFlag$dead && STATUS&StatusFlag$dead )
            Weapon$removeAll();
			
		
        // Combat handles stance, and sheathe on stance end
		if( (pre&StatusFlag$combat) != (STATUS&StatusFlag$combat) ){
		
			if( STATUS & StatusFlag$combat )
				onCombatEntered();
			else
				onCombatExited();
			
		}
		
		
    }
	
	if( script == "got SpellMan" && evt == SpellManEvt$recache ){
		
		SPELL_STANCES = SPELL_FLAGS = [];
		string tmpChr = hudTable$spellmanSpellsTemp;
		string chr = hudTable$bridgeSpells;
		integer i;
        for( ; i<5; ++i ){
            
            list d = llJson2List(db4$get(tmpChr, i));
            if( d == [] )
                d = llJson2List(db4$get(chr, i));
            SPELL_STANCES += l2s(d, BSSAA$stance);
			SPELL_FLAGS += l2i(d, BSSAA$target_flags);

        }

	}
	
    
}

loadWeapon( list data ){

    W_SCALE = l2f(data, BSUD$W_SCALE);
    
    // Avatar settings
    vector mainhand_offset = (vector)l2s(data, BSUD$W_MH_OFFSET);
    vector mainhand_back_offset = (vector)l2s(data, BSUD$W_BACK_MH_OFFSET);
    vector offhand_offset = (vector)l2s(data, BSUD$W_OH_OFFSET);
    vector offhand_back_offset = (vector)l2s(data, BSUD$W_BACK_OH_OFFSET);

	CLASS_STANCE = l2s(data, BSUD$DEFAULT_STANCE);
    
    list wdata = llJson2List(l2s(data, BSUD$WDATA));
    string rhand = l2s(wdata, 0);
    string lhand = l2s(wdata, 1);
	
    WFLAGS = l2i(wdata, 4);
    
    W_MAINHAND_SLOT = l2i(wdata, 6);
    W_OFFHAND_SLOT = l2i(wdata, 7);
	
	
	W_SOUNDS = llJson2List(l2s(wdata, 12));
	
	W_MAINHAND_BACK_SLOT = l2i(wdata, 14);
    W_OFFHAND_BACK_SLOT = l2i(wdata, 15);
	
    
    // Main hand offsets default to ZERO_VECTOR/ZERO_ROTATION, so we can just use the stuff from the avatar
    W_MAINHAND_POS = mainhand_offset;
    W_OFFHAND_POS = offhand_offset;
	
	
	
	STANCE = j(l2s(wdata, 13), 0);
	ANIM_SET = llJson2List(j(l2s(wdata, 13), 1));
	    
	
	CUSTOM_BACK_DEFAULT_POS = BACK_DEFAULT_POS;
	CUSTOM_BACK_OH_DEFAULT_POS = BACK_OH_DEFAULT_POS;
	
    if( (vector)l2s(wdata, 10) )
        CUSTOM_BACK_DEFAULT_POS = (vector)l2s(wdata, 10);
    if( (vector)l2s(wdata, 11) )
        CUSTOM_BACK_OH_DEFAULT_POS = (vector)l2s(wdata, 11);
	
	W_BACK_MAINHAND_POS = mainhand_back_offset+CUSTOM_BACK_DEFAULT_POS;
    W_BACK_OFFHAND_POS = offhand_back_offset+CUSTOM_BACK_OH_DEFAULT_POS;
    
    // Rotations are fixed, set to default
    W_BACK_MAINHAND_ROT = BACK_DEFAULT_ROT;
    W_BACK_OFFHAND_ROT = BACK_OH_DEFAULT_ROT;
	
    
    // Check if custom exists for this particular weapon
    if( (rotation)l2s(wdata, 8) )
        W_BACK_MAINHAND_ROT = (rotation)l2s(wdata, 8);
    if( (rotation)l2s(wdata, 9) )
        W_BACK_OFFHAND_ROT = (rotation)l2s(wdata, 9);
    
	
	// At least 1 weapon prim has changed so we need to re-spawn
	if(rhand != RHAND || lhand != LHAND){
	
        RHAND = rhand;
        LHAND = lhand;
        spawnWeapons();
		
    }

	BFL = BFL|BFL_LOADED;
	reloadWeapon();
    
}

// Data has been received either about the weapon or thong
reloadWeapon(){
	if(~BFL&BFL_LOADED)
		return;
		
	if( unsheatable && ~BFL&BFL_SHEATHED ){ 
	
		spawnWeapons();	
        BFL = BFL|BFL_SHEATHED;
		updateStance();
		
    }
	
    raiseEvent(WeaponLoaderEvt$sheathed, (str)((BFL&BFL_SHEATHED)>0));
}

// Returns an attachment slot
integer getAttachSlot(integer rhand){
    if(BFL&BFL_SHEATHED || unsheatable){
		if(rhand)
			return W_MAINHAND_BACK_SLOT;
        return W_OFFHAND_BACK_SLOT;
	}
    if(rhand)
        return W_MAINHAND_SLOT;
    return W_OFFHAND_SLOT;
}

// Returns the position
vector getAttachPos(integer rhand){

    if(BFL&BFL_SHEATHED || unsheatable){
        if(rhand)
            return W_BACK_MAINHAND_POS;
        return W_BACK_OFFHAND_POS;
    }
    
    if(rhand)
        return W_MAINHAND_POS;
    return W_OFFHAND_POS;
	
}

// Returns rotation
rotation getAttachRot(integer rhand){
    
    if(BFL&BFL_SHEATHED || unsheatable){
        if(rhand)
            return W_BACK_MAINHAND_ROT;
        return W_BACK_OFFHAND_ROT;
    }
    
    if(rhand){
        return W_MAINHAND_ROT;
    }
    return W_OFFHAND_ROT;
}

timerEvent(string id, string data){
    if(id == "WC"){
        if(
            (RHAND != "" && llKey2Name(RHAND_ATT) == "") ||
            (LHAND != "" && llKey2Name(LHAND_ATT) == "")
        )spawnWeapons();
    }
	else if(id == "SND")
		llTriggerSound(data, llFrand(.25)+.25);
		
	else if( id == "INI" ){
		
		BFL = BFL|BFL_INIT;
		spawnWeapons();
		
	}
		
}

spawnWeapons(){

	llOwnerSay("@acceptpermission=add");
	// NO weapons when dead
	if(STATUS&StatusFlag$dead || FX_FLAGS&fx$F_DISARM || ~BFL&BFL_INIT || ~BFL&BFL_LOADED )
		return;
    
	Weapon$removeAll();
    
    // Rhand changed
    // Remove current weapon
    RHAND_ATT = "";
    
    if(RHAND != "" && llGetInventoryType(RHAND) == INVENTORY_OBJECT){
        // Spawn a new weapon
        llRezAtRoot(RHAND, llGetRootPosition()+llRot2Fwd(llGetRot())*2-<0,0,5>, ZERO_VECTOR, ZERO_ROTATION, getAttachSlot(TRUE));
    }
        
    // Remove current weapon
    LHAND_ATT = "";
    if(LHAND != "" && llGetInventoryType(LHAND) == INVENTORY_OBJECT){
        // Spawn a new weapon
        // 256 means it's left handed
        llRezAtRoot(LHAND, llGetRootPosition()+llRot2Fwd(llGetRot())*2-<0,0,5>, ZERO_VECTOR, ZERO_ROTATION, getAttachSlot(FALSE)|256);
    }
    multiTimer(["WC", "", 10, TRUE]);
}

default{

	on_rez( integer bap ){
	
		BFL = BFL&~BFL_INIT;
		
	}

    state_entry(){
        memLim(1.5);
        llListen(12, "", "", "");
        
        Weapon$removeAll();
        /*
        onEvt("got Bridge", BridgeEvt$userDataChanged, [
            "","","","","",1,"","","","","Iron Sword","Iron Sword"
        ]);
        */
        
		// Uncomment for debug
        //loadWeapon(hud$bridge$userData());
            
        if(llGetAttached()){
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_OVERRIDE_ANIMATIONS);
        }
		
		
    }
        
    run_time_permissions(integer perm){
        if(perm&PERMISSION_OVERRIDE_ANIMATIONS)
            llResetAnimationOverride("Standing");
    }
    
    timer(){multiTimer([]);}
    
    listen(integer chan, string name, key id, string message){
        idOwnerCheck
        
        // Scale and position the object
        if(llGetSubString(message,0,2) == "INI"){
            integer hand = (int)llGetSubString(message, 3, 3);

			int sheathed = BFL&BFL_SHEATHED || unsheatable;
            // Right hand
            if( hand == 0 ){

                // Remove if ID mismatch
                if( id != RHAND_ATT )
                    Weapon$remove(RHAND_ATT, "*");
                
                RHAND_ATT = id;
				
                // Send data
                Weapon$ini(id, getAttachSlot(TRUE), getAttachPos(TRUE), getAttachRot(TRUE), W_SCALE, sheathed);
				
            }
            
            else if(hand == 1){
                
                if(id != LHAND_ATT)
                    Weapon$remove(LHAND_ATT, "*");
                    
                LHAND_ATT = id;
                // Send data
                Weapon$ini(id, getAttachSlot(FALSE), getAttachPos(FALSE), getAttachRot(FALSE), W_SCALE, sheathed);
            }
            
            
        }
        
    }
	
	
	// Get FX
	#define LM_PRE \
	if(nr == TASK_FX){ \
		integer pre = FX_FLAGS; \
        FX_FLAGS = (int)fx$getDurEffect(fxf$SET_FLAG); \
        if( (pre&fx$F_DISARM) != (FX_FLAGS&fx$F_DISARM) ){ \
			if(FX_FLAGS&fx$F_DISARM){ \
				Weapon$removeAll(); \
			} \
			else \
				spawnWeapons(); \
		} \
	}
    
    #include "xobj_core/_LM.lsl"
    
    if(method$isCallback){
        return;
    }
    
    if(method$internal){
        
		if( METHOD == WeaponLoaderMethod$anim ){
            
			raiseEvent(WeaponLoaderEvt$attackAnim, "");

            list kit = ["attack_fists_1", "attack_fists_2", "attack_fists_3"];
			if( ANIM_SET != [] && !unsheatable )
				kit = ANIM_SET;
           
            string anim = randElem(kit);
            list out = [anim, anim+"_ub"];
            AnimHandler$anim(mkarr(out), TRUE, 0, 0, 0);

			if( W_SOUNDS )
				multiTimer(["SND", randElem(W_SOUNDS), 0.25, FALSE]);
				
        }
		
		else if(METHOD == WeaponLoaderMethod$remInventory){
			
			integer i;
			for(i=0; i<count(PARAMS); ++i){
				string n = method_arg(i);
				if(n != llGetScriptName() && llGetInventoryType(n) != INVENTORY_NONE){
					llRemoveInventory(n);
				}
			}
		
		}
		
    }
    
    if(method$byOwner){
		
		if( METHOD == WeaponLoaderMethod$fxStance ){
			
			str stance = l2s(PARAMS, 0);
			int begin = l2i(PARAMS, 1);
			int pos = llListFindList(FXS, (list)stance);
			if( (~pos && begin) || (pos == -1 && !begin) )
				return;
			
			if( begin )
				FXS += stance;
			else{
				
				// This was an AO set. Remove
				if( llJsonValueType(l2s(FXS, pos), []) == JSON_OBJECT ){
				
					list l = llJson2List(l2s(FXS, pos));
					integer i;
					for(; i<count(l); i += 2 )
						llResetAnimationOverride(l2s(l, i));
					
				}
				
				FXS = llDeleteSubList(FXS, pos, pos);
				
			}
			updateStance();
			
		}
	
        if( METHOD == WeaponLoaderMethod$toggleSheathe && ~STATUS&StatusFlag$dead ){
		
            integer n = l2i(PARAMS, 0);
			// True if we should sheathe
            integer sheathe = (n == -1 && ~BFL&BFL_SHEATHED) || n == 1;
			int pre = BFL;
			
			if( sheathe && STATUS & StatusFlag$combat )
				return;
			
			// Change sheathe state
			BFL = BFL&~BFL_SHEATHED;
			if( sheathe )
				BFL = BFL|BFL_SHEATHED;
			
			if((pre&BFL_SHEATHED) != (BFL&BFL_SHEATHED) && !unsheatable){
				// Animate draw/grab weapons
				// Do not draw weapons because this was a custom or class stance

				if( unsheatable )
					llTriggerSound("1c7916eb-8ceb-1e39-c88d-94d1eaa2deb5", .1);
				else{

					list anims = ["unsheathe", "unsheathe_ub"];
					AnimHandler$anim(mkarr(anims), TRUE, 0, 0, 0);
					llTriggerSound("d381de30-9ee8-e32f-8b5a-9f6f77e2c007", .5);
					
				}

				// Update the weapons
				if( !unsheatable )
					spawnWeapons();

				raiseEvent(WeaponLoaderEvt$sheathed, (str)((BFL&BFL_SHEATHED)>0));
				updateStance();
				
			}
            
        }
		
		// Calculate position offset and send to server. Also re-cache defaults
		else if(METHOD == WeaponLoaderMethod$storeOffset){
			// First figure out the weapon
			integer offhand;
			if(id == RHAND_ATT){}
			else if(id == LHAND_ATT)offhand = TRUE;
			else return;
			
			integer back = FALSE;
			vector p = (vector)method_arg(0);
			rotation r = (rotation)method_arg(1);
			if(BFL&BFL_SHEATHED){
			
				back = TRUE;
				// Back needs custom offsets. Equipped does not as it should always be ZERO_VECTOR by default
				if( offhand ){
				
					W_BACK_OFFHAND_POS = p;
					W_BACK_OFFHAND_ROT = r;
					p -= CUSTOM_BACK_OH_DEFAULT_POS;
					
				}
				else{
				
					W_BACK_MAINHAND_POS = p;
					W_BACK_MAINHAND_ROT = r;
					p -= CUSTOM_BACK_DEFAULT_POS;
					
				}
				
			}
			// In hands
			else{
			
				if(offhand){
				
					W_OFFHAND_POS = p;
					W_OFFHAND_ROT = r;
					
				}
				else{
				
					W_MAINHAND_POS = p;
					W_MAINHAND_ROT = r;
					
				}
				
			}
			Bridge$savePos(offhand, back, p, r);
		}
		// Send scale offset to server
		else if(METHOD == WeaponLoaderMethod$storeScale){
			if(l2f(PARAMS, 0)>0){
				Bridge$saveScale(l2f(PARAMS, 0));
				W_SCALE = l2f(PARAMS, 0);
			}
		}
		
    } 
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

