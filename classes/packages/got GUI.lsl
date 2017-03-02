#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define TEXTURE_NUMBERS "176e096d-7a43-9f72-1eb1-f58c186bca8d"

integer BFL;
#define BFL_TOGGLED 0x1
#define BFL_FIRST_ENABLED 0x2		// If it's been enabled manually
#define BFL_UPDATE_QUEUE 0x4		// Bars update queue

#define BAR_STRIDE 2
list BARS = [0,0,0,0,0,0];  // [(int)portrait, (int)bars], self, friend, target
list FX_PRIMS = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

list SPELL_UPDATE_QUEUE;	// (key)id, (csv)data 
#define SUQSTRIDE 2

integer TEAM = TEAM_PC;

key TARG;
key COOP_HUD;
list PLAYERS;
key default_tx = "f5c7e300-20d9-204c-b0f7-19b1b19a3e8e";
integer CACHE_FX_FLAGS = 0;

integer P_QUIT;
integer P_RETRY;
#define RPB_SCALE <0.15643, 0.04446, 0.03635>*1.25
#define RPB_ROOT_POS <-0.074654, 0.0, 0.31>

integer P_BOSS_HP;
#define P_BOSS_HP_POS <-0.036293, -0.023650, 1.0222>
integer P_BOSS_PORTRAIT;
#define P_BOSS_PORTRAIT_POS <-0.102600, 0.19054, 1.022949>

integer P_POTION;
#define POTION_POS <0.000000, 0.323226, 0.307781>
integer P_PROGRESS;
#define PROGRESS_POS <0.000000, -0.328401, 0.307781>

integer P_BLIND;
#define BLIND_SCALE <2.50000, 1.25000, 0.01000>
#define BLIND_POS <0.204500, 0.000000, 0.660400>

integer P_SPINNER;
#define SPINNER_POS <-0.035507, -0.000000, 0.390417>

integer P_LOADINGBAR;
#define LOADING_SCALE <0.35011, 0.04376, 0.04376>
#define LOADING_POS <-0.159409, -0.001064, 0.359453>

key boss;				// ID of boss (used if boss is a monster)

#define toggle(show) GUI$toggle(show)
#define ini() toggle(TRUE)

// Data is 
#define updateSpellIcons(id, data)  \
	integer pos = llListFindList(SPELL_UPDATE_QUEUE, [id]); \
	if(~pos) \
		SPELL_UPDATE_QUEUE = llListReplaceList(SPELL_UPDATE_QUEUE, [data], pos+1, pos+1); \
	else \
		SPELL_UPDATE_QUEUE += [id, data]; \


onEvt(string script, integer evt, list data){
    if(script == "#ROOT"){
        if(evt == RootEvt$targ){
            updateTarget(l2s(data, 0), l2s(data, 1), l2i(data, 2));
        }else if(evt == RootEvt$players){
			PLAYERS = data;
			toggle(TRUE);
        }
		else if(evt == RootEvt$coop_hud){
			COOP_HUD = l2k(data, 1);
		}
    }
	else if(script == "got Status" && evt == StatusEvt$team){
		TEAM = l2i(data,0);
	}
}


updateTarget(key targ, key texture, integer team){
    TARG = targ;
    list out;
    if(targ != ""){
        vector offs1 = <0,-.05,0.37>;
        vector offs2 = <0.05,.08,0.371>;
        vector offs3 = <0.05, 0.11, 0.354>;
		
		vector color = <.5,1,.5>;
		if(team != TEAM)
			color = <1,.5,.5>;
		
        out+=[
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2),
            PRIM_POSITION, offs1,
            PRIM_COLOR, 0, color, 1,
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
            
            PRIM_TEXTURE, 2, default_tx, <.5,1,0>, <.25,0,0>, 0,
            PRIM_TEXTURE, 3, default_tx, <.5,1,0>, <.25,0,0>, 0,
            PRIM_TEXTURE, 4, default_tx, <.5,1,0>, <.25,0,0>, 0,
            PRIM_TEXTURE, 5, default_tx, <.5,1,0>, <.25,0,0>, 0
        ];
        integer i;
		for(i=16; i<24; i++){
			out+= [
				PRIM_LINK_TARGET, llList2Integer(FX_PRIMS, i), 
				PRIM_POSITION, <0.044754, 0.048681+0.022*(i-16), 0.352110>,
				PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0
			];
		}
    }else{
        out+= [
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2), 
            PRIM_POSITION, ZERO_VECTOR,
            PRIM_LINK_TARGET, llList2Integer(BARS, BAR_STRIDE*2+1),
            PRIM_POSITION, ZERO_VECTOR
        ];
		integer i;
		for(i=16; i<24; i++){
			// Spinner
			out+= [
				PRIM_LINK_TARGET, llList2Integer(FX_PRIMS, i), 
				PRIM_POSITION, ZERO_VECTOR, 
				PRIM_TEXTURE, 2, "23b2ec39-ee06-58f7-bf37-47a50e0071dc", <1./16,1./16,0>, <1./32-1./16*8, 1./32-1./16*9, 0>, 0
			];
		}
    }
	// Make sure target status is scheduled for update
	status_pre = llListReplaceList(status_pre, [0], 2, 2);
    llSetLinkPrimitiveParamsFast(0, out);
}


integer GCHAN;
list status_pre;
integer statusChanged(list check){
	if(check != status_pre)return TRUE;
	integer i;
	for(i=0; i<count(check); i++){
		if(l2i(check, i) != l2i(status_pre, i))return TRUE;
	}
	return FALSE;
}

default 
{

	timer(){
		// Tick the updates
		
		list statuses = [
			llGetKey(), COOP_HUD, TARG, boss
		];
		list out = [];
		
		if(llKey2Name(boss) == "" && boss != ""){
			GUI$toggleBoss(LINK_THIS, "", FALSE);
			/*
			boss = "";
			Status$toggleBossFight(false);
			statuses = llListReplaceList(statuses, [""], 3, 3);
			*/
		}
		
		
		// Loops through the keys above and sets to -1 if not found, or a bitwise resource block
		integer i;
		for(i=0; i<llGetListLength(statuses); i++){
			integer n = -1;
			key t = l2k(statuses, i);
			
			if(t){
				list data = llGetObjectDetails(t, [OBJECT_ATTACHED_POINT, OBJECT_DESC]);
				list split = explode("$", l2s(data, 1));
				n = l2i(split, 2);
				// PC
				if(l2i(data, 0))
					n = l2i(split, 0);
			}
			
			statuses = llListReplaceList(statuses, [n], i, i);
		}
		
		
		
		// Update bars if changed
		
		if(statusChanged(statuses)){
			status_pre = statuses;
			
			// Cycle status bars
			for(i=0; i<count(statuses); i++){
				integer n = l2i(statuses, i);
				if(~n){				
					integer bar = llList2Integer(BARS, 1); 							// Owner
					if(i == 2)bar = llList2Integer(BARS, BAR_STRIDE*2+1); 			// Targ
					else if(i == 1)bar = llList2Integer(BARS, BAR_STRIDE+1);		// Coop
					
					
					float hp = (n>>21&127) / 127.0;
					float mana = (n>>14&127) / 127.0;
					float ars = (n>>7&127) / 127.0;
					float pin = (n&127) / 127.0;
					
					list dta = [
						PRIM_TEXTURE, 2, default_tx, <.5,1,0>, <.25-.5*hp,0,0>, 0,
						PRIM_TEXTURE, 3, default_tx, <.5,1,0>, <.25-.5*mana,0,0>, 0,
						PRIM_TEXTURE, 4, default_tx, <.5,1,0>, <.25-.5*ars,0,0>, 0,
						PRIM_COLOR, 4, <1,.5,1>*(.5+ars*.5), 0.5+(float)floor(ars)/2,
						PRIM_TEXTURE, 5, default_tx, <.5,1,0>, <.25-.5*pin,0,0>, 0,
						PRIM_COLOR, 5, <.5,.5,1>*(.5+pin*.5), 0.5+(float)floor(pin)/2
					];
					
					// Boss top bar
					if(i == 3){
						bar = P_BOSS_HP;
						dta = [
							PRIM_TEXTURE, 2, default_tx, <0.5,1,0>, <.25-.5*hp,0,0>, 0
						];
					}
					
					out+=[PRIM_LINK_TARGET, bar]+dta;
				}
			}
		}

		// Updates spell icons
		integer snap = timeSnap();
		@execIconUpdateContinue;
		while(SPELL_UPDATE_QUEUE){
			
			key id = l2k(SPELL_UPDATE_QUEUE, 0);										// User ID
			list data = [];						// Strided data of [(int)pid, (key)texture, (int)added_ms, (int)duration_ms, (int)stacks]
			if(l2s(SPELL_UPDATE_QUEUE, 1))data = llCSV2List(l2s(SPELL_UPDATE_QUEUE, 1));
			SPELL_UPDATE_QUEUE = llDeleteSubList(SPELL_UPDATE_QUEUE, 0, SUQSTRIDE-1);
			
			list bars; 																	// Offset for linknumbers
			integer stride = 5;															// Stride of data
			
			if(id == "")id = llGetKey();
			// These aren't bars so we can't use id2bars
			if(id == llGetKey())bars+=0;
			if(id == TARG)bars += 2;
			if(id == COOP_HUD)bars += 1;
				
			if(bars == [])
				jump execIconUpdateContinue;

			//integer n = (integer)val;
			
			integer slot; 																// Index of icon slot
			list block = [];															// A block of data to set
			integer x;																	// Iterator for nrs to add blocks
			
			
			// Cycle over the icons 
			integer i;
			for(i=0; i<llGetListLength(data); i+=stride){
				key texture = llList2Key(data, i+1);
				integer added = llList2Integer(data, i+2);
				integer duration = llList2Integer(data, i+3);
				float dur = (float)duration/10;
				integer stacks = llList2Integer(data, i+4);
				string description = llList2String(data, i);
				
				// Make sure the effect hasn't already expired
				if(duration+added > timeSnap()){
					float percentage = ((float)(snap-added)/dur)/10;
					block=[
						PRIM_COLOR, ALL_SIDES, <1,1,1>,0,
						PRIM_COLOR, 0, <0,0,0>, 0.5,
						PRIM_COLOR, 1, <1,1,1>, 1,
						PRIM_COLOR, 2, ZERO_VECTOR, 0.8,
						
						PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0,
						PRIM_DESC, description
					];
					if(stacks>1){
						if(stacks >15)stacks = 15;
						// The texture begins at 1, not 0
						block+= [
							PRIM_COLOR, 3, <1,1,1>, 0.9, 
							PRIM_TEXTURE, 3, TEXTURE_NUMBERS, <1./16, 1,0>, <-1./16*8+1./32+(1./16*(stacks-1)), 0,0>, 0
						];
					}
					float end = 16*16;
					integer start = llRound(end*percentage);
					
					for(x=0; x<count(bars); x++){
						integer link = l2i(FX_PRIMS, 8*l2i(bars,x)+slot);
						llSetLinkTextureAnim(link, 0, 2, 0, 0, 0, 0, 0);
						llSetLinkTextureAnim(link, ANIM_ON, 2, 16, 16, start, end-start, end/dur);
						
						out+= [PRIM_LINK_TARGET,link]+block;
					}
					
					slot++;
				}
			}
			
			
			block =[
				PRIM_COLOR, ALL_SIDES, <1,1,1>,0,
				PRIM_DESC, "-1"
			];
			
			// Cycle over unset icons
			for(i=slot; i<8; i++){
				for(x=0; x<count(bars); x++)
					out+= [PRIM_LINK_TARGET,l2i(FX_PRIMS, 8*l2i(bars,x)+i)]+block;
			}
		}
		
		
		if(out)
			llSetLinkPrimitiveParams(0, out);
		
	}
	
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
                if(llGetSubString(name, 3, 3) == "O")pos++;
                BARS = llListReplaceList(BARS, [nr], pos, pos);
            }
			else if(llGetSubString(name, 0, 1) == "FX"){
				n = (int)llGetSubString(name, 2, -1);
				FX_PRIMS = llListReplaceList(FX_PRIMS, [nr], n, n);
			}
			else if(name == "LOADING")P_LOADINGBAR = nr;
            else if(name == "RETRY")P_RETRY = nr;
            else if(name == "QUIT")P_QUIT = nr;
            else if(name == "SPINNER")P_SPINNER = nr;
			else if(name == "BLIND")P_BLIND = nr;
			else if(name == "POTION")P_POTION = nr;
			else if(name == "PROGRESS")P_PROGRESS = nr;
			else if(name == "BOSS_HEALTH")P_BOSS_HP = nr;
			else if(name == "BOSS_PORTRAIT")P_BOSS_PORTRAIT = nr;
			//else if(name == "SingleFace")singles+= ([PRIM_LINK_TARGET, nr, PRIM_POSITION, <.1,0,0>]);
        ) 
		//return;

        toggle(FALSE);
		PLAYERS = [(string)llGetOwner()];
		GCHAN = GUI_CHAN(llGetOwner());
		llListen(GCHAN, "", "", "");
		llListen(GCHAN+1, "", "", "");
		llSetTimerEvent(0.5); // tick status bars
		
    } 
	
	listen(integer chan, string name, key id, string message){
		if(chan == GCHAN+1){
			updateSpellIcons(id, message);
		}
	}

    // This is the standard linkmessages
	//#define LM_PRE qd((str)link+" :: "+(str)nr+" :: "+(str)id+" :: "+(str)s);
	#define LM_PRE \
	if(nr == TASK_FX){ \
		integer flags = (int)j(s, 0); \
		if(flags == CACHE_FX_FLAGS)return; \
		if( \
			(flags&fx$F_BLINDED && ~CACHE_FX_FLAGS&fx$F_BLINDED) || \
			(~flags&fx$F_BLINDED && CACHE_FX_FLAGS&fx$F_BLINDED) \
		){ \
			integer on; \
			if(flags&fx$F_BLINDED)on = TRUE; \
			list d = [PRIM_POSITION, BLIND_POS, PRIM_SIZE, BLIND_SCALE]; \
			if(!on)d = [PRIM_POSITION, ZERO_VECTOR, PRIM_SIZE, ZERO_VECTOR]; \
			llSetLinkPrimitiveParams(P_BLIND, d); \
		} \
		CACHE_FX_FLAGS = flags; \
	}
	
    #include "xobj_core/_LM.lsl" 
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }

	// Updates status and stuff
	if(method$internal && METHOD == GUIMethod$setSpellTextures){
		updateSpellIcons(id, llList2CSV(PARAMS));
    }
	
	// Toggles the boss portrait
	if(METHOD == GUIMethod$toggleBoss){
		if(~BFL&BFL_TOGGLED)return;
		list out = [
			PRIM_LINK_TARGET, P_BOSS_PORTRAIT,
			PRIM_POSITION, ZERO_VECTOR,
			PRIM_LINK_TARGET, P_BOSS_HP,
			PRIM_POSITION, ZERO_VECTOR
		];
		
		boss = "";
		
		integer exists = FALSE;
		if((key)method_arg(0)){
			
			// If not forcing manual HP updates
			if(!l2i(PARAMS, 1))
				boss = id;
			
			
			out = [
				PRIM_LINK_TARGET, P_BOSS_PORTRAIT,
				PRIM_POSITION, P_BOSS_PORTRAIT_POS,
				PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
				PRIM_COLOR, 0, ZERO_VECTOR,1,
				PRIM_COLOR, 1, <1,1,1>,1,
				PRIM_TEXTURE, 1, method_arg(0), <1,1,1>, ZERO_VECTOR, 0,
				PRIM_LINK_TARGET, P_BOSS_HP,
				PRIM_POSITION, P_BOSS_HP_POS,
				PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
				PRIM_COLOR, 0, ZERO_VECTOR, 0.75,
				PRIM_COLOR, 1, ZERO_VECTOR, 0.5,
				PRIM_COLOR, 2, <1,.5,.5>, 1,
				PRIM_TEXTURE, 2, default_tx, <0.5,1,0>, <-0.25,0,0>, 0
			];
			exists = TRUE;
		}
		PP(0,out);
		Status$toggleBossFight(exists);
	}
	// Sets boss bar HP
	else if(METHOD == GUIMethod$bossHP){
		llSetLinkPrimitiveParamsFast(P_BOSS_HP, [
			PRIM_TEXTURE, 2, default_tx, <0.5,1,0>, <0.25-((float)method_arg(0)*.5),0,0>, 0
		]);
	}
    // This needs to show the proper breakfree messages
    else if(METHOD == GUIMethod$toggleQuit){
        integer on = (integer)method_arg(0);
        list out;
        if(on){
            out+= [
                PRIM_LINK_TARGET, P_QUIT,
                PRIM_TEXTURE, 0, "d44be195-0e8a-1a25-c3ed-c5372b8e39ad", <1,.5,0>, <0.,0.25,0>, 0,
                PRIM_POSITION, RPB_ROOT_POS,
                PRIM_SIZE, RPB_SCALE
           ];
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
	else if(METHOD == GUIMethod$toggleObjectives){
		integer on = (integer)method_arg(0);
		list data = [PRIM_POSITION, ZERO_VECTOR];
		if(on)data = [PRIM_POSITION, PROGRESS_POS, PRIM_COLOR, ALL_SIDES, <1,1,1>, 0, PRIM_COLOR, 5, <1,1,1>, 1, PRIM_COLOR, 0, <1,1,1>,.5];
		llSetLinkPrimitiveParamsFast(P_PROGRESS, data);
	}
	else if(METHOD == GUIMethod$togglePotion){
		key texture = method_arg(0);
		integer stacks = (int)method_arg(1);
		if(stacks>9)stacks = 9;
		list data = [PRIM_POSITION, ZERO_VECTOR];
		if(texture){
			data = [
				PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
				PRIM_POSITION, POTION_POS, PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0, 
				PRIM_COLOR, 0, <1,1,1>, .5,
				PRIM_COLOR, 1, <1,1,1>, 1
			];
			if(stacks>0){
				data+=[
					PRIM_COLOR, 4, <1,1,1>, 1,
					PRIM_TEXTURE, 4, "cd23a6a1-3d0e-532c-4383-bf3e9b878d57", <1./10,1,0>, <1./20-1./10*(6-stacks), 0, 0>, 0
				];
			}
		}
		llSetLinkPrimitiveParamsFast(P_POTION, data);
	}
	else if(METHOD == GUIMethod$potionCD){
		float cd = (float)method_arg(0);
		list out = [PRIM_COLOR, 2, <0,0,0>, 0];
		if(cd>0){
			llSetLinkTextureAnim(P_POTION, 0, 2, 16, 16, 0, 0, 0);
			out = [PRIM_COLOR, 2, <0,0,0>, .5, PRIM_TEXTURE, 2, "a0adbf17-dc55-9bd3-879e-4ba5527063b4", <1./16,1./16,0>, <1./32-1./16*8, 1./32-1./16*9, 0>,0];
			llSetLinkTextureAnim(P_POTION, ANIM_ON, 2, 16, 16, 0, 0, 16.*16./cd);
		}
		llSetLinkPrimitiveParamsFast(P_POTION, out);
	}
	
	else if(METHOD == GUIMethod$toggleLoadingBar){
		list out = [PRIM_SIZE, ZERO_VECTOR, PRIM_POSITION, ZERO_VECTOR, PRIM_TEXT, "", ZERO_VECTOR, 0];
		if((integer)method_arg(0)){
			float time = (float)method_arg(1);
			float width = 1./4;
			float height = 1./32;
			out = [
				PRIM_SIZE, LOADING_SCALE, PRIM_POSITION, LOADING_POS,
				PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 1,
				PRIM_COLOR, 2, ZERO_VECTOR, 0,
				
				PRIM_TEXT, "...regenerating...", <1,1,1>, 1,
				PRIM_COLOR, 1, <1,1,1>, 1,
				PRIM_TEXTURE, 1, "0c2f81c7-8ecf-92ab-0351-6bbe109f0d0a", <width,height,0>, <-2*width+width/2, 16*height-height/2, 0>, 0
			];
			float fps = 4*32/time;
			llSetLinkTextureAnim(P_LOADINGBAR, ANIM_ON, 1, 4,32, 0,0, fps);
		}
		llSetLinkPrimitiveParamsFast(P_LOADINGBAR, out);
	}
	else if(METHOD == GUIMethod$toggleSpinner){
		integer on = (integer)method_arg(0);
		string text = method_arg(1);
		if(!isset(text))text = "Loading...";
		
		list out = [PRIM_POSITION, ZERO_VECTOR, PRIM_TEXT, "", ZERO_VECTOR, 0];
		if(on){
			out = [PRIM_POSITION, SPINNER_POS, PRIM_TEXT, text, <1,1,1>, 1];
		}
		llSetLinkTextureAnim(P_SPINNER, ANIM_ON|SMOOTH|LOOP|ROTATE, 0, 0,0, 0,TWO_PI, -10);
		llSetLinkPrimitiveParamsFast(P_SPINNER, out);
	}
	

    else if(METHOD == GUIMethod$toggle){
		integer show = l2i(PARAMS, 0);
		if(show)BFL = BFL|BFL_FIRST_ENABLED;
		if(~BFL&BFL_FIRST_ENABLED && show)return;
		
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
					
					PRIM_TEXTURE, 2, default_tx, <.5,1,0>, <-.25,0,0>, 0,
					PRIM_TEXTURE, 3, default_tx, <.5,1,0>, <-.25,0,0>, 0,
					PRIM_TEXTURE, 4, default_tx, <.5,1,0>, <.25,0,0>, 0,
					PRIM_TEXTURE, 5, default_tx, <.5,1,0>, <.25,0,0>, 0
					
				];
				integer x;
				for(x=0; x<8; x++){
					float a = x;
					vector pos = <0.044754, 0.228554, 0.234596>;
					if(i){
						pos.y = -pos.y;
						a = -a;
					}
					pos += <0,0.022*a,0>;
					out+= [
						PRIM_LINK_TARGET, llList2Integer(FX_PRIMS, i*8+x), 
						PRIM_SIZE, <0.02184, 0.02191, 0.01312>,
						PRIM_POSITION, pos,
						PRIM_COLOR, ALL_SIDES, <1,1,1>, 0
					];
				}
			}else{ 
				out+= [
					PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE), 
					PRIM_POSITION, ZERO_VECTOR,
					
					PRIM_LINK_TARGET, llList2Integer(BARS, i*BAR_STRIDE+1),
					PRIM_POSITION, ZERO_VECTOR
				];
				integer x;
				for(x=0; x<8; x++){
					out+= [
						PRIM_LINK_TARGET, llList2Integer(FX_PRIMS, i*8+x),
						PRIM_POSITION, ZERO_VECTOR,
						PRIM_TEXTURE, 2, "23b2ec39-ee06-58f7-bf37-47a50e0071dc", <1./16,1./16,0>, <1./32-1./16*8, 1./32-1./16*9, 0>, 0
					];
				}
			}
		}
		
		BFL = BFL|BFL_TOGGLED;
		
		if(!show){
			BFL = BFL&~BFL_TOGGLED;
			GUI$toggleLoadingBar((string)LINK_THIS, FALSE, 0);
			GUI$toggleSpinner((string)LINK_THIS, FALSE, "");
			out+= [
				PRIM_LINK_TARGET, P_BOSS_HP, PRIM_POSITION, ZERO_VECTOR,
				PRIM_LINK_TARGET, P_BOSS_PORTRAIT, PRIM_POSITION, ZERO_VECTOR,
				
				PRIM_LINK_TARGET, P_BLIND, PRIM_POSITION, ZERO_VECTOR, PRIM_SIZE, ZERO_VECTOR,
				PRIM_LINK_TARGET, P_POTION, PRIM_POSITION, ZERO_VECTOR,
				PRIM_LINK_TARGET, P_PROGRESS, PRIM_POSITION, ZERO_VECTOR
			];
			updateTarget("","",0);
		}
		
		llSetLinkPrimitiveParamsFast(0, out);
	}

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
	
}
