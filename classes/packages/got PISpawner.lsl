/*
	This script was cloned from got Spawner and uses the same methods. But has custom methods too.
*/
#define USE_DB4
#define LM_ON_METHOD(METHOD, PARAMS, id, SENDER_SCRIPT, CB) onMethod(METHOD, PARAMS, id, SENDER_SCRIPT, CB)
#define TABLE gotTable$piSpawner

#include "got/_core.lsl"

float _DUR;
vector _POS;
rotation _ROT;

// if pos is ZERO_VECTOR it positions at the first player's feet by raycasting
spawnScene( string name, float duration, float min_speed, float max_speed, list players, vector pos, rotation rot, list pflags, list posOffs, list rotOffs ){
	
	if( duration < 5 )
		duration = 5;
	else if( duration > 120 )
		duration = 120;
	
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
		pos.z += sc.z/2+.1;
		
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
		mkarr(pflags),
		mkarr(posOffs),
		mkarr(rotOffs)
	];
	
	gotPISpawner$spawnTarg(LINK_THIS, name, pos, rot, mkarr(desc), FALSE, TRUE, "");
	
}

onMethod( integer METHOD, list PARAMS, key id, string SENDER_SCRIPT, string CB ){

	if( METHOD == gotPiSpawnerMethod$generateInteraction ){
		
		list pl = [];
		list _temp = llJson2List(method_arg(0));
		list_shift_each(_temp, val,
			pl += llGetOwnerKey(val);
		)
		
		_DUR = l2f(PARAMS, 1);
		_POS = (vector)method_arg(2);
		_ROT = (rotation)method_arg(3);
		int no_instigator = l2i(PARAMS, 4);
		
		list PLAYERS = hudGetPlayers();
		list PLAYER_HUDS = hudGetHuds();
		
		list viable = [];	// HUDs found
		integer i;
		for( ; i<count(pl); ++i ){
		
			integer pos = llListFindList(PLAYERS, (list)l2s(pl, i));
			if( ~pos )
				viable += (list)l2s(PLAYER_HUDS, pos);
			
			// Instigator missing
			if( i == 0 && !count(viable) && !no_instigator )
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
				[0,0],
				[],
				[0,"<0,0,1,0>"]
			);
			return;
			
		}
		
		pg = [];
		list out = [];
		for( i=0; i < count(adult); ++i ){
			
			parseSex(l2s(adult, i), sex);
			out += mkarr((list)l2s(adult, i)+sex);
			
		}
		
		//qd(mkarr(out));
		Bridge$getPVPScene(out, no_instigator);
		
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
				llJson2List(j(block, "scene" + 3)),
				llJson2List(j(block, "scene" + 5)),
				llJson2List(j(block, "scene" + 6))
				
			);
			
		}
		
	}
	
	if( method$byOwner && METHOD == gotPiSpawnerMethod$testInteraction ){
		
		float dur = l2f(PARAMS, 1);
		list players = llDeleteSubList(PARAMS, 0, 1);
		if( !count(players) ){
			qd("No players");
			return;
		}
		
		_DUR = dur;
		Bridge$testPVPScene(l2i(PARAMS, 0), players);
	
	}

}


#include "got/classes/packages/got Spawner.lsl"
