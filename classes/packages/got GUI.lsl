#define USE_EVENTS
#define USE_SHARED ["#ROOT", "got Bridge", BridgeSpells$name]
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

integer BFL;
#define BFL_BROWSER_SHOWN 0x1
#define BFL_DEAD 0x2
#define BFL_HAS_ABILITIES 0x4

#define BAR_STRIDE 4
list BARS = [0,0,0,0,0,0,0,0,0,0,0,0];  // [(int)portrait, (int)bars, (int)spells, (int)spells_overlays], self, friend, target
list ABILS = [0,0,0,0,0];
#define ABIL_BORDER_COLOR <.6, .6, .6>
#define ABIL_BORDER_ALPHA .5

key TARG;
list PLAYERS;

integer P_QUIT;
integer P_RETRY;
#define RPB_SCALE <0.15643, 0.04446, 0.03635>*1.25
#define RPB_ROOT_POS <-0.074654, 0.0, 0.31>

#define SPELLSCALE <0.14775, 0.01770, 0.01761>
 
 
#define id2bars(offs) \
list bars; \
if(id == "")id = llGetOwner(); \
if(prAttachPoint(id))id = llGetOwnerKey(id); \
if(id == llGetOwner())bars += llList2Integer(BARS, offs); \
if(id == TARG)bars += llList2Integer(BARS, BAR_STRIDE*2+offs); \
if(id == llList2Key(PLAYERS, 1))bars += llList2Integer(BARS, BAR_STRIDE+offs);

onEvt(string script, integer evt, string data){
    if(script == "#ROOT"){
        if(evt == RootEvt$targ){
            updateTarget(jVal(data, [0]), jVal(data, [1]));
        }else if(evt == RootEvt$players){
            toggle(TRUE);
            PLAYERS = llJson2List(data);
        }
    }else if(script == "got Status"){
        if(evt == StatusEvt$dead){
            if((integer)data)BFL = BFL|BFL_DEAD;
            else BFL = BFL&~BFL_DEAD;
            toggle(TRUE);
        }
    }else if(script == "got Rape"){
        if(evt == RapeEvt$onStart){
            BFL = BFL|BFL_DEAD;
            toggle(TRUE);
        }
    }
}


// If show > 1 then show is a bitfild for things to hide
toggle(integer show){
    list players = _getPlayers();
    
    list out;
    integer i;
    for(i=0; i<2; i++){
        integer exists = FALSE;
        if(llGetListLength(players)>i)exists = TRUE;
        
        key texture = TEXTURE_PC;
        if(i == 1)texture = TEXTURE_COOP;
        
        if(show && exists){
            vector offs1 = <0,.12,0.25>;
            vector offs2 = <0,.26,0.253>;
            vector offs3 = <0,.29,0.236>;
            if(i){
                offs1.y=-offs1.y;
                offs2.y=-offs2.y;
                offs3.y=-offs3.y;
            }

            out+=[
                // Self
                PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE),
                PRIM_POSITION, offs1,
                PRIM_COLOR, 0, ZERO_VECTOR, 1,
                PRIM_COLOR, 1, <1,1,1>, 1,
                PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0,
                PRIM_COLOR, 2, <1,1,1>, 0,
                PRIM_COLOR, 3, <1,1,1>, 0,
                PRIM_COLOR, 4, <1,1,1>, 0,
                PRIM_COLOR, 5, <1,1,1>, 0,
                
                PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE+1),
                PRIM_POSITION, offs2+<.05,0,0>,
                PRIM_COLOR, 0, ZERO_VECTOR, .25,
                PRIM_COLOR, 1, ZERO_VECTOR, .5,
                PRIM_COLOR, 2, <1,.5,.5>, 1,
                PRIM_COLOR, 3, <.5,.8,1>, 1,
                PRIM_COLOR, 4, <1,.5,1>, 1,
                PRIM_COLOR, 5, <.5,.5,1>, 1,
                
                PRIM_TEXTURE, 2, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <-.25,0,0>, 0,
                PRIM_TEXTURE, 3, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <-.25,0,0>, 0,
                PRIM_TEXTURE, 4, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25,0,0>, 0,
                PRIM_TEXTURE, 5, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25,0,0>, 0,
                
                PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE+2),
                PRIM_SIZE, SPELLSCALE,
                PRIM_POSITION, offs3,
                PRIM_COLOR, ALL_SIDES, <1,1,1>,0 
            ];
        }else{ 
            out+= [
                PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE), 
                PRIM_POSITION, ZERO_VECTOR,
                
                PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE+1),
                PRIM_POSITION, ZERO_VECTOR,
                
                PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE+2),
                PRIM_POSITION, ZERO_VECTOR
            ];
        }
    }
    
    if(!show || BFL&BFL_DEAD || ~BFL&BFL_HAS_ABILITIES){
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
    
    if(!show)
        updateTarget("", "");
    
    llSetLinkPrimitiveParamsFast(0, out);
}

updateTarget(key targ, key texture){
    TARG = targ;
    list out;
    if(targ != ""){
        vector offs1 = <0,-.05,0.37>;
        vector offs2 = <0.05,.08,0.371>;
        vector offs3 = <0.05, 0.11, 0.354>;
        out+=[
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2),
            PRIM_POSITION, offs1,
            PRIM_COLOR, 0, ZERO_VECTOR, 1,
            PRIM_COLOR, 1, <1,1,1>, 1,
            PRIM_COLOR, 2, <1,1,1>, 0,
            PRIM_COLOR, 3, <1,1,1>, 0,
            PRIM_COLOR, 4, <1,1,1>, 0,
            PRIM_COLOR, 5, <1,1,1>, 0
        ];
        if(texture)out+=[PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0];
        out+=[
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2+1),
            PRIM_POSITION, offs2,
            PRIM_COLOR, 0, ZERO_VECTOR, .25,
            PRIM_COLOR, 1, ZERO_VECTOR, .5,
            PRIM_COLOR, 2, <1,.5,.5>, 1,
            PRIM_COLOR, 3, <.5,.8,1>, 1,
            PRIM_COLOR, 4, <1,.5,1>, 1,
            PRIM_COLOR, 5, <.5,.5,1>, 1,
            
            PRIM_TEXTURE, 2, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25,0,0>, 0,
            PRIM_TEXTURE, 3, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25,0,0>, 0,
            PRIM_TEXTURE, 4, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25,0,0>, 0,
            PRIM_TEXTURE, 5, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25,0,0>, 0
        ];
        
        out+=[
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2+2),
            PRIM_POSITION, offs3,
            PRIM_SIZE, SPELLSCALE,
            PRIM_COLOR, ALL_SIDES, <1,1,1>,0 
        ];
        
    }else{
        out+= [
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2), 
            PRIM_POSITION, ZERO_VECTOR,
                
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2+1),
            PRIM_POSITION, ZERO_VECTOR,
            
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2+2),
            PRIM_POSITION, ZERO_VECTOR
        ];
    }
    llSetLinkPrimitiveParamsFast(0, out);
}

ini(){
    toggle(TRUE);
}

default 
{
    state_entry(){
        links_each(nr, name, 
            integer n = (integer)llGetSubString(name, -1, -1); 
            if(
                llGetSubString(name, 0, 2) == "FRB" || 
                llGetSubString(name, 0, 1) == "FR" || 
                llGetSubString(name, 0, 1) == "OP"
            ){
                integer pos = (n-1)*BAR_STRIDE; 
                if(llGetSubString(name, 0, 1) == "FR")pos+=BAR_STRIDE*2;
                if(llGetSubString(name, 2, 2) == "B")pos++;
                if(llGetSubString(name, 2, 2) == "S")pos+=2;
                if(llGetSubString(name, 3, 3) == "O")pos++;
                BARS = llListReplaceList(BARS, [nr], pos, pos);
            }
            else if(llGetSubString(name, 0, 3) == "Abil"){
                ABILS = llListReplaceList(ABILS, [nr], n, n);
            }
            else if(name == "RETRY")P_RETRY = nr;
            else if(name == "QUIT")P_QUIT = nr;
            
        )
        toggle(FALSE);
        db2$ini(); 
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
    if(method$isCallback){
        if(SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared){
            ini();
        }
        return;
    }
    
    if(id == ""){
        if(METHOD == GUIMethod$setGlobalCooldowns){
            list cds = llJson2List(PARAMS);
            float time = llList2Float(cds, 0);
            cds = llDeleteSubList(cds, 0, 0);
            list out;
            
            integer i;
            for(i=0; i<llGetListLength(cds); i++){
                if(llList2Integer(cds, i) == 1){
                    llSetLinkTextureAnim(llList2Integer(ABILS, i), 0, 2, 4,32, 0,32, 0);
                    out+= [PRIM_LINK_TARGET, llList2Integer(ABILS, i), PRIM_COLOR,0,ZERO_VECTOR,.1, PRIM_COLOR, 2, ZERO_VECTOR, 1, PRIM_TEXTURE, 2, "0c2f81c7-8ecf-92ab-0351-6bbe109f0d0a", <1,1,0>, <0,0,0>, 0];
                    llSetLinkTextureAnim(llList2Integer(ABILS, i), ANIM_ON|REVERSE, 2, 4,32, 0,0, (4.*32)/time);
                }else if(llList2Integer(cds, i) == -1)
                    out+= [PRIM_LINK_TARGET, llList2Integer(ABILS, i), PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0,ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA];
            }
            llSetLinkPrimitiveParamsFast(0, out);
        }
        
        else if(METHOD == GUIMethod$setCooldown || METHOD == GUIMethod$setCastedAbility){
            integer abil = (integer)method_arg(0)+1;
            float time = (float)method_arg(1);
            float total = (4.*32)/time;
            
            integer flags;
            float borderalpha = 1;
            vector border = <1,1,1>;
            vector color = <.5,1,.5>;
            if(METHOD == GUIMethod$setCooldown){
                color = <0,0,0>;
                border = <0,0,0>;
                borderalpha = 0.1;
                flags = REVERSE;
            }
            
            llSetLinkTextureAnim(llList2Integer(ABILS, abil), 0, 2, 4,32, 0,32, total);
            llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [PRIM_COLOR,0,border,borderalpha, PRIM_COLOR, 2, color, 1, PRIM_TEXTURE, 2, "0c2f81c7-8ecf-92ab-0351-6bbe109f0d0a", <1,1,0>, <0,0,0>, 0]);
            llSetLinkTextureAnim(llList2Integer(ABILS, abil), ANIM_ON|flags, 2, 4,32, 0,0, total);
        }
        else if(METHOD == GUIMethod$stopCast){
            integer abil = (integer)method_arg(0)+1;
            llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [PRIM_COLOR, 2, <1,1,1>, 0, PRIM_COLOR,0,ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA]);
        }
        
    }
    
    if(METHOD == GUIMethod$status){
        id2bars(1) // Fetches bars
        
        if(bars == [])return;  
        
        list out = [];
        
        float ars = (float)method_arg(2);
        float pin = (float)method_arg(3);
                
        list dta = [
            PRIM_TEXTURE, 2, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25-.5*(float)method_arg(0),0,0>, 0,
            PRIM_TEXTURE, 3, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25-.5*(float)method_arg(1),0,0>, 0,
            PRIM_TEXTURE, 4, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25-.5*ars,0,0>, 0,
            PRIM_COLOR, 4, <1,.5,1>*(.5+ars*.5), 0.5+(float)llFloor(ars)/2,
            PRIM_TEXTURE, 5, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25-.5*pin,0,0>, 0,
            PRIM_COLOR, 5, <.5,.5,1>*(.5+pin*.5), 0.5+(float)llFloor(pin)/2
        ];
        
        integer i;
        for(i=0; i<llGetListLength(bars); i++){
            out+=[PRIM_LINK_TARGET, llList2Integer(bars, i)]+dta;
        }
        llSetLinkPrimitiveParams(0, out);
    }
    
    else if(METHOD == GUIMethod$setSpellTextures){
        id2bars(2) // Fetches bars
        
        list data = llJson2List(method_arg(0));
        
        list out = [];
        
        
        integer a;
        for(a = 0; a<llGetListLength(bars); a++){
            out+=[PRIM_LINK_TARGET, llList2Integer(bars, a)];            
            integer i;
            for(i=0; i<8; i++){
                if(llGetListLength(data)>i)
                    out += [PRIM_COLOR, i, <1,1,1>, 1, PRIM_TEXTURE, i, llList2String(data, i), <1,1,0>, ZERO_VECTOR, 0];
                else
                    out += [PRIM_COLOR, i, <1,1,1>, 0];
            }
        }
        llSetLinkPrimitiveParamsFast(0, out);
            
    }
    
    
    
    else if(METHOD == GUIMethod$toggleQuit){
        integer on = (integer)method_arg(0);
        integer isHost = (integer)method_arg(0);
        list out;
        if(on){
            out+= [
                PRIM_LINK_TARGET, P_QUIT,
                PRIM_TEXTURE, 0, "a1370798-059b-a067-3bbb-cb4fbfd2e881", <1,.5,0>, <0.,-0.25,0>, 0,
                PRIM_POSITION, RPB_ROOT_POS,
                PRIM_SIZE, RPB_SCALE
           ];
           if(isHost && _statusFlags()&StatusFlag$inLevel){
                out+=[
                    PRIM_LINK_TARGET, P_RETRY,
                    PRIM_TEXTURE, 0, "a1370798-059b-a067-3bbb-cb4fbfd2e881", <1,.5,0>, <0.,0.25,0>, 0,
                    PRIM_POSITION, RPB_ROOT_POS+<0,0,.042>,
                    PRIM_SIZE, RPB_SCALE
                ];
           }
        }else{
            out+= [
                PRIM_LINK_TARGET, P_QUIT,
                PRIM_POSITION, ZERO_VECTOR,
                PRIM_LINK_TARGET, P_RETRY,
                PRIM_POSITION, ZERO_VECTOR
            ];
        }
        
        llSetLinkPrimitiveParamsFast(0,out);
    }
    else if(METHOD == GUIMethod$setSpells){
        list spells = llJson2List(db2$get(BridgeSpells$name, []));
        
        list set = [
            PRIM_LINK_TARGET, llList2Integer(ABILS, 0),
            PRIM_TEXTURE, 1, "46267af8-9c21-3c16-6afe-9861882009fd", <1,1,0>, <0,0,0>,0,
            PRIM_COLOR, 1, <1,1,1>, 1
        ];
        
        integer i;
        for(i=0; i<llGetListLength(spells); i++){
            string v = llList2String(spells, i);
            set += [
                PRIM_LINK_TARGET, llList2Integer(ABILS, i+1),
                PRIM_TEXTURE, 1, jVal(v, [BSSAA$TEXTURE]), <1,1,0>, <0,0,0>,0,
                PRIM_COLOR, 1, <1,1,1>, 1
            ];
        }
        BFL = BFL|BFL_HAS_ABILITIES;
        llSetLinkPrimitiveParamsFast(0, set);
        toggle(TRUE);
    }
    
    else if(METHOD == GUIMethod$close)toggle(FALSE);

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
