#include "xobj_core/_DB4.lsl"
#include "got/classes/got Banter.lsl"
#include "got/_core.lsl"
/*
    What do conditions need to check?
    - Event script
    - Event type
    - Event data
    - Nearby NPCs
    - Genital size/presence
    - Species type
    - Subspecies type
    - Outfits
    - Sex name
    
    Who should conditions target:
    - Value from event
    - AoE (dist)
    
    What data do we need?
    - Text
    
    What tags should be used?
    - Synonym tags
    - 
    
    Table structure:
    
*/

integer IIDX; // insert index
purge(){
    IIDX = 0;
    list deleted = llLinksetDataDeleteFound("^"+gotTable$banter+"(.|\\n)\\d", "");
    llOwnerSay("Purged "+l2s(deleted, 0));
}
insert( string script, integer evt, list evtData, list conds, list targs, string text, integer flags ){
    
    string iidx = (str)IIDX;
    db4$freplace(gotTable$banter, gotTable$banter$evtType+iidx, (str)evt);
    db4$freplace(gotTable$banter, gotTable$banter$evtScript+iidx, script);
    db4$freplace(gotTable$banter, gotTable$banter$evtData+iidx, mkarr(evtData));
    db4$freplace(gotTable$banter, gotTable$banter$conds+iidx, mkarr(conds));
    db4$freplace(gotTable$banter, gotTable$banter$targs+iidx, mkarr(targs));
    db4$freplace(gotTable$banter, gotTable$banter$text+iidx, text);
    db4$freplace(gotTable$banter, gotTable$banter$flags+iidx, (str)flags);
    
    ++IIDX;
    
}

evt( string data, list data  ){
    
}


default{
    
    state_entry(){
        
        purge();
        insert(
            "got Status", StatusEvt$monster_gotTarget,
            ["!"], // Not empty. Use ! to invert the value. Use JSON_INVALID for DISREGARD
            [],
            [0],
            "Ah ha! I see you!",
            gotBanter$flag$ONCE
        );
        
        
    }

}

