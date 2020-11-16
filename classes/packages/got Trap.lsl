/*
	
	This script is bad and clustered. Here is some documentation:
		
		
	- To use a quicktime event use Trap$useQTE(numTaps) or one of the conf qtes
	- Animations will be picked automatically for the player using "<anything>_<not_numeric>" as the base animation. And cycling between "<anything>_<numeric>"
		This means it will not support animesh by default. For animesh you must setup the animations manually in the INI_DATA
		After setting manual animations the subsequent animations will be calculated by the user animations
	- Seat will automatically use a prim named SEAT with sit target <0,0,0.01> ZERO_ROTATION
	- If no such prim is set it instead uses the root prim but does not assign a sit target. You must do that in localconf in that case.
	- Uses the prim "SPLAT" for splats. These work with legacy frame animations. For animesh you must emulate these frame events with TrapMethod$frame. Use "*" as data for automatic animation progression.
	


*/

#define USE_EVENTS
#include "got/_core.lsl"

#define TIMER_CD_RESET "a"			// Timer between allowing triggers
#define TIMER_TRIGGER_RESET "b"		// Retrigger timer

integer BFL;
#define BFL_CD 1
#define BFL_TRIGGERED 2

float cooldown = 2;             	// Time between trigger attempts
float cooldown_full = 20;        	// Delay after trigger is successful
list attachments;					// Names of things to attach on the victim

integer TRAP_FLAGS;

integer P_SEAT;
key sitter;
string base_anim;				// Loop
integer max_anims = 0;
integer cur_anim;
string animesh_anim;

integer QTE;					// QTE taps
int QTE_FLAGS;
float QTE_PRE_DELAY;
float QTE_BUTTON_DELAY;

key VICTIM;

list PLAYERS;

integer P_SPLAT;
onEvt(string script, integer evt, list data){

    if(script == "got Portal" && evt == evt$SCRIPT_INIT){
		PLAYERS = data;
        LocalConf$ini();
    }
	
	else if( script == "got LocalConf" ){
	
        if( evt == LocalConfEvt$iniData ){
		
            cooldown = l2f(data,TrapConf$triggerCooldown);
            cooldown_full = l2f(data,TrapConf$finishCooldown);
			attachments = llJson2List(l2s(data, TrapConf$attach));
			string d = l2s(data, TrapConf$baseAnim);
			if( isset(d) )
				base_anim = d;
			
			d = l2s(data, TrapConf$animeshAnim);
			if( isset(d) )
				animesh_anim = d;
			
			fetchSubAnims();
			debugUncommon("Got ini data: "+(str)cooldown+" :: "+(str)cooldown_full+" :: "+mkarr(attachments));
			
        }
		
    }
	
	else if((script == "ton MeshAnim" || script == "jas MaskAnim") && evt == MeshAnimEvt$frame){
	
		list split = llParseString2List(llList2String(data,0), [";"], []);
		string type = llList2String(split, 0);
		string val = llList2String(split, 1);
		string sub = llList2String(split, 2);
		
		if( type == FRAME_ANIM ){
		
			string anim = val;
			str obj_anim;
			
			if( val == "*" && max_anims ){
			
				if( base_anim )
					anim = base_anim+"_"+(string)(cur_anim+1);
				if( animesh_anim )
					animesh_anim = base_anim+"_"+(string)(cur_anim+1);
				
				cur_anim++;
				if( cur_anim >= max_anims )
					cur_anim = 0;
					
			}
			if( ~TRAP_FLAGS & Trap$fsFlags$noAnims ){
			
				if( anim != "" && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION )
					llStartAnimation(anim); 
				if( obj_anim ){
				
					llStopObjectAnimation(animesh_anim);
					llStartObjectAnimation(animesh_anim);
					
				}
				
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
		if( type == FRAME_AUDIO ){
		
			if( val == "*" )
				val = randElem((["e47ba69b-2b81-1ead-a354-fe8bb1b7f554", "9f81c0cb-43fc-6a56-e41e-7f932ceff1dc"]));
			if( llJsonValueType(val, []) == JSON_ARRAY )
				val = randElem(llJson2List(val));
			float vol = (float)sub;
			if( vol<=0 )
				vol = .5+llFrand(.5);
			if( val )
				llTriggerSound(val, vol);
				
		}
	}
}

timerEvent(string id, string data){
    
	if( id == TIMER_CD_RESET ){
	
		BFL = BFL&~BFL_CD;

		
	}
    else if( id == TIMER_TRIGGER_RESET ){
		
		BFL = BFL&~BFL_TRIGGERED;
		raiseEvent(TrapEvent$reset, "");
		
	}
	
}

// Automatically fetches sub animations
fetchSubAnims(){
	
	max_anims = 0;
	if( base_anim == "" )
		return;
		
	int i;
	for( ; i<llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
	
		string name = llGetInventoryName(INVENTORY_ANIMATION, i);
		if( llGetSubString(name, 0, llStringLength(base_anim)-1) == base_anim && name != base_anim )
			++max_anims;
		
	}
	
}

key getSitter(){
	links_each( nr, name,
		key t = llAvatarOnLinkSitTarget(nr);
		if(t)return t;
	)
	return NULL_KEY;
}

default{

    state_entry(){
	
		PLAYERS = [(str)llGetOwner()];
		memLim(1.5);
        raiseEvent(evt$SCRIPT_INIT, "");
        links_each(nr, name,
		
            if( name == "SEAT" ){
			
                P_SEAT = nr;
                llLinkSitTarget(P_SEAT, <0,0,.01>, ZERO_ROTATION);
				
            }
			else if( name == "SPLAT" )
				P_SPLAT = nr;
				
        )
		string base;
		integer i;
		for( ; i<llGetInventoryNumber(INVENTORY_ANIMATION) && base_anim == ""; ++i ){
		
			string name = llGetInventoryName(INVENTORY_ANIMATION, i);
			list spl = llParseString2List(name, ["_"], []);
			if( llList2Integer(spl, -1) > 0 )
				base_anim = llDumpList2String(llDeleteSubList(spl, -1, -1), "_");
			else 
				base = name;
			
		}
		base_anim = base;
		fetchSubAnims();
		
    }
    
    timer(){multiTimer([]);}
    
    changed(integer change){
		
        if( change & CHANGED_LINK ){
		
			key sitter = getSitter();
            if( sitter ){
			
				if( llListFindList(PLAYERS, [(str)sitter]) == -1 && portalConf$live ){
				
					debugCommon("Unsat because not a proper player")
					llUnSit(sitter);
					return;
					
				}
			
                BFL = BFL|BFL_TRIGGERED;
				VICTIM = sitter;
                raiseEvent(TrapEvent$seated, "[\""+(string)sitter+"\"]");
				
				llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
				
				debugCommon("Starting QTE: "+(str)QTE);
				if( QTE ){
					
					Evts$startQuicktimeEvent(sitter, QTE, QTE_PRE_DELAY, "a", QTE_BUTTON_DELAY, QTE_FLAGS);
					
				}
				
            }
			// Player unsat
			else if( BFL&BFL_TRIGGERED ){
				
				debugCommon("Player unsat");
				Evts$stopQuicktimeEvent(VICTIM);
                raiseEvent(TrapEvent$unseated, "[\""+(string)VICTIM+"\"]");
				if( cooldown_full > 0 )
					multiTimer([TIMER_TRIGGER_RESET, "", cooldown_full, FALSE]);
				fxlib$removeSpellByName(VICTIM, "_Q");
				
            }
			
        }
    }
	
	run_time_permissions(integer perm){

		if(base_anim != "" && perm & PERMISSION_TRIGGER_ANIMATION &&  ~TRAP_FLAGS & Trap$fsFlags$noAnims ){
			
			if( animesh_anim ){
				llStopObjectAnimation(animesh_anim);
				llStartObjectAnimation(animesh_anim);
				
			}
			
			llStopAnimation("sit");
			llStartAnimation(base_anim);
			
		}
		
	}
    
    #include "xobj_core/_LM.lsl"
    if(method$isCallback){
	
		if( SENDER_SCRIPT == "got Evts" && METHOD == EvtsMethod$startQuicktimeEvent ){
            integer type = l2i(PARAMS, 0);
            
            if(type == EvtsEvt$QTE$BUTTON)
                raiseEvent(TrapEvent$qteButton, l2s(PARAMS, 0));
            
			if( type == EvtsEvt$QTE$END ){
			
				debugCommon("Unsat because QTE end received from target")
                llUnSit(getSitter());
				
            }
			
        }
		return;
		
	}

	if( METHOD == TrapMethod$anim && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION ){
		
		str anim = method_arg(0);
		if( l2i(PARAMS, 1) )
			llStartAnimation(anim);
		else
			llStopAnimation(anim);
	
	}

    if( METHOD == TrapMethod$forceSit ){
	
		if( BFL&(BFL_CD|BFL_TRIGGERED) )
			return;
			
		if( cooldown>0 ){
		
			BFL = BFL|BFL_CD;
			multiTimer([TIMER_CD_RESET, "", cooldown, FALSE]);
			
		}
		
		float dur = (float)method_arg(1);
		key seat = llGetLinkKey(P_SEAT);
		if( (key)method_arg(2) )
			seat = (key)method_arg(2);
		if( seat == NULL_KEY )
			seat = llGetKey();
		
		TRAP_FLAGS = l2i(PARAMS, 3);

		// Strip
		integer f = fx$F_QUICKRAPE;
		if( TRAP_FLAGS&Trap$fsFlags$strip )
			f = f|fx$F_SHOW_GENITALS;
		if( TRAP_FLAGS&Trap$fsFlags$attackable ){
			f = f&~fx$F_QUICKRAPE;
		}

		string att = "";
		if( count(attachments) )
			att = ","+mkarr((list)fx$ATTACH+attachments);
		
		debugCommon("Force setting for "+(str)dur);
        FX$send(
			method_arg(0), 
			llGetKey(), 
			"[0,0,0,0,["+
				(string)dur+",65,\"_Q\",["+
					mkarr((list)fx$SET_FLAG+f)+","+
					mkarr((list)fx$FORCE_SIT+seat+1)+
					att+
				"]"+
			"]]", 
			TEAM_NPC
		);

        raiseEvent(TrapEvent$triggered, "");
		
		
    }
	
    if( METHOD == TrapMethod$useQTE ){
	
		QTE = l2i(PARAMS, 0);
			
		QTE_PRE_DELAY = l2f(PARAMS, 1);
		QTE_BUTTON_DELAY = l2f(PARAMS, 2);
		QTE_FLAGS = l2i(PARAMS, 3);
		
		if( count(PARAMS) < 2 )
			QTE_PRE_DELAY = 2;
		
		debugCommon("Using QTE "+(str)QTE)
		
	}
	
	if( METHOD == TrapMethod$frame )
		onEvt("ton MeshAnim", MeshAnimEvt$frame, PARAMS);
	
	if( METHOD == TrapMethod$end ){
		
		debugCommon("Unsat because method from "+SENDER_SCRIPT)
		llUnSit(getSitter());
		
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}

