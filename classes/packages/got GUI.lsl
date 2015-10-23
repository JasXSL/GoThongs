#define USE_EVENTS
#define USE_SHARED ["#ROOT", "got Bridge", BridgeSpells$name]
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

integer BFL;
#define BFL_BROWSER_SHOWN 0x1
#define BFL_DEAD 0x2

#define BAR_STRIDE 4
list BARS = [0,0,0,0,0,0,0,0,0,0,0,0];  // [(int)portrait, (int)bars, (int)spells, (int)spells_overlays], self, friend, target

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
			PLAYERS = llJson2List(data);
            toggle(TRUE);
            
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
    list players = PLAYERS;
    
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


updateBars(key id, list data){
	id2bars(1)
	if(bars == [])return;  
			
	list out = [];
		
	float ars = llList2Float(data, 2);
	float pin = llList2Float(data, 3);
				
	list dta = [
		PRIM_TEXTURE, 2, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25-.5*llList2Float(data, 0),0,0>, 0,
		PRIM_TEXTURE, 3, "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e", <.5,1,0>, <.25-.5*llList2Float(data, 1),0,0>, 0,
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

updateSpellIcons(key id, list data){
	id2bars(2)
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
            else if(name == "RETRY")P_RETRY = nr;
            else if(name == "QUIT")P_QUIT = nr;
            
        ) 
        toggle(FALSE);
        db2$ini(); 
		PLAYERS = [(string)llGetOwner()];
		llListen(GUI_CHAN(llGetOwner()), "", "", "");
    } 
	
	listen(integer chan, string name, key id, string message){
		if(llGetSubString(message, 0, 0) != "🐙"){ // Unicode U+1F419
			return;
		}
		string owner = llGetOwnerKey(id);
		if(llListFindList(PLAYERS, [owner]) == -1)return;
		
		string task = llGetSubString(message, 1, 1);
		message = llDeleteSubString(message, 0, 1);
		list split = llCSV2List(message);
		if(llList2String(split, 0) == "")split = [];
		if(task == "A")updateBars(id, split);
		else if(task == "B")updateSpellIcons(id, split);
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
    
	// Updates status and stuff
	if(method$internal){
		if(METHOD == GUIMethod$status){
			updateBars(id, llJson2List(PARAMS));
		}
		
		// Sets spell icons
		else if(METHOD == GUIMethod$setSpellTextures){
			id2bars(2) // Fetches bars
			updateSpellIcons(id, llJson2List(PARAMS));
		}
		
    }

    
    // This needs to show the proper breakfree messages
    if(METHOD == GUIMethod$toggleQuit){
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
	
	
	
    
    
    else if(METHOD == GUIMethod$toggle)toggle((integer)method_arg(0));

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
