#define USE_EVENTS
#include "got/_core.lsl"

#define TIMER_CD_RESET "a"
#define TIMER_TRIGGER_RESET "b"

integer BFL;
#define BFL_CD 1
#define BFL_TRIGGERED 2
#define BFL_USE_SIT 4

float cooldown = 2;             // Time between trigger attempts
float cooldown_full = 20;        // Delay after trigger is successful
integer P_SEAT;
key sitter;
string base_anim;				// Loop
integer max_anims = 0;
integer cur_anim;

onEvt(string script, integer evt, string data){
    if(script == "got Portal" && evt == evt$SCRIPT_INIT){
        LocalConf$ini();
    }else if(script == "got LocalConf"){
        if(evt == LocalConfEvt$iniData){
            cooldown = (float)j(data,0);
            cooldown_full = (float)j(data,1);
        }
    }else if(script == "ton MeshAnim" && evt == MeshAnimEvt$frame){
		list split = llParseString2List(data, [";"], []);
		string type = llList2String(split, 0);
		string val = llList2String(split, 1);
		string sub = llList2String(split, 2);
		if(type == FRAME_ANIM){
			string anim = val;
			if(val == "*" && base_anim != "" && max_anims){
				anim = base_anim+"_"+(string)(cur_anim+1);
				cur_anim++;
				if(cur_anim>=max_anims)cur_anim = 0;
			}
			if(anim != "" && llGetPermissions()&PERMISSION_TRIGGER_ANIMATION)llStartAnimation(anim);
		}
		if(type == FRAME_AUDIO){
			if(val == "*")val = randElem((["e47ba69b-2b81-1ead-a354-fe8bb1b7f554", "9f81c0cb-43fc-6a56-e41e-7f932ceff1dc"]));
			if(llJsonValueType(val, []) == JSON_ARRAY)val = randElem(llJson2List(val));
			float vol = (float)sub;
			if(vol<=0)vol = .5+llFrand(.5);
			if(val)llTriggerSound(val, vol);
		}
	}
}

timerEvent(string id, string data){
    if(id == TIMER_CD_RESET)BFL = BFL&~BFL_CD;
    else if(id == TIMER_TRIGGER_RESET)BFL = BFL&~BFL_TRIGGERED;
}


default
{
    state_entry(){
		memLim(1.5);
        raiseEvent(evt$SCRIPT_INIT, "");
        links_each(nr, name,
            if(name == "SEAT"){
                P_SEAT = nr;
                llLinkSitTarget(P_SEAT, <0,0,.01>, ZERO_ROTATION);
            }
        )
		
		string base;
		integer i;
		for(i=0; i<llGetInventoryNumber(INVENTORY_ANIMATION) && base_anim == ""; i++){
			string name = llGetInventoryName(INVENTORY_ANIMATION, i);
			list spl = llParseString2List(name, ["_"], []);
			if(llList2Integer(spl, -1)>0)base_anim = llDumpList2String(llDeleteSubList(spl, -1, -1), "_");
			else base = name;
		}
		base_anim = base;
		
		if(base_anim){
			for(i=0; i<llGetInventoryNumber(INVENTORY_ANIMATION); i++){
				string name = llGetInventoryName(INVENTORY_ANIMATION, i);
				if(llGetSubString(name, 0, llStringLength(base_anim)-1) == base_anim && name != base_anim)max_anims++;
			}
				
		}
    }
    
    timer(){multiTimer([]);}
    
    changed(integer change){
        if(change&CHANGED_LINK && BFL&BFL_USE_SIT){
            if(llAvatarOnLinkSitTarget(P_SEAT)){
                BFL = BFL|BFL_TRIGGERED;
                sitter = llAvatarOnLinkSitTarget(P_SEAT);
                if(cooldown_full>0)multiTimer([TIMER_TRIGGER_RESET, "", cooldown_full, FALSE]);
                raiseEvent(TrapEvent$seated, "[\""+(string)sitter+"\"]");
				llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
            }else if(BFL&BFL_TRIGGERED){
                raiseEvent(TrapEvent$unseated, "[\""+(string)sitter+"\"]");
            }
        }
    }
	
	run_time_permissions(integer perm){
		if(base_anim != "" && perm & PERMISSION_TRIGGER_ANIMATION){
			llStartAnimation(base_anim);
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
    if(method$isCallback)return;
    if(method$internal){
        if(METHOD == TrapMethod$forceSit){
            BFL = BFL|BFL_USE_SIT;
            if(BFL&(BFL_CD|BFL_TRIGGERED))return;
            if(cooldown>0){
                BFL = BFL|BFL_CD;
                multiTimer([TIMER_CD_RESET, "", cooldown, FALSE]);
            }
			float dur = (float)method_arg(1);
            FX$send(method_arg(0), llGetKey(), "[1,0,0,0,["+(string)dur+",65,\"_Q\",[[13,16],[31,"+(string)llGetLinkKey(P_SEAT)+",0]],[],[],[],0,0,0]]");
            raiseEvent(TrapEvent$triggered, "");
        }
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}

