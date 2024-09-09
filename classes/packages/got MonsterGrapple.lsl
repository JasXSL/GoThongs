/*
    Terminology:
    - Hookup (HUP): One monster starts a grapple. Another monster can hook up to double team the victim.
    - 
*/
//#define DEBUG DEBUG_COMMON

#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"



integer BFL = 4;
#define BFL_IN_GRAPPLE 0x1
#define BFL_PLAYERS_SEATED 0x2  // All players have been seated
#define BFL_DUMMY_MODE 0x4      // Allow unsit

float HP = 1.0;
vector HUP_POS;         // Where to go back to after finishing. Also used to detect client or host
key HUP_TARG;           // Host or client. The other NPC involved in the HUP.
str HUP_A_NPC;          // Cached active NPC idle animation, both client and host
str HUP_A_PC;           // Cached active PC idle animation
str HUP_LABEL;
list THREAT;            // Tracks global aggro. Stores HUDs as strings
bool _G_EN = TRUE;      // Grapple code enabled
list GRAPPLE_TARGS;
int nGTARGS;            // nr grapple targets needed to break out
int DEAD;
// Sequential anim run on GRAPPLE_TARGS
list sA;    // (str)player1anim, (str)playeranim...
integer sI;    // Iterator
list sC;    // Sequential camera. Set alongside seqAnim to update camera.
list VIABLE_POSES;

#define getGrappleMonsterFlags() \
    ((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$monsterFlags))
#define getGrappleStrip() \
    ((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$strip))
#define getGrappleDuration() \
    ((float)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$duration))
#define getGrapplePredelay() \
    ((float)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$predelay))
#define getGrappleFlags() \
    ((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$flags))
#define getGrappleButtonDelay() \
    ((float)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$buttonDelay))
#define getGrappleStages() \
    ((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$stages))
#define getGrappleNoQte() \
    ((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$noQte))
#define getGrappleHostName() \
    db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$host)
#define getGrappleFailTimeout() \
    ((float)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$failTimeout))
#define getGrappleNeedsTest() \
	((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$needsTest))

#define updateDummyMode() \
    db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$DUMMY_MODE, (BFL&BFL_DUMMY_MODE)>0)
#define updateGrappleTargs() \
    db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$GRAPPLE_TARGS, mkarr(GRAPPLE_TARGS))
#define updateGrappleActive() \
	db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$GRAPPLE_ACTIVE, (BFL&BFL_IN_GRAPPLE))
   
// Use this because it handles defaults
integer getGrappleMonsterFlagsCorrect(){
	integer flags = getGrappleMonsterFlags();
	if( !flags )
		flags = Monster$RF_IMMOBILE|
			Monster$RF_PACIFIED|
			Monster$RF_NOROT|
			Monster$RF_NO_SPELLS|
			Monster$RF_NOAGGRO
		;
	return flags;
}

acceptHupHost(){
	Monster$setFlags(getGrappleMonsterFlagsCorrect());
	multiTimer(["HUP_FAIL", 0, 3, FALSE]);        // Set fail timeout
	gotMonsterGrapple$hup$clientAck(HUP_TARG);
}

grappleEnd(){
    
	HUP_TARG = ""; // Needs to go before the return because a grapple may not have started when this is called
	
    if( ~BFL&BFL_IN_GRAPPLE )
        return;
       
	BFL = BFL&~BFL_IN_GRAPPLE;
    updateGrappleActive();
    
    // Tell other monsters that they should release if they were involved with this NPC
    gotMonsterGrapple$hup$end();
    
    // Stop the cached NPC animation.
    if( HUP_A_NPC )
        objAnimOff(HUP_A_NPC);

    // Go back to where you were if possible to prevent stuckage
    if( HUP_POS != ZERO_VECTOR ){
    
        llSetRegionPos(HUP_POS);
        HUP_POS = ZERO_VECTOR;
        
    }
    
    

    

    // Remove the QTE and force sit FX and boot any existing PCs off
    integer i;
    for(; i < count(GRAPPLE_TARGS); ++i ){
        fxlib$removeMySpellByName(l2k(GRAPPLE_TARGS, i), "_Q");
		if( BFL&BFL_PLAYERS_SEATED ){
			Evts$stopQuicktimeEvent(l2k(GRAPPLE_TARGS, i));
		}
    }
    for( i = 1; i <= llGetNumberOfPrims(); ++i ){
        if( llGetAgentSize(llGetLinkKey(i)) != ZERO_VECTOR )
            llUnSit(llGetLinkKey(i));
    }
	
	BFL = BFL&~BFL_PLAYERS_SEATED;
    Monster$unsetFlags(getGrappleMonsterFlagsCorrect());
    
    llStopSound();
    
    multiTimer(["HUPC"]); // Stop the timeout
    multiTimer(["_g_fail"]);
    
	raiseEvent(gotMonsterGrappleEvt$end, "");
	
}

// Force start a normal grapple on huds
grappleStart( list huds, integer fxFlags, integer debug ){

    if( BFL & BFL_IN_GRAPPLE )
        return;
		
	integer i = count(huds);
	while( i-- ){
		// Workaround for 2 monsters grappling at same time
		if( llGetAgentInfo(llGetOwnerKey(l2k(huds, i))) & AGENT_SITTING )
			return;
		
	}
    
    BFL = BFL|BFL_IN_GRAPPLE;
	updateGrappleActive();
	
    GRAPPLE_TARGS = [];
    
    nGTARGS = count(huds);
	
    Monster$setFlags(getGrappleMonsterFlagsCorrect());
    multiTimer(["_g_fail", 0, 3, FALSE]);       // Timeout
    
    BFL = BFL&~BFL_DUMMY_MODE;
    if( debug )
        BFL = BFL|BFL_DUMMY_MODE;
    updateDummyMode();
    
    if( getGrappleStrip() )
        fxFlags = fxFlags | fx$F_SHOW_GENITALS;
        
    integer blockUnsit = (BFL&BFL_DUMMY_MODE) > 0;
    
    float dur = getGrappleDuration();
    if( dur < 1 )
        dur = 300;
    
    for( i = 0; i < count(huds); ++i ){
        
        str targ = l2s(huds, i);
        GRAPPLE_TARGS += targ; // Must be string
        FX$send(
            targ, 
            llGetKey(), 
            "[9,0,0,0,["+
                (str)dur+","+(str)(PF_DETRIMENTAL|PF_NO_DISPEL)+",\"_Q\",["+
                    mkarr((list)fx$SET_FLAG + (fx$F_QUICKRAPE|fxFlags))+","+
                    mkarr(
                    (list)fx$FORCE_SIT + llGetLinkKey(i+1) + blockUnsit)+
                "],"+
				"[["+(str)(-fx$COND_HAS_PACKAGE_NAME)+",\"_Q\"]]"+
            "]]", 
            TEAM_NPC
        );
    }
    updateGrappleTargs();
    debugUncommon("Grappling "+mkarr(huds));
    raiseEvent(gotMonsterGrappleEvt$start, "");
    
}
    
timerEvent( string id, string data ){

    // Checks if the host or client died
    if( id == "HUPC" ){
    
        if( llKey2Name(HUP_TARG) == "" ){
        
            debugUncommon("HUPc Failed");
            grappleEnd();

        }
        
    }
    
    if( id == "_g_fail" || id == "_g_end" || id == "HUP_FAIL" ){
        
        debugUncommon("Grapple timed out");
        grappleEnd();
        
    }
    
}

onEvt(string script, integer evt, list data){
    
    if( script == "got Status" ){
        
        if( evt == StatusEvt$monster_aggro )
            THREAT = data;
        else if( evt == StatusEvt$dead ){
            
            DEAD = l2i(data, 0);
            if( !DEAD )
                return;
            debugUncommon("Ending grapple because dead");
            grappleEnd();
            
        }
        else if( evt == StatusEvt$monster_hp_perc )
            HP = l2f(data, 0);
        
    }

}

integer checkConds( list conds ){
	
	int p = count(GRAPPLE_TARGS);
	while( p-- ){
	
		key hud = l2k(GRAPPLE_TARGS, p);
		int i;
		for(; i < count(conds); i += 3 ){
			
			int type = l2i(conds, i);
			int inverse = l2i(conds, i+2);
			if( type == gotMonsterGrappleHupCond$sex ){
				parseSex(hud, sex);
				
				// Create a boolean success value. And then compare it with inverse. If both are the same, it fails.
				if( ((sex & l2i(conds, i+1)) == l2i(conds, i+1)) == inverse )
					return false;
			
			}
			else if( type == gotMonsterGrappleHupCond$fxFlags ){
				
				parseFxFlags(hud, fxFlags)
				if( ((fxFlags & l2i(conds, i+1)) == l2i(conds, i+1)) == inverse )
					return false;
					
			}
		
		}
	
	}
	return TRUE;
	
}

default{
    
    on_rez(integer mew){llResetScript();}
    state_entry(){
        
        raiseEvent(evt$SCRIPT_INIT, "1");
		
    }

    timer(){multiTimer([]);}
    
    
    // Grapple anim handler
    changed( integer change ){ 
    
        // Grapple disabled
        if( !_G_EN || DEAD )
            return;
        if( ~change & CHANGED_LINK )
            return;
        
        list PLAYERS = Portal$getPlayers();
        list PLAYER_HUDS = Portal$getHuds();
        list sitters;    // player huds sitting on this that are in GRAPPLE_TARGS and PLAYER_HUDS
        integer i;
        for( i = 1; i <= llGetNumberOfPrims(); ++i ){
        
            string lk = llGetLinkKey(i);
            integer pos = llListFindList(PLAYERS, (list)lk);
            if( ~pos ){
                
                lk = l2s(PLAYER_HUDS, pos); // Convert to HUD

                // Todo: Allow custom code for checking if player can sit: cf$sitCheck
                int p = llListFindList(GRAPPLE_TARGS, (list)lk);
                if( ~p )
                    sitters += lk;
                else
                    llUnSit(lk);

            }
            
        }
        
        // All players are seated
        if( sitters == GRAPPLE_TARGS && GRAPPLE_TARGS != [] && ~BFL & BFL_PLAYERS_SEATED ){
            
            multiTimer(["_g_fail"]);
            BFL = BFL|BFL_PLAYERS_SEATED;
            
            raiseEvent(gotMonsterGrappleEvt$seated, "");

            string host = getGrappleHostName();
            if( host ){
                debugUncommon(
                    "HUP :: Host :: Searching clients. Grapple targ "+mkarr(GRAPPLE_TARGS)
                );
                
                gotMonsterGrapple$hup$hostStart(host, sitters, (BFL&BFL_DUMMY_MODE));
                
            }
            
            if( !getGrappleNoQte() ){

                int gf = getGrappleFlags();
                // Multi-target failable is not yet supported
                if( count(GRAPPLE_TARGS) > 1 )
                    gf = gf&~Evts$qFlags$LR_CAN_FAIL;
                
                integer stages = getGrappleStages();
                stages += 30*(!stages);
                
                
                integer i;
                for(; i < count(GRAPPLE_TARGS); ++i ){
                    Evt$startQuicktimeEvent(
                        l2k(GRAPPLE_TARGS, i), 
                        stages, 
                        getGrapplePredelay(), 
                        "QTE", 
                        getGrappleButtonDelay(), 
                        gf
                    );
                }
				
            }

        }
        else if( sitters == [] ){
            debugUncommon("No viable sitters found. HUDs "+mkarr(PLAYER_HUDS)+" Targ "+mkarr(GRAPPLE_TARGS));
            grappleEnd();
        }
            
    }
    
    run_time_permissions( integer perm ){
        // Grapple not enabled        
        if( !_G_EN )
            return;
            

        if( perm & PERMISSION_TRIGGER_ANIMATION ){
            
            str a = l2s(sA, sI);
            // Trigger animation may not be set because SL
            if( a != "" && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION ) 
                llStartAnimation(a);
                
            // Set camera
            if( sC ){
            
                vector pos = l2v(sC, 0);
                vector targ = l2v(sC, 1);
                sC = llDeleteSubList(sC, 0, 1);
                
                llSetCameraParams([
                    CAMERA_ACTIVE, TRUE,
                    CAMERA_POSITION_LOCKED, TRUE,
                    CAMERA_FOCUS_LOCKED, TRUE,
                    CAMERA_POSITION, llGetPos()+pos*llGetRot(),
                    CAMERA_FOCUS, llGetPos()+targ*llGetRot()
                ]);
            
            }
                
            ++sI;
            if( l2k(GRAPPLE_TARGS, sI) != "" )
                llRequestPermissions(llGetOwnerKey(l2k(GRAPPLE_TARGS, sI)), PERMISSION_TRIGGER_ANIMATION);
            
        }
        
    }
    
        
    #include "xobj_core/_LM.lsl"
   
    // Callback is open because it must be accessible to multiple targets
    if( method$isCallback ){
        
        // Quicktime event callback
        if( CB == "QTE" ){
        
            integer type = l2i(PARAMS, 0);
            integer success = l2i(PARAMS, 1);
            if( type == EvtsEvt$QTE$END ){
                
                --nGTARGS;
                if( nGTARGS > 0 )
                    return;
                
                
                raiseEvent(gotMonsterGrappleEvt$qteComplete, success);
                
                if( success )
                    grappleEnd();
                else{
					float to = getGrappleFailTimeout();
					if( to < 0.1 )
						to = 0.1;
                    multiTimer(["_g_end", 0, to, FALSE]);
				}
            }
            else if( type == EvtsEvt$QTE$BUTTON ){
                raiseEvent(gotMonsterGrappleEvt$onButton, mkarr((list)id + success));
            }
            
        }
        
        return;
    }
	
    // Only owner allowed to interact with us
    if( !method$byOwner )
        return;
    
    if( METHOD == gotMonsterGrappleMethod$enable ){
        
        _G_EN = l2i(PARAMS, 0);
        
    }
    
    if( METHOD == gotMonsterGrappleMethod$grappleClosestConal ){
        
        float arc = l2f(PARAMS, 0); 
        float range = l2f(PARAMS, 1); 
        int grappleFlags = l2i(PARAMS, 2); 
        int minPlayers = l2i(PARAMS, 3);
        int maxPlayers = l2i(PARAMS, 4);
        int debug = l2i(PARAMS, 5);
        
        // Already in a grapple
        if( BFL & BFL_IN_GRAPPLE )
            return;
            
        vector pos = llGetPos();
        list huds = [];
        list PLAYER_HUDS = Portal$getHuds();
		
		
        runOnHUDs(hud,
            
            vector p = prPos(hud);
            p.z = 0;
            huds += (list)llVecDist(<pos.x, pos.y, 0>, p) + hud;
            
        )
        huds = llListSort(huds, 2, TRUE);
        //debugRare(mkarr(PLAYER_HUDS));
        list targs;
        integer i;
        for(; i<count(huds) && count(targs) < maxPlayers; i += 2 ){
        
            string targ = l2k(huds, i+1);
			
            string player = llGetOwnerKey(targ);
            vector ppos = prPos(player);
            
            list ray = llCastRay(pos+<0,0,.5>, ppos, RC_DEFAULT);
            prAngX(player, ang)
            float dist = l2f(huds, i);
            if( (llFabs(ang) < arc || dist < .5 ) && dist < range && !l2i(ray, -1) ){
                
                parseDesc(targ, resources, status, fx, sex, team, monsterflags, armor, _a)
                if( _attackableV(status, fx) && ~llGetAgentInfo(llGetOwnerKey(targ)) & AGENT_SITTING ){
                    targs += targ;
                }
                    
            }
        
        }
        
        if( count(targs) >= minPlayers ){
            debugRare("Starting grapple on "+mkarr(targs));
            grappleStart(targs, grappleFlags, debug);
            return;
        }
        
        debugRare("Not enough grapples passed filter");
        
    }
    
    
    
    if( METHOD == gotMonsterGrappleMethod$hup$end && HUP_TARG == id )
        grappleEnd();

    // Host is looking for a client
    if( METHOD == gotMonsterGrappleMethod$hup$hostStart && HUP_TARG == "" && ~BFL&BFL_IN_GRAPPLE ){
	
        string hostname = method_arg(0);
        GRAPPLE_TARGS = llJson2List(method_arg(1));
		raiseEvent(gotMonsterGrappleEvt$onHookupClientReq, "");
		updateGrappleTargs();
		BFL = BFL&~BFL_DUMMY_MODE;
        integer debug = l2i(PARAMS, 2);
		if( debug )
			BFL = BFL|BFL_DUMMY_MODE;
		updateDummyMode();
        VIABLE_POSES = [];
		db4$each(gotTable$monsterGrappleHup, index, arr, 
		
			int numTargs = (int)j(arr, gotMonsterGrappleConst$hup$numTargs);
			numTargs += (!numTargs); // defaults to 1
			if( j(arr, 0) == hostname && numTargs == count(GRAPPLE_TARGS) ){
				
				if( checkConds(llJson2List(j(arr, gotMonsterGrappleConst$hup$conditions))) )
					VIABLE_POSES += index;
				
			}
		)
		
		/*
        list posData = llGetObjectDetails(id, (list)OBJECT_POS + OBJECT_ROT);
        vector startPos = l2v(posData, 0);
        rotation startRot = l2r(posData, 1);
        */
        if( 
            VIABLE_POSES == []         // We do not support this animation
            || DEAD                                        // we are dead
            || HP < 0.25                                // HP is too low for this one
        ){
            debugRare("Reject pos, dead, hp, bfl");
            return;
        }
        
        integer i;
        for(; i < count(GRAPPLE_TARGS) && !debug; ++i ){
            if( llListFindList(THREAT, [l2s(GRAPPLE_TARGS, i)]) == -1 ){
                debugRare("Reject player not on threat");
                return;
            }
        }
        
        //hup$testClient here
        
        // See if pos is available
        /* Position checking is a little difficult. Probably best to leave it out for now and fix if something breaks
        // Draw a line straight to the end pos to make sure that it is free
        list ray = llCastRay(startPos, startPos+offs, RC_DEFAULT);
        if( l2i(ray, -1) > 0 ){
            debugRare("Reject FWD");
            return;
        }
        
        ray = llCastRay(startPos+offs, startPos+offs-<0,0,5>, RC_DEFAULT);
        // Must have a floor
        if( l2i(ray, -1) < 1 ){
            debugRare("Reject no floor");
            return;
        }
        */
            
        HUP_TARG = id;  
		db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_TARG, id);
		db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_HOSTNAME, hostname);
		
		if( getGrappleNeedsTest() ){
			debugUncommon("Requesting viable poses from localConf, picking from "+mkarr(VIABLE_POSES));
			LocalConf$canHookup(VIABLE_POSES);
			return;
		}
		
        acceptHupHost();
        
        
    }
    // Host accepted us
    else if( METHOD == gotMonsterGrappleMethod$hup$hostAck && HUP_TARG == id ){
        
        str hostname = method_arg(0);
        GRAPPLE_TARGS = llJson2List(method_arg(1));
        updateGrappleTargs();
        debugRare("Got ack from host, viable poses: "+mkarr(VIABLE_POSES));
		
        if( VIABLE_POSES == [] ) // This should never happen. But have it just in case.
            return;
			
		int idx = (int)randElem(VIABLE_POSES);
        list viable = llJson2List(db4$get(gotTable$monsterGrappleHup, idx)); 

        HUP_POS = llGetPos();            // Store our start position
        multiTimer(["HUP_FAIL"]);        // Stop fail
        multiTimer(["HUPC", 0, 1, TRUE]);        // Hup ticker. Checks if grapple is ongoing etc.
        BFL = BFL|BFL_IN_GRAPPLE;
		updateGrappleActive();
		
        list posData = llGetObjectDetails(id, (list)OBJECT_POS + OBJECT_ROT);
        vector startPos = l2v(posData, 0);
        rotation startRot = l2r(posData, 1);
        vector offs = (vector)l2s(viable, gotMonsterGrappleConst$hup$pos);
        offs *= startRot;
        
        gotMonsterGrapple$hup$clientStart(id);
        
        llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
        llSleep(.1);
        
        llSetRegionPos(offs+startPos);
        llRotLookAt((rotation)l2s(viable, gotMonsterGrappleConst$hup$rot)*startRot, 1,1);
        
        HUP_A_NPC = l2s(viable, gotMonsterGrappleConst$hup$clientIdleAnim);
        string animPc = l2s(viable, gotMonsterGrappleConst$hup$pcIdleAnim); // can be array
        string animHost = l2s(viable, gotMonsterGrappleConst$hup$hostIdleAnim);
        float resync = l2f(viable, gotMonsterGrappleConst$hup$resync_time);
        vector camPos = (vector)l2s(viable, gotMonsterGrappleConst$hup$camPos);
		vector camTarg = (vector)l2s(viable, gotMonsterGrappleConst$hup$camTarg);
		
		debugRare("Telling "+llKey2Name(id)+" to start anims h/p/r " + (str)animHost+" "+(str)animPc+" "+(str)resync);
        gotMonsterGrapple$seqAnim(id, animHost, animPc, resync, TRUE);
		
		if( camPos )
			gotMonsterGrapple$camSingle(id, camPos, camTarg);
        
        if( HUP_A_NPC ){
            
            if( resync ){
                
                objAnimOff(HUP_A_NPC);
                llSleep(resync);
                
            }
            
            objAnimOn(HUP_A_NPC);
			db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$ANIM_NPC, HUP_A_NPC); // Client NPC anim
            
        }
        
		db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_TARG, id);
		db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_HOSTNAME, hostname);
        raiseEvent(gotMonsterGrappleEvt$hookupStart, hostname);
        
    }
        
    // Client accepted.
    if( METHOD == gotMonsterGrappleMethod$hup$clientAck && HUP_TARG == "" ){
        
        HUP_TARG = id;    // Store client ID
        gotMonsterGrapple$hup$hostAck(id, getGrappleHostName(), GRAPPLE_TARGS);
        debugRare("Host accept "+llKey2Name(HUP_TARG));
        multiTimer(["HUPC", 0, 1, TRUE]);
		db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_TARG, id);
		
    }
    // We are now successfully hosting
    if( METHOD == gotMonsterGrappleMethod$hup$clientStart ){
        
        raiseEvent(gotMonsterGrappleEvt$hookupStart, ""); // Empty hostname when we host
        
        
    }
    // Hookup "thrust" animation received
    if( METHOD == gotMonsterGrappleMethod$seqAnim ){
        
        string hostAnim = method_arg(0);
        list playerAnims = llJson2List(method_arg(1));
        float resync = l2f(PARAMS, 2);
        integer looping = l2i(PARAMS, 3);
        
        if( looping ){
            
            db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$ANIM_PC, method_arg(1));
			db4$freplace(gotTable$monsterGrapple, gotTable$monsterGrapple$ANIM_NPC, hostAnim); // host NPC anim
            HUP_A_NPC = hostAnim;
            
        }
        
        if( resync > 0 ){
            
            integer i = count(playerAnims);
            while( i-- )
                lazyAnim(l2k(GRAPPLE_TARGS, i), l2s(playerAnims, i), FALSE);
            if( hostAnim )
                objAnimOff(HUP_A_NPC);
            llSleep(resync);
            
        }
        
        integer i = count(playerAnims);
        while( i-- )
            lazyAnim(l2k(GRAPPLE_TARGS, i), l2s(playerAnims, i), TRUE);
        
        if( hostAnim ){
			objAnimOff(hostAnim);
            objAnimOn(hostAnim);
        }
        raiseEvent(gotMonsterGrappleEvt$onClientAnim, mkarr((list)
            hostAnim + mkarr(playerAnims)
        ));
        
        
    }
	else if( METHOD == gotMonsterGrappleMethod$hup$viablePoses ){
		
		debugUncommon("HUP filter poses from localConf: "+method_arg(0));
		VIABLE_POSES = llJson2List(method_arg(0));
		if( VIABLE_POSES )
			acceptHupHost();
		
	}
    
    else if( METHOD == gotMonsterGrappleMethod$start ){
        grappleStart(llJson2List(method_arg(0)), l2i(PARAMS, 1), l2i(PARAMS, 2));
    } 
	else if( METHOD == gotMonsterGrappleMethod$end ){
		grappleEnd();
    } 
	else if( METHOD == gotMonsterGrappleMethod$cam ){
	
		vector basePos = (vector)j(method_arg(0), 0);
		vector baseTarg = (vector)j(method_arg(0), 1);
		
		integer i;
		for(; i < count(GRAPPLE_TARGS); ++i ){
		
			vector pos = (vector)j(method_arg(i), 0);
			vector targ = (vector)j(method_arg(i), 1);
			if( pos == ZERO_VECTOR && count(PARAMS) == 1 ){
				pos = basePos;
				targ = baseTarg;
			}
			
			if( pos )
				lazyCam(l2k(GRAPPLE_TARGS, i), pos, targ);
			
		}
		
	}
	else if( METHOD == gotMonsterGrappleMethod$reqte ){
		Evt$startQuicktimeEvent(
            l2k(GRAPPLE_TARGS, 0), 
            l2i(PARAMS, 0), 
            l2i(PARAMS, 1), 
            "QTE", 
            l2i(PARAMS, 2), 
            l2i(PARAMS, 3)
        );
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}



