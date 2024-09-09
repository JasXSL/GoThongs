#define SCRIPT_IS_ROOT
#include "got/_core.lsl"

key fetch;

onListen( integer chan, string message ){
    
    if( chan != 1 && chan != 0)
        return;
        
    // Get camera offset from level
    if( message == "cam" ){
        
        if(~llGetPermissions()&PERMISSION_TRACK_CAMERA){
            llOwnerSay("Cam permissions not yet");
            return;
        }
        LevelAux$getOffset(llGetCameraPos(), "CAM");
        
    }
    else if( llGetSubString(message, 0, 9) == "playsound " )
        llPlaySound(llGetSubString(message, 10, -1), 1);
    // Get player position relative to level
    else if( message == "myPos" ){
        LevelAux$getOffset(llGetPos(), "PP");
    }
    // Get position in global coordinates
    else if( message == "pos" )
        llOwnerSay("Your pos: "+(str)llGetPos());
    // Load the level or a group as if it were live
    // ex: "load live SPAWN_A" spawns the SPAWN_A group. "load live" loads the level and teleports the players to start etc
    else if( llGetSubString(message, 0, 8) == "load live" ){
        
        qd("Loading live...");
        string round;
        if( message != "load live" )
            round = llStringTrim(llGetSubString(message, 9, -1), STRING_TRIM);
        Level$loadSharp(round);
        
    }
    else if( llGetSubString(message, 0, 3) == "load" ){
        
        qd("Loading dummies...");
        string round;
        if( message != "load" )
            round = llStringTrim(llGetSubString(message, 5, -1), STRING_TRIM);
        Level$loadDebug(round);
        
    }
    // Get information about the level
    else if( message == "stats" ){
        LevelAux$stats();
    }
    // Show a dialog if the player wants to clean up all spawns
    else if(message == "close"){
        llDialog(llGetOwner(), "Are you sure you want to close?\nUnsaved objects will be lost.\nPress and hold Clean for 2 sec to ignore this warning.", ["Yes Close", "Cancel"], 1);
    }
    // Same as above but ignores the popup
    else if(message == "Yes Close"){
        Portal$killAll();
    }
    // Asks if the player wants to purge all spawns
    else if( message == "purge" ){
        llDialog(llGetOwner(), "Are you sure you want to purge? ALL SAVED SPAWNS AND EVERYTHING WILL BE WIPED.", ["Yes Purge", "Cancel"], 1);
    }
    // Same as above but ignores dialog
    else if( message == "Yes Purge" ){
        LevelAux$purge();
    }
    // Rezzes an asset from the level inventory at your feet
    else if(llGetSubString(message, 0, 5) == "asset "){
        string asset = llGetSubString(message, 6, -1);
        LevelAux$spawnAsset(asset);
    }
    // Spawns an asset by ID. These are synonymous now.
    else if(
        llGetSubString(message, 0, 9) == "testAsset " ||
        llGetSubString(message, 0, 9) == "testSpawn "
    ){
        list split = explode(" ", llGetSubString(message, 10, -1));\
        LevelAux$testSpawn(l2i(split,0), l2i(split, 1));
    }
    // Spawns a HUD inventory asset (monster usually) at your feet
    else if(llGetSubString(message, 0, 5) == "spawn "){\
        string asset = llGetSubString(message, 6, -1);
        
        // Anything ending in a 2 gets animesh rotation
        rotation rot;
        if( 
            asset != "Trigger" && 
            asset != "Armor Repair Box" && 
            llGetSubString(asset, -1, -1) != "2" 
        )rot = llEuler2Rot(<0,PI_BY_TWO,0>);
        LevelAux$spawnNPC(asset, rot);
        
    }
    // Adds currently spawned items to the level. Can optionally be followed by a group.
    // "add" Adds all spawned items to the spawn DB
    // "add A" Adds all spawned items to the spawn DB with the group tag "A"
    else if( llGetSubString(message,0,3) == "add " || message == "add" ){
        
        string group = JSON_INVALID;
        if( message != "add" )
            group = llGetSubString(message, 4, -1);
        LevelAux$save(group);
        
    }
    // Spawns lists items spawned from HUD. Assets lists assets from level inventory.
    else if(
        llGetSubString(message, 0, 9) == "listSpawns" || 
        llGetSubString(message, 0, 9) == "listAssets"
    ){
        
        integer type = llGetSubString(message, 0, 9) == "listAssets";
        string s = llGetSubString(message, 11, -1);
        if( llStringLength(message) < 11 )
            s = "";
        if( llGetSubString(s, 0,0) == "\"" && llGetSubString(s, -1,-1) == "\"" ){
            s = "\\"+s;
        }
        LevelAux$list(type, s);
        
    }
    // These are synonyms now. Removes an asset from the spawn list by id
    else if(
        llGetSubString(message, 0, 8) == "remSpawn " ||
        llGetSubString(message, 0, 8) == "remAsset "
    ){
        int id = (int)llGetSubString(message, 9, -1);
        LevelAux$remove(id);
    }
    // Spawns an NPC path helper
    else if(
        llToLower(message) == "walkpad" || 
        llToLower(message) == "walkassist" || 
        llToLower(message) == "path"
    ){
        llOwnerSay("- Copy and paste pos and rot from target NPC to walk assist.\n- Click walk assist to start the path.\n- Move and rotate walk assist and click to add a waypoint.\n- Say 'WA' to reset path and output a list for llSetKeyframedMotion.");
        llRezAtRoot("WalkAssist", llGetPos()+llRot2Fwd(llGetRot()), ZERO_VECTOR, llEuler2Rot(<0,PI_BY_TWO,0>), 1);
    }
    // Edit a table entry by id. These are synonymous
    // "setSpawnVal 1 3 [1,2,3]" sets the spawn data of the second asset to [1,2,3]
    else if(
        llGetSubString(message, 0, 11) == "setSpawnVal " ||
        llGetSubString(message, 0, 11) == "setAssetVal "
    ){
        list split = explode(" ", message);
        LevelAux$assetVar(
            llList2Integer(split, 1), 
            llList2Integer(split, 2), 
            implode(" ", llList2List(split, 3, -1))
        );
    }
    else if( llGetSubString(message, 0, 7) == "veccalc " ){
        list spl = llParseStringKeepNulls(
            llGetSubString(message, 8, -1), 
            [],
            (list)"+" + ">-<"
        );
        vector start = (vector)l2s(spl, 0);
        spl = llDeleteSubList(spl, 0, 0);
        
        while( spl ){
            string op = trim(l2s(spl, 0));
            string vec = trim(l2s(spl, 1));
            if( llGetSubString(vec, 0,0) != "<")
                vec = "<"+vec;
            if( llGetSubString(vec, -1, -1) != ">" )
                vec += ">";
                
            vector offs = (vector)vec;
            spl = llDeleteSubList(spl, 0, 1);
            if( op == ">-<" )
                start -= offs;
            else if( op == "+" )
                start += offs;
        }
        llOwnerSay((string)start);
    }
    
    
}

timerEvent( string id, string data ){
    
    if( id == "CLK" ){
        
        onListen( 1, "Yes Close");
        qd("Cleaning up");
        touchStarted = 0;
        
    }
    
}
float touchStarted;

default{
    on_rez( integer mew ){
        llResetScript();
    }
    
    state_entry(){
        
        llListen(0, "", llGetOwner(), "");
        llListen(1, "", llGetOwner(), "");
        initiateListen();
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
        llOwnerSay("List of commands: https://github.com/JasXSL/GoThongs/wiki/Dev-%7C-Command-List");
        
    }

    changed(integer change){
        if(change&CHANGED_INVENTORY)
            llResetScript();
    }

    timer(){
        multiTimer([]);
    }    

    #define LISTEN_LIMIT_FREETEXT \
        onListen(chan, message);
    
    
    #include "xobj_core/_LISTEN.lsl"
    
    touch_start( integer total ){
        detOwnerCheck
        
        touchStarted = llGetTime();
        if( llDetectedLinkNumber(0) != 1 )
            return;
        vector uv = llDetectedTouchUV(0);
        integer point = 8-llCeil(uv.y*8);

        // Clean
        if( point == 0 ){
            multiTimer(["CLK", 0, 2, FALSE]);
            return;
        }
        // Help
        else if( point == 1 ){
            list data = [
                "cam : Outputs camera pos and rotation relative to level. Useful for cutscenes.",
                "playsound (key)sound : Lets you preview sounds by UUID.",
                "myPos : Outputs your position relative to the level.",
                "pos : Outputs your region global position."+
                "load live (str)group : Loads a group of spawns 'live', meaning they will attack and function like in the level. Omitting the group will trigger the level start and teleport players to the start position etc.",
                "load (str)group : Loads a group as dev dummies. Omitting the group loads the default \"\" group.",
                "stats : Gives information about level LSD storage, if you have spawn points setup etc.",
                "close : Opens the clean up dialog.",
                "Yes Close : Cleans up without the verification.",
                "purge : Opens the purge dialog to truncate the spawns and assets database.",
                "Yes Purge : Truncates the spawns and assets database with no verification.",
                "asset (str)name : Spawns an object from the level inventory at your feet.",
                "spawn (str)name : Spawns an object (usually a monster) from the HUD at your feet.",
                "testSpawn (int)index (int)live : Spawns an object from the spawn database by its numeric index. If live is 1, then it will be in live mode (monsters can attack etc).",
                "add (str)group : Adds all rezzed objects with the portal script to the spawn DB. If an object is in the level inventory (by name) it is treate as an asset. Otherwise as a spawn. If group is omitted then it spawns when the level starts.",
                "listSpawns : Lists all entries in the spawn DB that are loaded from the HUD (first value in spawn array is 0).",
                "listAssets : Lists all entries in the spawn DB that are loaded from the level inventory (first value in spawn array is 1).",
                "remSpawn (int)index : Removes an item from the spawn DB by its unique index.",
                "walkpad : Spawns a keyframed motion helper.",
                "setSpawnVal (int)index, (int)posInSpawnArray, (var)data : Updates a value for an item in the spawn DB by index. posInSpawnArray is the pos in the data array. 1 being name, 2 pos, 3 rotation etc.",
                "vecCalc (str)formula : Lets you add or subtract two vectors. 'vecCalc <2,2,0>-<1,1,1>' would output <1,1,-1>"
            ];
            llOwnerSay("Dev tools chat commands (all are case sensitive):");
            integer i;
            for(; i < count(data); ++i )
                llOwnerSay(l2s(data, i));
                
        }
        // Spawn pos
        else if( point == 2 ){

            _portal_spawn_v3(
                "_STARTPOINT_P1", 
                llGetPos()+llRot2Fwd(llGetRot()), 
                ZERO_ROTATION, 
                <0,0,-8>, 
                TRUE, 
                "_P1",
                llGetKey(),
                "",
                []
            );
            
        }
        // Stats
        else if( point == 3 )
            onListen(1, "stats");
        // Path
        else if( point == 4 )
            onListen(1, "walkpad");
        // Cam
        else if( point == 5 )
            onListen(1, "cam");
        // Assets
        else if( point == 6 )
            onListen(1, "listAssets");
        // Spawns
        else if( point == 7 )
            onListen(1, "listSpawns");
            
    }
    
    touch_end( integer total ){
        detOwnerCheck
        if( llDetectedLinkNumber(0) != 1 )
            return;
        vector uv = llDetectedTouchUV(0);
        integer point = 8-llCeil(uv.y*8);
        multiTimer(["CLK"]);
        if( point == 0 && touchStarted > 0 )
            onListen( 1, "close" );
        
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
        if(CB == "CAM" || CB == "PP"){
            string offset = method_arg(0);
            rotation r = llGetCameraRot();
            if( CB == "PP" ){
                vector v = llRot2Euler(llGetRot());
                r = llEuler2Rot(<0,0,v.z>);
            }
            
            llOwnerSay("Put in level core:\nRLV$setCamera(TARG_KEY, ("+offset+"+llGetRootPosition()"+"), ("+(string)r+"));");
            
        }
    }
    
    if(METHOD == DevtoolMethod$spawnAt){
        _portal_spawn_v3(
            method_arg(0), 
            (vector)method_arg(1), 
            (rotation)method_arg(2), 
            <0,0,-8>, 
            TRUE, 
            "_DEVTOOL",
            id,
            "",
            []
        );
    }
    
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"
}
