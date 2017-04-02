#define SCRIPT_IS_ROOT
#define USE_EVENTS
#define ALLOW_USER_DEBUG 1
#include "got/_core.lsl"
 
// Generic root stuff
float pressStart;
float lastclick;
integer lcb;

list PLAYER_TEXTURES;
list PLAYERS;
list COOP_HUDS;
list ADDITIONAL; 		// Additional players

key TARG;
key TARG_ICON;
integer TARG_TEAM;
integer TEAM = TEAM_PC;
integer PLAYER_FOCUS;			// Player focus target

key ROOT_LEVEL;			// Current level being played

integer BFL;
#define BFL_WILDCARD 0x1

#define refreshTarget() \
	setTarget(TARG, TARG_ICON, TRUE, -1);

// If you want to use listen override, it ends up here
// onListenOverride(integer chan, key id, string message){}

// Timer to handle double clicks and click hold
timerEvent(string id, string data){
    if(llGetSubString(id, 0, 1) == "H_"){
        integer d = (integer)data;
        d++;
        raiseEvent(evt$BUTTON_HELD_SEC, mkarr(([(integer)llGetSubString(id, 2, -1), d])));
        multiTimer([id, d, 1, FALSE]);
    }
    else if(id == "T" && llKey2Name(TARG) == "" && TARG != "")
        setTarget("", "", TRUE, 0);
	
	// Run module initialization here
	else if(id == "INI"){
		raiseEvent(evt$SCRIPT_INIT, "");
		setTarget("", "", TRUE, 0);
		RLV$clearCamera((string)LINK_THIS);
		Level$bind(llGetOwner());
	}
}


#define onEvt(script, evt, data)  \
	if(script == "got Status" && evt == StatusEvt$team && l2i(data,0) != TEAM){ \
		TEAM = l2i(data, 0); \
		refreshTarget(); \
	} \
	else if(script == "got Bridge" && evt == BridgeEvt$partyIcons) \
		PLAYER_TEXTURES = data;


integer setTarget(key t, key icon, integer force, integer team){
	// We are already targeting this and it's not a force
    if(TARG == t && !force)return FALSE;
	
    // Target is currently set but if last npc targ is not, then set it
    if(TARG != "" && t != "" && !force){
        return FALSE;
    }
	
    // ID not found and not empty
    if(llKey2Name(t) == "" && t != "")
        return FALSE;
    

    // Clear previous updates
    //if(llListFindList(getPlayers(), [(str)TARG]) == -1)
    
	// Clear current target if it has changed
	if(TARG != t){
		Status$setTargeting(TARG, FALSE);
		// You get status updates from yourself and coop partner automatically
		llPlaySound("0b81cd3f-c816-1062-332c-bca149ef1c82", .2);
	}
    
	TARG_ICON = icon;
	
	integer preFocus = PLAYER_FOCUS;
	// Make sure we target a HUD if we target a player
	if(t == llGetOwner()){
		t = llGetKey();
		PLAYER_FOCUS = 0;
	}
	else{
		integer pos = llListFindList(getPlayers(), [(str)t]);
		if(~pos){
			t = l2k(COOP_HUDS, pos);
			PLAYER_FOCUS = pos;
		}
	}
	// Try to fetch from description
	if(team == -1){
		parseDesc(t, resources, status, fx, sex, te, junk);
		team = te;
	}
    
    TARG = t;
    
    raiseEvent(RootEvt$targ, mkarr(([t, icon, team])));
    if(PLAYER_FOCUS != preFocus)
		raiseEvent(RootEvt$focus, (str)PLAYER_FOCUS);
	
	// Check if target still exists
	if(t)
		multiTimer(["T", "", 2, TRUE]);
		
    // Make sure your target knows you are targeting them
	string ta = TARG;
	if(ta == llGetKey())
		ta = (string)LINK_THIS;
    Status$setTargeting(ta, TRUE);
    
	
    return TRUE;
}

list getPlayers(){
	if(BFL&BFL_WILDCARD)return ["*"];
	return PLAYERS+ADDITIONAL;
}

#define savePlayers() raiseEvent(RootEvt$players, mkarr(getPlayers()))

default 
{
    // Initialize on attach
    on_rez(integer rawr){  
        llResetScript();
    }
    
    // Start up the script
    state_entry()
    { 
		llDialog(llGetOwner(), "Welcome to GoThongs!\nThis project is licensed under [https://creativecommons.org/licenses/by-nc-sa/4.0/ Creative Commons BY-NC-SA 4.0]\nThe [http://jasx.org/?JB=gme&JBv=%7B%22g%22%3A%22jasxhud%22%7D JasX HUD] is required for RLV and sex.\nUse the [https://github.com/JasXSL/GoThongs/ GoThongs GitHub] for issues and pull requests.", [], 123);
        clearDB3();
        PLAYERS = [(str)llGetOwner()];
        
        // pre full reset
        runOmniMethod("jas Supportcube", SupportcubeMethod$killall, [], TNN);
        // Start listening
        initiateListen(); 
		llListen(AOE_CHAN, "", "", "");
        if(llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);

		savePlayers(); 
		ThongMan$reset();
		
		// Create schema before resetting the other scripts
		list tables = [
			BridgeSpells$name+"0",
			BridgeSpells$name+"1",
			BridgeSpells$name+"2",
			BridgeSpells$name+"3",
			BridgeSpells$name+"4",
			"got Bridge"
		];
		db3$addTables(tables);
		
		Root$attached();
    }
    
    
    
    // Timer event
    timer(){multiTimer([]);}
    
    // Touch handlers
    touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
        string ln = llGetLinkName(llDetectedLinkNumber(0));
        if(ln == "ROOT" || (ln == "BROWSER" && llDetectedTouchFace(0) == 3) || ln == "BROWSERBG"){
            SharedMedia$toggleBrowser("");
            return;
        }
        else if(ln == "BOOKBG")
            SharedMedia$setBook("");
        
		// Player clicked
        else if(llGetSubString(ln, 0,1) == "OP"){
			integer n = (int)llGetSubString(ln, 2, -1);
			if(llGetSubString(ln, 2, 2) == "B")
				n = (int)llGetSubString(ln, 3, -1);
				
			--n;
			
			if(n >= count(PLAYERS))
				return;
			
			setTarget(l2s(PLAYERS, n), l2s(PLAYER_TEXTURES, n), TRUE, TEAM);    // Add player default texture
		}
		
		// Target frame
        else if(ln == "FRB1" || ln == "FR1")setTarget("", "", TRUE, 0);
		
		// Scroll
		else if(ln == "PROGRESS")Level$getObjectives();
        else if(llGetSubString(ln,0,1) == "FX"){
			integer button = (int)llGetSubString(ln, 2, -1);
		
			// The description contains the spell PID
			int desc = llList2Integer(llGetLinkPrimitiveParams(llDetectedLinkNumber(0), [PRIM_DESC]), 0);
            if(desc == -1)return;
			
			// The icons are split into blocks of 8
			string targ = (string)LINK_ROOT;

			if(floor((float)button/8) == 1)targ = llList2String(PLAYERS, 1);
			else if(floor((float)button/8) == 2 && TARG != llGetOwner())targ = TARG;

            Status$getTextureDesc(targ, desc);
        }
        raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0), llDetectedTouchFace(0)]));
    }
    /*
    touch_end(integer total){ 
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_END, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    */
    
    control(key id, integer level, integer edge){
        if(level&edge){ // Pressed
            pressStart = llGetTime();
            raiseEvent(evt$BUTTON_PRESS, (string)(level&edge));
            if(llGetTime()-lastclick < .5){
                raiseEvent(evt$BUTTON_DOUBLE_PRESS, (string)(level&edge&lcb));
                lcb = 0;
            }else{
                lastclick = llGetTime();
                lcb = (level&edge);
            }
            
            integer i;
            for(i=0; i<32; i++){
                integer pow = llCeil(llPow(2,i));
                if(level&edge&pow)multiTimer(["H_"+(string)pow, 0, 1, TRUE]);
            }
        }
        
        if(~level&edge){
            raiseEvent(evt$BUTTON_RELEASE, (string)(~level&edge)+","+(string)(llGetTime()-pressStart));
            integer i;
            for(i=0; i<32; i++){
                integer pow = llCeil(llPow(2,i));
                if(~level&edge&pow)multiTimer(["H_"+(string)pow]);
            }
        } 
    }
    
    run_time_permissions(integer perms){
        if(perms&PERMISSION_TAKE_CONTROLS)llTakeControls(CONTROL_UP|CONTROL_DOWN|CONTROL_ML_LBUTTON, TRUE, FALSE);
    }
    
    
    // This is the listener
    #define LISTEN_LIMIT_FREETEXT if(llListFindList(getPlayers(), [(str)llGetOwnerKey(id)]) == -1 && ~BFL&BFL_WILDCARD)return; 
   
    
    #include "xobj_core/_LISTEN.lsl" 
    
	//#define LM_PRE qd("Ln."+(str)link+" N."+(str)nr+" ID."+(str)id+" :: "+s);
    // This is the standard linkmessages
	//#define LM_PRE llOwnerSay((str)llGetTime()+" :: Nr"+(str)nr+" id: "+(str)id+" Text: "+s);
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
		
		if(id == "" && SENDER_SCRIPT == llGetScriptName() && METHOD == stdMethod$setShared){
			// Reset all other scripts
			resetAllOthers();
			multiTimer(["INI", "", 2, FALSE]);	// Post reset timer
		}
		
		if(CB == "ATTACHED"){
			integer pos = llListFindList(PLAYERS, [(str)llGetOwnerKey(id)]);
			if(~pos){
				COOP_HUDS = llListReplaceList(COOP_HUDS, [id], pos, pos);
				raiseEvent(RootEvt$coop_hud, mkarr(COOP_HUDS));
			}
		}
		
        return;
    }
    
    // Internal means the method was sent from within the linkset
    if(method$internal){
        if(METHOD == RootMethod$statusControls){
            if(~llGetPermissions()&PERMISSION_TAKE_CONTROLS)return;
            llTakeControls((integer)method_arg(0), TRUE, FALSE);
        }
        else if(METHOD == RootMethod$setParty){
			
			string pre = mkarr(PLAYERS);
			
            PLAYERS = [(string)llGetOwner()];
			COOP_HUDS = [];
			
			
			
            if(count(PARAMS)){
				PLAYERS+=PARAMS;
			
				if(mkarr(PLAYERS) != pre)
					llOwnerSay("You are now in a party with secondlife:///app/agent/"+implode("/about, secondlife:///app/agent/", PARAMS)+"/about");
				
				runOnPlayers(targ,
					Level$bind(targ);
				)
            }
			
			else if(pre != mkarr(PLAYERS))
                AMS$(ARoot$coopDisband);
            
			if(PLAYER_FOCUS >= count(PLAYERS)){
				PLAYER_FOCUS = 0;
				raiseEvent(RootEvt$focus, (str)PLAYER_FOCUS);
			}
			
			integer i;
			for(i=0; i<count(PLAYERS); ++i)
				COOP_HUDS += "";
			raiseEvent(RootEvt$coop_hud, mkarr(COOP_HUDS));
			
            savePlayers();
			
			Root$attached(); // Fetches coop HUD
        }
    }
    
    // ByOwner means the method was run by the owner of the prim
    if(method$byOwner){
		if(METHOD == RootMethod$reset)
			llResetScript();
		else if(METHOD == RootMethod$manageAdditionalPlayer){
			integer rem = llList2Integer(PARAMS, 1);
			string targ = method_arg(0);
			integer pos = llListFindList(ADDITIONAL, [targ]);
			if(
				(pos == -1 && rem) ||
				(~pos && !rem)
			)return;
			
			if(rem){
				ADDITIONAL = llDeleteSubList(ADDITIONAL, pos, pos);
				if(targ == "*")BFL = BFL&~BFL_WILDCARD;
			}
			else{
				ADDITIONAL += targ;
				if(targ == "*"){
					BFL = BFL|BFL_WILDCARD;
					llDialog(llGetOwner(), "!! WARNING !!\nA script in the object "+llKey2Name(id)+" owned by you has enabled free for all mode.\nThis will allow ANYONE to run methods on your HUD.\nIf you didn't request this, please detach your HUD and remove the object: "+llKey2Name(id), [], 13298);
				}
			}
			savePlayers();
		}
		
    }
    
    if(METHOD == RootMethod$getPlayers){
		CB_DATA = [mkarr(getPlayers())];
	}
	
	else if(METHOD == RootMethod$attached){
		
		key okey = llGetOwnerKey(id);
		if(okey == llGetOwner()){
			if(llGetAttached()){
				llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
				llDetachFromAvatar();
			}
			return;
		}
		
		integer pos = llListFindList(PLAYERS, [(str)okey]);
		if(~pos){
			COOP_HUDS = llListReplaceList(COOP_HUDS, [id], pos, pos);
			raiseEvent(RootEvt$coop_hud, mkarr(COOP_HUDS));
		}
		
	}
    
    else if(METHOD == RootMethod$setTarget){
        setTarget(method_arg(0), method_arg(1), l2i(PARAMS, 2), l2i(PARAMS, 3));
    }
	else if(METHOD == RootMethod$setLevel){
		key pre = ROOT_LEVEL;
		ROOT_LEVEL = id;
		list split = llJson2List(prDesc(ROOT_LEVEL));
		integer isChallenge;
		list_shift_each(split, val,
			list d = llJson2List(val);
			if(l2i(d, 0) == LevelDesc$difficulty)
				isChallenge = l2i(d, 2);
		)
		
		raiseEvent(RootEvt$level, mkarr(([ROOT_LEVEL, isChallenge])));
			
		if(pre != ROOT_LEVEL && !method$byOwner){
			qd("You have joined secondlife:///app/agent/"+(string)llGetOwnerKey(id)+"/about 's level!");
			return;
		}
		CB_DATA = getPlayers();
	}
	else if(METHOD == RootMethod$refreshTarget){
		// Refresh active target
		
		// Method arg has to be our current target or empty to refresh regardless
		if(TARG != method_arg(0) && method_arg(0) != ""){
			return;
		}
		
		setTarget(TARG, TARG_ICON, TRUE, -1);
		
	}

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

