#ifndef _PlayerPoser
#define _PlayerPoser

/*
	Anim syntax:
		Base = animName_a / animName_t
		Steps = animName_1_a / animName_1_t, for multiple animations increase 1 to 2, 3 etc
	
	Pose instigator animations _a are always on the root prim
	
	Links:
		Root prim is always seat #0
		After that you make prims and name them POSEBALL with description being the index of the seat. Such as 1 or 2
		
	Scripts:
		Make a copy of the number script and name it the same as the player index, root prim is 0. For two players you need a "1" script. For three a "2" script etc
		
	Description:
		When spawned the description is a JSON array with the following indexes:
		0 : (array)player_keys | UUIDs of players in order to put on this
		1 : (float)anim_min_time | Min time between animation triggers
		2 : (float)anim_max_time | Max time between animation triggers
		3 : (float)duration | Total duration of scene. Min 5
		4 : (int)flags | See below
		5 : (arr)player_flags
		6 : (arr)pos_offsets,
		7 : (arr)rot_offsets
		
	Example:
	list conf = [
		mkarr((list)llGetOwner()+"984845e6-1d42-471f-8234-12883eaf8c7a"),
		0.6, 1,
		10,
		0,
		mkarr((list)0+1)
	];
	gotPISpawner$spawn("Spanking", llGetPos()+(<0,0,1>), ZERO_ROTATION, mkarr(conf), FALSE, TRUE, "");
*/


// Note, this can only be run through a script due to JSON
#define gotPlayerPoserMethod$test 1			// list players, list player_flags, float anim_duration, float anim_min_time, float anim_max_time, int flags, (arr)pos_offsets, (arr)rot_offsets



#define gotPlayerPoserEvt$animStep 1		// (int)step | An animation step has triggered
#define gotPlayerPoserEvt$start 2			// void | All players seated
#define gotPlayerPoserEvt$end 3				// void | The poser is shutting down and deleting itself

//#define gotPlayerPoserFlag$

#define gotPlayerPoser$test( players, player_flags, duration, min_repeat_time, max_repeat_time, flags, pos_offsets, rot_offsets) \
	runOmniMethod("got PlayerPoser", gotPlayerPoserMethod$test, (list) \
		mkarr(players) + \
		mkarr(player_flags) + \
		duration + \
		min_repeat_time + \
		max_repeat_time + \
		flags + \
		mkarr(pos_offsets) + \
		mkarr(rot_offsets) \
	, TNN)
	
	



#endif
