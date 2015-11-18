#define USE_EVENTS
#define USE_SHARED [BridgeSpells$name, "#ROOT", "got Status"]
#include "got/_core.lsl"


// This is the actual spell data cached
list CACHE;
#define spellWrapper(data) llList2String(data, 0)
#define spellSelfcast(data) llList2String(data, 1)
#define spellRange(data) llList2Float(data, 2)
#define spellFlags(data) llList2Integer(data, 3)

#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)

list CACHE_MANA_COST = [0,0,0,0]; 	// Mana cost of all but rest
integer CACHE_LOW_MANA = 0;		// Bitfield of 0000 spells with higher mana cost than mana cache


// Contains the fx data
#define CSTRIDE 4

list FX_CACHE;
#define FXSTRIDE 5
#define fxc$rezzable 0
#define fxc$finishAnim 1
#define fxc$finishSound 2
#define fxc$castAnim 3
#define fxc$castSound 4



// Contains particles
list PARTICLE_CACHE;
#define fxp$timeout 0
#define fxp$prim 1
#define fxp$particles 2
#define PSTRIDE 3

// Caching
float CACHE_AROUSAL;
float CACHE_PAIN;
float CACHE_CRIT;
key CACHE_THONG;

// Flags from got Status
integer STATUS_FLAGS;

list PLAYERS;
list SPELL_ANIMS;

// FX
float dmdmod = 1;       // Damage done
float critmod = 0;

// Abil prims
list ABILS = [0,0,0,0,0];
#define ABIL_BORDER_COLOR <.6, .6, .6>
#define ABIL_BORDER_ALPHA .5

string runMath(string FX){
    list split = llParseString2List(FX, ["$MATH$"], []);
    float pmod = 1;
    if(llList2Key(PLAYERS, 1))pmod = .5;
    float aroused = 1;
    if(STATUS_FLAGS&StatusFlag$aroused)aroused = .5;
	
	string consts = llList2Json(JSON_OBJECT, [
        "D", (dmdmod*pmod*aroused*CACHE_CRIT),
		"A", CACHE_AROUSAL,
		"P", CACHE_PAIN
    ]);
	
	
    integer i;
    for(i=1; i<llGetListLength(split); i++){
        split = llListReplaceList(split, [llGetSubString(llList2String(split, i-1), 0, -2)], i-1, i-1);
        string block = llList2String(split, i);
        integer q = llSubStringIndex(block, "\"");
        string math = llGetSubString(block, 0, q-1);
        block = llGetSubString(block, q+1, -1);
        float m = mathToFloat(math, 0, consts);
		split = llListReplaceList(split, [(string)m+block], i, i);
    }
    return llDumpList2String(split, "");
}

onEvt(string script, integer evt, string data){
    if(script == "#ROOT"){
        if(evt == RootEvt$players)
            PLAYERS = llJson2List(data);
		else if(evt == RootEvt$thongKey){
			CACHE_THONG = data;
			if(CACHE_THONG == ""){
				toggleSpellButtons(FALSE);
			}
		}
    }else if(script == "got Status"){
		if(evt == StatusEvt$flags){
			integer pre = STATUS_FLAGS;
			STATUS_FLAGS = (integer)data;
			
			integer hideOn = (StatusFlag$dead|StatusFlag$loading);
			
			if((!(pre&hideOn) && STATUS_FLAGS&hideOn) || (pre&hideOn && !(STATUS_FLAGS&hideOn))){
				toggleSpellButtons(TRUE);		// Auto hides if dead. So we can just go with TRUE for both cases
			}
		}
	}
    else if(script == "got FXCompiler" && evt == FXCEvt$update){
        dmdmod = (float)j(data, FXCUpd$DAMAGE_DONE);
		critmod = (float)j(data, FXCUpd$CRIT);
	}
}


toggleSpellButtons(integer show){
	integer i; list out;
	if(!show || STATUS_FLAGS&(StatusFlag$dead|StatusFlag$loading)){
        for(i=0; i<llGetListLength(ABILS); i++){
            out += [
                PRIM_LINK_TARGET, llList2Integer(ABILS, i),
                PRIM_POSITION, ZERO_VECTOR,
                PRIM_COLOR, 2, <1,1,1>, 0
            ];
        }
    }else{
        for(i=0; i<llGetListLength(ABILS); i++){
            vector pos = <0, 0.29586-0.073965-0.14793*(i-1), .31>;
            if(i == 0)pos = <0,0,.27>;
            out += [
                PRIM_LINK_TARGET, llList2Integer(ABILS, i),
                PRIM_POSITION, pos,
                PRIM_COLOR, 0, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA,
                PRIM_COLOR, 1, <1,1,1>, 1, 
                PRIM_COLOR, 3, <0,0,0>, 0,
                PRIM_COLOR, 4, <0,0,0>, 0,
                PRIM_COLOR, 5, <0,0,0>, 0
            ];
        }
    }
	llSetLinkPrimitiveParamsFast(0, out);
}


setAbilitySpinner(integer abil, float time, integer reverse){
    float total = (4.*32)/time;
            
    integer flags;
    float borderalpha = 1;
    vector border = <1,1,1>;
    vector color = <.5,1,.5>;
    if(reverse){
		color = <0,0,0>;
        border = <0,0,0>;
        borderalpha = 0.1;
        flags = REVERSE;
    }
    
    float width = .25; float height = 1./32;

    llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil+1), [
		PRIM_COLOR,0,border,borderalpha, PRIM_COLOR, 2, color, 1
	]);
    llSetLinkTextureAnim(llList2Integer(ABILS, abil+1), 0, 2, 4,32, 0,32, total);
	llSetLinkTextureAnim(llList2Integer(ABILS, abil+1), ANIM_ON|flags, 2, 4,32, 0,0, total);
}

#define stopCast(abil) llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil+1), [PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0,ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA])

default
{
	state_entry(){
		db2$ini();
		list out;
		links_each(nr, name, 
            integer n = (integer)llGetSubString(name, -1, -1); 
            if(llGetSubString(name, 0, 3) == "Abil"){
                ABILS = llListReplaceList(ABILS, [nr], n, n);
				
				float width = 1./4;
				float height = 1./32;
				out+= ([
					PRIM_LINK_TARGET, nr,
					PRIM_TEXTURE, 2, "0c2f81c7-8ecf-92ab-0351-6bbe109f0d0a", <width,height,0>, <-llFloor(4/2)*width+width/2+width, llFloor(32/2)*height-height/2-height, 0>, 0,
					PRIM_COLOR, 2, <1,1,1>, 1
				]);
				
			}
        )
		llSetLinkPrimitiveParamsFast(0, out);
		toggleSpellButtons(FALSE);
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
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback)
        return;
    
    if(method$internal){
	// SCRIPTME 
		// Visuals

		if(METHOD == SpellAuxMethod$setCooldown){
            setAbilitySpinner((integer)method_arg(0), (float)method_arg(1), TRUE);
        }
        else if(METHOD == SpellAuxMethod$stopCast){
            stopCast((integer)method_arg(0));
            
        }
		else if(METHOD == SpellAuxMethod$setGlobalCooldowns){

            integer cds = (integer)method_arg(1);
            float time = (float)method_arg(0);
            list out;
			
            integer i;
            for(i=0; i<5; i++){
				integer cd = getBitArr(cds, i, 2);
				// -1 = leave undecided, 0 = remove, 1 = add
                if(cd == 2){
                    llSetLinkTextureAnim(llList2Integer(ABILS, i), 0, 2, 4,32, 0,32, 0);
                    out+= [PRIM_LINK_TARGET, llList2Integer(ABILS, i), PRIM_COLOR,0,ZERO_VECTOR,.1, PRIM_COLOR, 2, ZERO_VECTOR, 1];
                    llSetLinkTextureAnim(llList2Integer(ABILS, i), ANIM_ON|REVERSE, 2, 4,32, 0,0, (4.*32)/time);
                }else if(cd == 1)
                    out+= [PRIM_LINK_TARGET, llList2Integer(ABILS, i), PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0,ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA];
            }
            llSetLinkPrimitiveParamsFast(0, out);
        }
	
	
        else if(METHOD == SpellAuxMethod$spellEnd){
            list_shift_each(SPELL_ANIMS, v, 
				if(isset(v))
					AnimHandler$anim(v, FALSE, 0);
            )
        }
		
		
		// This is a special thing got Status sends this
		else if(METHOD == SpellAuxMethod$statusCache){
			float mana = (float)method_arg(0);
			integer i;
			
			list out;
			for(i=0; i<4; i++){
				integer nr = (integer)llPow(i+1, 2);
				float cost = llList2Float(CACHE_MANA_COST, i);
				if(~CACHE_LOW_MANA&nr && cost>mana){
					CACHE_LOW_MANA = CACHE_LOW_MANA|nr;
					out+= [
						PRIM_LINK_TARGET, llList2Integer(ABILS, i+1),
						PRIM_COLOR, 1, <1,1,1>, .5
					];
				}else if(CACHE_LOW_MANA&nr && cost <= mana){
					CACHE_LOW_MANA = CACHE_LOW_MANA&~nr;
					out+= [
						PRIM_LINK_TARGET, llList2Integer(ABILS, i+1),
						PRIM_COLOR, 1, <1,1,1>, 1
					];
				}
				
			}
			
			llSetLinkPrimitiveParamsFast(0, out);
		}
        else if(METHOD == SpellAuxMethod$startCast){
            integer nr = (integer)method_arg(0);
			float ct = (float)method_arg(1);
			
			if(ct>0)
				setAbilitySpinner(nr, ct, FALSE);
			
            list data; list visual;
            
            // NOT rest
            if(~nr){
                data = nrToData(nr);
                visual = llList2List(FX_CACHE, nr*FXSTRIDE, nr*FXSTRIDE+FXSTRIDE-1);
                // particles
                list p = llList2List(PARTICLE_CACHE, nr*PSTRIDE, nr*PSTRIDE+PSTRIDE-1);
                
                if(llList2String(p,2) != JSON_INVALID)
                    ThongMan$particles(llList2Float(p, fxp$timeout), llList2Integer(p, fxp$prim), llList2String(p, fxp$particles));
            }
            
            list anims = [llList2String(visual, fxc$castAnim)];
            if(llJsonValueType((string)anims, []) == JSON_ARRAY)
                anims = llJson2List((string)anims);
            if(nr == -1)anims = ["got_rest"];
            
            list sounds = [llList2String(visual, fxc$castSound)];
            if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
                sounds = llJson2List((string)sounds);
            
            list_shift_each(anims, v,
                if(isset(v)){
                    AnimHandler$anim(v, TRUE, 0);
                    SPELL_ANIMS+=v;
                }
            )
            
            integer loop = TRUE;
            if(llGetListEntryType(sounds, 0) == TYPE_INTEGER && !llList2Integer(sounds, 0)){
                loop = FALSE;
                sounds = llDeleteSubList(sounds, 0, 0);
            }
            key sound = llList2String(sounds, 0);
            float vol = llList2Float(sounds, 1);
            if(vol<=0)vol = 1;
            if(sound){
                if(loop)
                    ThongMan$loopSound(sound, vol);
                else
                    llTriggerSound(sound, vol);
            }
        }
        

		
        else if(METHOD == SpellAuxMethod$finishCast){
            integer SPELL_CASTED = (integer)method_arg(0);
            list SPELL_TARGS = llJson2List(method_arg(1));
			
			if(!(integer)method_arg(2))
				stopCast(SPELL_CASTED);
			
            list data; integer flags = SpellMan$NO_CRITS;
            if(~SPELL_CASTED){
                data = nrToData(SPELL_CASTED);
				flags = spellFlags(data);
            }
			
            
            string FX = "[0,0,0,0,[0,0,\"\",[[1,-25],[2,-25],[3,-30],[4,30]],[],[]]";
            string SELF = "[]";
            list visual;
            if(~SPELL_CASTED){
				
				CACHE_AROUSAL = (float)db2$get("got Status", ([StatusShared$arousal, 0]));
				CACHE_PAIN = (float)db2$get("got Status", ([StatusShared$pain, 0]));
				CACHE_CRIT = 1;

				if(llFrand(1)<critmod && ~flags&SpellMan$NO_CRITS){
					CACHE_CRIT = 2;
					llTriggerSound("e713ffed-c518-b1ed-fcde-166581c6ad17", .25);
				}
			
                FX = runMath(spellWrapper(data));
                SELF = runMath(spellSelfcast(data));
                visual = llList2List(FX_CACHE, SPELL_CASTED*FXSTRIDE, SPELL_CASTED*FXSTRIDE+FXSTRIDE-1);
            }
            
            // Handle AOE
            if((string)SPELL_TARGS == "AOE"){
                FX$aoe(llGetOwner(), spellRange(data), llGetOwner(), FX);
                if(llGetListLength(PLAYERS)>1)
                    FX$aoe(llList2String(PLAYERS, 1), spellRange(data), llGetOwner(), FX);
                SPELL_TARGS = [LINK_ROOT];
            }

            list visuals = [llList2String(visual, fxc$rezzable)];
            if(llJsonValueType((string)visuals, []) == JSON_ARRAY)
                visuals = llJson2List((string)visuals);
    
            // Send effects and rez visuals
            list_shift_each(SPELL_TARGS, val, 
                key sender = llGetOwner();
                FX$send(val, sender, FX);
                
                integer i;
                for(i=0; i<llGetListLength(visuals); i++){
                    string v = llList2String(visuals, i); 
                    if(v){
                        string targ = val;
                        if(val == (string)LINK_ROOT)targ = llGetOwner();
                        
                        if(llJsonValueType(v, []) == JSON_ARRAY)
                            SpellFX$spawnInstant(v, targ);
                        
                        
                        else
                            SpellFX$spawn(v, targ);
                        
                    }
                }
            )
            
            if(SELF != "[]" && SELF != "")
                FX$run(llGetOwner(), SELF);
            
            
            // ANimations and sounds
            list anims = [llList2String(visual, fxc$finishAnim)];
            if(llJsonValueType((string)anims, []) == JSON_ARRAY)
                anims = llJson2List((string)anims);
                    
            list sounds = [llList2String(visual, fxc$finishSound)];
            if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
                sounds = llJson2List((string)sounds);
            
            list_shift_each(anims, v, 
                if(isset(v))
                    AnimHandler$anim(v, TRUE, 0);
                
            )
                
            list_shift_each(sounds, v,
                key s = v;
                float vol = 1; 
                if(llJsonValueType(v, []) == JSON_ARRAY){
                    s = jVal(v, [0]);
                    vol = (float)jVal(v, [1]);
                }
                if(s)
                    llTriggerSound(s, vol);
            )
            
        }
        else if(METHOD == SpellAuxMethod$cache){
            CACHE = [];
            FX_CACHE = [];
            PARTICLE_CACHE = [];
			CACHE_MANA_COST = [];
            list spells = llJson2List(db2$get(BridgeSpells$name, []));
            PARAMS = "";
			CACHE_LOW_MANA = 0;
			
			// Set textures
			list set = [
				PRIM_LINK_TARGET, llList2Integer(ABILS, 0),
				PRIM_TEXTURE, 1, "46267af8-9c21-3c16-6afe-9861882009fd", <1,1,0>, <0,0,0>,0,
				PRIM_COLOR, 1, <1,1,1>, 1
			];
			
			
            integer i;
            for(i=0; i<llGetListLength(spells); i++){
                list d = llJson2List(llList2String(spells, i));
                CACHE+= llList2String(d, 2); // Wrapper
                CACHE+= llList2String(d, 9); // Selfcast
                CACHE+= llList2Float(d, 6); // Range
				CACHE+= llList2Integer(d, 5); // Flags
                
                string visuals = llList2String(d, 8); // Visuals
                string p = j(visuals, 3);
                PARTICLE_CACHE += (float)j(p, 0);
                PARTICLE_CACHE += (integer)j(p, 1);
                PARTICLE_CACHE += j(p, 2);
                
				set += [
					PRIM_LINK_TARGET, llList2Integer(ABILS, i+1),
					PRIM_TEXTURE, 1, llList2String(d, BSSAA$TEXTURE), <1,1,0>, <0,0,0>,0,
					PRIM_COLOR, 1, <1,1,1>, 1
				];
                
                FX_CACHE+=[
                    j(visuals, 0),
                    j(visuals, 1),
                    j(visuals, 2),
                    j(visuals, 4),
                    j(visuals, 5)
                ];
                
				CACHE_MANA_COST += llList2Float(d, 3); 	// Mana cost of all but rest
            }

			llSetLinkPrimitiveParamsFast(0, set);
			if(!isset(CACHE_THONG))CACHE_THONG = db2$get("#ROOT", [RootShared$thongUUID]);
			if(isset(CACHE_THONG))toggleSpellButtons(TRUE);
			GUI$toggle(TRUE);
        }
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

