#define USE_EVENTS
#include "got/_core.lsl"

#define TIMER_CD_RESET "a"
#define TIMER_TRIGGER_RESET "b"

integer BFL;
#define BFL_CD 1
#define BFL_TRIGGERED 2

float cooldown = 2;             // Time between trigger attempts
float cooldown_full = 20;        // Delay after trigger is successful
integer P_SEAT;
key sitter;
string base_anim;				// Loop
integer max_anims = 0;
integer cur_anim;

integer QTE;					// QTE taps

key VICTIM;

list PLAYERS;

integer P_SPLAT;
onEvt(string script, integer evt, list data){
    if(script == "got Portal" && evt == evt$SCRIPT_INIT){
		PLAYERS = data;
        LocalConf$ini();
    }else if(script == "got LocalConf"){
        if(evt == LocalConfEvt$iniData){
            cooldown = llList2Float(data,0);
            cooldown_full = llList2Float(data,1);
        }
    }else if((script == "ton MeshAnim" || script == "jas MaskAnim") && evt == MeshAnimEvt$frame){
		list split = llParseString2List(llList2String(data,0), [";"], []);
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
			if(anim != "" && llGetPermissions()&PERMISSION_TRIGGER_ANIMATION){
				llStartAnimation(anim); 
			}
			
			llLinkParticleSystem(P_SPLAT, [
                PSYS_PART_MAX_AGE,.4, 
                PSYS_PART_FLAGS, 
                    PSYS_PART_EMISSIVE_MASK|
                    PSYS_PART_INTERP_COLOR_MASK|
                    PSYS_PART_INTERP_SCALE_MASK|
                    
                    PSYS_PART_FOLLOW_VELOCITY_MASK
                    , 
                PSYS_PART_START_COLOR, <1, 1, 1.>, 
                PSYS_PART_END_COLOR, <1, 1, 1.>, 
                PSYS_PART_START_SCALE, <0., 0., 0>, 
                PSYS_PART_END_SCALE, <0.08, 0.3, 0>, 
                PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, 
                PSYS_SRC_BURST_RATE, 0.01, 
                PSYS_SRC_ACCEL, <0,0,-1>,  
                PSYS_SRC_BURST_PART_COUNT, 3, 
                PSYS_SRC_BURST_RADIUS, 0.03, 
                PSYS_SRC_BURST_SPEED_MIN, .0, 
                PSYS_SRC_BURST_SPEED_MAX, .5, 
                
                PSYS_SRC_OMEGA, <0., 0., 0.>, 
                PSYS_SRC_MAX_AGE, 0.25, 
                PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", 
                
                PSYS_PART_START_ALPHA, .3, 
                PSYS_PART_END_ALPHA, 0.0, 
                PSYS_PART_START_GLOW, 0.05,
                PSYS_PART_END_GLOW, 0.0,
                
                PSYS_SRC_ANGLE_BEGIN, PI_BY_TWO-.5, 
                PSYS_SRC_ANGLE_END, PI_BY_TWO-.5 

            ]);
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

key getSitter(){
	links_each( nr, name,
		key t = llAvatarOnLinkSitTarget(nr);
		if(t)return t;
	)
	return NULL_KEY;
}

default
{
    state_entry(){
		PLAYERS = [(str)llGetOwner()];
		memLim(1.5);
        raiseEvent(evt$SCRIPT_INIT, "");
        links_each(nr, name,
            if(name == "SEAT"){
                P_SEAT = nr;
                llLinkSitTarget(P_SEAT, <0,0,.01>, ZERO_ROTATION);
            }
			else if(name == "SPLAT")P_SPLAT = nr;
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
		
        if(change&CHANGED_LINK){
			key sitter = getSitter();
            if(sitter){
				if(llListFindList(PLAYERS, [(str)sitter]) == -1){
					llUnSit(sitter);
					return;
				}
			
                BFL = BFL|BFL_TRIGGERED;
				VICTIM = sitter;
                raiseEvent(TrapEvent$seated, "[\""+(string)sitter+"\"]");
				llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
				if(QTE){
					Evt$startQuicktimeEvent(sitter, QTE, 2, "a");
				}
            }else if(BFL&BFL_TRIGGERED){
				Evt$startQuicktimeEvent(VICTIM, 0,0, TNN);
                raiseEvent(TrapEvent$unseated, "[\""+(string)VICTIM+"\"]");
				if(cooldown_full>0)multiTimer([TIMER_TRIGGER_RESET, "", cooldown_full, FALSE]);
				fxlib$removeSpellByName(VICTIM, "_Q");
            }
        }
    }
	
	run_time_permissions(integer perm){
		if(base_anim != "" && perm & PERMISSION_TRIGGER_ANIMATION){
			llStopAnimation("sit");
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
    if(method$isCallback){
		if(SENDER_SCRIPT == "got Evts" && METHOD == EvtsMethod$startQuicktimeEvent){
            integer type = l2i(PARAMS, 0);
            
            if(type == EvtsEvt$QTE$BUTTON){
                raiseEvent(TrapEvent$qteButton, l2s(PARAMS, 0));
            }
            else if(type == EvtsEvt$QTE$END){
                llUnSit(getSitter());
            }
        }
		return;
	}

    if(METHOD == TrapMethod$forceSit){
            if(BFL&(BFL_CD|BFL_TRIGGERED))return;
            if(cooldown>0){
                BFL = BFL|BFL_CD;
                multiTimer([TIMER_CD_RESET, "", cooldown, FALSE]);
            }
			float dur = (float)method_arg(1);
			key seat = llGetLinkKey(P_SEAT);
			if((key)method_arg(2))seat = (key)method_arg(2);
			if(seat == NULL_KEY)
				seat = llGetKey();
			
			// Strip
			integer strip = 0;
			if(l2i(PARAMS, 3))strip = fx$F_SHOW_GENITALS;
		
        FX$send(method_arg(0), llGetKey(), "[1,0,0,0,["+(string)dur+",65,\"_Q\",[[13,"+(str)(16|strip)+"],[31,"+(string)seat+",1]],[],[],[],0,0,0]]", TEAM_NPC);
        raiseEvent(TrapEvent$triggered, "");
    }
    if(METHOD == TrapMethod$useQTE){
		QTE = l2i(PARAMS, 0);
	}
	
	if(METHOD == TrapMethod$end){
		llUnSit(getSitter());
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}

