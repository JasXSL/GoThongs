#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

#define TIMER_FRAME "a"
#define TIMER_ATTACK "b" 
#define TIMER_EXEC_ATTACK "c"
#define TIMER_WAYPOINT "d"

#define isAnimesh() (RUNTIME_FLAGS&Monster$RF_ANIMESH)

string chasetarg;       // Currently aggroed player
string tracktarg;		// Last aggroed player
list SEEKTARG;			// [(var)targ, (float)range, (str)callback] Target received from MonsterMethod$seek, either a vector or a key

vector lastseen;        // Position target was last seen at
vector rezpos;          // Position this was rezzed at. Used for roaming
list WPOINTS;			// Vector positions where the NPC heard the target last

integer STATE;          // Current movement state

#define dout(text) llSetText((str)(text), <1,1,1>, 1)

integer FXFLAGS;
key look_override = ""; // Key to override looking at from current target

// Conf
float aptitude = 3.0;	// Nr seconds to track a player after losing sight
float speed = 1;        // Movement speed, lower is faster
float hitbox = 3;       // Range of melee attacks
#define HITBOX_DEFAULT 1.5		// if hitbox is this value, use default
float atkspeed = 1;     // Time between melee attacks
float wander;           // Range to roam
float hoverHeight;		// Hover height. Primarily used for animesh
float lastFlank;		// llGetTime of last attempt to flank
list flankPoints;		// Points to go to


integer height_add;		// LOS check height offset from the default 0.5m above root prim
#define hAdd() ((float)height_add/10)

float fxSpeed = 1;			// FX speed modifier
float fxCooldownMod = 1;	// Used for attack speed

integer RUNTIME_FLAGS = Monster$RF_ANIMESH;  		// Flags that can be set from other script, see got Monster head file
integer RUNTIME_FLAGS_SPELL;	// Flags set from npcspells

#define getRF() (RUNTIME_FLAGS|RUNTIME_FLAGS_SPELL)

integer BFL = 0x20;            // Don't roam unless a player is in range
#define BFL_IN_RANGE 0x1            // Monster is within attack range
#define BFL_MOVING 0x2              // Currently moving somewhere
#define BFL_ATTACK_CD 0x4           // Waiting for attack
#define BFL_DEAD 0x8                // Monster is dead
#define BFL_CHASING 0x10            // Chasing a target

#define BFL_INITIALIZED 0x40        // Script initialized
#define BFL_SEEKING 0x80			// Seeking a target received by MonsterMethod$seek
//#define BFL_ANIMATOR_LOADED 0x80    // 
//#define BFL_MANEUVERING 0x100       // Trying to go around a monster blocking the path


#define BFL_STOPON BFL_DEAD
 
#define getSpeed() (speed*fxSpeed)
#define setState(n) STATE = n; raiseEvent(MonsterEvt$state, (str)STATE)

vector groundPoint(){
	
	vector root = llGetRootPosition();
	root.z -= hoverHeight;
	return root;

}

lookAt( vector pos ){
	
	if( BFL&BFL_DEAD )
		return;
	
	debugCommon("LookAt "+(str)isAnimesh());
	vector mpos = llGetPos();
	pos.z = mpos.z;
	if( isAnimesh() )
		llRotLookAt(llRotBetween(<1,0,0>, llVecNorm(pos-mpos)), 1, 1);
	else
		llLookAt(pos,1,1);
	

}

integer moveInDir( vector dir ){

	if( dir == ZERO_VECTOR )
		return FALSE;
    dir = llVecNorm(dir);
	vector gpos = groundPoint();		// Returns the bottom of the mesh which should be ground level unless flying maybe
    
	float sp = getSpeed();
	// Can move
    if( ~getRF()&Monster$RF_IMMOBILE && ~FXFLAGS&fx$F_ROOTED && sp != 0.0 ){
        
		// If walking about then slow down

        if( ~BFL&BFL_CHASING && ~BFL&BFL_SEEKING && sp > 0.75 )
			sp = 0.75;

		// Multiply direction by speed
        dir = dir*sp;
		
		bool flying = getRF()&Monster$RF_FLYING;
		rotation baseRot = llGetRootRotation();
		if( ~getRF()&Monster$RF_ANIMESH )
			baseRot = llEuler2Rot(<0,-PI_BY_TWO,0>)*baseRot;

		// Vertical raycast
		vector rayStart = gpos;
		
		// Nonflying tries to locate the ground in front of the monster
		float bz = -1; float az = 1;
		if( getRF()&Monster$RF_FLYING )	// Flying draws a straight line towards where they want to go, centered at their middlepoint
			bz = az = hoverHeight;

		// If flying, only cast directly to target
        list r = llCastRay(
			gpos+<0,0,hAdd()+1>*baseRot, 
			gpos+dir+<0,0,bz>*baseRot, 
			[RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS, RC_DATA_FLAGS, RC_GET_ROOT_KEY]
		);
        
		vector hit = l2v(r, 1);
		
		
		if( 
			(!flying && l2i(r, -1) <= 0) ||		// Not flying and not found (too steep drop)
			(flying && l2i(r, -1))				// Flying and found (blocked)
		){
            
			toggleMove(FALSE);
			return FALSE;
			
        }

		// Point on the ground to walk to
		vector z = llList2Vector(r, 1);
		
		// If flying, move directly in direction
		if( getRF()&Monster$RF_FLYING )
			z = gpos+dir;
		// Otherwise move to ground plus hoverheight
		// Not needed because hoverHeight is subtracted from gpos
		/*else
			z.z += hoverHeight;
		*/
		
		float dist = llVecMag(z-gpos);
		float speed = dist/2/sp;
		
		if( speed < 0.12 )
			speed = 0.12;
        llSetKeyframedMotion([z-gpos, speed], [KFM_DATA, KFM_TRANSLATION]);
        toggleMove(TRUE);
		
    }else 
		toggleMove(FALSE);
    
    if( ~getRF()&Monster$RF_NOROT && ~FXFLAGS&fx$F_STUNNED && (look_override == "" || look_override == NULL_KEY ) )
		lookAt(gpos+<dir.x, dir.y, 0>);
		
	
    return TRUE;
}


anim(string anim, integer start){
	integer meshAnim = (llGetInventoryType("ton MeshAnim") == INVENTORY_SCRIPT);
	if(start){
		if(meshAnim)MeshAnim$startAnim(anim);
		else{
			MaskAnim$start(anim);
		}
	}else{
		if(meshAnim)MeshAnim$stopAnim(anim);
		else MaskAnim$stop(anim);
	}
}

toggleMove( integer on ){

    if( on && ~BFL&BFL_MOVING && ~BFL&BFL_STOPON && ~getRF()&Monster$RF_IMMOBILE ){
	
        BFL = BFL|BFL_MOVING;
        anim("walk", true);
		
    }
	else if( !on && BFL&BFL_MOVING ){
	
        BFL = BFL&~BFL_MOVING;
        anim("walk", false);
        llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		
    }
}

#define updateLookAt() \
	if(~getRF()&Monster$RF_NOROT && ~FXFLAGS&fx$F_STUNNED){ \
		vector pp = prPos(chasetarg); \
		vector gpos = llGetRootPosition(); \
		if( look_override ) \
			pp = prPos(look_override); \
		lookAt(<pp.x, pp.y, gpos.z>); \
	}\

#define setAttackCooldown() \
	BFL = BFL|BFL_ATTACK_CD; \
	multiTimer([TIMER_ATTACK, 0, atkspeed*fxCooldownMod, FALSE]); \
	multiTimer([TIMER_EXEC_ATTACK])

timerEvent( string id, string data ){

    if( id == TIMER_FRAME ){
	
        if( BFL&BFL_STOPON || FXFLAGS&fx$F_STUNNED )
			return;
        
		int rf = getRF();
		
        // Try to find a target
        if( STATE == MONSTER_STATE_IDLE ){
		
            if(
				rf&(Monster$RF_IMMOBILE|Monster$RF_FOLLOWER) || FXFLAGS&fx$F_ROOTED
			)return;
            
			//llSetLinkPrimitiveParamsFast(2, [PRIM_TEXT, (str)wander+"\n"+portalConf$desc, <1,1,1>, 1]);
            // Find a random pos to go to. The random lets them pick different targets at random times.
            if( wander == 0 || llFrand(1)>.1 )
				return;
			
			vector rootPos = groundPoint();
            vector a = rootPos+<0,0,.5>;
            vector b = rootPos+<0,0,.5>+llVecNorm(<llFrand(2)-1,llFrand(2)-1,0>)*llFrand(wander);
            
			if( rf&Monster$RF_FLYING )
				b.z = rootPos.z;
			
			if( llVecDist(b, rezpos) > wander )
				return;
			
			// Movement, hAdd() is not added
            list ray = llCastRay(a, b, []);
            if( llList2Integer(ray, -1) == 0 ){
			
                lastseen = b;
				setState(MONSTER_STATE_SEEKING);
				
            }
			
        } 
        
        
		// Seeking a specific position. Or flanking around a player if flankPoints are not empty
        else if( STATE == MONSTER_STATE_SEEKING ){
		
			// If monster ignore this because monster overrides
            if( rf&Monster$RF_FOLLOWER ){
			
				setState(MONSTER_STATE_IDLE);
				return;
				
			}

			vector gpos = groundPoint();
			int flanking = count(flankPoints);
			float md = 0.25+flanking*.25;				// Min dist to be considered at target
			
			vector t = lastseen;		// Pos to go to
			vector mPos = llGetPos();
			
			// External defined target
			if( SEEKTARG ){ 
			
				t = l2v(SEEKTARG, 0);
				md = l2f(SEEKTARG, 1);
				if( llGetListEntryType(SEEKTARG, 0) != TYPE_VECTOR )
					t = prPos(l2s(SEEKTARG,0));
					
			}
			// Attemptint to flank
			else if( flanking ){
				
				t = ZERO_VECTOR;
				while( count(flankPoints) && t == ZERO_VECTOR ){
				
					vector point = l2v(flankPoints, 0);
					list ray = llCastRay(mPos, point, RC_DEFAULT);
					if( l2i(ray, -1) != 0 || llVecDist(<mPos.x,mPos.y,0>, <point.x,point.y,0>) < 0.25 )
						flankPoints = llDeleteSubList(flankPoints, 0, 0);
					else
						t = point;
			
				}
							
			}
			// We have waypoints to follow (tracking a lost target). Find the closest waypoint and pick that instead.
			else if( count(WPOINTS) ){
			
				// Find the closest visible waypoint
				int i;
				for( ; i < count(WPOINTS) && count(WPOINTS); ++i ){
					
					list ray = llCastRay(mPos, l2v(WPOINTS, i), RC_DEFAULT);
					
					int r = l2i(ray, -1);
					// Stop here
					if( r != 0 ){
					
						if( i ){
							
							lastseen = t = l2v(WPOINTS, i-1)-<0,0,1>;
							WPOINTS = llDeleteSubList(WPOINTS, 0, i-1);
							
						}
						
						jump found;
						
					}
				
				}
				// Nothing found so we can remove everything except the last
				if( count(WPOINTS) > 1 ){
					WPOINTS = (list)l2v(WPOINTS, -1);
				}
				@found;
				
			}
			
			
			float dist = llVecDist(<t.x, t.y, 0>, <gpos.x, gpos.y, 0>);
			
            if( 
				dist > md && 
				t != ZERO_VECTOR &&
				~rf&Monster$RF_IMMOBILE && 
				~FXFLAGS&fx$F_ROOTED
			){
			
				// See if the path to the target location is clear
                list ray = llCastRay(groundPoint()+<0,0,1+hAdd()>, t+<0,0,0.5>, [
					RC_DATA_FLAGS, RC_GET_ROOT_KEY, 
					RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL
				]);
				
				// We can walk there
                if(
					llList2Integer(ray, -1) == 0 || 
					l2k(ray, 0) == l2k(SEEKTARG, 0)
				){
				
					vector dir = t-gpos;		
					// move towards the target
                    if( moveInDir(dir) ){

						return;
						
					}
						
                }
				
				
            }
			
			// We could not move towards the target or we have reached the target.
			
			// Flanking gets priority over tracking last seen, but not seektarg
			if( flanking && SEEKTARG == [] ){
			
				flankPoints = llDeleteSubList(flankPoints, 0, 0);
				// If a flank pos still exists we can try to do that one instead. No need to change state yet!
				if( count(flankPoints) )
					return;
				
			}
			else{
			
				// We are seeking towards a scripted target location.
				if( SEEKTARG ){
				
					BFL = BFL&~BFL_SEEKING;
					if( dist < md )
						raiseEvent(MonsterEvt$seekComplete, l2s(SEEKTARG, 2));
					else
						raiseEvent(MonsterEvt$seekFail, l2s(SEEKTARG, 2));
						
					SEEKTARG = [];
					
				}
				
				// Unable to move towards the target so start deleting waypoints until maybe one fits
				lastseen = l2v(WPOINTS, 0);
				WPOINTS = llDeleteSubList(WPOINTS, 0, 0);
				if( lastseen != ZERO_VECTOR )
					return;
					
			}
			// Stop moving
			integer s = MONSTER_STATE_IDLE;
			if( chasetarg )
				s = MONSTER_STATE_CHASING;
			
			setState(s);
            
			toggleMove(FALSE);
            lastseen = ZERO_VECTOR;
            BFL = BFL&~BFL_CHASING;
			
        }
        

		
		// Tracking a player
        else if( STATE == MONSTER_STATE_CHASING ){
		
            BFL = BFL|BFL_CHASING;
			
            vector ppos = prPos(chasetarg);
            parseMonsterOffsets(chasetarg, crAdd, chAdd)		// Range offsets
			ppos.z += chAdd;
			
            // Player left sim or monster target died
            if( ppos == ZERO_VECTOR ){
			
				setState(MONSTER_STATE_IDLE);
                Status$dropAggro(chasetarg);
                
                // raiseEvent(MonsterEvt$lostTarget, chasetarg);
                chasetarg = "";
                toggleMove(FALSE);
                return;
				
            }
            
			vector ground = groundPoint();
			
			
			
			list ray = llCastRay(ground+<0,0,1+hAdd()>, prPos(chasetarg)+<0,0,.5>, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_ROOT_KEY);
			
            // Close enough to attack
			if( llVecDist(ppos, ground) <= hitbox+crAdd ){
			
				if( ~BFL&BFL_IN_RANGE )
                    raiseEvent(MonsterEvt$inRange, chasetarg);
				
				// This is where we request an attack
				if(
					atkspeed>0 && 
					~BFL&BFL_ATTACK_CD &&
					BFL&BFL_IN_RANGE && 
					~BFL&BFL_STOPON && 
					~FXFLAGS&(fx$F_PACIFIED|fx$F_STUNNED) && 
					~rf&Monster$RF_PACIFIED && 
					// Attack LOS, hAdd() IS added
					llList2Integer(ray, -1) == 0
				){
					
					// ParseDesc here to save time
					parseDesc(chasetarg, resources, status, fx, sex, team, mf, arm, _a);					
					// not attackable
					if(
						status&StatusFlags$NON_VIABLE ||
						fx&fx$UNVIABLE
					){
						return;
					}
					
					setAttackCooldown();
					raiseEvent(MonsterEvt$attackStart, mkarr([chasetarg]));					
					anim("attack", TRUE);
					multiTimer([TIMER_EXEC_ATTACK, 0, 0.1, FALSE]);
					
					
				}
				
                BFL = BFL|BFL_IN_RANGE;
				
			}
			// Too far away
			else{
			
				// Player moved out of melee range
				if( BFL&BFL_IN_RANGE ){
				
                    raiseEvent(MonsterEvt$lostRange, chasetarg);
                    BFL = BFL&~BFL_IN_RANGE;
					
                }
				
			}
			
			// Stop moving at half the hitbox
            if( llVecDist(ppos, ground) <= hitbox/2 ){
                
				updateLookAt();
				toggleMove(FALSE);
				
				myAngX(chasetarg, ang)
				if( rf & Monster$RF_FLANKING && llGetTime()-lastFlank > 6 && llFabs(ang) < PI_BY_TWO ){
					
					if( llListFindList(llJson2List(db4$fget(hudTable$npcInt, hudTable$npcInt$directTargeting)), (list)((str)chasetarg)) == -1 ){
					
						lastFlank = llGetTime();
						float deg = llFrand(PI*0.08); // Around 30 deg
						float first = -PI_BY_TWO;	// left side
						if( ang > 0 ){
							deg = -deg; 		// need to remove degrees to turn counter clockwise (to the right side)
							first = -first;		// Make first positive to jump to right side first
						}
						rotation fwd = prRot(chasetarg);
						flankPoints = (list)
							(ppos+zRotNorm( first, fwd )) +
							(ppos+zRotNorm( PI+deg, fwd )*1.25)
						;
						
						// Todo: Check if flank points can be reached
						STATE = MONSTER_STATE_SEEKING;
						
					}
					
				}
				
            }
            // Might be in range but should move closer
            else{

				// Cannot see the target
                if( llList2Integer(ray, -1) > 0 ){
				
					// Wipe waypoints because we can now collect new ones
					WPOINTS = [
						lastseen
					];
					multiTimer((list)TIMER_WAYPOINT + 0 + .1 + FALSE);
					setState(MONSTER_STATE_SEEKING);
					
                    if( rf&Monster$RF_FREEZE_AGGRO )
						return;
						
                    string desc = prDesc(llList2Key(ray, 0));
                    Status$dropAggro(chasetarg); 

					
					
                }
				
				// can see target
				else{
				
					vector add = <0,0,1+hAdd()-hoverHeight>;	// Meters to raytrace to above us and target
                    lastseen = ppos+add;
					

					
					vector dir = ppos-ground;	// Our ground position minus target ground position
					//if( rf & Monster$RF_FLYING )
					//	dir += <0,0,hoverHeight>;	// Make sure we hover
					/*
					if( ~getRF() & Monster$RF_IMMOBILE )
						qd("Moving to: "+(str)(ppos+dir));
					*/
                    // move towards player
                    moveInDir(dir);
					//qd("Move, dist is "+(str)llVecDist(ppos, llGetRootPosition())+" hitbox is "+(str)hitbox);
					
                }
				
            }
			
        }
        
    }
	// Timer run after an attack
    else if(id == TIMER_ATTACK){
		// Set it so we can attack again
		BFL = BFL&~BFL_ATTACK_CD;
    }
	
	else if( id == TIMER_EXEC_ATTACK )
		attack();
	
	else if(id == "INI"){
		LocalConf$ini();
	}
	
	else if( id == TIMER_WAYPOINT && STATE != MONSTER_STATE_CHASING ){
		
		int n = (int)data+1;
		vector pos = prPos(tracktarg);
		
		int NUM_WPOINTS = floor(aptitude*10);
		
		if( pos == ZERO_VECTOR || n >= NUM_WPOINTS )
			return;
		
		WPOINTS += pos;
		setState(MONSTER_STATE_SEEKING);
		multiTimer([TIMER_WAYPOINT, n, 0.1, FALSE]);
	
	}
	
}


onEvt(string script, integer evt, list data){
	
	if( script == "got SpellMan" && evt == SpellManEvt$complete ){
		setAttackCooldown();
	}

    if( script == "got Portal" && evt == evt$SCRIPT_INIT ){
	
        rezpos = llGetRootPosition();
        
		if( !portalConf$live )
			return;
        LocalConf$ini();
		multiTimer(["INI", "", 5, FALSE]);	// Some times localconf fails, I don't know why
		
    }
    
	// Tunnels legacy into the new command
    if( script == "got LocalConf" && evt == LocalConfEvt$iniData ){
	
		multiTimer(["INI"]);
		list out = [];	// Strided list
		integer i;
		for( ; i<count(data); i++ ){
		
			if( isset(l2s(data,i)) )
				out+= [i]+llList2List(data, i, i);
			
		}
		
		// Description should be applied first if received from localconf. 
		// Custom updates sent directly through Monster$updateSettings should be sent after initialization to prevent overwrites
		string override = portalConf$desc;
		if( isset(override) ){
		
			list dt = llJson2List(override);
			override = "";
			list_shift_each(dt, v,
				list d = llJson2List(v);
				if(llGetListEntryType(d, 0) == TYPE_INTEGER)
					out += llList2List(d, 0, 1);
			)
			
		}
		
		Monster$updateSettings(out);
		
    }
	
    else if(
		((script == "ton MeshAnim" || script == "jas MaskAnim") && evt == MeshAnimEvt$frame) || 
		(script == "got LocalConf" && evt==LocalConfEvt$emulateAttack)
	){
        
		list split = llParseString2List(llList2String(data,0), [";"], []);
        string task = llList2String(split, 0);
        
        if( task == FRAME_AUDIO )
			llPlaySound(llList2String(split,1), llList2Float(split,2));
        else if( script == "got LocalConf" && evt == LocalConfEvt$emulateAttack )
			attack();
        
    }
    
    else if(script == "got Status"){
	
        if( evt == StatusEvt$dead ){
		
            if( ~BFL&BFL_DEAD && llList2Integer(data,0) ){
                BFL = BFL|BFL_DEAD;
                toggleMove(FALSE);
				setState(MONSTER_STATE_IDLE);
				chasetarg = "";
            }
			
			else if( !l2i(data, 0) )
				BFL = BFL&~BFL_DEAD;
				
        }
		
		else if( evt == StatusEvt$monster_gotTarget ){
		
			chasetarg = llList2String(data, 0);
			if( chasetarg )
				tracktarg = chasetarg;
			
            if( BFL&(BFL_STOPON|BFL_SEEKING) )
				return;
				
            if( llList2String(data, 0) != "" )
				setState(MONSTER_STATE_CHASING);
            
			
        }
		
    }
    

}

attack(){

	list odata = llGetPrimitiveParams([PRIM_POSITION, PRIM_ROTATION]);
	list ifdata = llGetObjectDetails(chasetarg, [OBJECT_POS, OBJECT_ROT]);
	vector pos = llList2Vector(odata,0);
	vector dpos = llList2Vector(ifdata, 0);
	
	if(
		~getRF()&Monster$RF_NOROT && 
		chasetarg != "" && 
		(look_override == "" || look_override == NULL_KEY)
	)lookAt(<dpos.x, dpos.y, pos.z>);
	
	raiseEvent(MonsterEvt$attack, chasetarg);
	
}

// Settings received
onSettings(list settings){ 

	integer flagsChanged;
	while( settings ){
		integer idx = l2i(settings, 0);
		list dta = llList2List(settings, 1, 1);
		settings = llDeleteSubList(settings, 0, 1);
		
		// Flags
		if(idx == 0){
			RUNTIME_FLAGS = l2i(dta,0);
			flagsChanged = TRUE;
		}
		// Movement speed
		if(idx == 1 && l2f(dta,0)>0)
			speed = l2f(dta,0);
			
		// Hitbox
		if(idx == 2 && l2f(dta, 0) != HITBOX_DEFAULT)
			hitbox = l2f(dta, 0);
		
		// Attackspeed
		if(idx == 3)
			atkspeed = l2f(dta,0);
		
		if(idx == 5 && l2f(dta,0)>=0){
			wander = l2f(dta,0);
		}
        
		if( idx == MLC$height_add )
			height_add = l2i(dta,0);
		
		if( idx == MLC$hover_height )
			hoverHeight = l2f(dta, 0);
		
		if( idx == MLC$aptitude )
			aptitude = l2f(dta, 0);
			
		
	}
	
	// Limits
	if( speed <= 0 )
		speed = 1;
	if( hitbox <= 0 )
		hitbox = 3;
    
	if( flagsChanged )
		raiseEvent(MonsterEvt$runtimeFlagsChanged, (string)getRF());
	
	if( ~BFL&BFL_INITIALIZED ){
	
		BFL = BFL|BFL_INITIALIZED; 
		multiTimer([TIMER_FRAME, "", .25, TRUE]);
		raiseEvent(MonsterEvt$confIni, "");
		
	}
	
}

default{

    timer(){multiTimer([]);}
    
    state_entry(){
		llSetStatus(STATUS_PHANTOM, TRUE);
        if( llGetStartParameter() )
			raiseEvent(evt$SCRIPT_INIT, "");
			
    }
	/*
    #define LISTEN_LIMIT_LINK LINK_THIS
    #define LISTEN_LIMIT_FREETEXT if(llListFindList(PLAYERS, [(string)llGetOwnerKey(id)]) == -1)return;
    #include "xobj_core/_LISTEN.lsl"
    */
	
	#define LM_PRE \
	if(nr == TASK_FX){ \
		FXFLAGS = (int)fx$getDurEffect(fxf$SET_FLAG); \
		if( RUNTIME_FLAGS & Monster$RF_IS_BOSS ) \
			FXFLAGS = FXFLAGS&~fx$F_STUNNED; \
		if( FXFLAGS&fx$F_STUNNED_IMPORTANT ) \
			FXFLAGS = FXFLAGS|fx$F_STUNNED; \
		fxSpeed = (float)fx$getDurEffect(fxf$MOVE_SPEED); \
		fxCooldownMod = (float)fx$getDurEffect(fxf$COOLDOWN_MULTI); \
		if( FXFLAGS&(fx$F_STUNNED|fx$F_ROOTED) ) \
			toggleMove(FALSE); \
	} \
	else if(nr == TASK_MONSTER_SETTINGS){\
		onSettings(llJson2List(s)); \
	}\
	
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls: 
        METHOD - (int)method  
        INDEX - (int)obj_index   
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    if(method$isCallback){ 
        return;  
    }
    
    // Public
    if(METHOD == MonsterMethod$toggleFlags){
        integer pre = getRF();
		// Basic flags
		if(!l2i(PARAMS, 2)){
			RUNTIME_FLAGS = RUNTIME_FLAGS|(integer)method_arg(0);
			RUNTIME_FLAGS = RUNTIME_FLAGS&~(integer)method_arg(1);
        }
		// Spell flags
		else{
			RUNTIME_FLAGS_SPELL = RUNTIME_FLAGS_SPELL|(integer)method_arg(0);
			RUNTIME_FLAGS_SPELL = RUNTIME_FLAGS_SPELL&~(integer)method_arg(1);
		}
        
        raiseEvent(MonsterEvt$runtimeFlagsChanged, (string)getRF());
        if(getRF()&Monster$RF_IMMOBILE){
            toggleMove(FALSE);
        }  
        if(pre&Monster$RF_NOROT && getRF()&Monster$RF_NOROT){
            llStopLookAt();
        }
		
    }
	else if(METHOD == MonsterMethod$seekStop){
		BFL = BFL&~BFL_SEEKING;
		setState(MONSTER_STATE_IDLE);
	}
	else if(METHOD == MonsterMethod$seek){
		BFL = BFL|BFL_SEEKING;
		setState(MONSTER_STATE_SEEKING);
		SEEKTARG = [method_arg(0)];
		if((vector)method_arg(0))
			SEEKTARG = [(vector)method_arg(0)];
		SEEKTARG += l2f(PARAMS, 1);
		SEEKTARG += l2s(PARAMS, 2);
	}
	
    else if(METHOD == MonsterMethod$lookOverride){
		look_override = method_arg(0);
		updateLookAt();
	}
	else if(METHOD == MonsterMethod$atkspeed)atkspeed = (float)method_arg(0);
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"   
}
