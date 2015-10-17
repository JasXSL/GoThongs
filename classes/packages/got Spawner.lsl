
#include "got/_core.lsl"


default
{
    state_entry(){
        memLim(1.5);
    }
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters   
        CB - The callback you specified when you sent a task
    */ 
    if(method$isCallback){
        return;
    }
    
    if(method$byOwner){
        if(METHOD == SpawnerMethod$spawn){
            string object = method_arg(0);
            if(llGetInventoryType(object) != INVENTORY_OBJECT)return;
            vector pos = (vector)method_arg(1);
            rotation rot = (rotation)method_arg(2);
            _portal_spawn_std(object, pos, rot, -<0,0,8>);
        }
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

