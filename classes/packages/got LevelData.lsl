
#define USE_EVENTS
#include "got/_core.lsl"

list PLAYERS = [];
list PLAYERS_COMPLETED;
list PLAYER_HUDS;	 // Should match PLAYERS

integer DIFFICULTY;  			
integer CHALLENGE;
integer DEATHS;


integer slave;

integer BFL;
#define BFL_WIPE_TRACKER 0x1 // enables the wipe tracker
#define BFL_WIPED 0x2		// Unable to finish the quest
#define BFL_COMPLETED 0x4	
#define BFL_LOADED 0x8

onEvt(string script, integer evt, list data){

	if( script == "got Level" ){
	
		if( evt == LevelEvt$players )
			PLAYERS = data;
		
		else if( evt == LevelEvt$playerHUDs ){
			
			PLAYER_HUDS = data;
			if( BFL&BFL_WIPE_TRACKER ){
				runOnPlayers(targ,
					GUI$setWipes(targ, wipesRemaining());
				)
			}
			
			
		}
		
		else if( evt == LevelEvt$load && l2s(data, 1) == "" ){
			
			BFL = BFL&~BFL_COMPLETED;
			BFL = BFL&~BFL_LOADED;
			runOnPlayers(targ,
				GUI$toggleSpinner(targ, TRUE, "");
			)
		}
		
		else if( evt == LevelEvt$loaded ){
			
			BFL = BFL|BFL_LOADED;
			runOnPlayers(targ,
				GUI$toggleSpinner(targ, FALSE, "");
			)
			
		}
	
	}

}
	
	


timerEvent(string id, string data){

	if( id == "WIPE" ){
	
		BFL = BFL&~BFL_WIPED;
		DEATHS = 0;
		Portal$killAll();
		multiTimer(["RESTART", "", 2, FALSE]);
		runOnPlayers(targ,
			Status$fullregenTarget(targ);
		)
		
		
	}
	
	else if( id == "RESTART" ){
		runMethod((string)LINK_THIS, "got Level", LevelMethod$load, [FALSE], TNN);
		runOnPlayers(targ,
			GUI$setWipes(targ, wipesRemaining());
		)
	}

}

int getNumViablePlayers(){
	int viable;
	runOnPlayers(targ,
		if(llKey2Name(targ) != "")
			++viable;
	)
	return viable;
}

int wipesRemaining(){
	
	int out = getNumViablePlayers()-1-DEATHS;
	if( out < 0 )
		return 0;
	return out;
	
}


default
{

    state_entry(){

		PLAYERS = [(string)llGetOwner()];
		
		// On remoteload
		if(llGetStartParameter() == 2)
			raiseEvent(evt$SCRIPT_INIT, "");

    }
    
    timer(){
		multiTimer([]);
    }


	
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */

	if( METHOD == gotLevelDataMethod$died && ~BFL&BFL_WIPED ){

		Level$raiseEvent(LevelEvt$playerDied, (list)id + method_arg(0));
		
		++DEATHS;
		
		integer viable = getNumViablePlayers(); // Players in region
		
		
		if( BFL&BFL_WIPE_TRACKER ){
						
			runOnPlayers(targ,
				GUI$setWipes(targ, wipesRemaining());
			)
			
		}
		
		if( BFL&BFL_WIPE_TRACKER && DEATHS >= viable && viable ){
		
			BFL = BFL|BFL_WIPED;
			Level$raiseEvent(LevelEvt$wipe, []);
			Portal$killAll();
			runOnPlayers(targ,
				Status$kill(targ);
			)
			multiTimer(["WIPE", "", 20, FALSE]);
			
		}
		return;
		
	}
	
	if(METHOD == gotLevelDataMethod$setFinished && method$byOwner){
	
		// Block finishing quest while everyone is dead
		if(BFL&BFL_WIPED)
			return;
		
		key p = llGetOwnerKey(method_arg(0));
		integer added;
		// Force override
		if((integer)method_arg(0) == -1){
			PLAYERS_COMPLETED = PLAYERS;
		}
		// This player has not completed
        else if(llListFindList(PLAYERS_COMPLETED, [p]) == -1 && p != NULL_KEY){		
			PLAYERS_COMPLETED += p;
			added = TRUE;
		}
		
		// See which players are in the region
		list needed;
		runOnPlayers(targ,
			if(llKey2Name(targ) != "")
				needed+= llGetOwnerKey(targ);
		)
		
		if( needed == [] )
			return;
		
		// All done
        if(PLAYERS_COMPLETED == needed && ~BFL&BFL_COMPLETED){
			runOnPlayers(targ,
				GUI$toggleObjectives(targ, FALSE); // Clear objectives
			)
			
			// Tell the _main that the level is finished
			if((integer)method_arg(1)){
				
				Level$raiseEvent(LevelEvt$levelCompleted, []);
				return;
				
			}
            
			// Actually send the completecell command, but only once
			if( llGetStartParameter() ){
				
				BFL = BFL|BFL_COMPLETED;

				Bridge$completeCell(llGetOwner(), 0, 0, TRUE);
				Portal$killAll();
				
				qd("Loading next stage.");
				return;
				
            }
            llOwnerSay("Cell test completed!");
			return;
        }
		
		// This person tapped the exit for the first time
		else if(added){
		
			// Not done
			integer i;
			runOnPlayers(targ,
				
				string msg = llGetDisplayName(p)+" has reached the level exit.";
				
				if(llListFindList(PLAYERS_COMPLETED, [llGetOwnerKey(targ)]) == -1){
					msg += " Waiting for you to do the same.";
				}
				
				Alert$freetext(targ, msg, TRUE, TRUE);
			)
			
		}
		
		return;
    }
	

	
	
	if(METHOD == gotLevelDataMethod$cellData && method$byOwner){
		string dta = method_arg(0);
		db3$set([LevelShared$questData], dta);
		Level$raiseEvent(LevelEvt$questData, llJson2List(dta));
	}

	if( METHOD == gotLevelDataMethod$difficulty && method$byOwner ){
	
		DIFFICULTY = l2i(PARAMS, 0);
		CHALLENGE = l2i(PARAMS, 1);
		list desc = llJson2List(llGetObjectDesc());
		if(llJsonValueType(llGetObjectDesc(), []) != JSON_ARRAY)
			desc = [];
		integer i;
		for(i=0; i<count(desc) && desc != []; ++i){
			list dta = llJson2List(l2s(desc,i));
			if(l2i(dta, 0) == LevelDesc$difficulty){
				desc = llDeleteSubList(desc, i, i);
				--i;
			}
		}
		desc+= mkarr((list)LevelDesc$difficulty + DIFFICULTY + CHALLENGE);
		
		if( _lSharp() )
			desc+= mkarr((list)LevelDesc$live);
		
		llSetObjectDesc(mkarr(desc));
		Level$raiseEvent(LevelEvt$difficulty, ([DIFFICULTY, CHALLENGE]));
		runOnPlayers(pk, 
			Root$setLevelOn(pk);
		)
		
	}
	
    if( METHOD == gotLevelDataMethod$enableWipeTracker && method$byOwner ){
		
		BFL = BFL|BFL_WIPE_TRACKER;
		runOnPlayers(targ,
			GUI$setWipes(targ, wipesRemaining());
		)
			
		
	}

    if( METHOD == gotLevelDataMethod$cellDesc && method$byOwner ){
	
		string txt = method_arg(0);
		if( ~BFL&BFL_LOADED && isset(txt) ){	// One of the items required for load is not set
		
			runOnPlayers(pk,
				GUI$toggleSpinner(pk, TRUE, txt);
			)
			
		}
		
	}
	
    if( METHOD == gotLevelDataMethod$getScripts && method$byOwner ){
	
        integer pin = l2i(PARAMS, 0);
        list scripts = llJson2List(method_arg(1));
        list_shift_each(scripts, v, 
            if( llGetInventoryType(v) == INVENTORY_SCRIPT ){
                slave++;
                if(slave>9)slave=1;
                // Remote load
                llMessageLinked(LINK_THIS, slave, llList2Json(JSON_ARRAY, [id, v, pin, 2]), "rm_slave");
            }
            else if(llGetInventoryType(v) != INVENTORY_NONE) llGiveInventory(id, v);
			else llOwnerSay("Trying to load script '"+v+"', but not in level");
        )
		
    }
    
	
	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}
