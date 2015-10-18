#define USE_EVENTS
#define USE_SHARED [BridgeSpells$name]
#include "got/_core.lsl"

#define spellWrapper(data) llList2String(data, 0)
#define spellSelfcast(data) llList2String(data, 1)
#define spellRange(data) llList2Float(data, 2)

#define nrToData(nr) llList2List(CACHE, nr*CSTRIDE, nr*CSTRIDE+CSTRIDE-1)

#define CSTRIDE 3
list CACHE;
list FX_CACHE;
#define FXSTRIDE 5
#define fxc$rezzable 0
#define fxc$finishAnim 1
#define fxc$finishSound 2
#define fxc$castAnim 3
#define fxc$castSound 4

list PARTICLE_CACHE;
#define fxp$timeout 0
#define fxp$prim 1
#define fxp$particles 2
#define PSTRIDE 3




integer STATUS_FLAGS;

list PLAYERS;
list SPELL_ANIMS;

// FX
float dmdmod = 1;       // Damage done

string runMath(string FX){
    list split = llParseString2List(FX, ["$MATH$"], []);
    float pmod = 1;
    if(llList2Key(PLAYERS, 1))pmod = .5;
    float aroused = 1;
    if(STATUS_FLAGS&StatusFlag$aroused)aroused = .5;
    integer i;
    for(i=1; i<llGetListLength(split); i++){
        split = llListReplaceList(split, [llGetSubString(llList2String(split, i-1), 0, -2)], i-1, i-1);
        string block = llList2String(split, i);
        integer q = llSubStringIndex(block, "\"");
        string math = llGetSubString(block, 0, q-1);
        block = llGetSubString(block, q+1, -1);
        split = llListReplaceList(split, [(string)mathToFloat(math, 0, llList2Json(JSON_OBJECT, [
            "D", (dmdmod*pmod*aroused)
        ]))+block], i, i);
    }
    return llDumpList2String(split, "");
}

onEvt(string script, integer evt, string data){
    if(script == "#ROOT"){
        if(evt == RootEvt$players)
            PLAYERS = llJson2List(data);
    }else if(script == "got Status" && evt == StatusEvt$flags)
        STATUS_FLAGS = (integer)data;
    else if(script == "got FXCompiler" && evt == FXCEvt$update)
        dmdmod = (float)j(data, FXCUpd$DAMAGE_DONE);

}



default
{
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
        if(METHOD == SpellAuxMethod$spellEnd){
            list_shift_each(SPELL_ANIMS, v, 
				if(isset(v))
					AnimHandler$anim(v, FALSE, 0);
            )
        }
        else if(METHOD == SpellAuxMethod$startCast){
            integer nr = (integer)method_arg(0);
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
            list data;
            if(~SPELL_CASTED){
                data = nrToData(SPELL_CASTED);
            }
            
            string FX = "[0,0,0,0,[0,0,\"\",[[1,-20],[2,-20],[3,-20],[4,20]],[],[]]";
            string SELF = "[]";
            list visual;
            if(~SPELL_CASTED){
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
            list spells = llJson2List(db2$get(BridgeSpells$name, []));
            PARAMS = "";
            
            
            integer i;
            for(i=0; i<llGetListLength(spells); i++){
                list d = llJson2List(llList2String(spells, i));
                CACHE+= llList2String(d, 2); // Wrapper
                CACHE+= llList2String(d, 9); // Selfcast
                CACHE+= llList2Float(d, 5); // Range
                
                string visuals = llList2String(d, 8); // Visuals
                string p = j(visuals, 3);
                PARTICLE_CACHE += (float)j(p, 0);
                PARTICLE_CACHE += (integer)j(p, 1);
                PARTICLE_CACHE += j(p, 2);
                
                
                FX_CACHE+=[
                    j(visuals, 0),
                    j(visuals, 1),
                    j(visuals, 2),
                    j(visuals, 4),
                    j(visuals, 5)
                ];
                
            }
        }
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

