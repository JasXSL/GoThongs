#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

#define LSD_STOR_A "NPCA"	// Stores spell icons in LSD. The PID is added to this.
							// A JSON array is stored like: [(int)PID, (key)texture, (int)added, (int)duration, (int)stacks, (int)flags]
#define LSD_STOR_D "NPCD"	// Coupled to NPCI and using the same index. Stores descriptions.

list OST; // Output status to (key)id, (int)flags
#define SPSTRIDE 3
list SPI;   // Spell Icons [(int)PID, (int)senderKey[0-8], (int)flags]
#define SPI_PID 0				// Package ID. Used when fetching descriptions
#define SPI_SENDER_KEY 1		// Stored as an int based on the first 8 hex characters
#define SPI_FLAGS 2				// 

integer T_CHAN;
list PLAYERS;
integer BFL;
#define BFL_TEX_QUEUE 0x100            // Spell icon send timeout
#define BFL_TEX_SENT 0x200            // Spell icon send timeout

list thSnd;          // Take hit sound
integer RF;         // Monster runtime flags
integer TEAM = TEAM_NPC;
string RN;            // Rape name, Usually prim name

#define startAnim( anim ) \
    MeshAnim$startAnim(anim); MaskAnim$start(anim)

float hAdd;             // Height add for raycast
float hoverHeight;

// Min time between icon outputs
#define oqTime count(OST)/2*0.25

vector groundPoint(){
	
	vector root = llGetRootPosition();
	root.z -= hoverHeight;
	return root;

}

// Takes an integerlized character and tries to convert it to a player that is targeting us directly
string getTargetingPlayer( int stub ){

	int i;
	for( ;i<count(OST); i += 2 ){
	
		integer n = (int)("0x"+l2s(OST, i));
		if( n == stub && l2i(OST, i+1) & NPCInt$targeting  )
			return l2s(OST, i);
			
	}
	return "";
	
}
sendTextures( string target ){

	if(target == "")
		return;
		
	int t = (int)("0x"+llGetSubString(target, 0, 7));
	str out = "[";
	
	integer i;
    for( ; i < count(SPI); i += SPSTRIDE ){
		
		int f = l2i(SPI, i+SPI_FLAGS);
		int pid = l2i(SPI, i+SPI_PID);
		int u = l2i(SPI, i+SPI_SENDER_KEY);
		if( ~f & PF_DETRIMENTAL || u == t || f & PF_FULL_VIS ){		// Show beneficial effects and sender effects and effects with full vis flags
			out += llGetSubString(llLinksetDataRead(LSD_STOR_A+(str)pid), 1, -2)+",";
		}
	}
	out = llDeleteSubString(out,-1,-1);
	out += "]";
	GUI$setSpellTextures(target, out);
	
}

ptEvt(string id){
    if( id == "OT" ){ \
		integer i; \
        for( i = 0; i<count(OST); i+= 2)\
			if(l2i(OST, i+1)&NPCInt$targeting) \
				sendTextures(l2s(OST, i)); \
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
	else if( script == "got Monster" && evt == MonsterEvt$runtimeFlagsChanged )
		RF = l2i(data, 0);
		
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
				// Find if we added a flag that we did not already have
                (~pos && !remove && flags&(cur^flags) ) ||
				// Or if this was completely new
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
                sendTextures(id);

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
                if(idx == MLC$takehit_sound) \
                    thSnd = llJson2List(l2s(dta, 0)); \
                if(idx == MLC$height_add) \
                    hAdd = l2f(dta, 0)/10; \
				if(idx == MLC$hover_height) \
                    hoverHeight = l2f(dta, 0); \
                if(idx == MLC$rapePackage && isset(l2s(dta, 0))) \
                    RN = l2s(dta, 0); \
            } \
			return; \
        }
    
    
    #include "xobj_core/_LM.lsl" 


    if( 
        METHOD == NPCIntMethod$addTextureDesc || 
        METHOD == NPCIntMethod$remTextureDesc || 
        METHOD == NPCIntMethod$stacksChanged 
    ){
                
        if( METHOD == NPCIntMethod$addTextureDesc ){
			
			// Method args
			//  pid, texture, desc, added, duration, stacks, casterSubstr(8), (int)flags
			
			// LSD_STOR_A
			// (int)PID, (key)texture, (int)added, (int)duration, (int)stacks, (int)flags
			
			// Shortened charkey
			int ck = (int)("0x"+method_arg(6));
			int pid = l2i(PARAMS, 0);
			int flags = l2i(PARAMS, 7);
			
			// This is stored in LSD and sent raw to the player targeting us
			list full = (list)
				pid +				// PID
				l2s(PARAMS, 1) + 	// texture
				l2i(PARAMS, 3) + 	// added
				l2i(PARAMS, 4) +	// duration
				l2i(PARAMS, 5) +	// stacks
				flags				// packageFlags
			;
			llLinksetDataWrite(LSD_STOR_A+(str)pid, mkarr(full));		// Store raw that should be sent to users
			llLinksetDataWrite(LSD_STOR_D+(str)pid, l2s(PARAMS, 2));		// Store desc
			
			// PID, sender, flags
            SPI += (list)
                pid +					// PID
				ck +					// Sender stub
				flags 					// packageFlags
            ;
			
			// If detrimental and not force send to everybody, only update the caster
			if( flags & PF_DETRIMENTAL && ~flags & PF_FULL_VIS ){
				sendTextures(getTargetingPlayer(ck));
				return;
			}
			
        }
        else if(METHOD == NPCIntMethod$remTextureDesc){
        
            integer pid = l2i(PARAMS, 0);
            integer pos = llListFindList(llList2ListStrided(SPI, 0,-1, SPSTRIDE), (list)pid);
            if( pos == -1 )
                return;
				
			pos *= SPSTRIDE;
			
			SPI = llDeleteSubList(SPI, pos, pos+SPSTRIDE-1);
			llLinksetDataDelete(LSD_STOR_A+(str)pid);
			llLinksetDataDelete(LSD_STOR_D+(str)pid);
			
			// See if can get away with only updating the caster
			int flags = l2i(SPI, pos+SPI_FLAGS);
			if( flags & PF_DETRIMENTAL && ~flags & PF_FULL_VIS ){
				sendTextures(getTargetingPlayer(l2i(SPI, pos+SPI_SENDER_KEY)));
				return;
			}
            
        }
        // Stacks changed
        else{
			// (int)PID, (int)added, (float)duration, (int)stacks
			
            integer pid = l2i(PARAMS, 0);
            integer pos = llListFindList(llList2ListStrided(SPI, 0,-1, SPSTRIDE), (list)pid);
            if( pos == -1 )
                return;
            pos *= SPSTRIDE;
			
			
			// [(int)PID, (key)texture, (int)added, (int)duration, (int)stacks, (int)flags]
			list data = llJson2List(llLinksetDataRead(LSD_STOR_A+(str)pid));
			data = llListReplaceList(data, (list)
				l2i(PARAMS, 1) + 	// Added
				l2i(PARAMS, 2) + 	// Duration
				l2i(PARAMS, 3),		// Stacks
				2, 4
			);
			llLinksetDataWrite(LSD_STOR_A+(str)pid, mkarr(data));
			
			// See if we can send this only to the caster
			int flags = l2i(SPI, pos+SPI_FLAGS);
			if( flags & PF_DETRIMENTAL && ~flags & PF_FULL_VIS ){
			
				sendTextures(getTargetingPlayer(l2i(SPI, pos+SPI_SENDER_KEY)));
				return;
				
			}
			
        }
		
		// See if we need to update everybody
		
		// Nobody is targeting us
		if( !count(OST) )
			return;
                
		// We have sent one too recently. 
        if( BFL&BFL_TEX_SENT ){
            
			// Set that we want to update when the cooldown finishes.
            BFL = BFL|BFL_TEX_QUEUE;
            return;
            
        }
        
		// Set a timer to send, and a cooldown
        BFL = BFL|BFL_TEX_SENT;
		ptSet("OT", .01, FALSE);    // Send textures
        ptSet("OQ", oqTime, FALSE);
        
    }

    
    // Get the description of an effect affecting me
    else if( METHOD == NPCIntMethod$getTextureDesc ){
    
        if( id == "" )
            id = llGetOwner();
        
        integer pid = l2i(PARAMS, 0);
		string data = llLinksetDataRead(LSD_STOR_A+(str)pid);
		int stacks = (int)j(data, 4);
        llRegionSayTo(llGetOwnerKey(id), 0, evtsStringitizeDesc(
			llLinksetDataRead(LSD_STOR_D+(str)pid),
			stacks
		));
        
    }
    
    // Take hit animation
    else if(METHOD == NPCIntMethod$takehit){
        startAnim("hit");
        if(thSnd)
            llTriggerSound(randElem(thSnd), 1);
    }
    
    else if( METHOD == NPCIntMethod$rapeMe ){


		if( RF & Monster$RF_INVUL && !(RF&(Monster$RF_IS_BOSS|Monster$RF_ALWAYS_R)) )
			return;
			
        parseDesc(id, resources, status, fx, sex, team, mf, void, _a);

        if( team == TEAM )
            return;
    
        list ray = llCastRay(
			groundPoint()+<0,0,1+hAdd*0.5>, 
			prPos(id)+<0,0,1>, 
			RC_DEFAULT
		);
		
        if( llList2Integer(ray, -1) == 0 ){
        
            if( !isset(RN) )
                RN = llGetObjectName();
				
            Bridge$fetchRape(llGetOwnerKey(id), RN);
            
        }
        
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}

