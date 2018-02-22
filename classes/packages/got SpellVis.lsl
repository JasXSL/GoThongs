/*
	Todo:
	Go over SpellMan and add SpellAux$spellEnd(); to this script where it would be in SpellMan
*/
#define USE_EVENTS
#include "got/_core.lsl"
 
// Abil prims
list ABILS = [0,0,0,0,0,0];
list ABILS_BG = [0,0,0,0,0,0];
#define ABIL_BG_SCALE <0.15680, 0.04833, 0.02577>
#define ABIL_BORDER_COLOR <.6, .6, .6>
#define ABIL_BORDER_ALPHA .5
#define ABIL_BORDER_HIGHLIGHTED_COLOR <1,1,.5>
#define ABIL_BORDER_HIGHLIGHTED_ALPHA 1
 
integer BFL;
#define BFL_INI 0x1
#define BFL_CASTING 0x2

list CACHE_MANA_COST = [0,0,0,0,0];     // Mana cost of all spells
integer CACHE_LOW_MANA = 0;                // Bitfield of 00000 spells with higher mana cost than mana cache

#define CCSTRIDE 3
list CACHE_COOLDOWNS = [0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0];	// (float)spellManStartTime, (float)startTime, (float)duration - relative to llGetTime() 


list FX_CACHE;
#define FXSTRIDE 6
#define fxc$rezzable 0
#define fxc$finishAnim 1
#define fxc$finishSound 2
#define fxc$castAnim 3
#define fxc$castSound 4
#define fxc$flags 5

// Contains particles
list PARTICLE_CACHE;
#define fxp$timeout 0
#define fxp$prim 1
#define fxp$particles 2
#define PSTRIDE 3

// Flags from got Status
integer STATUS_FLAGS;
integer QUEUED_SPELL;
integer SPELL_CASTED;

string SPELL_ANIMS;

// Fx stuff
integer fxFlags;
integer fxHighlight;    // Bitwise combination, 0x1 for rest, 0x2 for abil1 etc
float manamod = 1;        // Global mana cost mod
float cdmod = 1;        // Global cooldown mod
list manacostMulti = [1,1,1,1,1];

integer WEAPON_SHEATHED = TRUE;

// Removes all cast and cooldown bars
#define stopCast(abil) llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0]+getBorderColorAndAlpha(abil, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA));
#define setCooldown(index, currentTime, start, duration) \
	setAbilitySpinner(index, (currentTime-start)/duration, duration, TRUE); \
    multiTimer(["CD_"+(str)index, "", duration-(currentTime-start), FALSE])


onEvt(string script, integer evt, list data){
    // Status flags updated
    if(script == "got Status" && evt == StatusEvt$flags){

        integer pre = STATUS_FLAGS;
        STATUS_FLAGS = llList2Integer(data,0);
        
        integer hideOn = (StatusFlag$dead|StatusFlag$loading);
        
        if(BFL&BFL_INI && (!(pre&hideOn) && STATUS_FLAGS&hideOn) || (pre&hideOn && !(STATUS_FLAGS&hideOn))){
            SpellVis$toggle(TRUE);        // Auto hides if dead. So we can just go with TRUE for both cases
        } 
    }
    
    else if(script == "got Status" && evt == StatusEvt$resources){
        // [(float)dur, (float)max_dur, (float)mana, (float)max_mana, (float)arousal, (float)max_arousal, (float)pain, (float)max_pain] - PC only
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
    else if(script == "got FXCompiler" && evt == FXCEvt$spellMultipliers){
        manacostMulti = llJson2List(llList2String(data,1));
    }
    else if(script == "got SpellMan" && evt == SpellManEvt$recache){
	
        FX_CACHE = [];
        PARTICLE_CACHE = [];
        CACHE_MANA_COST = [];
        CACHE_LOW_MANA = 0;
        
        // Set textures
        list set = [];

        integer i;
        for(i=0; i<5; i++){
            
            list d = llJson2List(db3$get(BridgeSpells$name+"_temp"+(str)i, []));
            if(d == [])
                d = llJson2List(db3$get(BridgeSpells$name+(str)i, []));

            string visuals = llList2String(d, 8); // Visuals
            list p = llJson2List(j(visuals, 3));
			while( count(p) < 2 )
				p+= 0;
            PARTICLE_CACHE += l2f(p, 0);
            PARTICLE_CACHE += llList2List(p, 1, 1);
            PARTICLE_CACHE += l2s(p, 2);
			            
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
                j(visuals, 5),
                l2i(d, 5) // Flags
            ];
            
            CACHE_MANA_COST += llList2Float(d, 3);
        }
        
        if( FX_CACHE ){
		
            BFL = BFL|BFL_INI;
            llSetLinkPrimitiveParamsFast(0, set);
            SpellVis$toggle(TRUE);
            GUI$toggle(TRUE);
			
        }
		
    }
    
    // Spell handlers
    
    // CAST START
    else if(script == "got SpellMan" && evt == SpellManEvt$cast){
	
        BFL = BFL|BFL_CASTING;
        
        // SpellMan handles all the conversions from -1 to 0-5, so this is the true index
        
        float ct = i2f(l2i(data, 0));                    // Cast time
        SPELL_CASTED = l2i(data, 2);

		multiTimer(["CD_"+(str)SPELL_CASTED]);
		
        if( ct>0 )
            setAbilitySpinner(SPELL_CASTED, 0, ct, FALSE);                // Not an instant spell, show cast bar
        
	
        list visual = llList2List(FX_CACHE, SPELL_CASTED*FXSTRIDE, SPELL_CASTED*FXSTRIDE+FXSTRIDE-1);
        
        // particles
        list p = llList2List(PARTICLE_CACHE, SPELL_CASTED*PSTRIDE, SPELL_CASTED*PSTRIDE+PSTRIDE-1);
		
		
		// Send to class specific visuals
		if( l2i(p, 0) == -2 )
			gotClassAtt$spellStart(l2s(p, 1), ct+1);
		// Send to global thongmanager
		else if( llList2String(p, fxp$particles) != "" )
			ThongMan$particles(ct+1, l2i(p, fxp$prim), l2s(p, fxp$particles));
        
        list sounds = [llList2String(visual, fxc$castSound)];
        if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
            sounds = llJson2List((string)sounds);
        
		SPELL_ANIMS = "";
		if( llList2String(visual, fxc$castAnim) )				
			SPELL_ANIMS = llList2String(visual, fxc$castAnim);

		if( SPELL_ANIMS )
			AnimHandler$anim(SPELL_ANIMS, TRUE, 0,0,0);
        
        integer loop = TRUE;
        if(llGetListEntryType(sounds, 0) == TYPE_INTEGER && !llList2Integer(sounds, 0)){
            loop = FALSE;
            sounds = llDeleteSubList(sounds, 0, 0);
        }
        
        key sound = llList2String(sounds, 0);
        float vol = llList2Float(sounds, 1);
        if(sound)
            ThongMan$sound(sound, vol, loop);
    }
    
    // CAST FINISH
    else if(script == "got SpellMan" && evt == SpellManEvt$complete){
        
        integer SPELL_CASTED = l2i(data, 0);                    // Spell casted index 0-4
        list SPELL_TARGS = llJson2List(l2s(data, 3));                    // Targets casted at

        /*
        if(!l2i(data, 4))                                        // No cooldown, just wipe the cast bar
            stopCast(SPELL_CASTED);
        */
        
        list visual = llList2List(FX_CACHE, SPELL_CASTED*FXSTRIDE, SPELL_CASTED*FXSTRIDE+FXSTRIDE-1);

        // ANimations and sounds
                
        list sounds = [llList2String(visual, fxc$finishSound)];
        if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
            sounds = llJson2List((string)sounds);
        
		
		list p = llList2List(PARTICLE_CACHE, SPELL_CASTED*PSTRIDE, SPELL_CASTED*PSTRIDE+PSTRIDE-1);
		if( l2i(p, 0) == -2 ){

			if( l2s(p, 1) )
				gotClassAtt$spellEnd(l2s(p, 1), 1);
			if( l2s(p, 2) != "" && !WEAPON_SHEATHED )
				Weapon$trail(l2s(p,2));
			
		}
        
        if( llList2String(visual, fxc$finishAnim) == "_WEAPON_" )
            WeaponLoader$anim();
		else if( llList2String(visual, fxc$finishAnim) )
			AnimHandler$anim(llList2String(visual, fxc$finishAnim), TRUE, 0, 0, 0);
        
        
            
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
        
        list visuals = [llList2String(visual, fxc$rezzable)];
        if(llJsonValueType((string)visuals, []) == JSON_ARRAY)
            visuals = llJson2List((string)visuals);

        // rez visuals
        list_shift_each(SPELL_TARGS, val, 
            
            if(val == llGetKey() || val == "AOE" || val == "1")
                val = llGetOwner();
            
            integer i;
            for(i=0; i<llGetListLength(visuals); i++){
                string v = llList2String(visuals, i); 
                if(v){
                    string targ = val;
                    if(prAttachPoint(targ))
                        targ = llGetOwnerKey(val);
                    
                    if(llJsonValueType(v, []) == JSON_ARRAY){
                        SpellFX$spawnInstant(v, targ);
					}

                    else
                        SpellFX$spawn(v, targ);
                    
                }
            }
        )
        onSpellEnd(SPELL_CASTED, i2f(l2f(data, 5)));
    }
    else if(script == "got SpellMan" && evt == SpellManEvt$interrupted){
	
		list p = llList2List(PARTICLE_CACHE, SPELL_CASTED*PSTRIDE, SPELL_CASTED*PSTRIDE+PSTRIDE-1);
		if( l2i(p, 0) == -2 )
			gotClassAtt$spellEnd(l2s(p, 1), 0);
        onSpellEnd(l2i(data,0), i2f(l2i(data, 1)));
		
    }
    
	else if( script == "got WeaponLoader" && evt == WeaponLoaderEvt$sheathed )
		WEAPON_SHEATHED = l2i(data, 0);
	
}

onSpellEnd(integer index, float casttime){
    BFL = BFL&~BFL_CASTING;
	

	float startTime = l2f(CACHE_COOLDOWNS, index*CCSTRIDE+1);
	float total = l2f(CACHE_COOLDOWNS, index*CCSTRIDE+2);
	float time = llGetTime();
	float cd = startTime+total-time;
	
	if(cd <= 0)
		stopCast(index)
	else if(casttime){
		setCooldown(index, llGetTime(), startTime, total);
	}
	
    // Stops casting animations
	if( SPELL_ANIMS )
        AnimHandler$anim(SPELL_ANIMS, FALSE, 0, 0, 0);
		
}

setAbilitySpinner(integer abil, float startPercent, float duration, integer reverse){
    if(duration<=0)return;
    float total = 128./duration; // Total frames are 128
    integer startFrame = llRound(startPercent*127.); 
	integer totalFrames = 127-startFrame;
	
	if(reverse){
		// Swap
		totalFrames = 127-startFrame;
		startFrame = 0;
	}
	
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
    
    //qd("StartFrame: "+(str)startFrame+" Total frames: "+(str)(4*32-startFrame));
    llSetLinkTextureAnim(llList2Integer(ABILS, abil), ANIM_ON|flags, 2, 4,32, startFrame, totalFrames, total);
}

// Returns a list of [(vec)color, (float)alpha]
list getBorderColorAndAlpha(integer index, vector color, float alpha){
    if(QUEUED_SPELL == index)
        return [ABIL_BORDER_HIGHLIGHTED_COLOR,ABIL_BORDER_HIGHLIGHTED_ALPHA];
    return [color, alpha];
}



timerEvent(string id, string data){
    if(llGetSubString(id, 0, 2) == "CD_"){
        integer a = (int)llGetSubString(id, 3, -1);
        stopCast(a);
		CACHE_COOLDOWNS = llListReplaceList(CACHE_COOLDOWNS, [0,0], a*CCSTRIDE, a*CCSTRIDE+1);
    }
}

default 
{
    state_entry()
    {

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
        SpellVis$toggle(FALSE);
        
        
        // Debug
        onEvt("got SpellMan", SpellManEvt$recache, []);
    }
    
    timer(){multiTimer([]);}
    
    #define LM_PRE \
    if(nr == TASK_FX){ \
        list data = llJson2List(s); \
        manamod = i2f(l2f(data, FXCUpd$MANACOST)); \
        cdmod = i2f(l2f(data, FXCUpd$COOLDOWN)); \
        fxFlags = l2i(data, FXCUpd$FLAGS);\
        integer pre = fxHighlight; \
        fxHighlight = llList2Integer(data, FXCUpd$SPELL_HIGHLIGHTS); \
        list out = []; \
        integer i; \
        for(i=0; i<count(ABILS_BG); i++){ \
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
        INDEX - (int)obj_index
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }
    
    // Internal means the method was sent from within the linkset
    if(id != "")
        return;
        
        
    
    if( METHOD == SpellVisMethod$setCooldowns ){
	
        float currentTime = i2f(l2i(PARAMS, -1));
        PARAMS = llDeleteSubList(PARAMS, -1, -1);
        
		list CDS;
        integer i;
        for(i=0; i<count(PARAMS); i+=2){ // This has to match CDSTRIDE in got SpellMan
        
            integer index = i/2;
            float start = i2f(l2i(PARAMS, i));				// Script time relative to spellMan when cooldown began
            float duration = i2f(l2i(PARAMS, i+1));			// Total duration of cooldown
            float onCD = start+duration-currentTime;		// Total time left
            
			CDS += [
				start+duration,								// SpellMan end time
				llGetTime()-(currentTime-start),			// Converts start time to local time
				duration									// Total duration
			];
			
            if( 
				(~BFL&BFL_CASTING || SPELL_CASTED != index) && 
				(
					start+duration > l2f(CACHE_COOLDOWNS, index*CCSTRIDE) || 
					(start+duration-currentTime > 0) != (l2f(CACHE_COOLDOWNS, index*CCSTRIDE)-currentTime > 0) 
				)
			){
                // Update the spinner or hide
                if(onCD <= 0){
                    stopCast(index);
                }
                else{
					setCooldown(index, currentTime, start, duration);
                }
            }
        }
        // Stores CD values, can be negative
        CACHE_COOLDOWNS = CDS;
    }
    /*
    else if(METHOD == SpellVisMethod$stopCast){
        stopCast((integer)method_arg(0));
    }
    */


    // Show/hide spells
    else if(METHOD == SpellVisMethod$toggle){
    
        integer show = l2i(PARAMS, 0);
        integer i;  list out;
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
            PP(0,out);
            return;
        }
        
        // Else
        for(i=0; i<llGetListLength(ABILS); i++){

            vector pos = <0, 0.29586-0.073965-0.14793*(i-1), .31>;
            if(i == 0)pos = <0,0,.27>;
            if(i == 5)pos = <0,0,.35>;
            
            // Check disabled spells here
            integer f = l2i(FX_CACHE, i*FXSTRIDE+fxc$flags);
            
            // Spell disabled via flag or does not exist
            if(f&SpellMan$HIDE || count(FX_CACHE)/FXSTRIDE <= i) // 0x400 = disabled
                pos = ZERO_VECTOR;
            
            out+= [
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
        
        PP(0, out);
        
    }
    
    else if(METHOD == SpellVisMethod$setQueue){
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


    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

