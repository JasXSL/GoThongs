//#define USE_EVENTS
list PASSIVES;
// (str)name, (int)length, (int)attributeID, (float)attributeVal
#define COMPILATION_STRIDE 2
list compiled_passives;     // Compiled passives [id, val, id2, val2...]
// This should correlate to the values in fxcevt$update
list compiled_actives = [0,1,1,1,0,1,1,1,0,1,1,0,1,0,1,0,1,0,1];      // Compiled actives defaults

/*
    Converts a name into a position
*/
integer findPassiveByName(string name){
    integer i;
    while(i<llGetListLength(PASSIVES)){
        if(llList2String(PASSIVES, i) == name)
            return i;
        i+=llList2Integer(PASSIVES, i+1);
    }
    return -1;
}

/*
    Removes a passive by name
*/
removePassiveByName(string name){
    integer pos = findPassiveByName(name);
    if(~pos){
        integer ln = llList2Integer(PASSIVES, pos+1);
        PASSIVES = llDeleteSubList(PASSIVES, pos, pos+ln-1);
    }
}

compilePassives(){
    
    list keys = [];         // Stores the attribute IDs
    list vals = [];         // Stores the attribute values
    integer i;
    while(i<llGetListLength(PASSIVES)){
        // Get the effects
        list block = llList2List(PASSIVES, i+2, i+llList2Integer(PASSIVES, i+1)-1);
        i+=llList2Integer(PASSIVES, i+1);
        
        integer x;
        for(x = 0; x<llGetListLength(block); x+=2){
            integer id = llList2Integer(block, x);
            float val = llList2Float(block, x+1);
            
            integer pos = llListFindList(keys, [id]);
            // The key already exists, add!
            if(~pos)
                vals = llListReplaceList(vals, [llList2Float(vals, pos)+val], pos, pos);
            else{
                keys += id;
                vals += val;
            }
        }
    }
    
    // These need to match compilation stride
    compiled_passives = [];
    for(i=0; i<llGetListLength(keys); i++){
        list v = llList2List(vals, i, i);
        if(llList2Float(v,0) == (float)llList2Integer(v,0))v = [llList2Integer(v,0)];
        compiled_passives+= [llList2Integer(keys, i)]+v;
    }
    
    output();
}


output(){
    // Output the same event as FXCEvt$update
    list output = compiled_actives;
    
    
    integer set_flags = llList2Integer(output, FXCUpd$FLAGS);
    integer unset_flags;
    
    
    // Fields that should be treated as ints for shortening
    list INT_FIELDS = [
        FXCUpd$HP_ADD,
        FXCUpd$MANA_ADD,
        FXCUpd$AROUSAL_ADD,
        FXCUpd$PAIN_ADD
    ];
    
    integer i;
    for(i=0; i<llGetListLength(compiled_passives); i+=COMPILATION_STRIDE){
        integer type = llList2Integer(compiled_passives, i);
    
        // Cache the flags first so unset_flags can properly override
        if(type == FXCUpd$FLAGS)
            set_flags = set_flags|llList2Integer(compiled_passives,i+1);
        else if(type == FXCUpd$UNSET_FLAGS)
            unset_flags = unset_flags|llList2Integer(compiled_passives,i+1);
        else{
            list v = [llList2Float(compiled_passives, i+1)+llList2Float(output,type)];
            if(~llListFindList(INT_FIELDS, [type]))v = llListReplaceList(v, [llList2Integer(v,0)], 0, 0);
            output = llListReplaceList(output, v, type, type);
        }
    }
    
    set_flags = set_flags&~unset_flags;
    output = llListReplaceList(output, [set_flags], FXCUpd$FLAGS, FXCUpd$FLAGS);
    
    string out = mkarr(output);
    raiseEvent(PassivesEvt$data, out);

}


default
{
    state_entry()
    {
        
    }
    
    #include "xobj_core/_LM.lsl" 
    if(method$isCallback){
        return;
    }
    
    
    /*
        Adds a passive
    */
    if(METHOD == PassivesMethod$set){
        string name = method_arg(0);
        list effects = llJson2List(method_arg(1));
        
        // Find if passive exists and remove it
        removePassiveByName(name);
        
        // Go through the index
        if((llGetListLength(effects)%2) == 1)qd("Warning: Passives have an uneven index: "+name);
        PASSIVES += [name, llGetListLength(effects)+2]+effects;
        compilePassives();
    }
    
    
    /*
        Removes a passive
    */
    else if(METHOD == PassivesMethod$rem){
        string name = method_arg(0);
        removePassiveByName(name);
        compilePassives();
    }
    
    /*
        Returns a list of passive names
    */
    else if(METHOD == PassivesMethod$get){
        
        integer i;
        while(i<llGetListLength(PASSIVES)){
            CB_DATA += [llList2String(PASSIVES, i)];
            i+=llList2Integer(PASSIVES, i+1);
        }
        
    }
    
    /*
        The active effects have changed, we recompile the list and send it out
    */
    else if(METHOD == PassivesMethod$setActive){
        list set = llJson2List(method_arg(0));
        compiled_actives = llListReplaceList(compiled_actives, set, 0, llGetListLength(set)-1);
        output();
    }

    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
