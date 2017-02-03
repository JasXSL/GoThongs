#define USE_EVENTS
#include "got/_core.lsl"

integer TEAM = TEAM_PC;

// This is the actual spell data cached
list CACHE;
#define spellWrapper(data) llList2String(data, 0)
#define spellSelfcast(data) llList2String(data, 1)
#define spellRange(data) llList2Float(data, 2)
#define spellFlags(data) llList2Integer(data, 3)

#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)
#define difDmgMod() llPow(0.9, DIFFICULTY)

list CACHE_MANA_COST = [0,0,0,0,0]; 	// Mana cost of all spells
integer CACHE_LOW_MANA = 0;		// Bitfield of 00000 spells with higher mana cost than mana cache

// Contains the fx data
#define CSTRIDE 4

integer DIFFICULTY;

list FX_CACHE;
#define FXSTRIDE 5
#define fxc$rezzable 0
#define fxc$finishAnim 1
#define fxc$finishSound 2
#define fxc$castAnim 3
#define fxc$castSound 4

// Calculates bonus damage for particular spells
list SPELL_DMG_DONE_MOD = [-1,-1,-1,-1,-1];		// [rest, abil1, abil2...]
float spdmdm(integer index){
    float out = llList2Float(SPELL_DMG_DONE_MOD, index);
	if(out == -1)return 1;
	if(out<0)return 0;
    return out;
}

integer BFL;
#define BFL_INI 0x1
#define BFL_CASTING 0x2

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

// Flags from got Status
integer STATUS_FLAGS;
integer QUEUED_SPELL;

list PLAYERS;
list SPELL_ANIMS;

// FX
float dmdmod = 1;       // Damage done
float critmod = 0;
float manamod = 1;		// Global mana cost mod
float cdmod = 1;		// Global cooldown mod
float hdmod = 1;		// Healing done mod
list manacostMulti = [1,1,1,1,1];
integer fxHighlight;	// Bitwise combination, 0x1 for rest, 0x2 for abil1 etc
float befuddle = 1;		// Chance to cast at a random target

// Abil prims
list ABILS = [0,0,0,0,0];
list ABILS_BG = [0,0,0,0,0];
#define ABIL_BG_SCALE <0.15680, 0.04833, 0.02577>
#define ABIL_BORDER_COLOR <.6, .6, .6>
#define ABIL_BORDER_ALPHA .5
#define ABIL_BORDER_HIGHLIGHTED_COLOR <1,1,.5>
#define ABIL_BORDER_HIGHLIGHTED_ALPHA 1

string runMath(string FX, integer index, key targ){
    list split = llParseString2List(FX, ["$MATH$"], []);
    float pmod = 1;
	
	integer p = count(PLAYERS);
	if(p<1)p=1;
    pmod = 1./p;
	
    float aroused = 1;
    if(STATUS_FLAGS&StatusFlag$aroused)aroused = .9;
	
	integer B = 0;
	myAngZ(targ, ang)
	if(llFabs(ang)>PI_BY_TWO){
		B = 1;
	}

	
	string consts = llList2Json(JSON_OBJECT, [
		// Damage done multiplier
        "D", (dmdmod*pmod*aroused*CACHE_CRIT*spdmdm(index)*difDmgMod()),
		// Points of arousal
		"A", CACHE_AROUSAL,
		// Points of pain
		"P", CACHE_PAIN,
		// Backstab boolean
		"B", B,
		// Cooldown modifier
		"H", cdmod,
		// Spell damage done mod for index, added into D
		"M", spdmdm(index),
		// HEaling done multiplier
		"h", hdmod,
		"T", TEAM
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

onEvt(string script, integer evt, list data){
    if(script == "#ROOT"){
        if(evt == RootEvt$players)
            PLAYERS = data;
    }
	
	
	else if(script == "got Status"){
		if(evt == StatusEvt$flags){
			integer pre = STATUS_FLAGS;
			STATUS_FLAGS = llList2Integer(data,0);
			
			integer hideOn = (StatusFlag$dead|StatusFlag$loading);
			
			if(BFL&BFL_INI && (!(pre&hideOn) && STATUS_FLAGS&hideOn) || (pre&hideOn && !(STATUS_FLAGS&hideOn))){
				toggleSpellButtons(TRUE);		// Auto hides if dead. So we can just go with TRUE for both cases
			} 
		}
		
		else if(evt == StatusEvt$difficulty){
			DIFFICULTY = l2i(data, 0);
		}
		
		else if(evt == StatusEvt$resources){
			// [(float)dur, (float)max_dur, (float)mana, (float)max_mana, (float)arousal, (float)max_arousal, (float)pain, (float)max_pain] - PC only
			CACHE_AROUSAL = llList2Float(data, 4);
			CACHE_PAIN = llList2Float(data, 6);
			
			float mana = l2f(data, 2);
			integer i;
			
			list out;
			for(i=0; i<count(CACHE_MANA_COST); i++){
				integer nr = (integer)llPow(i, 2);
				float cost = llList2Float(CACHE_MANA_COST, i)*manamod*llList2Float(manacostMulti, i);
				if(~CACHE_LOW_MANA&nr && cost>mana){
					CACHE_LOW_MANA = CACHE_LOW_MANA|nr;
					out+= [
						PRIM_LINK_TARGET, llList2Integer(ABILS, i),
						PRIM_COLOR, 1, <1,1,1>, .5
					];
				}else if(CACHE_LOW_MANA&nr && cost <= mana){
					CACHE_LOW_MANA = CACHE_LOW_MANA&~nr;
					out+= [
						PRIM_LINK_TARGET, llList2Integer(ABILS, i),
						PRIM_COLOR, 1, <1,1,1>, 1
					];
				}
				
			}
			
			llSetLinkPrimitiveParamsFast(0, out);
		}
		else if(evt == StatusEvt$team)
			TEAM = l2i(data,0);
	}
	else if(script == "got FXCompiler" && evt == FXCEvt$spellMultipliers){
		SPELL_DMG_DONE_MOD = llJson2List(llList2String(data,0));
		manacostMulti = llJson2List(llList2String(data,1));
	}
}


toggleSpellButtons(integer show){
	integer i; list out;
	if(!show || STATUS_FLAGS&(StatusFlag$dead|StatusFlag$loading)){
        for(i=0; i<llGetListLength(ABILS); i++){
            out += [
                PRIM_LINK_TARGET, llList2Integer(ABILS, i),
                PRIM_POSITION, ZERO_VECTOR,
                PRIM_COLOR, 2, <1,1,1>, 0,
				PRIM_LINK_TARGET, llList2Integer(ABILS_BG, i),
                PRIM_POSITION, ZERO_VECTOR
            ];
        }
    }else{
        for(i=0; i<llGetListLength(ABILS); i++){
			if(count(CACHE)/CSTRIDE <= i) //TODO: Changeme
				out+= [PRIM_POSITION, ZERO_VECTOR];
			else{
            vector pos = <0, 0.29586-0.073965-0.14793*(i-1), .31>;
            if(i == 0)pos = <0,0,.27>;
			if(i == 5)pos = <0,0,.35>;
				out += [
					PRIM_LINK_TARGET, llList2Integer(ABILS, i),
					PRIM_POSITION, pos,
					PRIM_COLOR, 0, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA,
					PRIM_COLOR, 1, <1,1,1>, 1, 
					PRIM_COLOR, 3, <0,0,0>, 0,
					PRIM_COLOR, 4, <0,0,0>, 0,
					PRIM_COLOR, 5, <0,0,0>, 0,
					PRIM_LINK_TARGET, llList2Integer(ABILS_BG, i),
					PRIM_POSITION, pos+<.02,0,0>,
					PRIM_COLOR, 0, <1,1,1>, 0
				];
			}
        }
    }
	llSetLinkPrimitiveParamsFast(0, out);
}


setAbilitySpinner(integer abil, float time, integer reverse){
	if(time<=0)return;
    float total = (4.*32)/time;
            
    integer flags;
    float borderalpha = 1;
    vector border = <1,1,1>;
    vector color = <.5,1,.5>;
    if(reverse){
		color = <0,0,0>;
        border = <0,0,0>;
        borderalpha = ABIL_BORDER_ALPHA;
        flags = REVERSE;
    }

    float width = .25; float height = 1./32;

    llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [
		PRIM_COLOR,0]+getBorderColorAndAlpha(abil, border, borderalpha)+[ PRIM_COLOR, 2, color, 1
	]);
    llSetLinkTextureAnim(llList2Integer(ABILS, abil), 0, 2, 4,32, 0,32, total);
	llSetLinkTextureAnim(llList2Integer(ABILS, abil), ANIM_ON|flags, 2, 4,32, 0,0, total);
}

// Returns a list of [(vec)color, (float)alpha]
list getBorderColorAndAlpha(integer index, vector color, float alpha){
	if(QUEUED_SPELL == index)
		return [ABIL_BORDER_HIGHLIGHTED_COLOR,ABIL_BORDER_HIGHLIGHTED_ALPHA];
	return [color, alpha];
}

#define stopCast(abil) llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0]+getBorderColorAndAlpha(abil, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA));


default
{
	state_entry(){
		list out;
		links_each(nr, name, 
            integer n = (integer)llGetSubString(name, -1, -1); 
            if(llGetSubString(name, 0, 3) == "Abil"){
                ABILS = llListReplaceList(ABILS, [nr], n, n);
				
				float width = 1./4;
				float height = 1./32;
				out+= ([
					PRIM_LINK_TARGET, nr,
					PRIM_TEXTURE, 2, "0c2f81c7-8ecf-92ab-0351-6bbe109f0d0a", <width,height,0>, <-floor(4/2)*width+width/2+width, floor(32/2)*height-height/2-height, 0>, 0,
					PRIM_COLOR, 2, <1,1,1>, 1
				]);
			}
			else if(llGetSubString(name, 0, 1) == "BG"){
				ABILS_BG = llListReplaceList(ABILS_BG, [nr], n, n);
				llSetLinkTextureAnim(nr, ANIM_ON|LOOP, 0, 4, 8, 0, 0, 30);
				out+=([PRIM_LINK_TARGET, nr, PRIM_TEXTURE, 0, "47814d20-b171-43ff-d7b5-c02749508906", <1,1,0>, ZERO_VECTOR, 0, PRIM_SIZE, ABIL_BG_SCALE]);
			}
        )
		llSetLinkPrimitiveParamsFast(0, out);
		toggleSpellButtons(FALSE);
		//SpellAux$cache(); - Only turn on for debugging
	}
	
	
	#define LM_PRE \
	if(nr == TASK_FX){ \
		list data = llJson2List(s); \
		dmdmod = i2f(l2f(data, FXCUpd$DAMAGE_DONE)); \
		critmod = i2f(l2f(data, FXCUpd$CRIT)); \
		manamod = i2f(l2f(data, FXCUpd$MANACOST)); \
		cdmod = i2f(l2f(data, FXCUpd$COOLDOWN)); \
		hdmod = i2f(l2f(data, FXCUpd$HEAL_DONE_MOD)); \
		integer pre = fxHighlight; \
		fxHighlight = llList2Integer(data, FXCUpd$SPELL_HIGHLIGHTS); \
		befuddle = i2f(l2f(data, FXCUpd$BEFUDDLE));\
		list out = []; \
		integer i; \
		for(i=0; i<5; i++){ \
			integer check = (int)llPow(2,i); \
			if(fxHighlight&check){ \
				out+= [ \
					PRIM_LINK_TARGET, llList2Integer(ABILS_BG,i), \
					PRIM_COLOR,0,<1,1,1>,1 \
				]; \
			} \
			else if(pre&check){ \
				out+= [ \
					PRIM_LINK_TARGET, llList2Integer(ABILS_BG,i), \
					PRIM_COLOR,0,<1,1,1>,0 \
				]; \
			} \
		} \
		PP(0,out); \
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

            integer cds = l2i(PARAMS, 1);
            float time = i2f(l2f(PARAMS, 0));	// Received as int
            list out;
			
            integer i;
            for(i=0; i<5; i++){
				integer cd = getBitArr(cds, i, 2);
				// -1 = leave undecided, 0 = remove, 1 = add
                if(cd == 2){
                    llSetLinkTextureAnim(llList2Integer(ABILS, i), 0, 2, 4,32, 0,32, 0);
                    out+= [PRIM_LINK_TARGET, llList2Integer(ABILS, i), PRIM_COLOR,0]+getBorderColorAndAlpha(i, ZERO_VECTOR, ABIL_BORDER_ALPHA)+[ PRIM_COLOR, 2, ZERO_VECTOR, 1];
                    llSetLinkTextureAnim(llList2Integer(ABILS, i), ANIM_ON|REVERSE, 2, 4,32, 0,0, (4.*32)/time);
                }else if(cd == 1){
					out+= [PRIM_LINK_TARGET, llList2Integer(ABILS, i), PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0]+getBorderColorAndAlpha(i, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA);
				}
            }
            llSetLinkPrimitiveParamsFast(0, out);
        }
	
	
        else if(METHOD == SpellAuxMethod$spellEnd){
			BFL = BFL&~BFL_CASTING;
			
			// Stops casting animations
            list_shift_each(SPELL_ANIMS, v, 
				if(isset(v))
					AnimHandler$anim(v, FALSE, 0, 0);
            )
        }
		

        else if(METHOD == SpellAuxMethod$startCast){
			BFL = BFL|BFL_CASTING;
            integer nr = (integer)method_arg(0);				// SpellMan handles all the conversions from -1 to 0-5, so this is the true index
			float ct = (float)method_arg(1);					// Cast time
			if(ct>0)
				setAbilitySpinner(nr, ct, FALSE);				// Not an instant spell, show cast bar
			

            list visual = llList2List(FX_CACHE, nr*FXSTRIDE, nr*FXSTRIDE+FXSTRIDE-1);
			
            // particles
            list p = llList2List(PARTICLE_CACHE, nr*PSTRIDE, nr*PSTRIDE+PSTRIDE-1);
            if(llList2String(p,2) != "")
                ThongMan$particles(llList2Float(p, fxp$timeout), llList2Integer(p, fxp$prim), llList2String(p, fxp$particles));
            
            list anims = [llList2String(visual, fxc$castAnim)];
            if(llJsonValueType((string)anims, []) == JSON_ARRAY)
                anims = llJson2List((string)anims);

            
            list sounds = [llList2String(visual, fxc$castSound)];
            if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
                sounds = llJson2List((string)sounds);
            
            list_shift_each(anims, v,
                if(isset(v)){
                    AnimHandler$anim(v, TRUE, 0,0);
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
			
            integer SPELL_CASTED = (integer)method_arg(0);					// Spell casted index 0-4
            list SPELL_TARGS = llJson2List(method_arg(1));					// Targets casted at
			
			if(!(integer)method_arg(2))										// No cooldown, just wipe the cast bar
				stopCast(SPELL_CASTED);
			
			
            list data = nrToData(SPELL_CASTED);
			list visual = llList2List(FX_CACHE, SPELL_CASTED*FXSTRIDE, SPELL_CASTED*FXSTRIDE+FXSTRIDE-1);

			integer flags = spellFlags(data);
            
			CACHE_CRIT = 1;
			if(llFrand(1)<critmod && ~flags&SpellMan$NO_CRITS){
				CACHE_CRIT = 2;
				llTriggerSound("e713ffed-c518-b1ed-fcde-166581c6ad17", .25);
			}
			
			// ANimations and sounds
            list anims = [llList2String(visual, fxc$finishAnim)];
            if(llJsonValueType((string)anims, []) == JSON_ARRAY)
                anims = llJson2List((string)anims);
                    
            list sounds = [llList2String(visual, fxc$finishSound)];
            if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
                sounds = llJson2List((string)sounds);
            
			
			if(l2s(anims, 0) == "_WEAPON_"){
				WeaponLoader$anim();
				anims = [];
			}
			list_shift_each(anims, v, 
				if(isset(v))
					AnimHandler$anim(v, TRUE, 0, 0);
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
			
			
			// RunMath should be done against certain targets for backstab to work
            string FX = spellWrapper(data);
			
            // Handle AOE
            if((string)SPELL_TARGS == "AOE"){
                FX$aoe(spellRange(data), llGetKey(), runMath(FX,SPELL_CASTED, ""), TEAM);  
                SPELL_TARGS = [LINK_ROOT];
            }
			
			else if(llFrand(1) < befuddle-1){
				float r = spellRange(data);
				string targ = randElem(PLAYERS);
				if(targ == llGetOwner())
					SPELL_TARGS = [LINK_ROOT];
				else if(llVecDist(llGetPos(), prPos(targ)) < r){
					SPELL_TARGS = [targ];
				}
			}
			
			
            list visuals = [llList2String(visual, fxc$rezzable)];
            if(llJsonValueType((string)visuals, []) == JSON_ARRAY)
                visuals = llJson2List((string)visuals);
    
            // Send effects and rez visuals
            list_shift_each(SPELL_TARGS, val, 
                
				if(val == llGetKey() || val == llGetOwner())
					val = (str)LINK_ROOT;
                
                integer i;
                for(i=0; i<llGetListLength(visuals); i++){
                    string v = llList2String(visuals, i); 
                    if(v){
                        string targ = val;
                        if(val == (string)LINK_ROOT)targ = llGetOwner();
						if(prAttachPoint(targ))
							targ = llGetOwnerKey(val);
                        
                        if(llJsonValueType(v, []) == JSON_ARRAY)
                            SpellFX$spawnInstant(v, targ);

                        else
                            SpellFX$spawn(v, targ);
                        
                    }
                }
				
				if((string)SPELL_TARGS != "AOE"){
					FX$send(val, llGetKey(), runMath(FX,SPELL_CASTED, val), TEAM);
				}
            )
			
            string SELF = spellSelfcast(data);
            if(SELF != "[]" && SELF != "")
                FX$run(llGetOwner(), runMath(SELF, SPELL_CASTED, ""));
            
            
            
            
        }
		
        else if(METHOD == SpellAuxMethod$cache){
		    CACHE = [];
            FX_CACHE = [];
            PARTICLE_CACHE = [];
			CACHE_MANA_COST = [];
			PARAMS = [];
			CACHE_LOW_MANA = 0;
			
			// Set textures
			list set = [];

            integer i;
            for(i=0; i<5; i++){
				
                list d = llJson2List(db3$get(BridgeSpells$name+(str)i, []));
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
					PRIM_LINK_TARGET, llList2Integer(ABILS, i),
					PRIM_TEXTURE, 1, llList2String(d, BSSAA$texture), <1,1,0>, <0,0,0>,0,
					PRIM_COLOR, 1, <1,1,1>, 1
				];
                
                FX_CACHE+=[
                    j(visuals, 0),
                    j(visuals, 1),
                    j(visuals, 2),
                    j(visuals, 4),
                    j(visuals, 5)
                ];
                
				CACHE_MANA_COST += llList2Float(d, 3);
            }
			if(CACHE){
				BFL = BFL|BFL_INI;
				llSetLinkPrimitiveParamsFast(0, set);
				toggleSpellButtons(TRUE);
				GUI$toggle(TRUE);
			}
        }
		
		else if(METHOD == SpellAuxMethod$setQueue){
			list out = [];
			integer s = (int)method_arg(0);
			if(s == QUEUED_SPELL)return;

			if(~QUEUED_SPELL){
				out+=[PRIM_LINK_TARGET, llList2Integer(ABILS, QUEUED_SPELL), PRIM_COLOR, 0, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA];
			}
			QUEUED_SPELL = s;
			if(~QUEUED_SPELL){
				out+=[PRIM_LINK_TARGET, llList2Integer(ABILS, QUEUED_SPELL), PRIM_COLOR, 0, ABIL_BORDER_HIGHLIGHTED_COLOR, ABIL_BORDER_HIGHLIGHTED_ALPHA];
			}
			PP(0,out);
		}
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

