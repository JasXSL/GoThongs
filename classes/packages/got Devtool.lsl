#define SCRIPT_IS_ROOT
#include "got/_core.lsl"




default
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry(){
        llListen(0, "", llGetOwner(), "");
        llListen(1, "", llGetOwner(), "");
        initiateListen();
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
        
    }
    
    

    #define LISTEN_LIMIT_FREETEXT \
    if(chan == 1 || chan == 0){ \
        if(message == "cam"){ \
            if(~llGetPermissions()&PERMISSION_TRACK_CAMERA){ \
                llOwnerSay("Cam permissions not yet"); \
                return; \
            } \
            LevelAux$getOffset(llGetCameraPos(), "CAM"); \
        } \
        else if(message=="pos")llOwnerSay("Your pos: "+(str)llGetPos()); \
        else if(llGetSubString(message, 0, 8) == "load live"){ \
            qd("Loading live..."); \
            string round = JSON_INVALID; \
            if(message != "load live") \
                round = llStringTrim(llGetSubString(message, 9, -1), STRING_TRIM); \
            Level$loadSharp(round); \
        } \
        else if(llGetSubString(message,0,3) == "load"){ \
            qd("Loading dummies..."); \
            string group = JSON_INVALID; \
            if(message != "load")group = llGetSubString(message, 5, -1); \
            Level$loadDebug(group); \
        } \
        else if(message == "stats"){ \
            LevelAux$stats(); \
        } \
        else if(message == "close"){ \
            llDialog(llGetOwner(), "Are you sure you want to close? Unsaved data will be lost.", ["Yes Close", "Cancel"], 1); \
        } \
        else if(message == "Yes Close"){ \
            Portal$killAll(); \
        } \
        else if(message == "purge"){ \
            llDialog(llGetOwner(), "Are you sure you want to purge? ALL SAVED SPAWNS AND EVERYTHING WILL BE WIPED.", ["Yes Purge", "Cancel"], 1); \
        } \
        else if(message == "Yes Purge"){ \
            LevelAux$purge(); \
        } \
        else if(llGetSubString(message, 0, 5) == "asset "){\
            string asset = llGetSubString(message, 6, -1); \
            LevelAux$spawnAsset(asset); \
        }\
        else if(llGetSubString(message, 0, 9) == "testAsset "){\
            list split = explode(" ", llGetSubString(message, 10, -1));\
            LevelAux$testSpawn(0, llList2Integer(split,0), llList2Integer(split, 1)); \
        }\
        else if(llGetSubString(message, 0, 9) == "testSpawn "){\
            list split = explode(" ", llGetSubString(message, 10, -1));\
            LevelAux$testSpawn(1, llList2Integer(split, 0), llList2Integer(split,1)); \
        }\
        \
        else if(llGetSubString(message, 0, 5) == "spawn "){\
            string asset = llGetSubString(message, 6, -1); \
            LevelAux$spawnNPC(asset); \
        }\
        else if(llGetSubString(message,0,2) == "add"){ \
            string group = JSON_INVALID; \
            if(message != "add")group = llGetSubString(message, 3, -1); \
            LevelAux$save(group); \
        } \
        else if(message == "listSpawns"){ \
            LevelAux$list(1); \
        } \
        else if(message == "listAssets"){ \
            LevelAux$list(0); \
        } \
        else if(llGetSubString(message, 0, 8) == "remSpawn "){ \
            LevelAux$remove(1, (integer)llGetSubString(message, 9, -1)); \
        } \
        else if(llGetSubString(message, 0, 8) == "remAsset "){ \
            LevelAux$remove(0, (integer)llGetSubString(message, 9, -1)); \
        } \
        else if(llToLower(message) == "walkpad" || llToLower(message) == "walkassist" || llToLower(message) == "path"){\
            llRezAtRoot("WalkAssist", llGetPos()+llRot2Fwd(llGetRot()), ZERO_VECTOR, llEuler2Rot(<0,PI_BY_TWO,0>), 1);\
        } \
        else if(llGetSubString(message, 0, 11) == "setSpawnVal "){ \
            list split = explode(" ", message); \
            if(llJsonValueType(l2s(split,2), []) != JSON_NUMBER){ \
                return qd("Error: "+l2s(split, 2)+" is not a number"); \
            }\
            LevelAux$assetVar(1, llList2Integer(split, 1), llList2Integer(split, 2), implode(" ", llList2List(split, 3, -1))); \
        } \
        else if(llGetSubString(message, 0, 11) == "setAssetVal "){ \
            list split = explode(" ", message); \
            LevelAux$assetVar(0, llList2Integer(split, 1), llList2Integer(split, 2), implode(" ", llList2List(split, 3, -1))); \
        } \
        return; \
    } \
    
    
    #include "xobj_core/_LISTEN.lsl"
    
    touch_start(integer total_number)
    {
        string n = llGetLinkName(llDetectedLinkNumber(0));
        if(llGetSubString(n, 0, 12) == "_STARTPOINT_P"){
            _portal_spawn_std(n, llGetPos()+llRot2Fwd(llGetRot()), ZERO_ROTATION, <0,0,-8>, TRUE, FALSE, FALSE);
        }
    }
    
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    
    
    if(!method$byOwner)return;
    
    if(method$isCallback){
        if(CB == "CAM"){
            string offset = method_arg(0);
            rotation r = llGetCameraRot();
            
            llOwnerSay("Put in level core:\nRLV$setCamera(TARG_KEY, ("+offset+"+llGetRootPosition()"+"), ("+(string)r+"));");
            
        }
    }
    
    if(METHOD == DevtoolMethod$spawnAt){
        _portal_spawn_std(method_arg(0), (vector)method_arg(1), (rotation)method_arg(2), <0,0,-8>, TRUE, FALSE, FALSE);
    }
    
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"
}

