#define SCRIPT_IS_ROOT
#define ALLOW_USER_DEBUG 1
#include "got/_core.lsl"
 
integer FLAGS;
 
// Generic root stuff
float pressStart;
float lastclick;
integer lcb;

list PLAYERS;
key TARG;
key LAST_NPC_TARG;
key LAST_NPC_TEXTURE;
key THONG_ID;

integer TARGET_SWITCH;  // 0 = LAST_NPC_TARG, 1 = me, 2 = coop

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
        setTarget("", "", TRUE);
    else if(id == "THONG"){
        if(THONG_ID == "")return;
        if(llKey2Name(THONG_ID) == ""){
            THONG_ID = null;
            DB2$set([RootShared$thongUUID], THONG_ID);
            GUI$close();
            A$(ARoot$thongDetached);
        }
    }
}

#define setNpcTarg() \
if(t != LAST_NPC_TARG)raiseEvent(RootEvt$monsterTarg, mkarr(([t, icon]))); \
LAST_NPC_TARG = t; \
LAST_NPC_TEXTURE = icon; 


integer setTarget(key t, key icon, integer force){
    if(TARG == t)return FALSE;
    // Target is currently set but if last npc targ is not, then set it
    if(TARG != "" && t != "" && !force){
        if(llGetAgentSize(t) == ZERO_VECTOR && LAST_NPC_TARG == ""){
            setNpcTarg()
        }
        return FALSE;
    }
    // ID not found
    if(llKey2Name(t) == "" && t != "")
        return FALSE;
    
    // Clear previous updates
    if(llGetAgentSize(TARG) == ZERO_VECTOR){
        Status$setTargeting(TARG, FALSE);
    }
    
    TARG = t;
    // You get status updates from yourself and coop partner automatically
    llPlaySound("0b81cd3f-c816-1062-332c-bca149ef1c82", .2);
    
    db2$set([RootShared$targ], TARG);
    raiseEvent(RootEvt$targ, mkarr(([t, icon])));
    
    if(t)multiTimer(["T", "", 2, TRUE]);
    
    if(TARG == llGetOwner())TARGET_SWITCH = 1;
    else if(TARG == llList2String(PLAYERS, 1) && llGetListLength(PLAYERS)>1)TARGET_SWITCH = 2;
    else{
        // Also here
        TARGET_SWITCH = 0;
        setNpcTarg()
    }
    
    // Make sure your target knows you are targeting them
    if(TARG != "" && TARG != llList2String(PLAYERS, 1) && TARG != llGetOwner())
        Status$setTargeting(TARG, TRUE);
    else if(TARG == llList2String(PLAYERS, 1)){
        runMethod(TARG, "got Status", StatusMethod$outputStats, [], TNN);
    }
        
    
    return TRUE;
}

savePlayers(){
    db2$set([RootShared$players], mkarr(PLAYERS));
    raiseEvent(RootEvt$players, mkarr(PLAYERS));
}

default 
{
    // Initialize on attach
    on_rez(integer rawr){  
        llResetScript();
    }
    
    // Start up the script
    state_entry()
    { 
        clearDB2();
        PLAYERS = [llGetOwner()];
        savePlayers();
        
        // If you use the RLV supportcube
        runOmniMethod("jas Supportcube", SupportcubeMethod$killall, [], TNN);
        
        
        setTarget("", "", TRUE);
        
        
        // Reset all other scripts
        resetAllOthers();
        
        // Start listening
        initiateListen(); 
        llListen(3, "", llGetOwner(), "");
        llListen(2, "", "", "");
        
        ThongMan$get();
        raiseEvent(evt$SCRIPT_INIT, "");
        if(llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
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
        
        else if(ln == "OP1" || ln == "OPB1")setTarget(llGetOwner(), TEXTURE_PC, TRUE);    // Add player default texture
        else if((ln == "OP2" || ln == "OPB2") && llList2Key(PLAYERS, 1) != "")
            setTarget(llList2Key(PLAYERS, 1), TEXTURE_COOP, TRUE); // Add coop partner texture
        else if(ln == "FRB1" || ln == "FR1")setTarget("", "", TRUE);
        else if(ln == "OPS1" || ln == "OPS2" || ln == "FRS1"){
            string targ = "";
            if(ln == "OPS1")targ = (string)LINK_ROOT;
            else if(ln == "OPS2" && llGetListLength(PLAYERS)>1)targ = llList2String(PLAYERS, 1);
            else if(ln == "FRS1" && TARG != "")targ = TARG;
            if(targ == "")return;
            
            Status$getTextureDesc(targ, llDetectedTouchFace(0), llList2String(llGetLinkPrimitiveParams(llDetectedLinkNumber(0), [PRIM_TEXTURE, llDetectedTouchFace(0)]), 0));
        }
        
        raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
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
    #define LISTEN_LIMIT_FREETEXT \
if(chan == 3){ \
    if(message == "login") \
        Bridge$getToken(); \
    else if(message=="Join") \
        Bridge$dialog(message); \
    else if(message == "switch"){ \
        integer i; \
        for(i=0; i<3; i++){ \
            TARGET_SWITCH ++; \
            if(TARGET_SWITCH>2)TARGET_SWITCH = 0; \
            key t = LAST_NPC_TARG; \
            key texture = LAST_NPC_TEXTURE; \
            integer continue; \
            if(TARGET_SWITCH == 0 && LAST_NPC_TARG == "")continue = TRUE; \
            else if(TARGET_SWITCH == 1){ \
                setTarget(llGetOwner(), TEXTURE_PC, TRUE); \
                return; \
            }else if(TARGET_SWITCH == 2){ \
                if(llGetListLength(PLAYERS)<2)continue = TRUE; \
                else{ \
                    t = llList2String(PLAYERS, 1); \
                    texture = TEXTURE_COOP; \
                } \
            } \
            if(!continue) \
                if(setTarget(t, texture, TRUE))return; \
        } \
    } \
    else  \
        SpellMan$hotkey(message); \
return; \
} \
if(chan == 2){ \
    if(llGetSubString(message, 0, 8) == "settings:") \
        Status$setSex((integer)jVal(llGetSubString(message, 9, -1), ["sex"]));  \
    return; \
} \
if(llListFindList(PLAYERS, [llGetOwnerKey(id)]) == -1) \
    return; 
   
    
    #include "xobj_core/_LISTEN.lsl" 
    
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
    if(method$internal){
        if(METHOD == RootMethod$setThongIni){
            if((integer)method_arg(0))FLAGS=FLAGS|RootFlag$ini;
            else FLAGS = FLAGS&~RootFlag$ini;
            
            if(FLAGS&RootFlag$ini)AMS$(ARoot$thongEquipped);
            db2$set([RootShared$flags], (string)FLAGS);
            raiseEvent(RootEvt$flags, FLAGS);
        }
        else if(METHOD == RootMethod$statusControls){
            if(~llGetPermissions()&PERMISSION_TAKE_CONTROLS)return;
            llTakeControls((integer)method_arg(0), TRUE, FALSE);
        }
        else if(METHOD == RootMethod$setParty){
            key targ = llStringTrim(method_arg(0), STRING_TRIM);
            if(targ == llList2Key(PLAYERS, 1))return;
            
            PLAYERS = [llGetOwner()];
            if(targ)PLAYERS+=[targ];
            if(targ){
                AS$(ARoot$nowInParty);
                llOwnerSay("You are now in a party with secondlife:///app/agent/"+(string)targ+"/about");
            }else
                AMS$(ARoot$coopDisband);
            
            savePlayers();
        }
    }
    
    // ByOwner means the method was run by the owner of the prim
    if(method$byOwner){
        if(METHOD == RootMethod$refreshThong){
            THONG_ID = id;
            DB2$set([RootShared$thongUUID], id);
            raiseEvent(RootEvt$thongKey, id);
            Bridge$refreshThong((integer)method_arg(0));
            multiTimer(["THONG", "", 5, TRUE]);
        }else if(METHOD == RootMethod$reset)llResetScript();
    }
    
    if(METHOD == RootMethod$getPlayers)
        CB_DATA = [mkarr(PLAYERS)];
    
    else if(METHOD == RootMethod$setTarget)
        setTarget(method_arg(0), method_arg(1), (integer)method_arg(2));
    

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

