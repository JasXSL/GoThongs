
#include "got/_core.lsl"


list queue;			// [name, pos, rot, desc, debug]
#define QUEUESTRIDE 5
integer BFL;
#define BFL_QUEUE 1

key current;

next(){
	if(queue == [] || BFL&BFL_QUEUE)return;
	integer reqDesc = llList2String(queue, 3) != "";
	
	_portal_spawn_std(llList2String(queue, 0), llList2Vector(queue,1), llList2Rot(queue,2), -<0,0,8>, llList2Integer(queue, 4), reqDesc);
	BFL = BFL|BFL_QUEUE;
}

// An item has been initialized, let's continue
done(){
	queue = llDeleteSubList(queue, 0, QUEUESTRIDE-1);
	BFL = BFL&~BFL_QUEUE;
	next();
}

timerEvent(string id, string data){
	if(id == "A"){
		string desc = prDesc(current);
		if(desc == "READY"){
			// Send
			Portal$iniData(current, llList2String(queue, 3));
			multiTimer(["A"]);
			done();
		}
	}
	
}

default
{
	object_rez(key id){
		if(llStringTrim(llList2String(queue, 3), STRING_TRIM) == ""){
			done();
		}else{
			current = id; // Cache the current ID
			multiTimer(["A", "", .2, TRUE]);
		}
	}
		
	timer(){multiTimer([]);}
	
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
			string desc = (string)method_arg(3);		// DO something with this
			integer debug = (integer)method_arg(4);			
			queue+= [object, pos, rot, desc, debug];
			
			next();
        }
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

