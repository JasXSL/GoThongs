#define USE_EVENTS
#include "got/_core.lsl"
integer CHAN;

vector CONF_POS;
rotation CONF_ROT;
integer FLAGS;

key TARG;

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
			
			if(k == BuffSpawnConf$targ)
				TARG = v;
			else if(k == BuffSpawnConf$pos)
				CONF_POS = (vector)v;
			else if(k == BuffSpawnConf$rot)
				CONF_ROT = (rotation)v;
			else if(k == BuffSpawnConf$meta){
				raiseEvent(BuffSpawnEvt$meta, v);
			}
			else if(k == BuffSpawnConf$flags)
				FLAGS = BuffSpawnFlag$NO_ROT;
		}
		
		if(TARG  == "" || TARG == NULL_KEY)
			TARG = llGetOwner();
			
		llSetTimerEvent(.1);
        
    }
	
	timer(){
		
		if(llKey2Name(TARG) == "")
			llDie();
			
		list data = llGetObjectDetails(TARG, [OBJECT_POS, OBJECT_ROT]);
		vector pos = l2v(data, 0);
		vector r = llRot2Euler(l2r(data, 1));
		rotation rot = llEuler2Rot(<0,0,r.z>);
		vector ascale = llGetAgentSize(TARG);
		if(ascale == ZERO_VECTOR){
			boundsHeight(TARG, b)
			ascale.z = b;
			pos.z+= ascale.z/2;
		}
			
		
		vector posOut = pos-<0,0,ascale.z/2>+(<CONF_POS.x, CONF_POS.y, CONF_POS.z*ascale.z>*rot);
		rotation rotOut = CONF_ROT*rot;
		list out = [PRIM_POSITION, posOut];
		if(~FLAGS&BuffSpawnFlag$NO_ROT)
			out+= [PRIM_ROTATION, rotOut];
		llSetLinkPrimitiveParamsFast(LINK_THIS, out);
		
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

