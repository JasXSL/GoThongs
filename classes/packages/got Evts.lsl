#include "got/_core.lsl"
default
{
    state_entry(){
        llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoThongs, 1");
        llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoT, 1");
        memLim(1.5);
    }
    changed(integer change){
        if(change&CHANGED_REGION)Bridge$reURL();
    }
    
    attach(key id){
        if(id == NULL_KEY){
            llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoThongs, 0");
            llRegionSayTo(llGetOwner(), 1, "jasx.onattach GoT, 0");
        }
    }
    
}



