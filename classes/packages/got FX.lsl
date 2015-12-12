//#include "situation/_lib_effects.lsl"


#define PSTRIDE 4
list PCS;
list NPCS;
list PACKAGES;     // (int)pid, (key)id, (arr)package, (int)stacks
list EVT_INDEX;     // [scriptname_evt, [pid, pid...]]
list TAG_CACHE;     // [(int)tag1...]
integer PID;

float dodge_chance;
float dodge_add;

#define savePackages() db2$set([], llList2Json(JSON_ARRAY, PACKAGES))
#define runPackage(caster, package, stacks, pid) string c = caster; if(c == "s"){c = llGetOwner();} raiseEvent(FXEvt$runEffect, llList2Json(JSON_ARRAY, [c, stacks, mkarr(package), pid]))
onEvt(string script, integer evt, string data){
    // Packages to work on
if(script != cls$name){
    if(script == "got FXCompiler"){
		if(evt == FXCEvt$update){
			dodge_chance = (float)jVal(data, [4]);
		}
	}
	else if(script == "got Bridge"){
        if(evt == BridgeEvt$data_change){
			list BONUS_STATS = llJson2List(j(data, 0));
			dodge_add = 0;
			list_shift_each(BONUS_STATS, val, 
				if((integer)val == STAT_DODGE)dodge_add+=.05;
			)
		}
   }
	
	list packages = [];
	key dispeller;
		
	// If internal event, run on a specific ID by data
    if(script == "" && evt != INTEVENT_SPELL_ADDED){
		
		if(evt == INTEVENT_DISPEL){
			dispeller = jVal(data, [1]);
			data = jVal(data, [0]);
		}
		packages = find([], [], [], [(integer)data], 0);
	}
    else{
        integer pos = llListFindList(EVT_INDEX, [script+"_"+(string)evt]);
        if(~pos){
            packages = find([],[],[],llJson2List(llList2String(EVT_INDEX, pos+1)), 0);
        }
    }
    
    while(llGetListLength(packages)){
        string id = llList2String(packages, 0);
        packages = llDeleteSubList(packages, 0, 0);
        string sender = llList2String(PACKAGES, (integer)id+1);
        if(sender == "s")sender = llGetOwner();
        
        list evts = llJson2List(jVal(llList2String(PACKAGES, (integer)id+2), [PACKAGE_EVTS]));
		
		
        while(llGetListLength(evts)){
            string evdata = llList2String(evts, 0);
            evts = llDeleteSubList(evts, 0, 0);
            
            if(script+"_"+(string)evt == jVal(evdata, [1])+"_"+jVal(evdata,[0])){
				if(evtCheck(script, evt, data, jVal(evdata, [5]))){
					string wrapper = jVal(evdata, [4]);
					integer targ = (integer)jVal(evdata, [2]);
					integer maxtargs = (integer)jVal(evdata, [3]);
					if(maxtargs == 0)maxtargs = -1;
					
					if(targ&TARG_VICTIM || (targ&TARG_CASTER && sender == "s")){
						FX$run(sender, wrapper); maxtargs--;
					}
					if(targ&TARG_DISPELLER && dispeller != "" && maxtargs != 0){
						if(dispeller == "s" || dispeller == "")FX$run(sender, wrapper);
						else FX$send(dispeller, sender, wrapper);
						maxtargs--;
					}
					if(targ&TARG_CASTER && maxtargs != 0){FX$send(sender, sender, wrapper); maxtargs--;}
				}
            }
        }
        
    }
}
    #ifdef FXConf$useEvtListener
    evtListener(script, evt, data);
    #endif
}


integer preCheck(key sender, string package){
    list conds = llJson2List(j(package, PACKAGE_CONDS));
    integer min = (integer)jVal(package, [PACKAGE_MIN_CONDITIONS]);
    integer all = llGetListLength(conds);
    if(min == 0)min = all;
    integer successes;
    integer add = TRUE;
    integer parsed;
	integer flags = (integer)jVal(package, [PACKAGE_FLAGS]);
	
	if(~flags&PF_ALLOW_WHEN_DEAD){
		if(isDead()){
			return FALSE;
		}
	}
	
    // loop through all conditions
    list_shift_each(conds, cond, {
        list condl = llJson2List(cond);

		integer c = llList2Integer(condl,0);
        list dta = llDeleteSubList(condl,0,0);
		
		
        integer inverse;
        if(c<0)inverse = TRUE;
        c = llAbs(c);
        
        // Built in things
        if(c == fx$COND_HAS_PACKAGE_NAME || c == fx$COND_HAS_PACKAGE_TAG){
            integer found;
            if(c == fx$COND_HAS_PACKAGE_NAME){
                integer i;
                for(i=0; i<llGetListLength(PACKAGES) && !found; i+=PSTRIDE){
                    string pdata = llList2String(PACKAGES, i+2);
                    if(~llListFindList(dta, [jVal(pdata, [PACKAGE_NAME])]))found = TRUE;
                }
            }else{
                list_shift_each(dta, t, {
                    if(~llListFindList(TAG_CACHE, [(integer)t])){
                        found = TRUE;
                        dta = [];
                    }
                })
            }
            // Not found and required
            if(!found){
				add = FALSE;
				if(!inverse)debugUncommon("Package failed cause required fx name/tag not found.");
			}            
            else if(inverse)// Found and required not to be
                debugUncommon("Package failed cause required NOT fx name/tag found.");
        }
        else add = checkCondition(sender, c, dta, flags);
		
        if(inverse)add = !add;
		
        successes+=add;
        if(successes>=min)return TRUE;
        parsed++;
        if(successes+(min-parsed)<min)return FALSE;   // No way this can generate enough successes now
    })
    return successes>=min;
}
list find(list names, list senders, list tags, list pids, integer flags){
    list out; integer i;
    for(i=0; i<llGetListLength(PACKAGES); i+=PSTRIDE){
        integer add = TRUE; string p = llList2String(PACKAGES,  i+2);
        string n = jVal(p, [PACKAGE_NAME]);
        string u = llList2String(PACKAGES, i+1);
		
        if(names != [] && llListFindList(names, [n])==-1)
			add = FALSE;
		
		if(add && flags){
			if(!((integer)jVal(p, [PACKAGE_FLAGS])&flags))add = FALSE;
		}
		
        if(add && senders != []){
            if(llListFindList(senders, [u]) == -1)
				add = FALSE;
			
        }
		
        if(add && pids != []){
            if(llListFindList(pids, [llList2Integer(PACKAGES, i)]) == -1)
				add = false;
        }
		
		// Scan tags
		list t = llJson2List(jVal(p, [PACKAGE_TAGS]));
        if(add && t != []){
            integer x; 
			integer found;
            for(x = 0; x<llGetListLength(tags) && !found; x++){
                if(~llListFindList(tags, llList2List(t, x, x)))
					found = TRUE;
				
            }
			if(!found)add = FALSE;
        }
        if(add)out+=i;
    }
    return out;
}



addPackage(string sender, list package, integer stacks){
    if(sender == llGetOwner() || sender == "")sender = "s";
    float dur = llList2Float(package, PACKAGE_DUR);
    integer flags = llList2Integer(package, PACKAGE_FLAGS);
	
    if(stacks==0)stacks = 1;
    if(dur == 0 || flags&PF_TRIGGER_IMMEDIATE){
		//qd("Running immediate: "+mkarr(package));
        runPackage(sender, package, stacks, 0);
        if(dur == 0)return;
    }
    
    
    
    float tick = llList2Float(package, PACKAGE_TICK);
    integer mstacks = llList2Integer(package, PACKAGE_MAX_STACKS); 
    
	integer CS = 1;
	
	if(mstacks){
        list exists = find([llList2String(package,PACKAGE_NAME)], [sender], [], [], 0);
        if(exists){
            integer idx = llList2Integer(exists,0);
            CS = llList2Integer(PACKAGES, idx+3)+stacks;
            if(CS>mstacks)CS = mstacks;
            PACKAGES = llListReplaceList(PACKAGES, [CS], idx+3, idx+3);
            multiTimer(["F_"+(string)PID, "", dur, FALSE]);
            raiseEvent(FXEvt$effectStacksChanged, 
                mkarr(([
                    sender, 
                    CS, 
                    mkarr(package),
					llList2Integer(PACKAGES, idx)
                ]))
            );
            #ifdef FXConf$useShared
            savePackages();
            #endif
            return;
        }
    }
    
    PID++;
    
    
    // Remove if unique
    if(~flags&PF_NOT_UNIQUE){
		list u = [sender];
		if(flags&PF_FULL_UNIQUE)u = [];
		
		list find = find([llList2String(package, PACKAGE_NAME)], u, [], [], 0);
		integer i;
		for(i=0; i<llGetListLength(find); i++){
			FX$rem(flags&PF_EVENT_ON_OVERWRITE, "", 0, "", llList2Integer(PACKAGES, llList2Integer(find, i)), TRUE, 0, 0, 0);
		}
	}
    
    list evts = llJson2List(llList2String(package, PACKAGE_EVTS));
    
	while(llGetListLength(evts)){
        string val = llList2String(evts,0);
        evts = llDeleteSubList(evts, 0, 0);
        
		
		// (str)script_(int)event
        string find = jVal(val, [1])+"_"+jVal(val,[0]);
        integer pos = llListFindList(EVT_INDEX, [find]);
        list pids = llJson2List(llList2String(EVT_INDEX, pos+1));
        integer exists = llListFindList(pids, [PID]);
        if(exists==-1){
			pids+=PID;
            if(~pos){
                EVT_INDEX = llListReplaceList(EVT_INDEX, [mkarr(pids)], pos+1, pos+1);
            }else{
                EVT_INDEX+=[find, mkarr(pids)];
            }
        }
    } 
    // Remove conditions
    PACKAGES += [PID, sender, mkarr(package), 1];
    TAG_CACHE+= llJson2List(llList2String(package, PACKAGE_TAGS));
    
    
    // Set timers
    multiTimer(["F_"+(string)PID, "", dur, FALSE]);
    if(tick>0)
        multiTimer(["T_"+(string)PID, "", tick, TRUE]);
		
    raiseEvent(FXEvt$effectAdded, mkarr(([sender, stacks, mkarr(package), PID])));
    //runPackage(sender, package, CS);
    onEvt("", INTEVENT_ONADD, (string)PID);
    onEvt("", INTEVENT_SPELL_ADDED, llList2String(package, PACKAGE_NAME));
	
    #ifdef FXConf$useShared
    savePackages();
    #endif
}




timerEvent(string id, string data){
    integer pid = (integer)llGetSubString(id, 2, -1);
    if(llGetSubString(id, 0, 1) == "F_"){
        FX$rem(TRUE, "", 0, "", pid, FALSE, 0, 0, 0);
    }
    else if(llGetSubString(id, 0, 1) == "T_"){
        integer i;
        for(i=0; i<llGetListLength(PACKAGES); i+=PSTRIDE){
            if(llList2Integer(PACKAGES, i) == pid){
                runPackage(llList2String(PACKAGES, i+1), llJson2List(llList2String(PACKAGES, i+2)), llList2Integer(PACKAGES, i+3), pid);
                return;
            }
        }
    }
} 
default
{
    on_rez(integer start){
        llResetScript();
    }
	
	state_entry(){
		db2$ini();
		if(llGetStartParameter())raiseEvent(evt$SCRIPT_INIT, "");
	}
    
    timer(){multiTimer([]);}
    
    #include "xobj_core/_LM.lsl"
        /*
            Included in all these calls:
            METHOD - (int)method
            INDEX - (int)obj_index
            PARAMS - (var)parameters
            SENDER_SCRIPT - (var)parameters
            CB - The callback you specified when you sent a task
        */
        if(method$isCallback)return;

        if(METHOD == FXMethod$run){

            key sender = method_arg(0);
            string wrapper = method_arg(1);
			float range = (float)method_arg(2);

            list packages = llJson2List(wrapper);
            
			integer flags = llList2Integer(packages, 0);
			integer min_objs = llList2Integer(packages,1);
            integer max_objs = llList2Integer(packages,2);
			
			// PC only
			#ifndef IS_NPC
			if(_NPC_TARG == "" && flags&WF_DETRIMENTAL && llGetAgentSize(sender) == ZERO_VECTOR)
				Status$monster_attemptTarget(sender, false);
			#else
				integer RC = TRUE;
				if(flags&WF_REQUIRE_LOS){
					if(llList2Integer(llCastRay(llGetPos()+<0,0,.5>, prPos(id), [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]), -1)> 0){
						RC = FALSE;
					}
				}
			#endif
			
			packages = llDeleteSubList(packages, 0, 2);
			if(
				(~flags&WF_ALLOW_WHEN_DEAD && STATUS&StatusFlag$dead) || 
				(~flags&WF_ALLOW_WHEN_QUICKRAPE && FX_FLAGS&fx$F_QUICKRAPE) || 
				(~flags&WF_ALLOW_WHEN_RAPED && STATUS&StatusFlag$raped) ||
				(range > 0 && llVecDist(llGetPos(), prPos(id))>range)
				#ifdef IS_NPC
				|| !RC
				#endif
			){
				CB_DATA = [FALSE];
			}	
			#ifdef IS_NPC
			
			#endif			
			else if(~flags&WF_NO_DODGE && flags&WF_DETRIMENTAL && sender != llGetOwner() && llFrand(1)<(dodge_chance+dodge_add)){
				#ifndef IS_NPC
				AnimHandler$anim(mkarr((["got_dodge_active", "got_dodge_active_ub"])), TRUE, 0);
				llTriggerSound("2cd691be-46dc-ba05-9a08-ed4a8f48a976", .5);
				#endif
				CB_DATA = [FALSE];
			}
			else{
				list successful;
				integer i;
				for(i=0; i<llGetListLength(packages); i+=2){
					string p = llList2String(packages, i+1);
					if(preCheck(sender, p))successful+=[llList2Integer(packages,i), p];
					if(llGetListLength(successful)/2>=max_objs && max_objs != 0){
						packages = [];
					}
				}
				
				if(llGetListLength(successful)<min_objs){
					CB_DATA = [FALSE];
				}
				else{
					CB_DATA = [llGetListLength(successful)/2];
					for(i=0; i<llGetListLength(successful); i+=2)
						addPackage(sender, llJson2List(llList2String(successful,i+1)), llList2Integer(successful,i));
					
				}
			}
        }
        else if(METHOD == FXMethod$rem){
            integer raiseEvent = (integer)method_arg(0); 
            string name = method_arg(1);
            integer tag = (integer)method_arg(2);
            string sender = method_arg(3);
            integer pid = (integer)method_arg(4);
			integer overwrite = (integer)method_arg(5); // If this is FALSE it's an overwrite and should not send the rem event
            integer flags = (integer)method_arg(6);
			integer amount = (integer)method_arg(7);
			if(amount<1)amount = -1;
			integer is_dispel = (integer)method_arg(8);
			

            if((string)sender == llGetOwner())sender = "s";
            
            #ifdef FXConf$useShared
            integer nrRemoved;
            #endif
            
            integer i; 
            for(i=0; i<llGetListLength(PACKAGES) && llGetListLength(PACKAGES) && (amount == -1 || amount); i+=PSTRIDE){
				//key caster = llList2String(PACKAGES, i+1);
                string p = llList2String(PACKAGES, i+2);
				string n = jVal(p, [PACKAGE_NAME]);
				
                list tags = [];
                if(tag)tags = llJson2List(jVal(p, [PACKAGE_TAGS]));
                    
                if(
                    (name=="" || name==JSON_INVALID || name == n) &&
                    (!tag || llListFindList(tags, [tag])) && 
                    (sender=="" || sender == JSON_INVALID || (sender == llList2String(PACKAGES, i+1) || (llGetSubString(sender,0,0) == "!" && llList2String(PACKAGES, i+1) != llGetSubString(sender,1,-1)))) &&
                    (!pid || llList2Integer(PACKAGES, i) == pid) &&
					(!flags || (integer)jVal(p, [PACKAGE_FLAGS])&flags)
                ){
                    amount++;
                    string pid_rem = llList2String(PACKAGES, i);
                    if(raiseEvent && !overwrite)
						onEvt("", INTEVENT_ONREMOVE, (string)pid_rem);
					if(is_dispel)
						onEvt("", INTEVENT_DISPEL, mkarr(([pid_rem, sender])));
						
					raiseEvent(FXEvt$effectRemoved, mkarr(([llList2String(PACKAGES, i+1), llList2Integer(PACKAGES, i+3), p, (integer)pid_rem, (integer)overwrite])));
                    
					// Remove from evt cache
                    list evts = llJson2List(jVal(p, [PACKAGE_EVTS]));
                    list_shift_each(evts, val, {
                        string find = jVal(val, [1])+"_"+jVal(val, [0]);
                        integer pos = llListFindList(EVT_INDEX, [find]);
                        if(~pos){
                            list dta = llJson2List(llList2String(EVT_INDEX, pos+1));
                            integer ppos = llListFindList(dta, [(integer)pid_rem]);
                            if(~ppos){
                                dta = llDeleteSubList(dta, ppos, ppos);
                                if(dta == []){
                                    EVT_INDEX = llDeleteSubList(EVT_INDEX, pos, pos+1);
                                }else{
                                    EVT_INDEX = llListReplaceList(EVT_INDEX, [mkarr(dta)], pos+1, pos+1);
                                }
                            }
                        }
                    })
                    
                    // Remove from tag cache
                    list tags = llJson2List(jVal(p, [PACKAGE_TAGS]));
                    list_shift_each(tags, t, {
                        integer pos = llListFindList(TAG_CACHE, [(integer)t]);
                        if(~pos)TAG_CACHE=llDeleteSubList(TAG_CACHE, pos, pos);
                    })
                    /*
                    debug("EVT: "+llList2CSV(EVT_INDEX));
                    debug("TAGS: "+llList2CSV(TAG_CACHE));
                    */
                    multiTimer(["F_"+pid_rem]);
                    multiTimer(["T_"+pid_rem]);
                    PACKAGES = llDeleteSubList(PACKAGES, i, i+PSTRIDE-1);
                    
                    
                    // REMOVE FROM INDEX HERE
                            
                    i-=PSTRIDE;
                    #ifdef FXConf$useShared
                    nrRemoved++;
                    #endif
                }
                        
            }
            #ifdef FXConf$useShared
            savePackages();
            #endif
        }
        else if(METHOD == FXMethod$setPCs)PCS = llJson2List(method_arg(0));
        else if(METHOD == FXMethod$setNPCs)NPCS = llJson2List(method_arg(0));
        else if(METHOD == FXMethod$hasTags){
			list tags = [method_arg(0)];
			if(llJsonValueType(PARAMS, [0]) == JSON_ARRAY)tags = llJson2List(method_arg(0));
			integer i; integer c = FALSE;
			for(i=0; i<llGetListLength(tags) && !c; i++){
				if(~llListFindList(TAG_CACHE, [llList2Integer(tags, i)]))c = TRUE;
			}
			CB_DATA = [c];
		}
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 

}
