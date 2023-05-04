#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"


list OST; // Output status to (key)id, (int)flags


#define SPSTRIDE 3
// Note: if you change this stride, you have to update in got GUI too, and that must be -1 to this stride
list C_SPI;	// cache spellicons. [(int)pix, (key)texture, (str)desc]
#define SPI_PIX 0				// Package ID. Used when fetching descriptions
#define SPI_TEXTURE 1			// 
#define SPI_DESC 2				// 

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
sendTextures( key target ){

	list out;
	integer i; int max = 8;
    for( ; i < count(C_SPI); i += SPSTRIDE ){
		
		int pix = l2i(C_SPI, i+SPI_PIX);
		str table = getFxPackageTableByIndex(pix);
		str tx = l2s(C_SPI, i+SPI_TEXTURE);
		str desc = l2s(C_SPI, i+SPI_DESC);
		int flags = (int)db4$fget(table, fxPackage$FLAGS);
		key sender = db4$fget(table, fxPackage$SENDER);
		if( ~flags & PF_DETRIMENTAL || sender == target || flags & PF_FULL_VIS ){		// Show beneficial effects and sender effects and effects with full vis flags
			out += 
				(list)pix +
				tx +
				(int)db4$fget(table, fxPackage$ADDED) + // time added
				(float)db4$fget(table, fxPackage$DUR)+ // duration
				(int)db4$fget(table, fxPackage$STACKS) + // stacks
				(int)db4$fget(table, fxPackage$FLAGS)
			;
		}
		
	}
	GUI$setSpellTextures(target, mkarr(out));
	
}

ptEvt(string id){
    if( id == "OT" ){ \
		integer i; \
        for( ; i<count(OST); i += 2 )\
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
		db4$freplace(gotTable$npcInt, gotTable$npcInt$directTargeting, "[]");	// Reset
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
			list direct;
			integer i;
			for(; i < count(OST); i += 2 ){
				if( l2i(OST, i+1) & NPCInt$targeting )
					direct += l2k(OST, i);	
			}
			db4$freplace(gotTable$npcInt, gotTable$npcInt$directTargeting, mkarr(direct));
            
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
        } \
		else if( nr == TASK_FXC_PARSE ){ \
			int i; list entries = llJson2List(s); \
			s = ""; \
			int needUpdate; \
			for(; i < count(entries); i += FXCPARSE$STRIDE ){ \
				int task = l2i(entries, i); \
				int pix = l2i(entries, i+1); \
				int pos = llListFindList(C_SPI, (list)pix); \
				if( task & FXCPARSE$ACTION_REM ){ \
					C_SPI = llDeleteSubList(C_SPI, pos, pos+SPSTRIDE-1); \
					needUpdate = TRUE; \
				} \
				else{ \
					str table = getFxPackageTableByIndex(pix); \
					list fxs = llJson2List(db4$fget(table, fxPackage$FXOBJS)); \
					int n; \
					for(; n < count(fxs); ++n ){ \
						str fx = l2s(fxs, n); \
						if( (int)j(fx, 0) == fx$ICON ){ \
							str desc = j(fx, 2); \
							str texture = j(fx, 1); \
							if( ~pos ) \
								C_SPI = llListReplaceList(C_SPI, (list)texture + desc, pos+1, pos+2); \
							else \
								C_SPI += (list)pix + texture + desc; \
							needUpdate = TRUE; \
						} \
					} \
				} \
			} \
			if( needUpdate ){ \
				BFL = BFL|BFL_TEX_SENT; \
				ptSet("OT", .01, FALSE);    \
				ptSet("OQ", oqTime, FALSE); \
			} \
		} \
		
		
    
    
    #include "xobj_core/_LM.lsl" 



    
    // Get the description of an effect affecting me
    if( METHOD == NPCIntMethod$getTextureDesc ){
    
        if( id == "" )
            id = llGetOwner();
        
        integer pix = l2i(PARAMS, 0);
		int pos = llListFindList(C_SPI, (list)pix);
		if( pos == -1 )
			return;
		str table = getFxPackageTableByIndex(pix);
		string data = l2s(C_SPI, pos+SPI_DESC);
		int stacks = (int)db4$fget(table, fxPackage$STACKS);
        llRegionSayTo(llGetOwnerKey(id), 0, evtsStringitizeDesc(
			data,
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

