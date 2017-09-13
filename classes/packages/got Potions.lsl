#define USE_EVENTS
#include "got/_core.lsl"
integer BFL;
#define BFL_CD 0x1

integer P_POTION;
#define POTION_POS <0.000000, 0.323226, 0.307781>

string NAME;
key TEXTURE;
integer CHARGES_REMAINING;
integer FLAGS;
float COOLDOWN;
string DATA;
#define onCooldownFinish() BFL = BFL&~BFL_CD
key ROOT_LEVEL;
onEvt(string script, integer evt, list data){
	if(script == "#ROOT" && evt == RootEvt$level){
		ROOT_LEVEL = llList2String(data,0);
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
	if(NAME == "" || FLAGS&PotionsFlag$no_drop)return;
	
	vector pos = llGetPos()+llRot2Left(llGetRot())*.3;
	rotation rot = llGetRot();
	if(FLAGS&PotionsFlag$is_in_hud){
		Spawner$spawnInt(NAME, pos, rot, "", FALSE, TRUE, ""); 
	}
	else if(FLAGS&PotionsFlag$raise_drop_event){
		Level$potionDropped(NAME);
	}
	else{
		LevelAux$spawnLiveTarg(ROOT_LEVEL, NAME, pos, rot);
	}
	
	raiseEvent(PotionsEvt$drop, NAME);
}


// Clears
remPotion(){
	NAME = "";
	TEXTURE = "";
	CHARGES_REMAINING = 0;
	FLAGS = 0;
	COOLDOWN = 0;
	DATA = "";
	hidePotionVisual();
}

setPotionVisual(key texture, integer stacks){
	if(stacks>9)stacks = 9;
	list data = [PRIM_POSITION, ZERO_VECTOR];
	if(texture){
		data = [
			PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
			PRIM_POSITION, POTION_POS, PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0, 
			PRIM_COLOR, 0, <1,1,1>, .5,
			PRIM_COLOR, 1, <1,1,1>, 1
		];
		if(stacks>0){
			data+=[
				PRIM_COLOR, 4, <1,1,1>, 1,
				PRIM_TEXTURE, 4, "cd23a6a1-3d0e-532c-4383-bf3e9b878d57", <1./10,1,0>, <1./20-1./10*(6-stacks), 0, 0>, 0
			];
		}
	}
	llSetLinkPrimitiveParamsFast(P_POTION, data);
}

hidePotionVisual(){
	PP(P_POTION, ([PRIM_POSITION, ZERO_VECTOR]));
}

setCDVisual(float cd){
	list out = [PRIM_COLOR, 2, <0,0,0>, 0];
	if(cd>0){
		llSetLinkTextureAnim(P_POTION, 0, 2, 16, 16, 0, 0, 0);
		out = [PRIM_COLOR, 2, <0,0,0>, .5, PRIM_TEXTURE, 2, "a0adbf17-dc55-9bd3-879e-4ba5527063b4", <1./16,1./16,0>, <1./32-1./16*8, 1./32-1./16*9, 0>,0];
		llSetLinkTextureAnim(P_POTION, ANIM_ON, 2, 16, 16, 0, 0, 16.*16./cd);
	}
	llSetLinkPrimitiveParamsFast(P_POTION, out);
}



default 
{
    // Timer event
    timer(){multiTimer([]);}
    
    state_entry(){
		memLim(1.5);
		links_each(nr, name,
			if(name == "POTION")P_POTION = nr;
		)
		hidePotionVisual();
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
		
		setPotionVisual(TEXTURE, CHARGES_REMAINING);
		raiseEvent(PotionsEvt$pickup, NAME);
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
		
		if(FLAGS&PotionsFlag$raise_event){
			Level$potionUsed(NAME);
		}
		
		raiseEvent(PotionsEvt$use, NAME);
		
		if(CHARGES_REMAINING <= 0 && CHARGES_REMAINING != -1){
			remPotion();
		}else{
			setPotionVisual(TEXTURE, CHARGES_REMAINING);
			if(COOLDOWN>0){
				BFL = BFL|BFL_CD;
				multiTimer(["CD", "", COOLDOWN, FALSE]);
				setCDVisual(COOLDOWN);
			}
		}
	}
    

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}


