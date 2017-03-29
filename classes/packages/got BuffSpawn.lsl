#define USE_EVENTS
#include "got/_core.lsl"
integer CHAN;

vector CONF_POS;
rotation CONF_ROT;

onEvt(string script, integer evt, list data){
    if(script == "got Portal" && evt == evt$SCRIPT_INIT){
        llRegionSayTo(mySpawner(), CHAN, "INI");
    }
}

default
{
    state_entry()
    {
        CHAN = BuffSpawnChan(llGetOwner());
        memLim(1.5);
        llListen(CHAN, "", "", "");
        raiseEvent(evt$SCRIPT_INIT, "");
    }
    
    listen(integer chan, string name, key id, string message){
        idOwnerCheck
        
        list conf = llJson2List(message);
		while(conf){
			integer k = l2i(conf, 0);
			string v = l2s(conf, 1);
			conf = llDeleteSubList(conf, 0, 1);
			
			if(k == BuffSpawnConf$pos)
				CONF_POS = (vector)v;
			else if(k == BuffSpawnConf$rot)
				CONF_ROT = (rotation)v;
			else if(k == BuffSpawnConf$meta)
				raiseEvent(BuffSpawnEvt$meta, v);
		}
		
		llSetTimerEvent(.1);
        
    }
	
	timer(){
		
		list data = llGetObjectDetails(llGetOwner(), [OBJECT_POS, OBJECT_ROT]);
		vector pos = l2v(data, 0);
		vector r = llRot2Euler(l2r(data, 1));
		rotation rot = llEuler2Rot(<0,0,r.z>);
		vector ascale = llGetAgentSize(llGetOwner());
		
		vector posOut = pos-<0,0,ascale.z/2>+(CONF_POS*ascale.z*rot);
		rotation rotOut = CONF_ROT*rot;
		llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POSITION, posOut, PRIM_ROTATION, rotOut]);
		
	}
    
    
    
    #include "xobj_core/_LM.lsl" 
    /*
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    if(method$byOwner){
        if(METHOD == BuffSpawnMethod$purge)
            llDie();
    }
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  

}

