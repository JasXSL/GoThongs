#define USE_EVENTS
#include "got/_core.lsl"
integer BFL;
#define BFL_CD 0x1

string NAME;
key TEXTURE;
integer CHARGES_REMAINING;
integer FLAGS;
float COOLDOWN;
string DATA;
#define onCooldownFinish() BFL = BFL&~BFL_CD
key level;
onEvt(string script, integer evt, string data){
	if(script == "#ROOT" && evt == RootEvt$level){
		level = j(data,0);
	}
}

timerEvent(string id, string data){
	if(id == "CD"){
		onCooldownFinish();
	}
	else if(id == "DROP"){
		dropPotion();
		remPotion();
		//qd("Potion cleared");
	}
}

dropPotion(){
	if(NAME == "")return;
	vector pos = llGetPos()+llRot2Left(llGetRot())*.3;
	rotation rot = llGetRot();
	if(FLAGS&PotionsFlag$is_in_hud){
		Spawner$spawnInt(NAME, pos, rot, "", FALSE, TRUE); 
	}else{
		Level$spawnLiveTarg(level, NAME, pos, rot);
	}
}


// Clears
remPotion(){
	NAME = "";
	TEXTURE = "";
	CHARGES_REMAINING = 0;
	FLAGS = 0;
	COOLDOWN = 0;
	DATA = "";
	GUI$togglePotion("", 0);
}

default 
{
    // Timer event
    timer(){multiTimer([]);}
    
    state_entry(){
		memLim(1.5);
		GUI$togglePotion(TEXTURE, CHARGES_REMAINING);
	}
	
	touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
        string ln = llGetLinkName(llDetectedLinkNumber(0));
		if(ln == "POTION"){
			multiTimer(["DROP", "", 1, FALSE]);
		}
	}
	
	touch_end(integer total){
		if(llDetectedKey(0) != llGetOwner())return;
        string ln = llGetLinkName(llDetectedLinkNumber(0));
		if(ln == "POTION"){
			multiTimer(["DROP"]);
			Potions$use((string)LINK_ROOT);
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

	// public
	if(METHOD == PotionsMethod$setPotion){
		//qd("Name is "+NAME+" Received from "+SENDER_SCRIPT);
		if(FLAGS&PotionsFlag$no_drop)return;
		if(NAME != ""){
			dropPotion();
		}
		
		NAME = method_arg(0);
		TEXTURE = method_arg(1); 
		CHARGES_REMAINING = (int)method_arg(2);
		FLAGS = (int)method_arg(3); 
		COOLDOWN = (float)method_arg(4);
		DATA = method_arg(5);
		
		//qd("Setting potion");
		
		if(CHARGES_REMAINING == 0)CHARGES_REMAINING = 1;
		
		GUI$togglePotion(TEXTURE, CHARGES_REMAINING);
		
    }
	else if(METHOD == PotionsMethod$resetCooldown){
		
		onCooldownFinish();
	}
	else if(METHOD == PotionsMethod$remove){
		//qd("Remove method gotten");
		if(FLAGS&PotionsFlag$no_drop && !(int)method_arg(1))return;
		if(NAME != "" && PotionsFlag$no_drop && (int)method_arg(0)){
			dropPotion();
		}
		remPotion();
	}
	else if(METHOD == PotionsMethod$use){
		if(NAME == "" || BFL&BFL_CD)return;
		if(~CHARGES_REMAINING)CHARGES_REMAINING --;
		FX$run(llGetOwner(), DATA);
		
		if(CHARGES_REMAINING <= 0 && CHARGES_REMAINING != -1){
			remPotion();
		}else{
			GUI$togglePotion(TEXTURE, CHARGES_REMAINING);
			if(COOLDOWN>0){
				BFL = BFL|BFL_CD;
				multiTimer(["CD", "", COOLDOWN, FALSE]);
				GUI$potionCD(COOLDOWN);
			}
		}
	}
    

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}


