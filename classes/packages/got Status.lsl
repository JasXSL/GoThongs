#define USE_EVENTS
#define USE_SHARED [cls$name, "got Bridge"]
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define saveFlags() db2$set([StatusShared$flags], (string)STATUS_FLAGS); raiseEvent(StatusEvt$flags, (string)STATUS_FLAGS)

#define maxDurability() ((DEFAULT_DURABILITY+THONG_LEVEL)*llPow(1.01+.01*(float)getBonusStat(STAT_DURABILITY), THONG_LEVEL))
#define maxMana() ((DEFAULT_MANA+THONG_LEVEL)*llPow(1.01+.01*(float)getBonusStat(STAT_MANA), THONG_LEVEL))
#define maxArousal() ((DEFAULT_AROUSAL+THONG_LEVEL)*llPow(1.01+.01*(float)getBonusStat(STAT_AROUSAL), THONG_LEVEL))
#define maxPain() ((DEFAULT_PAIN+THONG_LEVEL)*llPow(1.01+.01*(float)getBonusStat(STAT_PAIN), THONG_LEVEL))

#define TIMER_REGEN "a"


// Cache
integer PRE_CONTS;
integer PRE_FLAGS;

// Constant
integer THONG_LEVEL = 1;
list BONUS_STATS = [];

#define SPSTRIDE 2
list SPELL_ICONS;   // [(key)texture, (int)desc]

// Effects
integer STATUS_FLAGS = 0; 
key coop_player;

integer GENITAL_FLAGS;

// FX
integer FXFLAGS = 0;
float fxModDmgTaken = 1;
float fxModManaRegen = 1;

list SPELL_DMG_TAKEN_MOD;

// Resources
float DURABILITY = DEFAULT_DURABILITY;
float MANA = DEFAULT_MANA;
float AROUSAL = 0; 
float PAIN = 0;

list OUTPUT_STATUS_TO; 




integer getBonusStat(integer stat){
    integer i; integer out;
    for(i=0; i<llGetListLength(BONUS_STATS); i++){
        if(llList2Integer(BONUS_STATS, i) == stat)out++;
    }
    return out;
}


        
toggleClothes(integer showGenitals){
    if(showGenitals){
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Bits");
    }else{
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed/Arms");
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed/Boots");
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed/Head"); 
        llRegionSayTo(llGetOwner(), 1, "jasx.setclothes Dressed/Torso"); 
               
        
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Bits/Groin, 0");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Dressed/Groin, 0");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Underwear/Groin, 0");
        llRegionSayTo(llGetOwner(), 1, "jasx.togglefolder Bits/Torso, 0");
    }
}
        

addDurability(float amount, string spellName){
    if(STATUS_FLAGS&StatusFlag$dead)return;
    float pre = DURABILITY;
    amount*=spdmtm(spellName);
    if(amount<0){
         if(STATUS_FLAGS&StatusFlag$pained)amount*=1.5;
         amount*=fxModDmgTaken;
    }
    DURABILITY += amount;
    if(DURABILITY<=0){
        SpellMan$interrupt();
        DURABILITY = 0;
        STATUS_FLAGS = STATUS_FLAGS|StatusFlag$dead;
        outputStats();
        raiseEvent(StatusEvt$dead, "1");
        AnimHandler$anim("got_loss", TRUE, 0);
        ThongMan$dead(TRUE);
        toggleClothes(TRUE);
        if(~STATUS_FLAGS&StatusFlag$inLevel)GUI$toggleQuit(TRUE);
    }else{
        if(DURABILITY > maxDurability())DURABILITY = maxDurability();
        if(STATUS_FLAGS&StatusFlag$dead){
            STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
            raiseEvent(StatusEvt$dead, "0");
            Rape$end();
            AnimHandler$anim("got_loss", FALSE, 0);
            ThongMan$dead(FALSE);
            
            toggleClothes(FALSE);
        }
    }
    if(pre != DURABILITY){
        db2$set([StatusShared$dur], mkarr(([DURABILITY, maxDurability()])));
        outputStats();
    }
}
addMana(float amount, string spellName){
    if(STATUS_FLAGS&StatusFlag$dead)return;
    float pre = MANA;
    amount*=spdmtm(spellName);
    
    MANA += amount;
    if(MANA<=0)MANA = 0;
    else if(MANA > maxMana())MANA = maxMana();
    
    if(pre != MANA){
        db2$set([StatusShared$mana], mkarr(([MANA, maxMana()])));
        outputStats();
    }
}
addArousal(float amount, string spellName){
    if(STATUS_FLAGS&StatusFlag$dead)return;
    float pre = AROUSAL;    
    amount*=spdmtm(spellName);
    if(amount>0)amount*=fxModDmgTaken;
    AROUSAL += amount;
    if(AROUSAL<=0)AROUSAL = 0;
    else if(AROUSAL >= maxArousal()){
        AROUSAL = maxArousal();
        if(~STATUS_FLAGS&StatusFlag$aroused){
            STATUS_FLAGS = STATUS_FLAGS|StatusFlag$aroused;
            llTriggerSound("d573fb93-d83e-c877-740f-6c28498668b8", 1);
        }
    }else if(STATUS_FLAGS&StatusFlag$aroused)
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$aroused;
    

    if(pre != AROUSAL){
        db2$set([StatusShared$arousal], mkarr(([AROUSAL, maxArousal()])));
        outputStats();
        
    }
}
addPain(float amount, string spellName){
    if(STATUS_FLAGS&StatusFlag$dead)return;
    float pre = PAIN;
    amount*=spdmtm(spellName);
    if(amount>0)amount*=fxModDmgTaken;
    PAIN += amount;
    if(PAIN<=0)PAIN = 0;
    else if(PAIN >= maxPain()){
        PAIN = maxPain();
        if(~STATUS_FLAGS&StatusFlag$pained){
            STATUS_FLAGS = STATUS_FLAGS|StatusFlag$pained;
            llTriggerSound("4db10248-1e18-63d7-b9d5-01c6c0d8a880", 1);
        }
    }else if(STATUS_FLAGS&StatusFlag$pained)
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$pained;
    
    
    if(pre != PAIN){
        db2$set([StatusShared$pain], mkarr(([PAIN, maxPain()])));
        outputStats();
    }
        
    
    
}

float spdmtm(string spellName){
    if(!isset(spellName))return 1;
    integer i;
    for(i=0; i<llGetListLength(SPELL_DMG_TAKEN_MOD); i+=2){
        if(llList2String(SPELL_DMG_TAKEN_MOD, i) == spellName){
            float nr = llList2Float(SPELL_DMG_TAKEN_MOD, i+1);
            if(nr <0)return 0;
            return nr;
        }
    }
    return 1;
}


onEvt(string script, integer evt, string data){
    if(script == "got FXCompiler"){
        if(evt == FXCEvt$update){
            FXFLAGS = (integer)jVal(data, [0]);
            fxModDmgTaken = (float)jVal(data, [3]);
            fxModManaRegen = (float)jVal(data, [1]);
            outputStats();
        }
    }else if(script == "#ROOT"){
        if(evt == RootEvt$players){
            coop_player = jVal(data, [1]);
        }
        else if(evt == evt$TOUCH_START){
            if(~STATUS_FLAGS&StatusFlag$dead && ~STATUS_FLAGS&StatusFlag$raped)return;
            integer prim = (integer)j(data, 0);
            string ln = llGetLinkName(prim);
            if(ln == "QUIT" || ln == "RETRY"){
                if(ln == "RETRY")qd("Retry action here");
                else qd("Quit action here");
                Status$fullregen();
            }
        }
        // Force update on targeting self, otherwise it requests
        else if(evt == RootEvt$targ && jVal(data, [0]) == llGetOwner())outputStats();
    }else if(script == "got SpellMan"){
        if(evt == SpellManEvt$cast || evt == SpellManEvt$interrupted || evt == SpellManEvt$complete){
            if(evt == SpellManEvt$cast){
                // At least 1 sec to count as a cast
                if((float)jVal(data, [0])<1)return;
                STATUS_FLAGS = STATUS_FLAGS|StatusFlag$casting;
            }
            else STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$casting;
            outputStats();
        }
    }else if(script == "got Bridge"){
        if(evt == BridgeEvt$data_change){
            data = db2$get("got Bridge", [BridgeShared$data]);
            BONUS_STATS = llJson2List(jVal(data, [1]));
            THONG_LEVEL = (integer)jVal(data, [2]);
        }else if(evt == BridgeEvt$thong_initialized)toggleClothes(FALSE);
        
    }
    else if(script == "got Rape"){
        if(evt == RapeEvt$onStart || evt == RapeEvt$onEnd){
            if(evt == RapeEvt$onStart){
                STATUS_FLAGS = STATUS_FLAGS|StatusFlag$raped;
                outputStats();
            }
            else{
                STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$raped;
                Status$fullregen();
            }
            AnimHandler$anim("got_loss", FALSE, 0);
        }
    }
}



outputStats(){ 
    multiTimer(["S", "", .2, FALSE]);
    
    
    integer controls = CONTROL_ML_LBUTTON|CONTROL_UP|CONTROL_DOWN;
    if(FXFLAGS&fx$F_STUNNED || (STATUS_FLAGS&StatusFlag$dead && ~STATUS_FLAGS&StatusFlag$raped))
        controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT;
    if(FXFLAGS&fx$F_ROOTED || STATUS_FLAGS&StatusFlag$casting)
        controls = controls|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT;


    if(PRE_CONTS != controls){
        PRE_CONTS = controls;
        Root$statusControls(controls);
    }
    if(PRE_FLAGS != STATUS_FLAGS){
        integer c = StatusFlag$pained|StatusFlag$aroused;
        if((~PRE_FLAGS&c) == c && STATUS_FLAGS&c)
            AnimHandler$anim("got_pain", TRUE, 0);
        else if(PRE_FLAGS&c && (~STATUS_FLAGS&c) == c)
            AnimHandler$anim("got_pain", FALSE, 0);
        
        PRE_FLAGS = STATUS_FLAGS;
        saveFlags();
    }
}

timerEvent(string id, string data){
    if(id == TIMER_REGEN)
        addMana((maxMana()*.05)*fxModManaRegen, "");
    else if(id == "S"){
       GUI$status(LINK_ROOT, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), STATUS_FLAGS, FXFLAGS);
        if(coop_player)
            GUI$status(coop_player, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), STATUS_FLAGS, FXFLAGS);
    }else if(id == "OP"){
        string dta = mkarr(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE));
        GUI$setSpellTextures(LINK_ROOT, dta);
        if(coop_player)
            GUI$setSpellTextures(coop_player, dta);
    }
}
  

default 
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry(){
        db2$ini();
        coop_player = llList2String(_getPlayers(), 1);
        outputStats();
        Status$fullregen();
        multiTimer([TIMER_REGEN, "", 2, TRUE]);
        llRegionSayTo(llGetOwner(), 1, "jasx.settings");
        toggleClothes(FALSE);
    }
    
    timer(){
        multiTimer([]);
    }
    
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
        return;
    }
    
    if(id == ""){
        if(METHOD == StatusMethod$addTextureDesc){
            key texture = (key)method_arg(0);
            string desc = method_arg(1);
            SPELL_ICONS += [texture, desc];
            multiTimer(["OP", "", .5, FALSE]);
        }
        else if(METHOD == StatusMethod$remTextureDesc){
            key texture = (key)method_arg(0);
            integer pos = llListFindList(SPELL_ICONS, [texture]);
            if(pos == -1)return;
            SPELL_ICONS = llDeleteSubList(SPELL_ICONS, pos, pos+SPSTRIDE-1);
            
            multiTimer(["OP", "", .1, FALSE]);
        }
        else if(METHOD == StatusMethod$setSex){
            GENITAL_FLAGS = (integer)method_arg(0);
            db2$set([StatusShared$sex], (string)GENITAL_FLAGS);
        }
    }
    
    if(METHOD == StatusMethod$addDurability)addDurability((float)method_arg(0), method_arg(2));
    else if(METHOD == StatusMethod$addMana)addMana((float)method_arg(0), method_arg(1));
    else if(METHOD == StatusMethod$addArousal)addArousal((float)method_arg(0), method_arg(1));
    else if(METHOD == StatusMethod$addPain)addPain((float)method_arg(0), method_arg(1));
    else if(METHOD == StatusMethod$setTargeting){
        integer on = (integer)method_arg(0);
        integer pos = llListFindList(OUTPUT_STATUS_TO, [id]);
        if(!on){
            if(pos == -1)return;
            OUTPUT_STATUS_TO = llDeleteSubList(OUTPUT_STATUS_TO, pos, pos);
        }else{
            if(~pos)return;
            OUTPUT_STATUS_TO += id;
            outputStats();
        }
    }
    else if(METHOD == StatusMethod$fullregen){
        if(STATUS_FLAGS&StatusFlag$raped)Rape$end();
        
        DURABILITY = maxDurability();
        MANA = maxMana();
        AROUSAL = 0;
        PAIN = 0;
        db2$set([StatusShared$dur], mkarr(([DURABILITY, maxDurability()])));
        db2$set([StatusShared$mana], mkarr(([MANA, maxMana()])));
        db2$set([StatusShared$arousal], mkarr(([AROUSAL, maxArousal()])));
        db2$set([StatusShared$pain], mkarr(([PAIN, maxPain()])));
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$dead;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$raped;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$pained;
        STATUS_FLAGS = STATUS_FLAGS&~StatusFlag$aroused;
        raiseEvent(StatusEvt$dead, "0");
        
        AnimHandler$anim("got_loss", FALSE, 0);
        outputStats();
        ThongMan$dead(FALSE);
        toggleClothes(FALSE);
        GUI$toggleQuit(FALSE);
    }
    else if(METHOD == StatusMethod$get){
        CB_DATA = [STATUS_FLAGS, FXFLAGS, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), GENITAL_FLAGS];
    }
    else if(METHOD == StatusMethod$spellModifiers){
        SPELL_DMG_TAKEN_MOD = llJson2List(method_arg(0));
    }
    else if(METHOD == StatusMethod$getTextureDesc){
        if(id == "")id = llGetOwner();
        string out = "";
        
        integer pos = (integer)method_arg(0);
        string texture = method_arg(1);
        
        if(llList2String(SPELL_ICONS, pos*SPSTRIDE) == texture)out = llList2String(SPELL_ICONS, pos*SPSTRIDE+1);
        else{
            integer p = llListFindList(llList2ListStrided(SPELL_ICONS, 0, -1, SPSTRIDE), [(key)texture]);
            if(~p)out = llList2String(SPELL_ICONS, p*SPSTRIDE+1);
        }
        
        if(out)
            llRegionSayTo(llGetOwnerKey(id), 0, out);
    }
    else if(METHOD == StatusMethod$outputStats)
        outputStats();
    

    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
