#define USE_EVENTS
#include "got/_core.lsl"


integer STATUS; // Flags from got Status

integer BFL = 0x1;
#define BFL_SHEATHED 0x1

integer WFLAGS;
#define WFLAG_UNSHEATHABLE 0x8

string RHAND;
key RHAND_ATT;

string LHAND;
key LHAND_ATT;

float W_SCALE = 1;

list W_SOUNDS;


// FX
integer FX_FLAGS;

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

integer ANIM_SET;

rotation BACK_DEFAULT_ROT = <0.00000, 0.00000, 0.53730, 0.84339>;
vector BACK_DEFAULT_POS = <-0.11448, -0.37465, -0.04116>;
rotation BACK_OH_DEFAULT_ROT = <0.00000, 0.00000, 0.84339, 0.53730>;
vector BACK_OH_DEFAULT_POS = <0.11448, -0.37465, -0.04116>;

onEvt(string script, integer evt, list data){
    
    if(script == "got Bridge" && evt == BridgeEvt$userDataChanged){
        
        loadWeapon(data);
        
    }
    
    if(script == "got Status" && evt == StatusEvt$flags){
        integer pre = STATUS;
        STATUS = l2i(data, 0);
        
        if(pre&StatusFlag$dead && ~STATUS&StatusFlag$dead){
            // Rape ended
            spawnWeapons();
        }
        else if(~pre&StatusFlag$dead && STATUS&StatusFlag$dead){
            // Remove weapons
            Weapon$removeAll();
        }
    }
    
}

loadWeapon(list data){
    W_SCALE = l2f(data, BSUD$W_SCALE);
    
    // Avatar settings
    vector mainhand_offset = (vector)l2s(data, BSUD$W_MH_OFFSET);
    vector mainhand_back_offset = (vector)l2s(data, BSUD$W_BACK_MH_OFFSET);
    vector offhand_offset = (vector)l2s(data, BSUD$W_OH_OFFSET);
    vector offhand_back_offset = (vector)l2s(data, BSUD$W_BACK_OH_OFFSET);
    
    list wdata = llJson2List(l2s(data, BSUD$WDATA));
    string rhand = l2s(wdata, 0);
    string lhand = l2s(wdata, 1);
    WFLAGS = l2i(wdata, 4);
    
    ANIM_SET = l2i(wdata, 3);
    
    W_MAINHAND_SLOT = l2i(wdata, 6);
    W_OFFHAND_SLOT = l2i(wdata, 7);
	
	W_SOUNDS = llJson2List(l2s(wdata, 12));
    
    /*
        Not yet supported
        W_OFFHAND_ROT;
        W_MAINHAND_ROT = ;
    */
    
    // Main hand offsets default to ZERO_VECTOR/ZERO_ROTATION, so we can just use the stuff from the avatar
    W_MAINHAND_POS = mainhand_offset;
    W_OFFHAND_POS = offhand_offset;
    
    // Calculate back positions. Back position use OFFSETS
    vector add = BACK_DEFAULT_POS;
    if((vector)l2s(wdata, 10))
        add = (vector)l2s(wdata, 10);
    W_BACK_MAINHAND_POS = mainhand_offset+add;
    
    add = BACK_OH_DEFAULT_POS;
    if((vector)l2s(wdata, 11)){
        add = (vector)l2s(wdata, 11);
    }
    W_BACK_OFFHAND_POS = offhand_offset+add;
    
    
    
    // Rotations are fixed, set to default
    W_BACK_MAINHAND_ROT = BACK_DEFAULT_ROT;
    W_BACK_OFFHAND_ROT = BACK_OH_DEFAULT_ROT;
    
    // Check if custom exists for this particular weapon
    if((rotation)l2s(wdata, 8)){
        W_BACK_MAINHAND_ROT = (rotation)l2s(wdata, 8);
    }
    if((rotation)l2s(wdata, 9)){
        W_BACK_OFFHAND_ROT = (rotation)l2s(wdata, 9);
    }
    // Check if custom exists from DB (Not yet in DB)
    
    if(WFLAGS&WFLAG_UNSHEATHABLE) 
        BFL = BFL|BFL_SHEATHED;
    
    if(rhand != RHAND || lhand != LHAND){
        RHAND = rhand;
        LHAND = lhand;
        spawnWeapons();
    }

    raiseEvent(WeaponLoaderEvt$sheathed, (str)((BFL&BFL_SHEATHED)>0));
}

// Returns an attachment slot
integer getAttachSlot(integer rhand){
    if(BFL&BFL_SHEATHED || WFLAGS&WFLAG_UNSHEATHABLE)
        return ATTACH_BACK;
    if(rhand)
        return W_MAINHAND_SLOT;
    return W_OFFHAND_SLOT;
}

// Returns the position
vector getAttachPos(integer rhand){
    if(BFL&BFL_SHEATHED || WFLAGS&WFLAG_UNSHEATHABLE){
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
    
    if(BFL&BFL_SHEATHED || WFLAGS&WFLAG_UNSHEATHABLE){
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
}

spawnWeapons(){
	// NO weapons when dead
	if(STATUS&StatusFlag$dead || FX_FLAGS&fx$F_DISARM)
		return;
    
	Weapon$removeAll();
    
    // Rhand changed
    // Remove current weapon
    RHAND_ATT = "";
    
    
    if(RHAND != "" && llGetInventoryType(RHAND) == INVENTORY_OBJECT){
        // Spawn a new weapon
        llRezAtRoot(RHAND, llGetPos()+llRot2Fwd(llGetRot())*2-<0,0,5>, ZERO_VECTOR, ZERO_ROTATION, getAttachSlot(TRUE));
    }
        
    // Remove current weapon
    LHAND_ATT = "";
    if(LHAND != "" && llGetInventoryType(LHAND) == INVENTORY_OBJECT){
        // Spawn a new weapon
        // 256 means it's left handed
        llRezAtRoot(LHAND, llGetPos()+llRot2Fwd(llGetRot())*2-<0,0,5>, ZERO_VECTOR, ZERO_ROTATION, getAttachSlot(FALSE)|256);
    }
    multiTimer(["WC", "", 10, TRUE]);
}

default
{
    state_entry()
    {
        memLim(1.5);
        llListen(12, "", "", "");
        
        Weapon$removeAll();
        /*
        onEvt("got Bridge", BridgeEvt$userDataChanged, [
            "","","","","",1,"","","","","Iron Sword","Iron Sword"
        ]);
        */
        if(llGetOwner() == "cf2625ff-b1e9-4478-8e6b-b954abde056b")
            loadWeapon(llJson2List(Bridge$userData()));
            
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

            // Right hand
            if(hand == 0){

                // Remove if ID mismatch
                if(id != RHAND_ATT)
                    Weapon$remove(RHAND_ATT, "*");
                
                RHAND_ATT = id;                
                // Send data
                Weapon$ini(id, getAttachSlot(TRUE), getAttachPos(TRUE), getAttachRot(TRUE), W_SCALE);
            }
            
            else if(hand == 1){
                
                if(id != LHAND_ATT)
                    Weapon$remove(LHAND_ATT, "*");
                    
                LHAND_ATT = id;
                // Send data
                Weapon$ini(id, getAttachSlot(FALSE), getAttachPos(FALSE), getAttachRot(FALSE), W_SCALE);
            }
            
            
        }
        
    }
	
	
	// Get FX
	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		integer pre = FX_FLAGS; \
        FX_FLAGS = llList2Integer(data, FXCUpd$FLAGS); \
        if((pre&fx$F_DISARM) != (FX_FLAGS&fx$F_DISARM)){ \
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
        
		if(METHOD == WeaponLoaderMethod$anim){
            
			raiseEvent(WeaponLoaderEvt$attackAnim, "");
			
			
			
            list kit = ["attack_fists_1", "attack_fists_2", "attack_fists_3"];
            // 2handed
            if(ANIM_SET == 1){
                kit = ["stance_2h_1", "stance_2h_2", "stance_2h_3"];
            }
            // Piercing
            if(ANIM_SET == 4){
                kit = ["stance_1hpierce_1","stance_1hpierce_2","stance_1hpierce_3","stance_1hpierceoh_1","stance_1hpierceoh_2"];
            }
            
            // One handed default
            if(ANIM_SET == 2 || ANIM_SET == 3){
                kit = ["stance_1h_1", "stance_1h_2", "stance_1h_3"];
            }
            // Dual wield slash
            if(ANIM_SET == 3){
                kit+= ["stance_1hoh_1", "stance_1hoh_2"];
            }
            
            string anim = randElem(kit);
            list out = [anim, anim+"_ub"];
            AnimHandler$anim(mkarr(out), TRUE, 0, 0);
            
            if(BFL&BFL_SHEATHED){
                WeaponLoader$toggleSheathe(LINK_THIS, 0);
            }
			
			if(W_SOUNDS)
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
        if(METHOD == WeaponLoaderMethod$toggleSheathe && ~STATUS&StatusFlag$dead){
            integer n = l2i(PARAMS, 0);
            
            // True if we should sheathe
            integer sheathe = (n == -1 && ~BFL&BFL_SHEATHED) || n == 1;
            
            // Limit updates to change
            if(
                (!sheathe && BFL&BFL_SHEATHED) ||
                (sheathe && ~BFL&BFL_SHEATHED)
            ){
                if(ANIM_SET == 0){
                    llTriggerSound("1c7916eb-8ceb-1e39-c88d-94d1eaa2deb5", .1);
                }else{
                    list anims = ["unsheathe", "unsheathe_ub"];
                    AnimHandler$anim(mkarr(anims), TRUE, 0, 0);
                    llTriggerSound("d381de30-9ee8-e32f-8b5a-9f6f77e2c007", .5);
                }
                BFL = BFL&~BFL_SHEATHED;
                if(sheathe){
                    BFL = BFL|BFL_SHEATHED;
                }
                // Update the weapons
                if(~WFLAGS&WFLAG_UNSHEATHABLE)
                    spawnWeapons();
					
				raiseEvent(WeaponLoaderEvt$sheathed, (str)((BFL&BFL_SHEATHED)>0));
            }
            
            // Animations
            integer p = llGetPermissions()&PERMISSION_OVERRIDE_ANIMATIONS;
            list anim = ["stance_fists", "stance_2h", "stance_1h", "stance_1h", "stance_1h", "stance_1h"];
            
            if(!p)return;
            if(!sheathe){
                llSetAnimationOverride( "Standing", l2s(anim, ANIM_SET) );
            }
            else{
                llResetAnimationOverride("Standing");
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
				if(offhand){
					W_BACK_OFFHAND_POS = p;
					W_BACK_OFFHAND_ROT = r;
					p -= BACK_OH_DEFAULT_POS;
				}
				else{
					W_BACK_MAINHAND_POS = p;
					W_BACK_MAINHAND_ROT = r;
					p -= BACK_DEFAULT_POS;
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

