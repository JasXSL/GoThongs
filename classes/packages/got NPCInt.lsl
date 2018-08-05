#define USE_EVENTS
#include "got/_core.lsl"

list OST; // Output status to (key)id, (int)flags
#define SPSTRIDE 3
list SPI;   // Spell Icons [(int)PID, (csv)"(key)texture, (int)added, (int)duration, (int)stacks", (str)desc]
integer T_CHAN;
list PLAYERS;
integer BFL;
#define BFL_TEX_QUEUE 0x100            // Spell icon send timeout
#define BFL_TEX_SENT 0x200            // Spell icon send timeout

key thSnd;          // Take hit sound
integer RF;         // Monster runtime flags
integer TEAM = TEAM_NPC;
string RN;            // Rape name, Usually prim name

#define startAnim( anim ) \
    MeshAnim$startAnim(anim); MaskAnim$start(anim)

float hAdd;             // Height add for raycast

// Min time between icon outputs
#define oqTime count(OST)*0.25

ptEvt(string id){
    if( id == "OT" ){ \
        integer i; string out;\
        for( ; i<count(SPI); i+=SPSTRIDE )\
            out+= l2s(SPI, i)+","+l2s(SPI,i+1)+",";\
        out = llDeleteSubString(out, -1, -1);\
        for( i = 0; i<count(OST); i+= 2)\
            GUI$setSpellTextures(l2s(OST, i), out); \
    } \
    else if( id == "OQ" ){ \
        if( BFL&BFL_TEX_QUEUE ){ \
            BFL = BFL&~BFL_TEX_QUEUE; \
			if( !count(OST) ) \
				return; \
            ptSet("OT",0.1,FALSE); \
            ptSet(id, oqTime, FALSE); \
            return; \
        } \
        BFL = BFL&~BFL_TEX_SENT; \
    }
}


onEvt( string script, integer evt, list data ){
    if( script == "got Portal" && (evt == evt$SCRIPT_INIT || evt == PortalEvt$players) )
        PLAYERS = data;
    else if( script == "got Status" && evt == StatusEvt$team )
        TEAM = l2i(data, 0);
}

default{
    
    state_entry(){
        raiseEvent(evt$SCRIPT_INIT, 0);
        T_CHAN = NPCIntChan$targeting(llGetOwner());
        llListen(T_CHAN, "", "", "");
    }
    
    timer(){ptRefresh();}
    
    listen(integer c, string n, key id, string m){
        if( 
            llListFindList(PLAYERS, [(string)llGetOwnerKey(id)]) == -1 && \
            llList2String(PLAYERS, 0) != "*" && \
            llGetOwnerKey(id) != llGetOwner() \
        )return;
        
        if( c == T_CHAN ){
            
            integer flags = (integer)m;
            integer pos = llListFindList(OST, [(str)id]);
            
            integer remove;
            if( flags < 0 ){
                
                flags = llAbs(flags);
                remove = TRUE;
                
            }
            
            integer cur = l2i(OST, pos+1);
            
            // Remove from existing
            if( ~pos && remove )
                cur = cur&~flags;
            // Add either new or existing
            else if( 
                (~pos && !remove && (cur|flags) != flags ) ||
                ( pos == -1 && !remove )
            )cur = cur|flags;
            // Cannot remove what does not exist
            else
                return;
            
            // Exists, update
            if( ~pos && cur )
                OST = llListReplaceList(OST, [cur], pos+1, pos+1);
            // Exists, delete
            else if( ~pos && !cur )
                OST = llDeleteSubList(OST, pos, pos+1);
            // Insert new
            else
                OST += [(str)id, cur];

            if( cur )
                ptSet("OT",.01,FALSE);

            //raiseEvent(StatusEvt$targeted_by, mkarr(OST));
            NPCSpells$setOutputStatusTo(OST);
            
        }
           
    }
    
    #define LM_PRE \
        if( nr == TASK_MONSTER_SETTINGS ){ \
            list data = llJson2List(s); \
            while(data){ \
                integer idx = l2i(data, 0); \
                list dta = llList2List(data, 1, 1); \
                data = llDeleteSubList(data, 0, 1); \
                if(idx == 0) \
                    RF = l2i(dta, 0); \
                if(idx == MLC$takehit_sound) \
                    thSnd = l2s(dta, 0); \
                if(idx == MLC$height_add) \
                    hAdd = l2f(dta, 0)/10; \
                if(idx == MLC$rapePackage && isset(l2s(dta, 0))) \
                    RN = l2s(dta, 0); \
            } \
        }
    
    
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 

    if( 
        METHOD == NPCIntMethod$addTextureDesc || 
        METHOD == NPCIntMethod$remTextureDesc || 
        METHOD == NPCIntMethod$stacksChanged 
    ){
                
        if( METHOD == NPCIntMethod$addTextureDesc ){
        
            SPI += [
                l2i(PARAMS, 0), 
                method_arg(1)+","+method_arg(3)+","+method_arg(4)+","+method_arg(5), 
                method_arg(2)
            ];
            ptSet("OT", .05, FALSE);
            
        }
        else if(METHOD == NPCIntMethod$remTextureDesc){
        
            integer pid = (integer)method_arg(0);
            integer pos = llListFindList(SPI, [pid]);
            if( pos == -1 )
                return;
            
            SPI = llDeleteSubList(SPI, pos, pos+SPSTRIDE-1);
            ptSet("OT", .3, FALSE);
            
        }
        // Stacks changed
        else{
        
            integer pid = (integer)method_arg(0);
            integer pos = llListFindList(SPI, [pid]);
            if( pos == -1 )
                return;
            
            list spl = llCSV2List(l2s(SPI, pos+1));
            spl = llListReplaceList(spl, [(int)method_arg(1),(int)method_arg(2),(int)method_arg(3)], 1, -1);
            SPI = llListReplaceList(SPI, [implode(",", spl)], pos+1,pos+1);
            
            
        }
		
		// Nobody to output status to
		if( !count(OST) )
			return;
                
        if( BFL&BFL_TEX_SENT ){
            
            BFL = BFL|BFL_TEX_QUEUE;
            return;
            
        }
        
        BFL = BFL|BFL_TEX_SENT;
        ptSet("OT", .01, FALSE);    // Send textures
        ptSet("OQ", oqTime, FALSE);
        
    }

    
    // Get the description of an effect affecting me
    else if( METHOD == NPCIntMethod$getTextureDesc ){
    
        if( id == "" )
            id = llGetOwner();
        
        integer pid = (integer)method_arg(0);
        integer pos = llListFindList(SPI, [pid]);
        if( pos == -1 )
            return;
        
        llRegionSayTo(llGetOwnerKey(id), 0, llList2String(SPI, pos+2));
        
    }
    
    // Take hit animation
    else if(METHOD == NPCIntMethod$takehit){
        startAnim("hit");
        if(thSnd)
            llTriggerSound(thSnd, 1);
    }
    
    else if(METHOD == NPCIntMethod$rapeMe && ~RF&Monster$RF_INVUL){
        
        parseDesc(id, resources, status, fx, sex, team, mf);
        
        if(team == TEAM)
            return;
    
        list ray = llCastRay(llGetPos()+<0,0,1+hAdd>, prPos(id)+<0,0,1>, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]);
        if(llList2Integer(ray, -1) == 0){
        
            if(!isset(RN))
                RN = llGetObjectName();
            Bridge$fetchRape(llGetOwnerKey(id), RN);
            
        }
        
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}

