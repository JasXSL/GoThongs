#define LM_NO_CALLBACKS
#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define TEXTURE_NUMBERS "176e096d-7a43-9f72-1eb1-f58c186bca8d"
#define TEXTURE_ROLES "8b7f71e3-d440-c2fa-11b2-2a603349102e"

integer BFL;
#define BFL_TOGGLED 0x1
#define BFL_FIRST_ENABLED 0x2		// If it's been enabled manually
#define BFL_UPDATE_QUEUE 0x4		// Bars update queue
#define BFL_LOADING_SCREEN 0x8

#define BARS$getPortrait( array ) ((array>>16)&0xFF)
#define BARS$getBars( array ) ((array>>8)&0xFF)
#define BARS$getRole( array ) (array&0xFF)

#define BARS$setPortrait( array, prim ) (array|(prim<<16))
#define BARS$setBars( array, prim ) (array|(prim<<8))
#define BARS$setRole( array,prim ) (array|prim)

#define BAR_TARGET 0
#define BAR_SELF 1
#define BAR_COOP0 2
#define BAR_COOP1 3
#define BAR_COOP2 4

// 
#define getFxPrim( index ) ((l2i(FX_PRIMS, index/4)>>(index%4)*8)&0xFF)
#define setFxPrim( index, val ) FX_PRIMS = llListReplaceList(FX_PRIMS, (list)((l2i(FX_PRIMS, index/4)&~(0xFF<<(index%4)*8))|(val<<((index%4)*8))), index/4, index/4)

list BARS = [0,0,0,0,0];  	// Bitwise storing prims: (uint8)portrait (uint8)bars (uint8)role For: target, self, coop0, coop1, coop2
list FX_PRIMS = [0,0,0,0];	// 8bit blocks of prims. First 2 are self, second 2 are target
list PARTY_ICONS = [];

// Rez tracker
int P_SKULL;
int P_SKULL_NR;
#define SKULL_SIZE <0.02813, 0.02813, 0.02240>
#define SKULL_POS <0.000000, 0.203495, 0.264575>
#define SKULL_TEXT_POS <-0.010000, 0.204623, 0.266049>

int P_ARMOR;
#define ARMOR_SCALE <0.032596, 0.032596, 0.025960>
#define ARMOR_POS <-0.068990, 0.174857, 0.265924>

list SPELL_UPDATE_QUEUE;	// (key)id, (csv)data 
#define SUQSTRIDE 2

integer TEAM = TEAM_PC;

key TARG;
list PLAYER_HUDS;
key TARG_FOCUS;
#define FOCUS_BORDER <0.820, 0.820, 0.820>

// Bar textures
#define default_tx GUI$BAR_TEXTURE
integer CACHE_FX_FLAGS = 0;

integer P_QUIT;
#define RPB_SCALE <0.15643, 0.04446, 0.03635>*1.25
#define RPB_ROOT_POS <-0.074654, 0.0, 0.31>

integer P_BOSS_HP;
#define P_BOSS_HP_POS <-0.036293, -0.023650, 1.0222>
integer P_BOSS_PORTRAIT;
#define P_BOSS_PORTRAIT_POS <-0.102600, 0.19054, 1.022949>

integer P_PROGRESS;
#define PROGRESS_POS <0.000000, -0.328401, 0.307781>

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
		SPELL_UPDATE_QUEUE += [id, data]; 

#define onEvt(script, evt, data) \
    if(script == "#ROOT"){ \
        if(evt == RootEvt$targ){ \
            key targ = l2s(data, 0); \
			key texture = l2s(data, 1); \
			integer team = l2i(data, 2); \
			TARG = targ; \
			int bar = l2i(BARS, BAR_TARGET); \
			list out = [ \
				PRIM_LINK_TARGET, BARS$getPortrait(bar),  \
				PRIM_POSITION, ZERO_VECTOR, \
				PRIM_LINK_TARGET, BARS$getBars(bar), \
				PRIM_POSITION, ZERO_VECTOR \
			]; \
			integer i; \
			for(i=8; i<16; i++){ \
				out+= [ \
					PRIM_LINK_TARGET, getFxPrim(i),  \
					PRIM_POSITION, ZERO_VECTOR,  \
					PRIM_TEXTURE, 2, "23b2ec39-ee06-58f7-bf37-47a50e0071dc", <1./16,1./16,0>, <1./32-1./16*8, 1./32-1./16*9, 0>, 0  \
				]; \
			} \
			if( targ != "" ){ \
				vector offs1 = <0,-.05,0.37>; \
				vector offs2 = <0.05,.08,0.371>; \
				vector base_offs = <0,0,.02>; \
				 \
				vector color = <.5,1,.5>; \
				if(team != TEAM) \
					color = <1,.5,.5>; \
				 \
				out=[ \
					PRIM_LINK_TARGET, BARS$getPortrait(bar), \
					PRIM_POSITION, offs1+base_offs, \
					PRIM_COLOR, 0, color, 1, \
					PRIM_COLOR, 1, <1,1,1>, 1, \
					PRIM_COLOR, 2, <1,1,1>, 0, \
					PRIM_COLOR, 3, <1,1,1>, 0, \
					PRIM_COLOR, 4, <1,1,1>, 0, \
					PRIM_COLOR, 5, <1,1,1>, 0 \
				]; \
				if(texture)out+=[PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0]; \
				out+=[ \
					PRIM_LINK_TARGET, BARS$getBars(bar), \
					PRIM_POSITION, offs2+base_offs, \
					PRIM_COLOR, 0, ZERO_VECTOR, .25, \
					PRIM_COLOR, 1, ZERO_VECTOR, .5, \
					PRIM_COLOR, 2, <1,.5,.5>, 1, \
					PRIM_COLOR, 3, <.5,.8,1>, 1, \
					PRIM_COLOR, 4, <1,.5,1>, 1, \
					PRIM_COLOR, 5, <.5,.5,1>, 1/*,*/ \
					/* \
					PRIM_TEXTURE, 2, default_tx, <.5,1,0>, <.25,0,0>, 0, \
					PRIM_TEXTURE, 3, default_tx, <.5,1,0>, <.25,0,0>, 0, \
					PRIM_TEXTURE, 4, default_tx, <.5,1,0>, <.25,0,0>, 0, \
					PRIM_TEXTURE, 5, default_tx, <.5,1,0>, <.25,0,0>, 0 \
					*/ \
				]; \
				integer i; \
				for(i=8; i<16; i++){ \
					out+= [ \
						PRIM_LINK_TARGET, getFxPrim(i),  \
						PRIM_POSITION, <0.044754, 0.048681+0.022*(i-8), 0.352110>+base_offs, \
						PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0 \
					]; \
				} \
			} \
			llSetLinkPrimitiveParamsFast(0, out); \
        } \
		else if(evt == RootEvt$coop_hud){ \
			PLAYER_HUDS = llListReplaceList(data, [llGetKey()], 0,0); \
			toggle(TRUE); \
		} \
		else if( evt == RootEvt$focus ){ \
			TARG_FOCUS = l2s(data, 0); \
			list out = []; integer i; \
			for( ; i<count(PLAYER_HUDS); ++i ){ \
				vector color = <0,0,0>; \
				if( l2k(PLAYER_HUDS, i) == TARG_FOCUS ) \
					color = FOCUS_BORDER; \
					\
				out+= [ \
					PRIM_LINK_TARGET, BARS$getPortrait(l2i(BARS, i+1)), \
					PRIM_COLOR, 0, color, .75 \
				]; \
			} \
			PP(0,out); \
		} \
		else if( evt == RootEvt$level ){ \
			GUI$setChallenge(l2i(data, 1)); \
		} \
    } \
	else if(script == "got Status" && evt == StatusEvt$team){ \
		TEAM = l2i(data,0); \
	} \
	else if(script == "got Status" && evt == StatusEvt$armor){ \
		int slots = Status$sumArmorSlots( l2i(data, 0) ); \
		llSetLinkPrimitiveParamsFast(P_ARMOR, (list)PRIM_TEXTURE + 0 + "bceae9a2-68d7-1dfe-1461-700a2b3ee23e" + (<1./8,1,0>) + (<-.0625-1./8*3+(1./8*(5-slots)), 0, 0>) + 0); \
	} \
	else if(script == "got Bridge" && evt == BridgeEvt$partyIcons){ \
		PARTY_ICONS = data; \
		GUI$toggle(TRUE); \
	}




integer GCHAN;
default {

	timer(){
		// Tick the updates
		if(~BFL&BFL_TOGGLED)
			return;
			
		list statuses = (list)TARG+PLAYER_HUDS+boss;
		list statuses_flags;
		list statuses_sex;
		list statuses_fx;
		integer i;
		
		
		list out = [];
		
		if( llKey2Name(boss) == "" && boss != "" )
			GUI$toggleBoss(LINK_THIS, "", FALSE);
		
		// Loops through the keys above and sets to -1 if not found, or a bitwise resource block
		for( ; i<count(statuses); ++i ){
		
			int n = -1;
			key t = l2k(statuses, i);
			int s;		// Status
			int se;		// Sex
			int fx;		// FX Flags
			if( llKey2Name(t) ){
			
				list data = llGetObjectDetails(t, [OBJECT_ATTACHED_POINT, OBJECT_DESC]);
				list split = explode("$", l2s(data, 1));
				n = l2i(split, StatusDesc$npc$RESOURCES); // Resource block
				s = l2i(split, StatusDesc$npc$STATUS);
				fx = l2i(split, StatusDesc$npc$FX);
				se = -1;	// Sex. Only relevent for player targets right now
				int mf = l2i(split, StatusDesc$npc$MONSTERFLAGS);
				
				// PC
				if( l2i(data, 0) ){ // Attached
					
					n = l2i(split, StatusDesc$pc$RESOURCES); // HP block is in a different position of the description for PC
					s = l2i(split, StatusDesc$pc$STATUS); // Same with status
					se = l2i(split, StatusDesc$pc$SEX);
					fx = l2i(split, StatusDesc$pc$FX);
					
					mf = 0;
					
				}
				
				if( i == 0 && (mf&Monster$RF_NO_TARGET || s&StatusFlag$dead) )
					Root$clearTargetIfIs(LINK_THIS, TARG);
				
			}
			
			statuses_flags += s;
			statuses_sex += se;
			statuses_fx += fx;
			statuses = llListReplaceList(statuses, (list)n, i, i);
			
		}
		
		// Cycle status bars
		for( i=0; i<count(statuses); ++i ){
		
			int n = l2i(statuses, i);
				
			int bar = BARS$getBars(l2i(BARS, i)); 						// Targ
			int portrait = BARS$getPortrait(l2i(BARS, i));
			int role = BARS$getRole(l2i(BARS, i));
			float al = 0.5;

			// Boss
			if(i == count(statuses)-1){
				bar = P_BOSS_HP;
				portrait = P_BOSS_PORTRAIT;
				al = 1;
			}
			
			
			list data_out = [PRIM_LINK_TARGET, portrait, PRIM_COLOR, 1, <1,1,1>, 1];
			
			if(~n){				
						
				list faces = [2,3,4,5]; // HP, Mana, Arousal, pain
						
				if( i > 1 && i != count(statuses)-1 )
					faces = [1,2,3,4];
						
				float hp = (n>>21&127) / 127.0;
				float mana = (n>>14&127) / 127.0;
				float ars = (n>>7&127) / 127.0;
				float pin = (n&127) / 127.0;
				integer flags = l2i(statuses_flags, i);
				int sex = l2i(statuses_sex, i);
				int fx = l2i(statuses_fx, i);
				
				vector overlay = <1,1,1>;

				if( flags&StatusFlag$dead )
					overlay = <.5,0,0>;
				else if( fx&fx$F_IMPORTANT_DISPEL )
					overlay = <.5,0,1>;
				else if( flags&StatusFlag$coopBreakfree )
					overlay = <.5,.75,1>;
						
				// Set bars
				list dta = [
					PRIM_TEXTURE, l2i(faces,0), default_tx, <.5,1,0>, <.25-.5*hp,0,0>, 0,
					PRIM_TEXTURE, l2i(faces,1), default_tx, <.5,1,0>, <.25-.5*mana,0,0>, 0,
					PRIM_TEXTURE, l2i(faces,2), default_tx, <.5,1,0>, <.25-.5*ars,0,0>, 0,
					PRIM_COLOR, l2i(faces,2), <1,.5,1>*(.5+ars*.5), 0.5+(float)floor(ars)/2,
					PRIM_TEXTURE, l2i(faces,3), default_tx, <.5,1,0>, <.25-.5*pin,0,0>, 0,
					PRIM_COLOR, l2i(faces,3), <.5,.5,1>*(.5+pin*.5), 0.5+(float)floor(pin)/2
				];

				// Boss top bar
				if(i == count(statuses)-1)
					dta = [
						PRIM_TEXTURE, 2, default_tx, <0.5,1,0>, <.25-.5*hp,0,0>, 0
					];
				
					
				data_out =
					[PRIM_LINK_TARGET, bar]+dta+
					[PRIM_LINK_TARGET, portrait, PRIM_COLOR, 1, overlay, 1]
				;
				
				data_out += (list)PRIM_LINK_TARGET + role;
				// Portrait additional
				if( ~sex )
					data_out += [
						PRIM_COLOR, 0, ONE_VECTOR, 1,
						PRIM_TEXTURE, 0, TEXTURE_ROLES, <.25,1,0>, <-.375+.25*getRoleFromSex( sex ),0,0>, 0
					];
				else
					data_out += [PRIM_COLOR, 0, ZERO_VECTOR, 0];
				
			}
	
			
			out+= data_out;
					
		}

	
		PP(0,out);
		out = [];
		
		// Updates spell icons
		integer snap = timeSnap();
		@execIconUpdateContinue;
		while(count(SPELL_UPDATE_QUEUE)){
			
			key id = l2k(SPELL_UPDATE_QUEUE, 0);										// User ID
			list data = [];		// CSV stringified strided list of [pid, sender_key, time_added_ms, duration_ms, stacks, flags]
			// Data exists
			if( l2s(SPELL_UPDATE_QUEUE, 1) )
				data = llCSV2List(l2s(SPELL_UPDATE_QUEUE, 1));
			SPELL_UPDATE_QUEUE = llDeleteSubList(SPELL_UPDATE_QUEUE, 0, SUQSTRIDE-1);

			// Select the bars that must be updated
			list bars; 																	// Offset for linknumbers
			integer stride = 6;															// Stride of data
			
			if( id == "" )
				id = llGetKey();
				
			// These aren't bars so we can't use id2bars
			if( id == llGetKey() )
				bars+=0;
				
			if( id == TARG )
				bars += 1;
				
			if( !count(bars) )
				jump execIconUpdateContinue;

			//integer n = (integer)val;
			
			integer slot; 																// Index of icon slot
			list block = [];															// A block of data to set
			integer x;																	// Iterator for nrs to add blocks
			
			
			// Cycle over the icons 
			integer i;
			for( ; i<llGetListLength(data); i+=stride ){
				
				key texture = llList2Key(data, i+1);
				integer added = llList2Integer(data, i+2);
				integer duration = llList2Integer(data, i+3);
				float dur = (float)duration/10;
				integer stacks = llList2Integer(data, i+4);
				string description = llList2String(data, i);		// PID
				int flags = l2i(data, i+5);
				
				// Make sure the effect hasn't already expired
				if( duration+added > timeSnap() ){
				
					vector border = <0.5,1,0.5>;
					if( flags & PF_DETRIMENTAL ){
					
						border = <1,0.5,0.5>;
						if( flags&PF_NO_DISPEL )
							border = <0.5,0,1>;
						
					}
				
					float percentage = ((float)(snap-added)/dur)/10;
					block=[
						PRIM_COLOR, ALL_SIDES, <1,1,1>,0,
						PRIM_COLOR, 0, border, 1,
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
					
						integer link = getFxPrim((8*l2i(bars,x)+slot));
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
					out+= [PRIM_LINK_TARGET,getFxPrim((8*l2i(bars,x)+i))]+block;
			}
		}
		
		
		if(out)
			llSetLinkPrimitiveParams(0, out);
		
	}
	
    state_entry(){
	
		PLAYER_HUDS = (list)llGetKey();

        links_each(nr, name, 
            
			int n = (int)llGetSubString(name, -1, -1); 
			str start = llGetSubString(name, 0, 1);
            if(
                start == "FR" ||  // Targ
                start == "OP" ||   // Player
				start == "SP"
            ){
			
                int pos = n; 
				int cur = l2i(BARS, pos);
				// Set bars
				if( llGetSubString(name, 2, 2) == "B" )
					cur = BARS$setBars(cur, nr);
				// Set role icon
				else if( start == "SP" )
					cur = BARS$setRole(cur, nr);
				// Set portrait
				else
					cur = BARS$setPortrait(cur, nr);
				
                BARS = llListReplaceList(BARS, (list)cur, pos, pos);
				
            }
			else if(llGetSubString(name, 0, 1) == "FX"){
			
				n = (int)llGetSubString(name, 2, -1);
				setFxPrim(n, nr);
				
			}
			else if(name == "LOADING")P_LOADINGBAR = nr;
            else if(name == "QUIT")P_QUIT = nr;
            else if(name == "SPINNER")P_SPINNER = nr;
			else if(name == "PROGRESS")P_PROGRESS = nr;
			else if(name == "BOSS_HEALTH")P_BOSS_HP = nr;
			else if(name == "BOSS_PORTRAIT")P_BOSS_PORTRAIT = nr;
			else if( name == "ARMOR" )
				P_ARMOR = nr;
			else if( name == "WCOUNT" )
				P_SKULL_NR = nr;
			else if( name == "WSKULL" )
				P_SKULL = nr;
				
			//else if(name == "SingleFace")singles+= ([PRIM_LINK_TARGET, nr, PRIM_POSITION, <.1,0,0>]);
        ) 
		//return;

        toggle(FALSE);
		GCHAN = GUI_CHAN(llGetOwner());
		llListen(GCHAN, "", "", "");
		llListen(GCHAN+1, "", "", "");
		llSetTimerEvent(0.5); // tick status bars
		//toggle(TRUE);
		llOwnerSay("@setoverlay=y");
		//GUI$toggle(TRUE);
    } 
	
	listen(integer chan, string name, key id, string message){
		if(chan == GCHAN+1 && id == TARG){
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
			~BFL&BFL_LOADING_SCREEN && (\
				(flags&fx$F_BLINDED && ~CACHE_FX_FLAGS&fx$F_BLINDED) || \
				(~flags&fx$F_BLINDED && CACHE_FX_FLAGS&fx$F_BLINDED) \
			)\
		){ \
			string out = "@setoverlay=n,setoverlay_texture:"+TEXTURE_BLANK+"=force,setoverlay_tint:0/0/0=force"; \
			if(flags&fx$F_BLINDED) \
				out+= ",setoverlay_alpha:1=force"; \
			else \
				out+= ",setoverlay_tween:0;;1=force"; \
			llOwnerSay(out); \
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
		return;
    }
	
	
	

	// Toggles the boss portrait
	if(METHOD == GUIMethod$toggleBoss && BFL&BFL_TOGGLED ){
		
		list out = [
			PRIM_LINK_TARGET, P_BOSS_PORTRAIT,
			PRIM_POSITION, ZERO_VECTOR,
			PRIM_LINK_TARGET, P_BOSS_HP,
			PRIM_POSITION, ZERO_VECTOR
		];
		
		boss = "";
		
		integer exists = FALSE;
		if( (key)method_arg(0) ){
			
			// If not forcing manual HP updates
			if( llStringLength(l2s(PARAMS, 1)) == 36 ){
				boss = l2k(PARAMS, 1);
			}
			else if(!l2i(PARAMS, 1))
				boss = id;
			
			
			out = [
				PRIM_LINK_TARGET, P_BOSS_PORTRAIT,
				PRIM_POSITION, P_BOSS_PORTRAIT_POS,
				PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
				PRIM_COLOR, 0, ZERO_VECTOR,1,
				PRIM_COLOR, 1, <1,1,1>,1,
				PRIM_TEXTURE, 1, method_arg(0), <1,1,1>, ZERO_VECTOR, 0,
				PRIM_DESC, (str)boss,
				PRIM_LINK_TARGET, P_BOSS_HP,
				PRIM_POSITION, P_BOSS_HP_POS,
				PRIM_COLOR, ALL_SIDES, <1,1,1>, 0,
				PRIM_COLOR, 0, ZERO_VECTOR, 0.75,
				PRIM_COLOR, 1, ZERO_VECTOR, 0.5,
				PRIM_COLOR, 2, <1,.5,.5>, 1,
				//PRIM_TEXTURE, 2, default_tx, <0.5,1,0>, <-0.25,0,0>, 0,
				PRIM_DESC, (str)boss
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
	
	else if( METHOD == GUIMethod$setWipes ){
		int wipes = l2i(PARAMS, 0);
		if( wipes == -1 )
			PP(P_SKULL_NR, (list)PRIM_POSITION + ZERO_VECTOR);
		else{
			int y = wipes/16;
			int x = wipes-y*16;
			PP(P_SKULL_NR, (list)PRIM_POSITION + SKULL_TEXT_POS + PRIM_TEXTURE + 0 + "b8fbd724-51ac-eef4-ab8c-e643241de558" + (<1./16, 1./4,0>) + (<-1./32-1./16*7+1./16*x,1./8+1./4-1./4*y,0>) + 0);
		}
	}
	
	else if( METHOD == GUIMethod$setChallenge ){
		
		vector pos; float alpha;
		if( l2i(PARAMS, 0) ){
			pos = SKULL_POS;
			alpha = 1;
		}
		PP(P_SKULL, (list)PRIM_POSITION + pos + PRIM_LINK_TARGET + P_SKULL_NR + PRIM_COLOR + 0 + ONE_VECTOR + alpha);
			
	}
	
	
    // This needs to show the proper breakfree messages
    else if(METHOD == GUIMethod$toggleQuit){
		integer show = l2i(PARAMS, 0);
        list out = [
            PRIM_LINK_TARGET, P_QUIT,
            PRIM_POSITION, ZERO_VECTOR
        ];
		
		if(show){
            out = [
                PRIM_LINK_TARGET, P_QUIT,
                PRIM_TEXTURE, 0, "d44be195-0e8a-1a25-c3ed-c5372b8e39ad", <1,.5,0>, <0.,0.25,0>, 0,
                PRIM_POSITION, RPB_ROOT_POS,
                PRIM_SIZE, RPB_SCALE
           ];
        }
        llSetLinkPrimitiveParamsFast(0,out);
    }
	else if( METHOD == GUIMethod$toggleObjectives ){
	
		integer on = (integer)method_arg(0);
		list data = [PRIM_POSITION, ZERO_VECTOR];
		if( on )
			data = [PRIM_POSITION, PROGRESS_POS, PRIM_COLOR, ALL_SIDES, <1,1,1>, 0, PRIM_COLOR, 5, <1,1,1>, 1, PRIM_COLOR, 0, <1,1,1>,.5];
		llSetLinkPrimitiveParamsFast(P_PROGRESS, data);
		
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
	
	else if( METHOD == GUIMethod$setOverlay ){
		
		key texture = method_arg(0);
		if( texture ){
			llOwnerSay("@setoverlay=n,setoverlay_texture:"+(str)texture+"=force,setoverlay_tint:1/1/1=force,setoverlay_alpha:1=force");
			BFL = BFL|BFL_LOADING_SCREEN;
		}
		else{
			
			BFL = BFL&~BFL_LOADING_SCREEN;
			float fade = l2f(PARAMS, 0);
			llOwnerSay("@setoverlay_tween:0;;"+(str)fade+"=force");	
			
		}
	
	}

    else if(METHOD == GUIMethod$toggle){
		
		integer show = l2i(PARAMS, 0);
		if(show){
			BFL = BFL|BFL_FIRST_ENABLED;
		}
		if( ~BFL&BFL_FIRST_ENABLED && show )
			return;

		list out;
		integer i;
		for(i=0; i<4; i++){
			integer exists = FALSE;
			if(llGetListLength(PLAYER_HUDS)>i)exists = TRUE;
			
			key texture = l2k(PARTY_ICONS, i);
			if(texture){}else{texture = "d1f4998d-edb0-4067-da12-d651a3dbe9ac";}
			
			if(show && exists){
				vector offs1 = <0,.12,0.25>;
				vector offs2 = <0,.26,0.253>;
				float width = 0.07422;
				vector scale = <0.07862, 0.01523, 0.07422>;
				vector barscale = <0.21838, 0.01000, 0.06641>;
				list colors = [2,3,4,5]; // Faces of HP, Mana, Arousal, Pain
				vector border;
				if(i){
					offs1.y=-offs1.y-(width*(i-1)*1.05);
					offs2.y=offs1.y;
					scale = <0.07422, 0.07422, 0.07862>;
					barscale = scale;
					barscale.y = 0.08394;
					colors = [1,2,3,4];
				}
				if( l2k(PLAYER_HUDS, i) == TARG_FOCUS )
					border = FOCUS_BORDER;
				
				float bgAlpha = 1;
				if(llKey2Name(l2k(PLAYER_HUDS, i)) == "")
					bgAlpha = .5;

				out+=[
					// Self
					PRIM_LINK_TARGET, BARS$getPortrait(l2i(BARS, i+1)),
					PRIM_POSITION, offs1,
					//PRIM_COLOR, 0, border, .75,
					PRIM_COLOR, 1, <1,1,1>, bgAlpha,
					PRIM_TEXTURE, 1, texture, <1,1,0>, ZERO_VECTOR, 0,
					PRIM_COLOR, 2, <1,1,1>, 0,
					PRIM_COLOR, 3, <1,1,1>, 0,
					PRIM_COLOR, 4, <1,1,1>, 0,
					PRIM_COLOR, 5, <1,1,1>, 0,
					PRIM_SIZE, scale,
					
					PRIM_LINK_TARGET, BARS$getBars(l2i(BARS, i+1)),
					PRIM_POSITION, offs2+<.05,0,0>,
					PRIM_COLOR, 0, ZERO_VECTOR, .25,
					PRIM_COLOR, 1, ZERO_VECTOR, .5,
					PRIM_COLOR, l2i(colors,0), <1,.5,.5>, 1,
					PRIM_COLOR, l2i(colors,1), <.5,.8,1>, 1,
					PRIM_COLOR, l2i(colors,2), <1,.5,1>, 1,
					PRIM_COLOR, l2i(colors,3), <.5,.5,1>, 1,
					/*
					PRIM_TEXTURE, l2i(colors,0), default_tx, <.5,1,0>, <-.25,0,0>, 0,
					PRIM_TEXTURE, l2i(colors,1), default_tx, <.5,1,0>, <-.25,0,0>, 0,
					PRIM_TEXTURE, l2i(colors,2), default_tx, <.5,1,0>, <.25,0,0>, 0,
					PRIM_TEXTURE, l2i(colors,3), default_tx, <.5,1,0>, <.25,0,0>, 0,
					*/
					PRIM_SIZE, barscale,
					
					PRIM_LINK_TARGET, BARS$getRole(l2i(BARS, i+1)),
					PRIM_POSITION, offs1+<-0.03,-0.02,0.02>,
					PRIM_SIZE, <.03,.03,.03>
					
				];
					
				// Owner only spell icons
				if(i==0){
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
							PRIM_LINK_TARGET, getFxPrim((i*8+x)), 
							PRIM_SIZE, <0.02184, 0.02191, 0.01312>,
							PRIM_POSITION, pos,
							PRIM_COLOR, ALL_SIDES, <1,1,1>, 0
						];
					}
				}
			}else{ 
				
				out+= [
					PRIM_LINK_TARGET, BARS$getPortrait(l2i(BARS, i+1)), 
					PRIM_POSITION, ZERO_VECTOR,
					PRIM_LINK_TARGET, BARS$getBars(l2i(BARS, i+1)),
					PRIM_POSITION, ZERO_VECTOR,
					PRIM_LINK_TARGET, BARS$getRole(l2i(BARS, i+1)),
					PRIM_POSITION, ZERO_VECTOR
				];
				if(i == 0){
				
					integer x;
					for( ; x<8; ++x ){
						out+= [
							PRIM_LINK_TARGET, getFxPrim(x),
							PRIM_POSITION, ZERO_VECTOR//,
							//PRIM_TEXTURE, 2, "23b2ec39-ee06-58f7-bf37-47a50e0071dc", <1./16,1./16,0>, <1./32-1./16*8, 1./32-1./16*9, 0>, 0
						];
					}
					
				}
				
				
				
			}
			llSetLinkPrimitiveParamsFast(0, out);
			out = [];
		}
		
		BFL = BFL|BFL_TOGGLED;
		
		if(!show){
			BFL = BFL&~BFL_TOGGLED;
			GUI$toggleLoadingBar((string)LINK_THIS, FALSE, 0);
			GUI$toggleSpinner((string)LINK_THIS, FALSE, "");
			out+= 
				(list)PRIM_LINK_TARGET + P_BOSS_HP + PRIM_POSITION + ZERO_VECTOR +
				PRIM_LINK_TARGET + P_BOSS_PORTRAIT + PRIM_POSITION + ZERO_VECTOR +
				PRIM_LINK_TARGET + P_PROGRESS + PRIM_POSITION + ZERO_VECTOR +
				PRIM_LINK_TARGET + P_ARMOR + PRIM_POSITION + ZERO_VECTOR +
				PRIM_TEXTURE + 0 + "bceae9a2-68d7-1dfe-1461-700a2b3ee23e" + (<1./8,1,0>) + (<-.0625-1./8*3, 0, 0>) + 0 +
				PRIM_LINK_TARGET + P_SKULL + PRIM_POSITION + ZERO_VECTOR +
				PRIM_LINK_TARGET + P_SKULL_NR + PRIM_POSITION + ZERO_VECTOR 
			;
			onEvt("#ROOT", RootEvt$targ, []);
		}else{
			out += (list)PRIM_LINK_TARGET + P_ARMOR + PRIM_POSITION + ARMOR_POS + PRIM_SIZE + ARMOR_SCALE;
		}
		llSetLinkPrimitiveParamsFast(0, out);
	}

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
	
}
