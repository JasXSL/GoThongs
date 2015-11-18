#define USE_EVENTS
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

key aggro_target;

float hp = 1;

integer monster_flags;
integer spell_flags;
integer spell_id;
key spell_targ;

list CACHE;
list PLAYERS;

integer BFL;
#define BFL_CASTING 1
#define BFL_INTERRUPTED 2
#define BFL_DEAD 4
#define BFL_RECENT_CAST 0x8			// Used to limit spells from casting too often

float spells_per_sec_limit;			// Max spells per sec that can be cast

// Effects
integer STATUS_FLAGS = 0; 
// See ots Monster
integer RUNTIME_FLAGS;
// FX
integer FXFLAGS = 0;
float fxModDmgDone = 1;
float fxCTM = 1;
float fxCDM = 1;

list cooldowns;
list OUTPUT_STATUS_TO;

float CAST_START_TIME;
float CAST_END_TIME;
string CACHE_NAME;              // Name of spell cast

integer P_TXT;
string CACHE_TEXT;
updateText(){
	integer i;
    integer p = llRound(hp*5);
	
	list names = [];
	for(i=0; i<llGetListLength(OUTPUT_STATUS_TO); i++){
		string n = llGetSubString(
			llList2String(
				explode(" ", llGetDisplayName(llGetOwnerKey(llList2String(OUTPUT_STATUS_TO, i)))),
				0
			)
			, 0, 15
		);

		if(n != ""){
			names+= "["+n+"]\n";
		}
	}
	string text = (string)names;
    string middle =  " 💓 ";
    for(i=0; i<p; i++)
        middle = "▶️"+middle+"◀️";
    text+= middle;
	
    vector color = <1, .8, .8>;
    
	
	
	
    if(BFL&BFL_CASTING){
        color = <.8,.6,1>;
        integer tBlocks = llRound((CAST_END_TIME-llGetTime())/(CAST_END_TIME-CAST_START_TIME)*5);
        string add = CACHE_NAME;
        for(i=0; i<5; i++){
            if(i<tBlocks)
                add = "⇒"+add+"⇐";
        }
        
        text += "\n"+add;
    }else if(BFL&BFL_INTERRUPTED){
        color = <.8, 1, .8>;
        text += "\n[ Interrupted! ]";
    }
    CACHE_TEXT = text;
    llSetLinkPrimitiveParamsFast(P_TXT, [PRIM_TEXT, CACHE_TEXT, color, 1]);
	
	list t = ["FDE"];
	if(names == [])
		t+=[1, 2, TRUE];
	multiTimer(t);
}

onEvt(string script, integer evt, string data){
    if(script == "got FXCompiler"){
        if(evt == FXCEvt$update){
            FXFLAGS = (integer)j(data, FXCUpd$FLAGS);
            fxModDmgDone = (float)j(data, FXCUpd$DAMAGE_DONE);
            fxCTM = (float)j(data, FXCUpd$CASTTIME);
            fxCDM = (float)j(data, FXCUpd$COOLDOWN);
            if(BFL&BFL_CASTING && FXFLAGS&fx$NOCAST)
                endCast(FALSE);
            
        }
    }
    else if(script == "got Monster"){
        if(evt == MonsterEvt$runtimeFlagsChanged){
            RUNTIME_FLAGS = (integer)data;
        }
    }else if(script == "got Status"){
        if(evt == StatusEvt$flags){
            STATUS_FLAGS = (integer)data;
        }else if(evt == StatusEvt$monster_gotTarget){
            aggro_target = jVal(data, [0]);
        }else if(evt == StatusEvt$monster_hp_perc){
            hp = (float)data;
            updateText();
        }else if(evt == StatusEvt$dead){
            BFL = BFL|BFL_DEAD;
            if(BFL&BFL_CASTING)endCast(FALSE);
            
        }
    }else if(script == "got Portal" && evt == evt$SCRIPT_INIT)
        PLAYERS = llJson2List(data);
    
}

endCast(integer success){
    if(~BFL&BFL_CASTING)return;
    integer evt = NPCSpellsEvt$SPELL_CAST_INTERRUPT;
    
    if(success)evt = NPCSpellsEvt$SPELL_CAST_FINISH;
    else{
        integer flags = (integer)j(llList2String(CACHE, spell_id), 0);
        if(flags&NPCS$FLAG_RESET_CD_ON_INTERRUPT){
            integer pos = llListFindList(cooldowns, [spell_id]);
            if(~pos)cooldowns = llDeleteSubList(cooldowns, pos, pos);
        }else{
            BFL = BFL|BFL_INTERRUPTED;
            multiTimer(["IR", "", 3, FALSE]);
        }
    }
    raiseEvent(evt, mkarr(([spell_id, spell_targ])));
    Monster$unsetFlags(monster_flags);
    BFL = BFL&~BFL_CASTING;
    multiTimer(["CB"]);
    multiTimer(["CAST"]);
    multiTimer(["US", monster_flags, 1, FALSE]);
    updateText();
    Monster$lookOverride("");
}

startCast(integer spid, key targ, integer hasStatus){
	if(BFL&BFL_RECENT_CAST)return;
	if(targ != aggro_target && !hasStatus){
        Status$get(targ, "SPL;"+(string)spid);
		return;
    }
    if(BFL&BFL_CASTING)return;
	
	if(spells_per_sec_limit){
		BFL = BFL|BFL_RECENT_CAST;
		multiTimer(["SPS", "", spells_per_sec_limit, FALSE]);
	}
	
    spell_targ = targ;
    list d = llJson2List(llList2String(CACHE, spid));
    integer flags = llList2Integer(d, NPCS$SPELL_FLAGS);
    float casttime = llList2Float(d, NPCS$SPELL_CASTTIME)*fxCTM;
    float recasttime = llList2Float(d, NPCS$SPELL_RECASTTIME)*fxCDM;
    
    if(flags&NPCS$FLAG_LOOK_OVERRIDE){
        Monster$lookOverride(targ);
		if(casttime<=0)multiTimer(["LAT", "", 1, FALSE]); // Stop lookat
	}
    
    if(casttime <=0){
		raiseEvent(NPCSpellsEvt$SPELL_CAST_FINISH, mkarr(([spid, spell_targ])));
		
	}
    else{
        BFL = BFL&~BFL_INTERRUPTED;
        raiseEvent(NPCSpellsEvt$SPELL_CAST_START, mkarr(([spid, spell_targ])));
        spell_id = spid;
        multiTimer(["CAST", "", casttime, FALSE]);
        multiTimer(["CB", "", .1, TRUE]);
        BFL = BFL|BFL_CASTING;
                        
        CAST_START_TIME = llGetTime();
        CAST_END_TIME = llGetTime()+casttime;
                        
        CACHE_NAME = llList2String(d, NPCS$SPELL_NAME);
                        
        // Monster flags to set
        spell_flags = flags;
        monster_flags = 0;
        if(flags&NPCS$FLAG_ROOT)monster_flags = monster_flags|Monster$RF_IMMOBILE;
        if(flags&NPCS$FLAG_PACIFY)monster_flags = monster_flags|Monster$RF_PACIFIED;
        if(flags&NPCS$FLAG_NOROT)monster_flags = monster_flags|Monster$RF_NOROT;
        
        Monster$setFlags(monster_flags);
                        
        updateText();
    }
                
    if(recasttime>0){
        cooldowns += spid;
        multiTimer(["CD_"+(string)spid, "", recasttime, FALSE]);
    }
}

timerEvent(string id, string data){
    if(id == "FDE"){
        float rem = (float)data-.05;
        llSetLinkPrimitiveParamsFast(P_TXT, [PRIM_TEXT, CACHE_TEXT, <1,.8,.8>, rem]);
        if(rem <= 0)return;
        multiTimer(["FDE", rem, .05, FALSE]);
    }
	else if(id == "LAT")Monster$lookOverride("");
	else if(id == "SPS")BFL = BFL&~BFL_RECENT_CAST;
    else if(id == "IR")BFL = BFL&~BFL_INTERRUPTED;
    else if(id == "F"){
        if(aggro_target == ""){return;}
        if(BFL&(BFL_CASTING|BFL_DEAD|BFL_INTERRUPTED|BFL_RECENT_CAST)){ return;}
        if(FXFLAGS & fx$NOCAST){return;}
        

        list r;
        integer i;
        for(i=0; i<llGetListLength(CACHE); i++)r+=[i, llList2String(CACHE, i)];
        r = llListRandomize(r, 2);
		
        for(i=0; i<llGetListLength(r); i+=2){
            integer spid = llList2Integer(r, i);
            if(llListFindList(cooldowns, [spid]) == -1){
                list d = llJson2List(llList2String(r, i+1));
                integer flags = llList2Integer(d, NPCS$SPELL_FLAGS);
                float range = llList2Float(d, NPCS$SPELL_RANGE);
                float minrange = llList2Float(d, NPCS$SPELL_MIN_RANGE);
                
                
                list p = [aggro_target];
                if(flags&NPCS$FLAG_CAST_AT_RANDOM)p = llListRandomize(PLAYERS, 1);

                while(llGetListLength(p)){
                    key targ = llList2Key(p, 0);
                    p = llDeleteSubList(p, 0, 0);
                    vector ppos = prPos(targ);
                    float dist = llVecDist(llGetPos(), ppos);
                    list ray = llCastRay(llGetPos()+<0,0,.5>, ppos, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
                    if((range<=0 || dist<range) && dist>=minrange && llList2Integer(ray, -1) == 0){
                        if(flags&NPCS$FLAG_REQUEST_CASTSTART){
                            // Request start cast
                            LocalConf$checkCastSpell(llList2Integer(r, i), targ, "SPELL;"+llList2String(r,i)+";"+(string)targ);
                        }
                        else{
							startCast(spid, targ, FALSE);
							return;
						}
                        if(~flags&(NPCS$ALLOW_MULTIPLE_CHECKS|NPCS$FLAG_REQUEST_CASTSTART)){
							return;
						}
                    }//else qd(llGetDisplayName(targ)+", not allowed: Range: "+(string)range+" dist "+(string)dist+" Minrange: "+(string)minrange+" Ray: "+llList2String(ray,-1));
                }
            }
        }
        
        multiTimer(["F", "", 2, TRUE]);
    }
    else if(llGetSubString(id, 0, 2) == "CD_"){
        integer id = (integer)llGetSubString(id, 3, -1);
        integer pos = llListFindList(cooldowns, [id]);
        if(~pos)cooldowns = llDeleteSubList(cooldowns, pos, pos);
    }
    else if(id == "CAST"){
        endCast(TRUE);
    }
    else if(id == "CB")updateText();
    else if(id == "US")Monster$unsetFlags((integer)data);
}




default 
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry(){
        if(llGetStartParameter())
            raiseEvent(evt$SCRIPT_INIT, "");
        links_each(nr, name, 
            if(name == "TXT")P_TXT = nr;
        )
        PLAYERS = [llGetOwner()];
    }
    
    timer(){multiTimer([]);}
    
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
        if(llGetSubString(CB, 0, 5) == "SPELL;" && SENDER_SCRIPT == "got LocalConf"){
            list split = llParseString2List(CB, [";"], []);
            startCast(llList2Integer(split, 1), llList2String(split, 2), FALSE);
        }
        if(llGetSubString(CB, 0, 3) == "SPL;" && SENDER_SCRIPT == "got Status"){
            integer f = (integer)method_arg(0);
            if(f&StatusFlags$NON_VIABLE)return;
            list split = llParseString2List(CB, [";"], []);
            startCast(llList2Integer(split, 1), llGetOwnerKey(id), TRUE);
        }
        return;
    }
    
    if(method$byOwner){
        if(METHOD == NPCSpellsMethod$setSpells){
            CACHE = llJson2List(PARAMS);
            integer i;
            for(i=0; i<llGetListLength(CACHE); i++){
                integer flags = (integer)jVal(llList2String(CACHE, i), [NPCS$SPELL_FLAGS]);
                if(flags&NPCS$FLAG_DISABLED_ON_START)cooldowns+=i;
            }
            multiTimer(["F", "", 1+llFrand(4), TRUE]);
        }
        else if(METHOD == NPCSpellsMethod$interrupt){
            endCast(FALSE);
        }
		else if(METHOD == NPCSpellsMethod$setOutputStatusTo){
			OUTPUT_STATUS_TO = llJson2List(PARAMS);
			updateText();
		}
		else if(METHOD == NPCSpellsMethod$setConf){
			spells_per_sec_limit = (float)method_arg(0);
		}
    }
	

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
