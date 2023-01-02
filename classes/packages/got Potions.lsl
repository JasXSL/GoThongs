#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"
integer BFL;
#define BFL_CD 0x1

integer P_POTION;
#define POTION_POS <0.000000, 0.323226, 0.307781>
integer P_POTION_INSPECT;

string PRIM;
string NAME;
key TEXTURE;
integer CHARGES_REMAINING;
integer FLAGS;
float COOLDOWN;
string DESC;
string DATA;
#define onCooldownFinish() BFL = BFL&~BFL_CD
key ROOT_LEVEL;

#define hidePotionVisual() setPotionVisual("", 0)

onEvt(string script, integer evt, list data){

	if( script == "#ROOT" && evt == RootEvt$level )
		ROOT_LEVEL = llList2String(data,0);
	
}

timerEvent(string id, string data){

	if(id == "CD")
		onCooldownFinish();
	
	else if(id == "DROP"){
	
		dropPotion();
		remPotion();
		
	}
	
}

dropPotion(){

	if( PRIM == "" || FLAGS&PotionsFlag$no_drop )
		return;
	
	vector pos = llGetRootPosition()+llRot2Left(llGetRot())*.3;
	rotation rot = llGetRot();
	if(FLAGS&PotionsFlag$is_in_hud)
		Spawner$spawnInt(PRIM, pos, rot, "[\"M\"]", FALSE, TRUE, "POTS"); 
	else if( FLAGS&PotionsFlag$raise_drop_event )
		Level$potionDropped(PRIM);
	else
		LevelAux$spawnTarg(ROOT_LEVEL, PRIM, pos, rot, FALSE, "[\"M\"]", "POTS");
	
	
	raiseEvent(PotionsEvt$drop, PRIM);
	
}


// Clears
remPotion(){

	PRIM = "";
	NAME = "";
	TEXTURE = "";
	CHARGES_REMAINING = 0;
	FLAGS = 0;
	COOLDOWN = 0;
	DATA = "";
	hidePotionVisual();
	
}

setPotionVisual( key texture, integer stacks ){

	if( stacks>9 )
		stacks = 9;
	list data = [PRIM_POSITION, ZERO_VECTOR, PRIM_LINK_TARGET, P_POTION_INSPECT, PRIM_POSITION, ZERO_VECTOR];
	
	if( texture ){
	
		data = [
			PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
			PRIM_POSITION, POTION_POS, PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0, 
			PRIM_COLOR, 0, <1,1,1>, .5,
			PRIM_COLOR, 1, <1,1,1>, 1
		];
		
		if( stacks > 1 ){
		
			data+=[
				PRIM_COLOR, 4, <1,1,1>, 1,
				PRIM_TEXTURE, 4, "cd23a6a1-3d0e-532c-4383-bf3e9b878d57", <1./10,1,0>, <1./20-1./10*(6-stacks), 0, 0>, 0
			];
			
		}
		
		data += (list)PRIM_LINK_TARGET + P_POTION_INSPECT +
			PRIM_TEXTURE + 1 + "1be22f40-217b-8379-86d0-4145f7ce4893" + ONE_VECTOR + ZERO_VECTOR + 0 +
			PRIM_COLOR + ALL_SIDES + ONE_VECTOR + 0 +
			PRIM_COLOR + 1 + ONE_VECTOR + 1 +
			PRIM_COLOR + 0 + ONE_VECTOR + 0.5 +
			PRIM_POSITION + (POTION_POS+<-.1,0.025,-.012>)
		;
		
	}
	
	llSetLinkPrimitiveParamsFast(P_POTION, data);
	
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



default {

    // Timer event
    timer(){multiTimer([]);}
    
    state_entry(){
	
		memLim(1.5);
		links_each(nr, name,
			
			if( name == "POTION" )
				P_POTION = nr;
			else if( name == "POT_INSPECT" )
				P_POTION_INSPECT = nr;
			
		)
		hidePotionVisual();
		
		
	}
	
	touch_start( integer total ){
		detOwnerCheck
        
		integer nr = llDetectedLinkNumber(0);
		if( nr == P_POTION )
			multiTimer(["DROP", "", 1, FALSE]);
		
		if( nr == P_POTION_INSPECT ){
		
			string name = NAME;
			if( name == "" )
				name = "Unknown item";
			string desc = DESC;
			if( desc == "" )
				desc = "Unknown effect.";
			Alert$freetext(LINK_ROOT, name+": "+desc, FALSE, TRUE);
			
		}
		
	}
	
	touch_end( integer total ){
		detOwnerCheck
		
        int nr = llDetectedLinkNumber(0);
		if( nr == P_POTION ){
		
			multiTimer(["DROP"]);
			Potions$use((string)LINK_ROOT);
			
		}
		
	}
		
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    if( method$isCallback )
        return;
    

	// public
	if( METHOD == PotionsMethod$setPotion ){
	
		//qd("Name is "+NAME+" Received from "+SENDER_SCRIPT);
		if( NAME != "" )
			dropPotion();
		
		
		NAME = method_arg(0);
		TEXTURE = method_arg(1); 
		CHARGES_REMAINING = (int)method_arg(2);
		FLAGS = (int)method_arg(3); 
		COOLDOWN = (float)method_arg(4);
		DATA = method_arg(5);
		DESC = method_arg(6);
		PRIM = method_arg(7);
		
		if( PRIM == "" )
			PRIM = NAME;
		//qd("Setting potion");
		
		if( CHARGES_REMAINING == 0 )
			CHARGES_REMAINING = 1;
		
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
		
		if( NAME == "" || BFL&BFL_CD )
			return;
			
		if( ~CHARGES_REMAINING )
			CHARGES_REMAINING --;
		
		FX$run(llGetOwner(), DATA);
		
		if( FLAGS&PotionsFlag$raise_event )
			Level$potionUsed(NAME);
		
		
		raiseEvent(PotionsEvt$use, NAME);
		
		if( CHARGES_REMAINING <= 0 && CHARGES_REMAINING != -1 )
			remPotion();
		
		else{
		
			setPotionVisual(TEXTURE, CHARGES_REMAINING);
			if( COOLDOWN>0 ){
			
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


