/*
	This script was cloned from got Spawner and uses the same methods. But has custom methods too.
*/

#define LM_ON_METHOD(METHOD, PARAMS, id, SENDER_SCRIPT, CB) onMethod(METHOD, PARAMS, id, SENDER_SCRIPT, CB)
#define onEvtCustom( script, evt, data) onEvtCustom( script, evt, data)

#include "got/_core.lsl"

list PLAYERS;
list PLAYER_HUDS;

float _DUR;
vector _POS;
rotation _ROT;

// if pos is ZERO_VECTOR it positions at the first player's feet by raycasting
spawnScene( string name, float duration, float min_speed, float max_speed, list players, vector pos, rotation rot, list pflags ){
	
	key pl = l2k(players, 0);
	if( pos == ZERO_VECTOR ){
		pos = prPos(pl);
		if( pos == ZERO_VECTOR )
			return;
		list ray = llCastRay(pos, pos-<0,0,10>, (list)RC_REJECT_TYPES+(RC_REJECT_AGENTS|RC_REJECT_PHYSICAL));
		if( l2i(ray, -1) != 1 )
			return;
		pos = l2v(ray, 1);
		vector sc = llGetAgentSize(llGetOwnerKey(pl));
		pos.z += sc.z/2;
	}
	
	integer i;
	for(; i<count(players); ++i )
		players = llListReplaceList(players, (list)llGetOwnerKey(l2s(players, i)), i, i);
	
	list desc = [
		mkarr(players),
		min_speed,
		max_speed,
		duration,
		0,
		mkarr(pflags)
	];
	
	gotPISpawner$spawnTarg(LINK_THIS, name, pos, rot, mkarr(desc), FALSE, TRUE, "");
	
}

onMethod( integer METHOD, list PARAMS, key id, string SENDER_SCRIPT, string CB ){

	if( METHOD == gotPiSpawnerMethod$generateInteraction && method$byOwner ){
		
		list pl = llJson2List(method_arg(0));
		_DUR = l2f(PARAMS, 1);
		if( _DUR < 5 )
			_DUR = 5;
		else if( _DUR > 120 )
			_DUR = 120;
			
		_POS = (vector)method_arg(2);
		_ROT = (rotation)method_arg(3);
		
		
		list viable = [];	// HUDs found
		integer i;
		for( ; i<count(pl); ++i ){
			integer pos = llListFindList(PLAYER_HUDS, (list)l2s(pl, i));
			if( ~pos ){
				viable += (list)l2s(PLAYER_HUDS, i);
			}
			else{
				pos = llListFindList(PLAYERS, (list)l2s(pl, i));
				if( ~pos )
					viable += (list)l2s(PLAYER_HUDS, i);
			}
			// Instigator missing
			if( i == 0 && !count(viable) )
				return;
		}
		
		// Not enough players
		if( count(viable) < 2 ){		
			return;
		}
		
		// Split into pg and adult
		list pg;
		list adult;
		for( i=0; i<count(viable); ++i ){
			str t = l2s(viable, i);
			parsePCSettingFlags(t, flags);
			if( flags&BSUD$SFLAG_PVP_SEX )
				adult += t;
			else
				pg += t;
		}

		// Not enough adults to request or instigator is nonadult
		if( count(adult) < 2 || l2s(pg, 0) == l2s(viable, 0) ){
			// Spawn a spank
			spawnScene( 
				"Spanking", 
				_DUR, 
				0.7, 
				1.1, 
				llList2List(viable, 0, 1), 
				_POS, 
				_ROT,
				[0,0]
			);
			return;
		}
		
		pg = [];
		list out = [];
		for(i=0; i<count(adult); ++i){
			parseSex(l2s(adult, i), sex);
			out += mkarr((list)l2s(adult, i)+sex);
		}
		Bridge$getPVPScene(out);
		
	}
	
	if( method$internal && METHOD == gotPiSpawnerMethod$callback ){
		
		integer i;
		for(; i<count(PARAMS); ++i ){
			string block = l2s(PARAMS, i);
			spawnScene( 
				j(block, "scene" + 0), 
				_DUR, 
				(float)j(block, "scene" + 1), 
				(float)j(block, "scene" + 2), 
				llJson2List(j(block, "players")), 
				_POS, 
				_ROT,
				llJson2List(j(block, "scene" + 3))
			);
		}
				
		
	}

}

onEvtCustom( str script, int evt, list data ){

	if( script == "#ROOT" ){
		if( evt == RootEvt$coop_hud )
			PLAYER_HUDS = llListReplaceList(data, (list)((str)llGetLinkKey(LINK_ROOT)), 0, 0);
		else if( evt == RootEvt$players )
			PLAYERS = data;
	}
	

}


#include "got/classes/packages/got Spawner.lsl"
